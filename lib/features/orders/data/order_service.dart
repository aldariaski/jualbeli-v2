import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_storage.dart';
import 'order_model.dart';

class OrderService {
  OrderService._();

  static final OrderService instance =
      OrderService._();

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
  // GET ORDERS
  // ------------------------------------------------------------

  Future<List<Order>> getOrders(
    String email,
  ) async {
    final token =
        await _getToken();

    final uri = Uri.parse(
      '$baseUrl/orders/',
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load orders: '
        '${response.statusCode} '
        '${response.body}',
      );
    }

    final data =
        jsonDecode(response.body);

    if (data is! Map<String, dynamic> ||
        data['orders'] is! List) {
      throw Exception(
        'Invalid orders response.',
      );
    }

    return (data['orders'] as List)
        .map(
          (item) => Order.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ------------------------------------------------------------
  // GET SINGLE ORDER
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> getOrder(
    String email,
    int orderId,
  ) async {
    final token =
        await _getToken();

    final uri = Uri.parse(
      '$baseUrl/orders/$orderId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load order: '
        '${response.statusCode} '
        '${response.body}',
      );
    }

    final data =
        jsonDecode(response.body);

    if (data is! Map<String, dynamic> ||
        data['order'] is! Map) {
      throw Exception(
        'Invalid order response.',
      );
    }

    return Map<String, dynamic>.from(
      data['order'],
    );
  }
}