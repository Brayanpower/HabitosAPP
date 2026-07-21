import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';
import 'package:habitos_app/infrastructure/models/habit_log_model.dart';
import 'package:habitos_app/infrastructure/models/habit_model.dart';

class HabitMapper {
  static HabitEntity toEntity(HabitModel model) {
    return model.toEntity();
  }

  static HabitModel toModel(HabitEntity entity) {
    return HabitModel.fromEntity(entity);
  }

  static Map<String, dynamic> toMap(HabitEntity entity) {
    return HabitModel.fromEntity(entity).toMap();
  }

  static HabitEntity fromMap(Map<String, dynamic> map) {
    return HabitModel.fromMap(map).toEntity();
  }

  static HabitLogEntity logToEntity(HabitLogModel model) {
    return model.toEntity();
  }

  static HabitLogModel logToModel(HabitLogEntity entity) {
    return HabitLogModel.fromEntity(entity);
  }

  static Map<String, dynamic> logToMap(HabitLogEntity entity) {
    return HabitLogModel.fromEntity(entity).toMap();
  }

  static HabitLogEntity logFromMap(Map<String, dynamic> map) {
    return HabitLogModel.fromMap(map).toEntity();
  }
}
