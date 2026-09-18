import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/product_service.dart';
import '../middleware/auth_middleware.dart';

class ProductRoutes {
  final ProductService _productService;

  ProductRoutes({ProductService? productService})
    : _productService = productService ?? ProductService();

  Router get router {
    final router = Router();

    router.post('/', _createProduct);
    router.get('/', _getProducts);
    router.get('/<id|[0-9]+>', _getProduct);
    router.put(
      '/<id|[0-9]+>',
      AuthMiddleware.middleware(_updateProductHandler),
    );

    return router;
  }

  Future<Response> _createProduct(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final product = await _productService.createProduct(
        name: body['name'],
        price: (body['price'] as num).toDouble(),
        image: body['image'],
        category: body['category'],
        sellerEmail: body['sellerEmail'],
        sellerName: body['sellerName'],
      );

      return _jsonResponse(201, {
        'message': 'Product created successfully.',
        'product': product.toMap(),
      });
    } catch (e) {
      return _jsonResponse(500, {
        'message': 'Failed to create product.',
        'error': e.toString(),
      });
    }
  }

  Future<Response> _getProducts(Request request) async {
    try {
      final products = await _productService.getProducts();

      return _jsonResponse(200, {
        'products': products.map((product) => product.toMap()).toList(),
      });
    } catch (e) {
      return _jsonResponse(500, {
        'message': 'Failed to load products.',
        'error': e.toString(),
      });
    }
  }

  Future<Response> _getProduct(Request request, String id) async {
    try {
      final product = await _productService.getProduct(int.parse(id));

      return _jsonResponse(200, {'product': product.toMap()});
    } catch (e) {
      return _jsonResponse(404, {'message': 'Product not found.'});
    }
  }

  Future<Response> _updateProductHandler(Request request) {
    return _updateProduct(request, request.params['id']!);
  }

  Future<Response> _updateProduct(Request request, String id) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = request.context['userEmail'] as String?;

      if (email == null || email.isEmpty) {
        return _jsonResponse(401, {
          'message': 'Authenticated user is required.',
        });
      }

      final product = await _productService.updateProduct(
        id: int.parse(id),
        ownerEmail: email,
        name: body['name'] as String,
        price: (body['price'] as num).toDouble(),
        image: body['image'] as String?,
        category: body['category'] as String,
      );

      return _jsonResponse(200, {
        'message': 'Product updated successfully.',
        'product': product.toMap(),
      });
    } catch (e) {
      return _jsonResponse(403, {
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
