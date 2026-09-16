import '../database/database.dart';
import '../models/cart_item.dart';
import '../database/mysql_compat.dart';

class CartRepository {
  final DatabaseConnection _database;

  CartRepository({
    DatabaseConnection? database,
  }) : _database = database ?? DatabaseConnection.instance;

  Future<List<CartItem>> findByUser(String userEmail) async {
    const sql = '''
      SELECT
        c.Id,
        c.UserEmail,
        c.ProductId,
        c.Quantity,
        p.Name AS ProductName,
        p.Price,
        p.Image,
        p.Category,
        p.SellerName,
        p.SellerEmail
      FROM CartItems c
      INNER JOIN Products p
        ON c.ProductId = p.Id
      WHERE c.UserEmail = ?
      ORDER BY c.Id DESC
    ''';

    final result = await _database.query(sql, [userEmail]);

    return result.rows.map((row) {
      final fields = row.toColumnMap();

      return CartItem(
        id: _int(fields['Id']),
        userEmail: fields['UserEmail']?.toString() ?? '',
        productId: _int(fields['ProductId']),
        quantity: _int(fields['Quantity']),
        productName: fields['ProductName']?.toString() ?? '',
        price: _double(fields['Price']),
        image: fields['Image']?.toString(),
        category: fields['Category']?.toString() ?? '',
        sellerName: fields['SellerName']?.toString() ?? '',
        sellerEmail: fields['SellerEmail']?.toString() ?? '',
      );
    }).toList();
  }

  Future<void> addOrIncrease(
    String userEmail,
    int productId,
  ) async {
    const sql = '''
      INSERT INTO CartItems (
        UserEmail,
        ProductId,
        Quantity
      )
      VALUES (?, ?, 1)
      ON DUPLICATE KEY UPDATE
        Quantity = Quantity + 1
    ''';

    await _database.execute(sql, [userEmail, productId]);
  }

  Future<void> updateQuantity(
    String userEmail,
    int productId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      await remove(userEmail, productId);
      return;
    }

    const sql = '''
      UPDATE CartItems
      SET Quantity = ?
      WHERE UserEmail = ?
        AND ProductId = ?
    ''';

    await _database.execute(sql, [
      quantity,
      userEmail,
      productId,
    ]);
  }

  Future<void> remove(
    String userEmail,
    int productId,
  ) async {
    const sql = '''
      DELETE FROM CartItems
      WHERE UserEmail = ?
        AND ProductId = ?
    ''';

    await _database.execute(sql, [
      userEmail,
      productId,
    ]);
  }

  Future<void> clear(String userEmail) async {
    const sql = '''
      DELETE FROM CartItems
      WHERE UserEmail = ?
    ''';

    await _database.execute(sql, [userEmail]);
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

  double _double(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}