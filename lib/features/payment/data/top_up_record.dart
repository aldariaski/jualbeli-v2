class TopUpRecord {
  final int id;
  final double amount;
  final String status;
  final DateTime? createdAt;

  const TopUpRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory TopUpRecord.fromJson(Map<String, dynamic> json) {
    return TopUpRecord(
      id: (json['id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
