import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/auth_service.dart';
import '../middleware/auth_middleware.dart';

class AuthRoutes {
  final AuthService _authService;

  AuthRoutes({AuthService? authService})
    : _authService = authService ?? AuthService();

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.get('/me', AuthMiddleware.middleware(_me));
    router.post('/change-password', AuthMiddleware.middleware(_changePassword));

    return router;
  }

  Future<Response> _me(Request request) async {
    final userId = request.context['userId'];

    final email = request.context['userEmail'];

    return _jsonResponse(200, {
      'message': 'Authenticated successfully.',
      'userId': userId,
      'email': email,
    });
  }

  Future<Response> _changePassword(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = request.context['userEmail'] as String?;
      final currentPassword = body['currentPassword'] as String?;
      final newPassword = body['newPassword'] as String?;

      if (email == null || currentPassword == null || newPassword == null) {
        return _jsonResponse(400, {
          'message': 'Current and new passwords are required.',
        });
      }

      await _authService.changePassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return _jsonResponse(200, {'message': 'Password changed successfully.'});
    } catch (e) {
      return _jsonResponse(400, {
        'message': e.toString().replaceFirst('Exception: ', ''),
      });
    }
  }

  Future<Response> _register(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (name == null ||
          email == null ||
          password == null ||
          name.trim().isEmpty ||
          email.trim().isEmpty ||
          password.isEmpty) {
        return _jsonResponse(400, {
          'message': 'Name, email, and password are required.',
        });
      }

      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      return _jsonResponse(201, {
        'message': 'Registration successful.',
        'user': {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'createdAt': user.createdAt?.toIso8601String(),
        },
      });
    } catch (e) {
      return _jsonResponse(400, {
        'message': e.toString().replaceFirst('Exception: ', ''),
      });
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null ||
          password == null ||
          email.trim().isEmpty ||
          password.isEmpty) {
        return _jsonResponse(400, {
          'message': 'Email and password are required.',
        });
      }

      final result = await _authService.login(email: email, password: password);

      return _jsonResponse(200, {
        'message': 'Login successful.',
        'token': result.token,
        'user': {
          'id': result.user.id,
          'name': result.user.name,
          'email': result.user.email,
        },
      });
    } catch (e) {
      return _jsonResponse(401, {
        'message': e.toString().replaceFirst('Exception: ', ''),
      });
    }
  }

  Response _jsonResponse(int statusCode, Map<String, dynamic> body) {
    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
  }
}
