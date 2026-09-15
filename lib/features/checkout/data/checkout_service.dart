import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_storage.dart';

class CheckoutService {
  CheckoutService._();

  static final CheckoutService instance =
      CheckoutService._();

  static const String baseUrl =
      'https://jualbeli-v2-aldariaski-api.vercel.app';

  // ------------------------------------------------------------
  // GET JWT TOKEN
  // ------------------------------------------------------------

  Future<String> _getToken() async {
    final token =
        await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found.',
      );
    }

    return token;
  }

  // ------------------------------------------------------------
  // PLACE ORDER
  // ------------------------------------------------------------

  Future<int> placeOrder({
    String? email,
  }) async {
    final token =
        await _getToken();

    final uri = Uri.parse(
      '$baseUrl/orders/',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Failed to place order: '
        '${response.statusCode} '
        '${response.body}',
      );
    }

    final data =
        jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Invalid order response.',
      );
    }

    final orderId =
        data['orderId'];

    if (orderId == null) {
      throw Exception(
        'Order ID missing from response.',
      );
    }

    return int.parse(
      orderId.toString(),
    );
  }
}