import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_storage.dart';
import '../../product/data/product_model.dart';
import 'cart_item.dart';

class CartService {
  CartService._();

  static final CartService instance = CartService._();

  static const String baseUrl =
      'https://jualbeli-v2-aldariaski-api.vercel.app';

  // ------------------------------------------------------------
  // SERIALIZE CART REQUESTS
  // ------------------------------------------------------------

  Future<void> _requestLock = Future.value();

  Future<T> _withLock<T>(
    Future<T> Function() operation,
  ) {
    final previous = _requestLock;

    final completer = Completer<void>();

    _requestLock = completer.future;

    return previous.then((_) async {
      try {
        return await operation();
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
  }

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
  // GET CART
  // ------------------------------------------------------------

  Future<List<CartItem>> getCart(
    String email,
  ) {
    return _withLock(() async {
      final token =
          await _getToken();

      final uri = Uri.parse(
        '$baseUrl/cart/',
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
          'Failed to load cart: '
          '${response.statusCode} '
          '${response.body}',
        );
      }

      final data =
          jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid cart response.',
        );
      }

      final items = data['items'];

      if (items is! List) {
        return <CartItem>[];
      }

      return items
          .map(
            (item) => CartItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    });
  }

  // ------------------------------------------------------------
  // ADD PRODUCT
  // ------------------------------------------------------------

  Future<void> addProduct(
    String email,
    Product product,
  ) {
    return _withLock(() async {
      final token =
          await _getToken();

      final uri = Uri.parse(
        '$baseUrl/cart/',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode({
          'productId': product.id,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to add product to cart: '
          '${response.statusCode} '
          '${response.body}',
        );
      }
    });
  }

  // ------------------------------------------------------------
  // UPDATE QUANTITY
  // ------------------------------------------------------------

  Future<void> updateQuantity(
    String email,
    int productId,
    int quantity,
  ) {
    return _withLock(() async {
      if (quantity <= 0) {
        await _removeProductInternal(
          email,
          productId,
        );
        return;
      }

      final token =
          await _getToken();

      final uri = Uri.parse(
        '$baseUrl/cart/$productId',
      );

      final response = await http.put(
        uri,
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update cart: '
          '${response.statusCode} '
          '${response.body}',
        );
      }
    });
  }

  // ------------------------------------------------------------
  // REMOVE PRODUCT
  // ------------------------------------------------------------

  Future<void> removeProduct(
    String email,
    int productId,
  ) {
    return _withLock(() async {
      await _removeProductInternal(
        email,
        productId,
      );
    });
  }

  Future<void> _removeProductInternal(
    String email,
    int productId,
  ) async {
    final token =
        await _getToken();

    final uri = Uri.parse(
      '$baseUrl/cart/$productId',
    );

    final response = await http.delete(
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
        'Failed to remove product: '
        '${response.statusCode} '
        '${response.body}',
      );
    }
  }

  // ------------------------------------------------------------
  // CLEAR CART
  // ------------------------------------------------------------

  Future<void> clearCart(
    String email,
  ) {
    return _withLock(() async {
      final token =
          await _getToken();

      final uri = Uri.parse(
        '$baseUrl/cart/',
      );

      final response = await http.delete(
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
          'Failed to clear cart: '
          '${response.statusCode} '
          '${response.body}',
        );
      }
    });
  }
}