import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../auth/data/auth_storage.dart';
import 'payment_record.dart';

class PaymentService {
  PaymentService._();

  static final instance = PaymentService._();
  static const baseUrl = 'https://jualbeli-v2-aldariaski-api.vercel.app';

  Future<double> getBalance() async {
    final response = await _authorizedGet('/payments/balance');
    return (response['balance'] as num).toDouble();
  }

  Future<double> topUp(double amount) async {
    if (amount <= 0) throw Exception('Top-up amount must be greater than zero.');
    final response = await _authorizedPost('/payments/top-up', {'amount': amount});
    return (response['balance'] as num).toDouble();
  }

  Future<void> payOrder(int orderId) async {
    await _authorizedPost('/payments/orders/$orderId/pay', {});
  }

  Future<List<PaymentRecord>> getPaymentHistory() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/orders/payments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(_message(response.body, response.statusCode));
    }

    final data = _parseJson(response.body);
    if (data is! Map || data['payments'] is! List) {
      throw Exception('Invalid payment history response.');
    }

    return (data['payments'] as List)
        .map((item) => PaymentRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> _authorizedGet(String path) async {
    final token = await _token();
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: {'Authorization': 'Bearer $token'});
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _authorizedPost(String path, Map<String, dynamic> body) async {
    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<String> _token() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Authentication token not found.');
    return token;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response.body, response.statusCode));
    }
    final data = _parseJson(response.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid payment response.');
    return data;
  }

  dynamic _parseJson(String body) {
    if (body.trim().isEmpty) {
      throw Exception('Payment service returned an empty response.');
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      final preview = body.trim().replaceAll(RegExp(r'\s+'), ' ');
      throw Exception(
        'Payment service returned an invalid response: '
        '${preview.length > 120 ? '${preview.substring(0, 120)}...' : preview}',
      );
    }
  }

  String _message(String body, int statusCode) {
    try {
      final data = _parseJson(body);
      if (data is Map && data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return 'Payment failed ($statusCode).';
  }
}
