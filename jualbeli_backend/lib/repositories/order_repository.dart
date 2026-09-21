import '../database/database.dart';
import '../database/mysql_compat.dart';

class OrderRepository {
  OrderRepository._();

  static final OrderRepository instance = OrderRepository._();

  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> createOrder({
    required String email,
  }) async {
    final cartResult = await _db.query(
      '''
      SELECT
        c.ProductId,
        c.Quantity,
        p.Price,
        p.SellerEmail
      FROM CartItems c
      INNER JOIN Products p
        ON p.Id = c.ProductId
      WHERE c.UserEmail = ?
      ''',
      [email],
    );

    // IMPORTANT:
    // mysql_dart uses result.rows for actual database rows.
    if (cartResult.rows.isEmpty) {
      throw Exception('Cart is empty.');
    }

    final hasSelfPurchase = cartResult.rows.any((row) {
      final sellerEmail = row.toColumnMap()['SellerEmail']?.toString().trim().toLowerCase();
      return sellerEmail != null && sellerEmail.isNotEmpty && sellerEmail == email.trim().toLowerCase();
    });

    if (hasSelfPurchase) {
      throw Exception('You cannot buy a product from yourself.');
    }

    final totalResult = await _db.query(
      '''
      SELECT
        SUM(
          CAST(p.Price AS DECIMAL(30,2))
          * c.Quantity
        ) AS totalAmount
      FROM CartItems c
      INNER JOIN Products p
        ON p.Id = c.ProductId
      WHERE c.UserEmail = ?
      ''',
      [email],
    );

    if (totalResult.rows.isEmpty) {
      throw Exception(
        'Failed to calculate Orders total.',
      );
    }

    final totalFields = totalResult.rows.first.toColumnMap();
    final totalAmount = totalFields['totalAmount'];

    if (totalAmount == null) {
      throw Exception('Orders total is null.');
    }

    final insertResult = await _db.execute(
      '''
      INSERT INTO Orders (
        email,
        total_amount,
        status
      )
      VALUES (
        ?,
        ?,
        'Pending'
      )
      ''',
      [
        email,
        totalAmount,
      ],
    );

    final orderId = insertResult.insertId;

    if (orderId == 0) {
      throw Exception(
        'Orders ID was not returned.',
      );
    }

    await _db.execute(
      '''
      INSERT INTO OrderItems (
        order_id,
        product_id,
        quantity,
        price
      )
      SELECT
        ?,
        c.ProductId,
        c.Quantity,
        p.Price
      FROM CartItems c
      INNER JOIN Products p
        ON p.Id = c.ProductId
      WHERE c.UserEmail = ?
      ''',
      [
        orderId,
        email,
      ],
    );

    await _db.execute(
      '''
      DELETE FROM CartItems
      WHERE UserEmail = ?
      ''',
      [email],
    );

    return orderId;
  }

  Future<List<Map<String, dynamic>>> getOrdersForUser(
    String email,
  ) async {
    final result = await _db.query(
      '''
      SELECT
        id,
        email,
        total_amount,
        status,
        created_at
      FROM Orders
      WHERE email = ?
      ORDER BY created_at DESC, id DESC
      ''',
      [email],
    );

    return result.rows.map((row) {
      final fields = row.toColumnMap();

      return {
        'id': _int(fields['id']),
        'email': fields['email']?.toString() ?? '',
        'totalAmount': _number(fields['total_amount']),
        'status': fields['status']?.toString() ?? '',
        'createdAt': fields['created_at']?.toString(),
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getOrderForUser({
    required int orderId,
    required String email,
  }) async {
    final orderResult = await _db.query(
      '''
      SELECT
        id,
        email,
        total_amount,
        status,
        created_at
      FROM Orders
      WHERE id = ?
        AND email = ?
      ''',
      [
        orderId,
        email,
      ],
    );

    if (orderResult.rows.isEmpty) {
      return null;
    }

    final itemResult = await _db.query(
      '''
      SELECT
        oi.id,
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.price,
        p.Name,
        p.Image
      FROM OrderItems oi
      LEFT JOIN Products p
        ON p.Id = oi.product_id
      WHERE oi.order_id = ?
      ORDER BY oi.id ASC
      ''',
      [orderId],
    );

    final order = orderResult.rows.first.toColumnMap();

    return {
      'id': _int(order['id']),
      'email': order['email']?.toString() ?? '',
      'totalAmount': _number(order['total_amount']),
      'status': order['status']?.toString() ?? '',
      'createdAt': order['created_at']?.toString(),

      'items': itemResult.rows.map((row) {
        final fields = row.toColumnMap();

        return {
          'id': _int(fields['id']),
          'orderId': _int(fields['order_id']),
          'productId': _int(fields['product_id']),
          'quantity': _int(fields['quantity']),
          'price': _number(fields['price']),
          'name': fields['Name']?.toString() ??
              'Product unavailable',
          'image': fields['Image']?.toString(),
        };
      }).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> getPaymentHistoryForUser(
    String email,
  ) async {
    final result = await _db.query(
      '''
      SELECT id, order_id, amount, method, status, paid_at
      FROM Payments
      WHERE payer_email = ?
      ORDER BY paid_at DESC, id DESC
      ''',
      [email],
    );

    return result.rows.map((row) {
      final fields = row.toColumnMap();
      return {
        'id': _int(fields['id']),
        'orderId': _int(fields['order_id']),
        'amount': _number(fields['amount']),
        'method': fields['method']?.toString() ?? 'Wallet',
        'status': fields['status']?.toString() ?? '',
        'paidAt': fields['paid_at']?.toString(),
      };
    }).toList();
  }

  int _int(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  double _number(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}