import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:jualbeli_backend/database/database.dart';
import 'package:jualbeli_backend/middleware/auth_middleware.dart';
import 'package:jualbeli_backend/routes/auth_routes.dart';
import 'package:jualbeli_backend/routes/cart_routes.dart';
import 'package:jualbeli_backend/routes/order_routes.dart';
import 'package:jualbeli_backend/routes/product_routes.dart';

Future<void> main() async {
// ------------------------------------------------------------
// Database configuration
// ------------------------------------------------------------

final database = DatabaseConnection.instance;

final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';

final dbPort =
int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 3306;

final dbName =
Platform.environment['DB_NAME'] ?? 'jualbeli_db';

final dbUser =
Platform.environment['DB_USER'] ?? 'root';

final dbPassword =
Platform.environment['DB_PASSWORD'] ?? '';

await database.connect(
host: dbHost,
port: dbPort,
databaseName: dbName,
username: dbUser,
password: dbPassword,
);

// ------------------------------------------------------------
// Router
// ------------------------------------------------------------

final router = Router();

// Health check
router.get('/', (Request request) {
return Response.ok(
'JualBeli Backend is running.',
);
});

// Authentication
router.mount(
'/auth/',
AuthRoutes().router.call,
);

// Products
router.mount(
'/products/',
ProductRoutes().router.call,
);

// Cart
router.mount(
'/cart/',
Pipeline()
.addMiddleware(AuthMiddleware.middleware)
.addHandler(CartRoutes().router.call),
);

// Orders
router.mount(
'/orders/',
Pipeline()
.addMiddleware(AuthMiddleware.middleware)
.addHandler(OrderRoutes.instance.router.call),
);

// ------------------------------------------------------------
// Middleware
// ------------------------------------------------------------

final handler = Pipeline()
.addMiddleware(corsHeaders())
.addMiddleware(logRequests())
.addHandler(router.call);

// ------------------------------------------------------------
// Server
// ------------------------------------------------------------

// Vercel provides PORT automatically.
// Locally, the backend continues to use port 8080.
final serverPort =
int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

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
