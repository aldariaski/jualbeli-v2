import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/auth_storage.dart';

class PaymentService {
  PaymentService._();

  static final instance = PaymentService._();
  static const _balanceKeyPrefix = 'wallet_balance_';
  static const baseUrl = 'https://jualbeli-v2-aldariaski-api.vercel.app';

  Future<double> getBalance() async {
    final key = await _userBalanceKey();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key) ?? 0;
  }

  Future<double> topUp(double amount) async {
    if (amount <= 0) throw Exception('Top-up amount must be greater than zero.');
    final balance = await getBalance() + amount;
    final key = await _userBalanceKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, balance);
    return balance;
  }

  Future<void> payOrder(int orderId, double amount) async {
    final balance = await getBalance();
    if (balance < amount) throw Exception('Insufficient wallet balance.');

    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Authentication token not found.');

    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/pay'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      throw Exception(_message(response.body, response.statusCode));
    }

    final prefs = await SharedPreferences.getInstance();
    final key = await _userBalanceKey();
    await prefs.setDouble(key, balance - amount);
  }

  Future<String> _userBalanceKey() async {
    final email = await AuthStorage.getCurrentUserEmail();
    if (email == null || email.trim().isEmpty) {
      throw Exception('Authentication user not found.');
    }

    return '$_balanceKeyPrefix${email.trim().toLowerCase()}';
  }

  String _message(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return 'Payment failed ($statusCode).';
  }
}
