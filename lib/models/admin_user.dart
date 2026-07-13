class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.lastSignInAt,
  });

  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        email: (json['email'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        lastSignInAt: json['last_sign_in_at'] == null
            ? null
            : DateTime.parse(json['last_sign_in_at'] as String),
      );
}
