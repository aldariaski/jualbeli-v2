import 'dart:convert';

import 'package:http/http.dart' as http;

class CheckoutService {
  CheckoutService._();

  static final CheckoutService instance =
      CheckoutService._();

  static const String baseUrl =
      'https://jualbeli-v2-aldariaski-api.vercel.app';

  Future<int> placeOrder({
    required String email,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/orders/',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
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

    final orderId = data['orderId'];

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