class User {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final DateTime? createdAt;

  const User({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: int.parse((map['Id']).toString()),
      name: map['Name'] as String,
      email: map['Email'] as String,
      passwordHash: map['PasswordHash'] as String,
      createdAt: _parseUtc(map['CreatedAt']),
    );
  }

  static DateTime? _parseUtc(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim().replaceFirst(' ', 'T');
    final hasTimezone = text.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(text);
    return DateTime.tryParse(hasTimezone ? text : '${text}Z')?.toUtc();
  }
}