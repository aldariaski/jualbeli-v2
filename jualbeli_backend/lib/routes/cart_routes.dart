import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/cart_service.dart';
import '../middleware/auth_middleware.dart';

class CartRoutes {
  final CartService _service;

  CartRoutes({
    CartService? service,
  }) : _service =
            service ?? CartService();

  Router get router {
    final router = Router();

    router.get(
      '/',
      _getCart,
    );

    router.post(
      '/',
      _addToCart,
    );

    router.put(
      '/<productId|[0-9]+>',
      _updateQuantity,
    );

    router.delete(
      '/<productId|[0-9]+>',
      _removeFromCart,
    );

    router.delete(
      '/',
      _clearCart,
    );

    return router;
  }

  Future<Response> _getCart(
    Request request,
  ) async {
    final email =
        request.context['userEmail'] as String;

    try {
      final items =
          await _service.getCart(email);

      return _jsonResponse(
        200,
        {
          'items': items
              .map((item) => item.toMap())
              .toList(),
        },
      );
    } catch (e) {
      print('GET /cart error: $e');

      return _jsonResponse(
        500,
        {
          'message': 'Failed to load cart.',
          'error': e.toString(),
        },
      );
    }
  }

  Future<Response> _addToCart(
    Request request,
  ) async {
    try {
      final body = jsonDecode(
        await request.readAsString(),
      );

      if (body is! Map<String, dynamic>) {
        return _jsonResponse(
          400,
          {
            'message': 'Invalid request body.',
          },
        );
      }

      final productId = body['productId'];

      if (productId is! int) {
        return _jsonResponse(
          400,
          {
            'message': 'productId is required.',
          },
        );
      }

      final email =
          request.context['userEmail'] as String;

      await _service.addToCart(
        email,
        productId,
      );

      return _jsonResponse(
        200,
        {
          'message':
              'Product added to cart.',
        },
      );
    } catch (e) {
      print('POST /cart error: $e');

      final message = e.toString().replaceFirst('Exception: ', '');
      final statusCode = message == 'You cannot buy a product from yourself.'
          ? 409
          : message == 'Product not found.'
              ? 404
              : 500;

      return _jsonResponse(
        statusCode,
        {
          'message':
              'Failed to add product to cart.',
          'error': message,
        },
      );
    }
  }

  Future<Response> _updateQuantity(
    Request request,
    String productId,
  ) async {
    try {
      final body = jsonDecode(
        await request.readAsString(),
      );

      if (body is! Map<String, dynamic>) {
        return _jsonResponse(
          400,
          {
            'message': 'Invalid request body.',
          },
        );
      }

      final quantity = body['quantity'];

      if (quantity is! int) {
        return _jsonResponse(
          400,
          {
            'message': 'quantity is required.',
          },
        );
      }

      final email =
          request.context['userEmail'] as String;

      final id = int.tryParse(productId);

      if (id == null) {
        return _jsonResponse(
          400,
          {
            'message': 'Invalid product ID.',
          },
        );
      }

      await _service.updateQuantity(
        email,
        id,
        quantity,
      );

      return _jsonResponse(
        200,
        {
          'message': 'Cart updated.',
        },
      );
    } catch (e) {
      print(
        'PUT /cart/$productId error: $e',
      );

      return _jsonResponse(
        500,
        {
          'message':
              'Failed to update cart.',
          'error': e.toString(),
        },
      );
    }
  }

  Future<Response> _removeFromCart(
  Request request,
  String productId,
  ) async {
    final email =
        request.context['userEmail'] as String;

    try {
      final id = int.tryParse(productId);

      if (id == null) {
        return _jsonResponse(
          400,
          {
            'message':
                'Invalid product ID.',
          },
        );
      }

      await _service.removeFromCart(
        email,
        id,
      );

      return _jsonResponse(
        200,
        {
          'message':
              'Product removed from cart.',
        },
      );
    } catch (e) {
      print(
        'DELETE /cart/$productId error: $e',
      );

      return _jsonResponse(
        500,
        {
          'message':
              'Failed to remove product.',
          'error': e.toString(),
        },
      );
    }
  }

  Future<Response> _clearCart(
    Request request,
  ) async {
    final email =
      request.context['userEmail'] as String;

    if (email == null || email.isEmpty) {
      return _jsonResponse(
        400,
        {
          'message': 'Email is required.',
        },
      );
    }

    try {
      await _service.clearCart(email);

      return _jsonResponse(
        200,
        {
          'message': 'Cart cleared.',
        },
      );
    } catch (e) {
      print('DELETE /cart error: $e');

      return _jsonResponse(
        500,
        {
          'message':
              'Failed to clear cart.',
          'error': e.toString(),
        },
      );
    }
  }

  Response _jsonResponse(
    int statusCode,
    Map<String, dynamic> body,
  ) {
    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: {
        'content-type':
            'application/json',
      },
    );
  }
}