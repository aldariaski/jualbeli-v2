import '../database/database.dart';
import '../database/mysql_compat.dart';

class WalletRepository {
  WalletRepository._();

  static final instance = WalletRepository._();
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<double> getBalance(String email) async {
    final result = await _db.query(
      'SELECT balance FROM Wallets WHERE email = ?',
      [email],
    );
    if (result.rows.isEmpty) {
      await _db.execute(
        'INSERT INTO Wallets (email, balance) VALUES (?, 0)',
        [email],
      );
      return 0;
    }
    return _number(result.rows.first.toColumnMap()['balance']);
  }

  Future<double> topUp({required String email, required double amount}) async {
    if (amount <= 0) throw Exception('Top-up amount must be greater than zero.');

    return _db.transaction((connection) async {
      await _db.transactionExecute(
        connection,
        '''INSERT INTO Wallets (email, balance) VALUES (?, 0)
           ON DUPLICATE KEY UPDATE email = email''',
        [email],
      );
      await _db.transactionExecute(
        connection,
        'UPDATE Wallets SET balance = balance + ? WHERE email = ?',
        [amount, email],
      );
      await _db.transactionExecute(
        connection,
        '''INSERT INTO WalletTransactions (email, type, amount, status)
           VALUES (?, 'TopUp', ?, 'Completed')''',
        [email, amount],
      );
      final result = await _db.transactionExecute(
        connection,
        'SELECT balance FROM Wallets WHERE email = ?',
        [email],
      );
      return _number(result.rows.first.toColumnMap()['balance']);
    });
  }

  Future<double> payOrder({
    required String email,
    required int orderId,
  }) async {
    return _db.transaction((connection) async {
      final order = await _db.transactionExecute(
        connection,
        'SELECT total_amount, status FROM Orders WHERE id = ? AND email = ? FOR UPDATE',
        [orderId, email],
      );
      if (order.rows.isEmpty) throw Exception('Order not found.');
      final orderFields = order.rows.first.toColumnMap();
      if (orderFields['status']?.toString().toLowerCase() != 'pending') {
        throw Exception('Order is not pending.');
      }
      final amount = _number(orderFields['total_amount']);

      final wallet = await _db.transactionExecute(
        connection,
        'SELECT balance FROM Wallets WHERE email = ? FOR UPDATE',
        [email],
      );
      if (wallet.rows.isEmpty || _number(wallet.rows.first.toColumnMap()['balance']) < amount) {
        throw Exception('Insufficient wallet balance.');
      }

      final payment = await _db.transactionExecute(
        connection,
        '''INSERT INTO Payments (order_id, payer_email, amount, method, status)
           VALUES (?, ?, ?, 'Wallet', 'Paid')''',
        [orderId, email, amount],
      );
      if (payment.affectedRows == BigInt.zero) throw Exception('Payment failed.');

      final updated = await _db.transactionExecute(
        connection,
        '''UPDATE Orders SET status = 'Paid'
           WHERE id = ? AND email = ? AND status = 'Pending' ''',
        [orderId, email],
      );
      if (updated.affectedRows == BigInt.zero) throw Exception('Order is not pending.');
      await _db.transactionExecute(
        connection,
        'UPDATE Wallets SET balance = balance - ? WHERE email = ?',
        [amount, email],
      );
      await _db.transactionExecute(
        connection,
        '''INSERT INTO WalletTransactions (email, type, amount, order_id, status)
           VALUES (?, 'Payment', ?, ?, 'Completed')''',
        [email, amount, orderId],
      );
      final result = await _db.transactionExecute(
        connection,
        'SELECT balance FROM Wallets WHERE email = ?',
        [email],
      );
      return _number(result.rows.first.toColumnMap()['balance']);
    });
  }

  double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}