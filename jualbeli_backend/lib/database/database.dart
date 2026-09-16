import 'dart:async';
import 'dart:io';

import 'package:mysql1/mysql1.dart';

class DatabaseConnection {
  DatabaseConnection._();

  static final DatabaseConnection instance = DatabaseConnection._();

  MySqlConnection? _connection;

  String? _host;
  int? _port;
  String? _username;
  String? _password;
  String? _databaseName;

  bool _connecting = false;

  Future<void> _operationQueue = Future.value();

  bool _caLoaded = false;

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

    _loadCaCertificate();

    await _connect();
  }

  void _loadCaCertificate() {
    if (_caLoaded) {
      return;
    }

    final caCert = Platform.environment['CA_CERT'];

    if (caCert != null && caCert.trim().isNotEmpty) {
      print('Loading CA certificate from CA_CERT...');

      SecurityContext.defaultContext.setTrustedCertificatesBytes(
        caCert.codeUnits,
      );

      _caLoaded = true;

      print('CA certificate loaded successfully.');

      return;
    }

    final caPath = Platform.environment['CA_PATH'];

    if (caPath != null && caPath.trim().isNotEmpty) {
      print('Loading CA certificate from: $caPath');

      final file = File(caPath);

      if (!file.existsSync()) {
        throw Exception(
          'CA_PATH does not exist: $caPath',
        );
      }

      SecurityContext.defaultContext.setTrustedCertificates(
        caPath,
      );

      _caLoaded = true;

      print('CA certificate loaded successfully.');

      return;
    }

    print(
      'No custom CA certificate supplied. '
      'Using system trusted certificates.',
    );

    _caLoaded = true;
  }

  Future<void> _connect() async {
    if (_connection != null) {
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
      final settings = ConnectionSettings(
        host: _host!,
        port: _port!,
        user: _username!,
        password: _password!,
        db: _databaseName!,
        useSSL: true,
        timeout: const Duration(seconds: 30),
      );

      _connection = await MySqlConnection.connect(
        settings,
      );

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

  Future<Results> query(
    String sql, [
    List<Object?>? positionalParams,
  ]) {
    return _withLock(() async {
      await _connect();

      try {
        return await _connection!.query(
          sql,
          positionalParams,
        );
      } catch (e) {
        print('Database query failed: $e');

        final oldConnection = _connection;

        _connection = null;

        if (oldConnection != null) {
          try {
            await oldConnection.close();
          } catch (_) {}
        }

        await _connect();

        return await _connection!.query(
          sql,
          positionalParams,
        );
      }
    });
  }

  Future<Results> execute(
    String sql, [
    List<Object?>? positionalParams,
  ]) {
    return query(
      sql,
      positionalParams,
    );
  }

  Future<T> transaction<T>(
    Future<T> Function(
      MySqlConnection connection,
    ) operation,
  ) async {
    return _withLock(() async {
      await _connect();

      try {
        return await _connection!.transaction(
          (ctx) async {
            return await operation(
              _connection!,
            );
          },
        ) as T;
      } catch (e) {
        print('Database transaction failed: $e');
        rethrow;
      }
    });
  }

  Future<void> close() async {
    final connection = _connection;

    _connection = null;

    if (connection != null) {
      try {
        await connection.close();
      } catch (e) {
        print('Database close error: $e');
      }
    }
  }
}

extension ResultRowMapExtension on ResultRow {
  Map<String, dynamic> toColumnMap() {
    final map = <String, dynamic>{};

    if (fields != null) {
      for (var i = 0; i < fields!.length; i++) {
        final name = fields![i].name;

        if (name != null) {
          map[name] = this[i];
        }
      }
    }

    return map;
  }
}