import '../database/database.dart';
import '../models/product.dart';
import '../database/mysql_compat.dart';

class ProductRepository {
  final DatabaseConnection _database;

  ProductRepository({
    DatabaseConnection? database,
  }) : _database = database ?? DatabaseConnection.instance;

  Future<Product> createProduct({
    required String name,
    required double price,
    String? image,
    required String category,
    required String sellerName,
    required String sellerEmail,
  }) async {
    const sql = '''
      INSERT INTO Products (
        Name,
        Price,
        Image,
        Category,
        SellerName,
        SellerEmail
      )
      VALUES (?, ?, ?, ?, ?, ?)
    ''';

    final result = await _database.execute(sql, [
      name,
      price,
      image,
      category,
      sellerName,
      sellerEmail,
    ]);

    final insertedId = result.insertId;

    if (insertedId == 0) {
      throw Exception(
        'Failed to create product.',
      );
    }

    final newProduct = await findById(insertedId);

    if (newProduct == null) {
      throw Exception(
        'Failed to fetch newly created product.',
      );
    }

    return newProduct;
  }

  Future<List<Product>> getAll() async {
    const sql = '''
      SELECT
        Id,
        Name,
        Price,
        Image,
        Category,
        SellerName,
        SellerEmail
      FROM Products
      ORDER BY Id DESC
    ''';

    final result = await _database.query(sql);

    return result.rows.map((row) {
      final fields = row.toColumnMap();

      return Product.fromMap({
        'Id': fields['Id'],
        'Name': fields['Name'],
        'Price': fields['Price'],
        'Image': fields['Image'],
        'Category': fields['Category'],
        'SellerName': fields['SellerName'],
        'SellerEmail': fields['SellerEmail'],
      });
    }).toList();
  }

  Future<Product?> findById(int id) async {
    const sql = '''
      SELECT
        Id,
        Name,
        Price,
        Image,
        Category,
        SellerName,
        SellerEmail
      FROM Products
      WHERE Id = ?
    ''';

    final result = await _database.query(sql, [id]);

    if (result.rows.isEmpty) {
      return null;
    }

    final fields = result.rows.first.toColumnMap();

    return Product.fromMap({
      'Id': fields['Id'],
      'Name': fields['Name'],
      'Price': fields['Price'],
      'Image': fields['Image'],
      'Category': fields['Category'],
      'SellerName': fields['SellerName'],
      'SellerEmail': fields['SellerEmail'],
    });
  }
}