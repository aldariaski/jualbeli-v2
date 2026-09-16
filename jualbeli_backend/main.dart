import 'dart:io';

import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:jualbeli_backend/database/database.dart';
import 'package:jualbeli_backend/routes/auth_routes.dart';
import 'package:jualbeli_backend/routes/product_routes.dart';
import 'package:jualbeli_backend/routes/cart_routes.dart';
import 'package:jualbeli_backend/routes/order_routes.dart';
import 'package:jualbeli_backend/middleware/auth_middleware.dart';

Future<void> main() async {
  try {
    final database = DatabaseConnection.instance;

    final host = Platform.environment['DB_HOST'] ?? 'localhost';
    final port =
        int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 3306;
    final databaseName =
        Platform.environment['DB_NAME'] ?? 'JualBeliDb';
    final username =
        Platform.environment['DB_USER'] ?? 'root';
    final password =
        Platform.environment['DB_PASSWORD'] ?? '';

    print('DB_HOST: $host');
    print('DB_PORT: $port');
    print('DB_NAME: $databaseName');
    print('Connecting to database...');

    await database.connect(
      host: host,
      port: port,
      databaseName: databaseName,
      username: username,
      password: password,
    );

    print('Database connected successfully.');

    final router = Router();

    router.get('/', (Request request) {
      return Response.ok('JualBeli Backend is running.');
    });

    router.mount(
      '/auth/',
      AuthRoutes().router.call,
    );

    router.mount(
      '/products/',
      ProductRoutes().router.call,
    );

    router.mount(
      '/cart/',
      Pipeline()
          .addMiddleware(AuthMiddleware.middleware)
          .addHandler(CartRoutes().router.call),
    );

    router.mount(
      '/orders/',
      Pipeline()
          .addMiddleware(AuthMiddleware.middleware)
          .addHandler(OrderRoutes.instance.router.call),
    );

    final handler = Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    final serverPort =
        int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

    print('Starting server on port $serverPort...');

    final server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      serverPort,
    );

    print(
      'JualBeli backend running on '
      'http://${server.address.host}:${server.port}',
    );
  } catch (e, stackTrace) {
    print('SERVER STARTUP ERROR: $e');
    print('STACK TRACE:');
    print(stackTrace);
    exit(255);
  }
}