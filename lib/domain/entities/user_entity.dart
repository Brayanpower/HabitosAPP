class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? password;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
