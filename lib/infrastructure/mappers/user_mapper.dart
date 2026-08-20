import 'package:habitos_app/domain/entities/user_entity.dart';
import 'package:habitos_app/infrastructure/models/user_model.dart';

class UserMapper {
  static UserEntity toEntity(UserModel model) {
    return model.toEntity();
  }

  static UserModel toModel(UserEntity entity) {
    return UserModel.fromEntity(entity);
  }

  static Map<String, dynamic> toMap(UserEntity entity) {
    return UserModel.fromEntity(entity).toMap();
  }

  static UserEntity fromMap(Map<String, dynamic> map) {
    return UserModel.fromMap(map).toEntity();
  }
}
