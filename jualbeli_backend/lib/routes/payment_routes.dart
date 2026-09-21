import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../repositories/wallet_repository.dart';

class PaymentRoutes {
  PaymentRoutes._();

  static final instance = PaymentRoutes._();
  final _wallet = WalletRepository.instance;

  Router get router {
    final router = Router();
    router.get('/balance', _balance);
    router.post('/top-up', _topUp);
    router.post('/orders/<id|[0-9]+>/pay', _payOrder);
    return router;
  }

  Future<Response> _balance(Request request) async {
    try {
      final balance = await _wallet.getBalance(request.context['userEmail'] as String);
      return _json(200, {'balance': balance});
    } catch (e) {
      return _json(500, {'message': e.toString()});
    }
  }

  Future<Response> _topUp(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final amount = body is Map ? (body['amount'] as num?)?.toDouble() : null;
      if (amount == null || amount <= 0) return _json(400, {'message': 'A valid amount is required.'});
      final balance = await _wallet.topUp(
        email: request.context['userEmail'] as String,
        amount: amount,
      );
      return _json(200, {'balance': balance});
    } catch (e) {
      return _json(400, {'message': e.toString().replaceFirst('Exception: ', '')});
    }
  }

  Future<Response> _payOrder(Request request, String id) async {
    try {
      final balance = await _wallet.payOrder(
        email: request.context['userEmail'] as String,
        orderId: int.parse(id),
      );
      return _json(200, {'message': 'Order paid successfully.', 'balance': balance});
    } catch (e) {
      return _json(409, {'message': e.toString().replaceFirst('Exception: ', '')});
    }
  }

  Response _json(int status, Map<String, dynamic> body) => Response(
        status,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
      );
}