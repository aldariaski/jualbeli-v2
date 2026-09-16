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
      id: map['Id'],
      name: map['Name'] as String,
      email: map['Email'] as String,
      passwordHash: map['PasswordHash'] as String,
      createdAt: map['CreatedAt'] == null
          ? null
          : DateTime.parse(
              map['CreatedAt'].toString(),
            ),
    );
  }
}