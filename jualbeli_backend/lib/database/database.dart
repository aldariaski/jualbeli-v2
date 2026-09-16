import 'dart:async';
import 'dart:io';

import 'package:mysql_dart/mysql_dart.dart';
import 'mysql_compat.dart';

class DatabaseConnection {
  DatabaseConnection._();

  static final DatabaseConnection instance =
      DatabaseConnection._();

  MySQLConnection? _connection;

  String? _host;
  int? _port;
  String? _username;
  String? _password;
  String? _databaseName;

  bool _connecting = false;

  Future<void> _operationQueue = Future.value();

  Future<void> connect({
    required String host,
    required int port,
    required String databaseName,
    required String username,
    required String password,
  }) async {
    _host = host;
    _port = port;
    _databaseName = databaseName;
    _username = username;
    _password = password;

    await _connect();
  }

  SecurityContext _createSecurityContext() {
    final context = SecurityContext(
      withTrustedRoots: true,
    );

    final caCertificate =
        Platform.environment['CA_CERT'];

    if (caCertificate != null &&
        caCertificate.trim().isNotEmpty) {
      print('Loading TiDB CA certificate...');

      context.setTrustedCertificatesBytes(
        caCertificate.codeUnits,
      );

      print('TiDB CA certificate loaded.');

      return context;
    }

    final caPath =
        Platform.environment['CA_PATH'];

    if (caPath != null &&
        caPath.trim().isNotEmpty) {
      final file = File(caPath);

      if (!file.existsSync()) {
        throw Exception(
          'CA_PATH does not exist: $caPath',
        );
      }

      print(
        'Loading TiDB CA certificate from $caPath',
      );

      context.setTrustedCertificates(
        caPath,
      );

      return context;
    }

    print(
      'No custom CA provided. '
      'Using system trusted certificates.',
    );

    return context;
  }

  Future<void> _connect() async {
    if (_connection != null &&
        _connection!.connected) {
      return;
    }

    if (_connecting) {
      while (_connecting) {
        await Future.delayed(
          const Duration(milliseconds: 50),
        );
      }

      return;
    }

    _connecting = true;

    print('========================================');
    print('Connecting to MySQL/TiDB...');
    print('Host: $_host');
    print('Port: $_port');
    print('Database: $_databaseName');
    print('User: $_username');
    print('TLS: enabled');
    print('========================================');

    try {
      final securityContext =
          _createSecurityContext();

      final connection =
          await MySQLConnection.createConnection(
        host: _host!,
        port: _port!,
        userName: _username!,
        password: _password!,
        databaseName: _databaseName!,
        secure: true,
        securityContext: securityContext,
      );

      await connection.connect();

      _connection = connection;

      print('========================================');
      print('MYSQL/TIDB CONNECTED');
      print('Database connection successful!');
      print('TLS connection established.');
      print('========================================');
    } catch (e, stackTrace) {
      _connection = null;

      print('========================================');
      print('MYSQL/TIDB CONNECTION ERROR');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      print('========================================');

      rethrow;
    } finally {
      _connecting = false;
    }
  }

  Future<T> _withLock<T>(
    Future<T> Function() operation,
  ) {
    final previous = _operationQueue;

    final completer = Completer<void>();

    _operationQueue = completer.future;

    return previous.then((_) async {
      try {
        return await operation();
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
  }

  Future<IResultSet> query(
    String sql, [
    List<Object?>? positionalParams,
  ]) {
    return _withLock(() async {
      await _connect();

      try {
        return await _executePositional(
          sql,
          positionalParams,
        );
      } catch (e) {
        print(
          'Database query failed: $e',
        );

        await _reconnect();

        return await _executePositional(
          sql,
          positionalParams,
        );
      }
    });
  }

  Future<IResultSet> execute(
    String sql, [
    List<Object?>? positionalParams,
  ]) {
    return query(
      sql,
      positionalParams,
    );
  }

  Future<IResultSet> _executePositional(
    String sql,
    List<Object?>? params,
  ) async {
    /*
     * mysql_dart 3.0.0 supports positional parameters
     * through execute().
     *
     * If there are no parameters, execute directly.
     */

    if (params == null || params.isEmpty) {
      return await _connection!.execute(sql);
    }

    /*
     * Convert:
     *
     *   SELECT * FROM users WHERE id = ?
     *
     * into:
     *
     *   SELECT * FROM users WHERE id = :p0
     *
     * and provide:
     *
     *   { "p0": value }
     */

    var convertedSql = sql;

    final parameters =
        <String, dynamic>{};

    for (var i = 0; i < params.length; i++) {
      final parameterName = 'p$i';

      convertedSql =
          convertedSql.replaceFirst(
        '?',
        ':$parameterName',
      );

      parameters[parameterName] =
          params[i];
    }

    return await _connection!.execute(
      convertedSql,
      parameters,
    );
  }

  Future<void> _reconnect() async {
    final oldConnection = _connection;

    _connection = null;

    if (oldConnection != null) {
      try {
        await oldConnection.close();
      } catch (_) {}
    }

    await _connect();
  }

  Future<T> transaction<T>(
    Future<T> Function(
      MySQLConnection connection,
    ) operation,
  ) {
    return _withLock(() async {
      await _connect();

      return await _connection!.transactional<T>(
        operation,
      );
    });
  }

  Future<void> close() async {
    final connection = _connection;

    _connection = null;

    if (connection != null) {
      try {
        await connection.close();
      } catch (e) {
        print(
          'Database close error: $e',
        );
      }
    }
  }
}