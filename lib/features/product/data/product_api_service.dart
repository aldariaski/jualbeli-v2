import 'dart:convert';

import 'package:http/http.dart' as http;

import 'product_model.dart';
import '../../auth/data/auth_storage.dart';

class ProductApiService {
  static const String baseUrl = 'https://jualbeli-v2-aldariaski-api.vercel.app';

  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products/'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    final List products = data['products'];

    return products
        .map((json) => Product.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<Product> getProduct(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load product: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    return Product.fromJson(Map<String, dynamic>.from(data['product']));
  }

  Future<Product> createProduct({
    required String name,
    required double price,
    String? image,
    required String category,
    required String sellerEmail,
    required String sellerName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'price': price,
        'image': image,
        'category': category,
        'sellerEmail': sellerEmail,
        'sellerName': sellerName,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to create product: '
        '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return Product.fromJson(Map<String, dynamic>.from(data['product']));
  }

  Future<Product> updateProduct({
    required int id,
    required String name,
    required double price,
    String? image,
    required String category,
  }) async {
    final token = await AuthStorage.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'image': image,
        'category': category,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update product.');
    }

    return Product.fromJson(Map<String, dynamic>.from(data['product']));
  }
}
