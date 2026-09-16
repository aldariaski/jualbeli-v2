import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:jualbeli_backend/database/database.dart';
import 'package:jualbeli_backend/routes/auth_routes.dart';
import 'package:jualbeli_backend/routes/product_routes.dart';
import 'package:jualbeli_backend/routes/cart_routes.dart';
import 'package:jualbeli_backend/routes/order_routes.dart';
import 'package:jualbeli_backend/middleware/auth_middleware.dart';

Future<void>? _databaseInitialization;

Future<void> _connectDatabase() async {
  final database = DatabaseConnection.instance;

  final host = Platform.environment['DB_HOST'] ?? 'localhost';
  final port =
      int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 3306;
  final databaseName =
      Platform.environment['DB_NAME'] ?? 'jualbeli_db';
  final username =
      Platform.environment['DB_USER'] ?? 'root';
  final password =
      Platform.environment['DB_PASSWORD'] ?? '';

  await database.connect(
    host: host,
    port: port,
    databaseName: databaseName,
    username: username,
    password: password,
  );
}

Future<void> _ensureDatabaseConnection() {
  return _databaseInitialization ??= _connectDatabase();
}

final router = Router()
  ..get('/', (Request request) {
    return Response.ok(
      'JualBeli Backend is running.',
    );
  })
  ..mount(
    '/auth/',
    AuthRoutes().router.call,
  )
  ..mount(
    '/products/',
    ProductRoutes().router.call,
  )
  ..mount(
    '/cart/',
    Pipeline()
        .addMiddleware(AuthMiddleware.middleware)
        .addHandler(CartRoutes().router.call),
  )
  ..mount(
    '/orders/',
    Pipeline()
        .addMiddleware(AuthMiddleware.middleware)
        .addHandler(OrderRoutes.instance.router.call),
  );

final appHandler = const Pipeline()
    .addMiddleware(corsHeaders())
    .addMiddleware(logRequests())
    .addHandler(router.call);

Future<Response> handler(Request request) async {
  await _ensureDatabaseConnection();

  return appHandler(request);
}