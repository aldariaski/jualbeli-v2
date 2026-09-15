import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      'https://jualbeli-v2-aldariaski-api.vercel.app';

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body)
        as Map<String, dynamic>;

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ?? 'Registration failed.',
      );
    }

    return body;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body)
        as Map<String, dynamic>;

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ?? 'Login failed.',
      );
    }

    return body;
  }
}

