class PaymentRecord {
  final int id;
  final int orderId;
  final double amount;
  final String method;
  final String status;
  final DateTime? paidAt;

  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: (json['id'] as num).toInt(),
      orderId: (json['orderId'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      method: json['method']?.toString() ?? 'Wallet',
      status: json['status']?.toString() ?? '',
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.tryParse(json['paidAt'].toString()),
    );
  }
}