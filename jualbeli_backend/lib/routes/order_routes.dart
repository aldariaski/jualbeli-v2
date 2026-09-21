import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../repositories/order_repository.dart';

class OrderRoutes {
  OrderRoutes._();

  static final OrderRoutes instance =
      OrderRoutes._();

  final OrderRepository _repository =
      OrderRepository.instance;

  Router get router {
    final router = Router();

    router.post(
      '/',
      _createOrder,
    );

    router.get(
      '/',
      _getOrders,
    );

    router.get(
      '/<id|[0-9]+>',
      _getOrder,
    );

    router.post(
      '/<id|[0-9]+>/pay',
      _payOrder,
    );

    return router;
  }

  // ------------------------------------------------------------
  // CREATE ORDER / CHECKOUT
  // ------------------------------------------------------------

  Future<Response> _createOrder(
    Request request,
  ) async {
    try {
      final email =
          request.context['userEmail'] as String;

      final orderId =
          await _repository.createOrder(
        email: email,
      );

      return _jsonResponse(
        201,
        {
          'message':
              'Order created successfully.',
          'orderId': orderId,
        },
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      final statusCode = message == 'You cannot buy a product from yourself.'
          ? 409
          : 500;
      print(
        'Create order error: $e',
      );

      return _jsonResponse(
        statusCode,
        {
          'error':
              'Failed to create order.',
          'details': message,
        },
      );
    }
  }

  // ------------------------------------------------------------
  // GET ALL ORDERS
  // ------------------------------------------------------------

  Future<Response> _getOrders(
    Request request,
  ) async {
    try {
      final email =
          request.context['userEmail'] as String;

      final orders =
          await _repository.getOrdersForUser(
        email,
      );

      return _jsonResponse(
        200,
        {
          'orders': orders,
        },
      );
    } catch (e) {
      print(
        'Get orders error: $e',
      );

      return _jsonResponse(
        500,
        {
          'error':
              'Failed to load orders.',
          'details': e.toString(),
        },
      );
    }
  }

  // ------------------------------------------------------------
  // GET SINGLE ORDER
  // ------------------------------------------------------------

  Future<Response> _getOrder(
    Request request,
    String id,
  ) async {
    try {
      final email =
          request.context['userEmail'] as String;

      final order =
          await _repository.getOrderForUser(
        orderId: int.parse(id),
        email: email,
      );

      if (order == null) {
        return _jsonResponse(
          404,
          {
            'error': 'Order not found.',
          },
        );
      }

      return _jsonResponse(
        200,
        {
          'order': order,
        },
      );
    } catch (e) {
      print(
        'Get order error: $e',
      );

      return _jsonResponse(
        500,
        {
          'error':
              'Failed to load order.',
          'details': e.toString(),
        },
      );
    }
  }

  Future<Response> _payOrder(
    Request request,
    String id,
  ) async {
    try {
      await _repository.payOrder(
        orderId: int.parse(id),
        email: request.context['userEmail'] as String,
      );

      return _jsonResponse(200, {'message': 'Order paid successfully.'});
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      final statusCode = message == 'Order not found.' ? 404 : 409;
      return _jsonResponse(statusCode, {'message': message});
    }
  }

  // ------------------------------------------------------------
  // JSON RESPONSE
  // ------------------------------------------------------------

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