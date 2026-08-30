import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_app/config/constants/app_constants.dart';
import 'package:habitos_app/config/helpers/notification_helper.dart';
import 'package:habitos_app/config/helpers/step_sensor_service.dart';

class StepProvider extends ChangeNotifier {
  final StepSensorService _sensorService;

  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<String>? _statusSubscription;

  int _todaySteps = 0;
  int _stepGoal = 8000;
  String _pedestrianStatus = 'Listo';
  bool _isSensorAvailable = false;
  bool _notifiedGoalReachedToday = false;

  int get todaySteps => _todaySteps;
  int get stepGoal => _stepGoal;
  String get pedestrianStatus => _pedestrianStatus;
  bool get isSensorAvailable => _isSensorAvailable;
  bool get isGoalReached => _todaySteps >= _stepGoal;
  double get progress => (_stepGoal > 0) ? (_todaySteps / _stepGoal).clamp(0.0, 1.0) : 0.0;

  // Callback opcional cuando se alcanza la meta de pasos
  Function(int steps)? onGoalReachedCallback;

  StepProvider({StepSensorService? sensorService})
      : _sensorService = sensorService ?? StepSensorService.instance {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _stepGoal = prefs.getInt(AppConstants.stepGoalKey) ?? 8000;

    await _sensorService.init();
    _todaySteps = _sensorService.todaySteps;
    _isSensorAvailable = _sensorService.isSensorAvailable;
    _pedestrianStatus = _sensorService.pedestrianStatus;

    _stepSubscription = _sensorService.stepStream.listen((steps) {
      _todaySteps = steps;
      _checkGoalReached();
      notifyListeners();
    });

    _statusSubscription = _sensorService.statusStream.listen((status) {
      _pedestrianStatus = status;
      _isSensorAvailable = _sensorService.isSensorAvailable;
      notifyListeners();
    });

    notifyListeners();
  }

  void _checkGoalReached() {
    if (_todaySteps >= _stepGoal && !_notifiedGoalReachedToday) {
      _notifiedGoalReachedToday = true;
      NotificationHelper.showStepGoalReachedNotification(steps: _todaySteps);
      onGoalReachedCallback?.call(_todaySteps);
    }
  }

  Future<void> setStepGoal(int newGoal) async {
    _stepGoal = newGoal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.stepGoalKey, newGoal);
    _checkGoalReached();
    notifyListeners();
  }

  Future<void> addSimulatedSteps(int count) async {
    await _sensorService.addSimulatedSteps(count);
  }

  Future<void> resetSteps() async {
    await _sensorService.resetSteps();
    _notifiedGoalReachedToday = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
