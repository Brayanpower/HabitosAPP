import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';

class HabitTemplate {
  final String title;
  final String description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final IconData icon;
  final Color color;
  final int? goalTarget;
  final int? goalDays;
  final int timesPerDay;
  final String tag;
  final HabitTargetType targetType;
  final int targetValue;
  final String unit;

  const HabitTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.icon,
    required this.color,
    this.goalTarget,
    this.goalDays,
    this.timesPerDay = 1,
    required this.tag,
    this.targetType = HabitTargetType.simpleCheck,
    this.targetValue = 1,
    this.unit = 'check',
  });

  HabitEntity toEntity(String userId, {double? userWeight}) {
    int target = goalTarget ?? 30;
    int times = timesPerDay;
    String desc = description;
    int calculatedTargetValue = targetValue;
    String calculatedUnit = unit;

    // Si es agua y tenemos peso, personalizar el objetivo en ml
    if (tag == 'water') {
      if (userWeight != null && userWeight > 0) {
        final liters = (userWeight * 35) / 1000;
        calculatedTargetValue = (liters * 1000).round();
        final glasses = (calculatedTargetValue / 250).round();
        desc = 'Meta personalizada ($userWeight kg): ${liters.toStringAsFixed(1)}L ($glasses vasos de 250ml)';
      } else {
        calculatedTargetValue = 2000;
      }
      calculatedUnit = 'ml';
    }

    return HabitEntity(
      id: const Uuid().v4(),
      userId: userId,
      name: title,
      description: desc,
      category: category,
      frequency: frequency,
      createdAt: DateTime.now(),
      isActive: true,
      goalTarget: target,
      goalDays: goalDays,
      timesPerDay: times,
      targetType: targetType,
      targetValue: calculatedTargetValue,
      unit: calculatedUnit,
    );
  }
}

class DefaultHabitsHelper {
  DefaultHabitsHelper._();

  static const List<HabitTemplate> templates = [
    HabitTemplate(
      title: 'Caminar 8,000 pasos',
      description: 'Medición automática mediante los sensores de movimiento de tu dispositivo.',
      category: HabitCategory.salud,
      frequency: HabitFrequency.daily,
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF00B894),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'walk',
      targetType: HabitTargetType.steps,
      targetValue: 8000,
      unit: 'pasos',
    ),
    HabitTemplate(
      title: 'Tomar 2.5L de agua',
      description: 'Registra tus vasos de agua (250ml) para mantenerte hidratado todo el día.',
      category: HabitCategory.salud,
      frequency: HabitFrequency.daily,
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0288D1),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'water',
      targetType: HabitTargetType.water,
      targetValue: 2500,
      unit: 'ml',
    ),
    HabitTemplate(
      title: 'Lectura diaria (20 min)',
      description: 'Inicia el temporizador de concentración para disfrutar de tu libro favorito.',
      category: HabitCategory.estudio,
      frequency: HabitFrequency.daily,
      icon: Icons.menu_book_rounded,
      color: Color(0xFF6C5CE7),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'reading',
      targetType: HabitTargetType.timer,
      targetValue: 20,
      unit: 'min',
    ),
    HabitTemplate(
      title: 'Meditación & Mindfulness',
      description: 'Temporizador guiado de respiración y relajación consciente.',
      category: HabitCategory.salud,
      frequency: HabitFrequency.daily,
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF00CEC9),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'meditation',
      targetType: HabitTargetType.timer,
      targetValue: 10,
      unit: 'min',
    ),
    HabitTemplate(
      title: 'Ejercicio físico (45 min)',
      description: 'Entrenamiento de fuerza o cardio con cronómetro interactivo.',
      category: HabitCategory.salud,
      frequency: HabitFrequency.daily,
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFFF7675),
      goalTarget: 20,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'workout',
      targetType: HabitTargetType.timer,
      targetValue: 45,
      unit: 'min',
    ),
    HabitTemplate(
      title: 'Dormir 8 horas',
      description: 'Descanso reparador para regenerar tu cuerpo y mente.',
      category: HabitCategory.salud,
      frequency: HabitFrequency.daily,
      icon: Icons.bedtime_rounded,
      color: Color(0xFF283593),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'sleep',
      targetType: HabitTargetType.simpleCheck,
      targetValue: 1,
      unit: 'check',
    ),
    HabitTemplate(
      title: 'Planificar el día',
      description: 'Organizar tus 3 prioridades clave antes de comenzar tus actividades.',
      category: HabitCategory.trabajo,
      frequency: HabitFrequency.daily,
      icon: Icons.checklist_rounded,
      color: Color(0xFF0984E3),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'plan',
      targetType: HabitTargetType.simpleCheck,
      targetValue: 1,
      unit: 'check',
    ),
    HabitTemplate(
      title: 'Registrar gastos diarios',
      description: 'Llevar control de tus finanzas personales y ahorro.',
      category: HabitCategory.finanzas,
      frequency: HabitFrequency.daily,
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF55EFC4),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'finance',
      targetType: HabitTargetType.simpleCheck,
      targetValue: 1,
      unit: 'check',
    ),
    HabitTemplate(
      title: 'Desconexión digital nocturna',
      description: 'Temporizador para dejar pantallas y descansar la vista antes de dormir.',
      category: HabitCategory.ocio,
      frequency: HabitFrequency.daily,
      icon: Icons.phone_disabled_rounded,
      color: Color(0xFFFD79A8),
      goalTarget: 30,
      goalDays: 30,
      timesPerDay: 1,
      tag: 'digital_detox',
      targetType: HabitTargetType.timer,
      targetValue: 30,
      unit: 'min',
    ),
  ];
}
