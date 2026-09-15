import '../database/database.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseConnection _database;

  UserRepository({
    DatabaseConnection? database,
  }) : _database = database ?? DatabaseConnection.instance;

  Future<User?> findByEmail(String email) async {
    const sql = '''
      SELECT
        Id,
        Name,
        Email,
        PasswordHash,
        CreatedAt
      FROM Users
      WHERE Email = ?
    ''';

    final result = await _database.query(sql, [email]);

    if (result.isEmpty) {
      return null;
    }

    final fields = result.first.toColumnMap();

    return User.fromMap({
      'Id': fields['Id'],
      'Name': fields['Name'],
      'Email': fields['Email'],
      'PasswordHash': fields['PasswordHash'],
      'CreatedAt': fields['CreatedAt'],
    });
  }

  Future<User> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    const sql = '''
      INSERT INTO Users (
        Name,
        Email,
        PasswordHash
      )
      VALUES (?, ?, ?)
    ''';

    final result = await _database.execute(sql, [
      name,
      email,
      passwordHash,
    ]);

    final insertedId = result.insertId;

    if (insertedId == null || insertedId == 0) {
      throw Exception('Failed to create user.');
    }

    final newUser = await findByEmail(email);

    if (newUser == null) {
      throw Exception('Failed to fetch newly created user.');
    }

    return newUser;
  }
}