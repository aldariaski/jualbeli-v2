import '../database/database.dart';
import '../models/cart_item.dart';
import '../database/mysql_compat.dart';

class CartRepository {
  final DatabaseConnection _database;

  CartRepository({
    DatabaseConnection? database,
  }) : _database = database ?? DatabaseConnection.instance;

  Future<List<CartItem>> findByUser(
    String userEmail,
  ) async {
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

    return result.map((row) {
      // row.fields can be accessed using column names or index in mysql1
      final fields = row.toColumnMap();

      return CartItem(
        id: fields['Id'] as int,
        userEmail: fields['UserEmail'] as String,
        productId: fields['ProductId'] as int,
        quantity: fields['Quantity'] as int,
        productName: fields['ProductName'] as String,
        price: (fields['Price'] as num).toDouble(),
        image: fields['Image'] as String?,
        category: fields['Category'] as String,
        sellerName: fields['SellerName'] as String,
        sellerEmail: fields['SellerEmail'] as String,
      );
    }).toList();
  }

  Future<void> addOrIncrease(
    String userEmail,
    int productId,
  ) async {
    // Replaced SQL Server IF EXISTS / ELSE with MySQL ON DUPLICATE KEY UPDATE.
    // Assumes (UserEmail, ProductId) is a UNIQUE index / composite key in MySQL.
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
      await remove(
        userEmail,
        productId,
      );
      return;
    }

    const sql = '''
      UPDATE CartItems
      SET Quantity = ?
      WHERE UserEmail = ?
        AND ProductId = ?
    ''';

    await _database.execute(sql, [quantity, userEmail, productId]);
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

    await _database.execute(sql, [userEmail, productId]);
  }

  Future<void> clear(
    String userEmail,
  ) async {
    const sql = '''
      DELETE FROM CartItems
      WHERE UserEmail = ?
    ''';

    await _database.execute(sql, [userEmail]);
  }
}