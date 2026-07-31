import 'package:habitos_app/domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String? gender;
  final double? weight;
  final double? height;
  final int? age;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.gender,
    this.weight,
    this.height,
    this.age,
    required this.createdAt,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      password: entity.password ?? '',
      gender: entity.gender,
      weight: entity.weight,
      height: entity.height,
      age: entity.age,
      createdAt: entity.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      gender: map['gender'] as String?,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
      'weight': weight,
      'height': height,
      'age': age,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      password: password,
      gender: gender,
      weight: weight,
      height: height,
      age: age,
      createdAt: createdAt,
    );
  }
}
