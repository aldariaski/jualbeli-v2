import '../database/database.dart';
import '../database/mysql_compat.dart';

class OrderRepository {
  OrderRepository._();

  static final OrderRepository instance = OrderRepository._();

  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> createOrder({
    required String email,
  }) async {
    // ------------------------------------------------------------
    // Check that the cart is not empty
    // ------------------------------------------------------------

    final cartResult = await _db.query(
      '''
      SELECT
          c.ProductId,
          c.Quantity,
          p.price
      FROM CartItems c
      INNER JOIN Products p
          ON p.Id = c.ProductId
      WHERE c.UserEmail = ?
      ''',
      [email],
    );

    if (cartResult.isEmpty) {
      throw Exception(
        'Cart is empty.',
      );
    }

    // ------------------------------------------------------------
    // Calculate total amount
    // ------------------------------------------------------------

    final totalResult = await _db.query(
      '''
      SELECT
          SUM(
              CAST(p.price AS DECIMAL(30,2))
              * c.quantity
          ) AS totalAmount
      FROM CartItems c
      INNER JOIN Products p
          ON p.Id = c.ProductId
      WHERE c.UserEmail = ?
      ''',
      [email],
    );

    if (totalResult.isEmpty) {
      throw Exception(
        'Failed to calculate Orders total.',
      );
    }

    final totalAmount = totalResult.first.toColumnMap()['totalAmount'];

    if (totalAmount == null) {
      throw Exception(
        'Orders total is null.',
      );
    }

    // ------------------------------------------------------------
    // Create Orders
    // ------------------------------------------------------------

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
      [email, totalAmount],
    );

    final orderId = insertResult.insertId;

    if (orderId == null || orderId == 0) {
      throw Exception(
        'Orders ID was not returned.',
      );
    }

    // ------------------------------------------------------------
    // Create OrderItems
    // ------------------------------------------------------------

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
          c.quantity,
          p.price
      FROM CartItems c
      INNER JOIN Products p
          ON p.Id = c.ProductId
      WHERE c.UserEmail = ?;
      ''',
      [orderId, email],
    );

    // ------------------------------------------------------------
    // Clear cart
    // ------------------------------------------------------------

    await _db.execute(
      '''
      DELETE FROM CartItems
      WHERE UserEmail = ?;
      ''',
      [email],
    );

    // ------------------------------------------------------------
    // Return Orders ID
    // ------------------------------------------------------------

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

    return result.map((row) {
      final fields = row.toColumnMap();

      return {
        'id': int.parse(fields['id'].toString()),
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
      [orderId, email],
    );

    if (orderResult.isEmpty) {
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

    final order = orderResult.first.toColumnMap();

    return {
      'id': int.parse(order['id'].toString()),
      'email': order['email']?.toString() ?? '',
      'totalAmount': _number(order['total_amount']),
      'status': order['status']?.toString() ?? '',
      'createdAt': order['created_at']?.toString(),
      'items': itemResult.map((row) {
        final fields = row.toColumnMap();

        return {
          'id': int.parse(fields['id'].toString()),
          'orderId': int.parse(fields['order_id'].toString()),
          'productId': int.parse(fields['product_id'].toString()),
          'quantity': int.parse(fields['quantity'].toString()),
          'price': _number(fields['price']),
          'name': fields['Name']?.toString() ?? 'Product unavailable',
          'image': fields['Image']?.toString(),
        };
      }).toList(),
    };
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