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

    print('Connecting to MySQL...');
    print('Host: $_host');
    print('Port: $_port');
    print('Database: $_databaseName');
    print('User: $_username');

    try {
      final settings = ConnectionSettings(
        host: _host!,
        port: _port!,
        user: _username!,
        password: _password!,
        db: _databaseName!,
        timeout: const Duration(seconds: 30),
        useSSL: true,
      );

      _connection = await MySqlConnection.connect(settings);

      print('========== MYSQL CONNECTED ==========');
      print('Database connection successful!');
      print('=====================================');
    } catch (e, stackTrace) {
      _connection = null;

      print('========== MYSQL ERROR ==========');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      print('=================================');

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

        _connection = null;

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
    return query(sql, positionalParams);
  }

  Future<T> transaction<T>(
    Future<T> Function(MySqlConnection connection) operation,
  ) async {
    return _withLock(() async {
      await _connect();

      try {
        return await _connection!.transaction(
          (ctx) async {
            return await operation(_connection!);
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

// ====================================================================
// ResultRow Extension
// Converts mysql1 ResultRow to a Column Name Map
// ====================================================================

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