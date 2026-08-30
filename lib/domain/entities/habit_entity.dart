enum HabitFrequency {
  daily,
  weekly,
  monthly,
}

enum HabitCategory {
  salud,
  trabajo,
  estudio,
  finanzas,
  hogar,
  social,
  ocio,
  otro;

  String get label {
    switch (this) {
      case HabitCategory.salud:
        return 'Salud';
      case HabitCategory.trabajo:
        return 'Trabajo';
      case HabitCategory.estudio:
        return 'Estudio';
      case HabitCategory.finanzas:
        return 'Finanzas';
      case HabitCategory.hogar:
        return 'Hogar';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.ocio:
        return 'Ocio';
      case HabitCategory.otro:
        return 'Otro';
    }
  }
}

enum HabitTargetType {
  steps,       // Medición de pasos diarios con sensor del dispositivo
  timer,       // Duración en minutos con temporizador interactivo
  water,       // Ingesta de agua en ml con acción rápida de vaso (+250ml)
  counter,     // Contador de repeticiones numéricas (+ / -)
  simpleCheck; // Verificación binaria (checkbox)

  String get label {
    switch (this) {
      case HabitTargetType.steps:
        return 'Pasos diarios (Sensor)';
      case HabitTargetType.timer:
        return 'Tiempo / Temporizador';
      case HabitTargetType.water:
        return 'Consumo de Agua';
      case HabitTargetType.counter:
        return 'Conteo / Repeticiones';
      case HabitTargetType.simpleCheck:
        return 'Check simple';
    }
  }

  String get defaultUnit {
    switch (this) {
      case HabitTargetType.steps:
        return 'pasos';
      case HabitTargetType.timer:
        return 'minutos';
      case HabitTargetType.water:
        return 'ml';
      case HabitTargetType.counter:
        return 'veces';
      case HabitTargetType.simpleCheck:
        return 'check';
    }
  }

  static HabitTargetType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'steps':
        return HabitTargetType.steps;
      case 'timer':
        return HabitTargetType.timer;
      case 'water':
        return HabitTargetType.water;
      case 'counter':
        return HabitTargetType.counter;
      default:
        return HabitTargetType.simpleCheck;
    }
  }
}

class HabitEntity {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final HabitFrequency frequency;
  final HabitCategory category;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final bool isActive;
  final int currentStreak;
  final int bestStreak;
  final int? goalTarget;
  final int? goalDays;
  final List<int> repeatDays;
  final int timesPerDay;
  final HabitTargetType targetType;
  final int targetValue; // pasos, minutos, ml, o veces
  final String unit;     // 'pasos', 'min', 'ml', 'veces'

  HabitEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.category = HabitCategory.otro,
    required this.createdAt,
    this.reminderTime,
    this.isActive = true,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.goalTarget,
    this.goalDays,
    this.repeatDays = const [],
    this.timesPerDay = 1,
    this.targetType = HabitTargetType.simpleCheck,
    int? targetValue,
    String? unit,
  })  : targetValue = targetValue ?? _inferDefaultTargetValue(targetType, timesPerDay),
        unit = unit ?? targetType.defaultUnit;

  static int _inferDefaultTargetValue(HabitTargetType type, int timesPerDay) {
    switch (type) {
      case HabitTargetType.steps:
        return 8000;
      case HabitTargetType.timer:
        return 20;
      case HabitTargetType.water:
        return 2000;
      case HabitTargetType.counter:
        return timesPerDay > 1 ? timesPerDay : 3;
      case HabitTargetType.simpleCheck:
        return 1;
    }
  }

  bool get hasCustomDays => repeatDays.isNotEmpty;
  bool get isMultiTimes => timesPerDay > 1;
  bool get isTimerHabit => targetType == HabitTargetType.timer;
  bool get isWaterHabit => targetType == HabitTargetType.water;
  bool get isStepsHabit => targetType == HabitTargetType.steps;

  /// Determina si este hábito está programado para una fecha específica
  bool isScheduledForDate(DateTime date) {
    if (!isActive) return false;
    if (frequency == HabitFrequency.monthly) {
      if (repeatDays.isEmpty) return true;
      return repeatDays.contains(date.day);
    } else if (frequency == HabitFrequency.weekly) {
      if (repeatDays.isEmpty) return true;
      return repeatDays.contains(date.weekday);
    } else {
      // HabitFrequency.daily
      return true;
    }
  }

  HabitEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    HabitFrequency? frequency,
    HabitCategory? category,
    DateTime? createdAt,
    DateTime? reminderTime,
    bool? isActive,
    int? currentStreak,
    int? bestStreak,
    int? goalTarget,
    int? goalDays,
    List<int>? repeatDays,
    int? timesPerDay,
    HabitTargetType? targetType,
    int? targetValue,
    String? unit,
  }) {
    return HabitEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      goalTarget: goalTarget ?? this.goalTarget,
      goalDays: goalDays ?? this.goalDays,
      repeatDays: repeatDays ?? this.repeatDays,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
    );
  }
}
