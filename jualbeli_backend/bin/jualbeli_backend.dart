import 'dart:io';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/database/database.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/product_routes.dart';
import '../lib/routes/cart_routes.dart';
import '../lib/routes/order_routes.dart';
import '../lib/middleware/auth_middleware.dart';

Future<void> main() async {
  final database = DatabaseConnection.instance;

  // Retrieve database configuration from environment variables with fallback defaults
  final host = Platform.environment['DB_HOST'] ?? 'localhost';
  final port = int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 3306;
  final databaseName = Platform.environment['DB_NAME'] ?? 'jualbeli_db';
  final username = Platform.environment['DB_USER'] ?? 'root';
  final password = Platform.environment['DB_PASSWORD'] ?? '';

  await database.connect(
    host: host,
    port: port,
    databaseName: databaseName,
    username: username,
    password: password,
  );

  final router = Router();

  router.get('/', (Request request) {
    return Response.ok(
      'JualBeli Backend is running.',
    );
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

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final serverPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    serverPort,
  );

  print(
    'JualBeli backend running on '
    'http://${server.address.host}:${server.port}',
  );
}