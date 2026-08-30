import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_app/config/helpers/date_helper.dart';

class StepSensorService {
  static final StepSensorService instance = StepSensorService._();
  StepSensorService._();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  final _stepController = StreamController<int>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<int> get stepStream => _stepController.stream;
  Stream<String> get statusStream => _statusController.stream;

  int _todaySteps = 0;
  int _lastBootSteps = 0;
  int _simulatedSteps = 0;
  String _pedestrianStatus = 'Desconocido';
  bool _isSensorAvailable = false;
  bool _isInitialized = false;

  int get todaySteps => _todaySteps;
  String get pedestrianStatus => _pedestrianStatus;
  bool get isSensorAvailable => _isSensorAvailable;

  static const _kLastDate = 'sensor_step_last_date';
  static const _kMidnightBootSteps = 'sensor_step_midnight_boot';
  static const _kSimulatedSteps = 'sensor_step_simulated';

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadSavedState();

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('StepSensorService: Dispositivo sin hardware directo de podómetro, modo simulador activo.');
      _isSensorAvailable = false;
      _updateTotal();
      return;
    }

    await _requestPermissionsAndStart();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_kLastDate);
    final todayStr = DateHelper.formatDate(DateTime.now());

    if (savedDate != todayStr) {
      // Nuevo día: resetear línea base
      await prefs.setString(_kLastDate, todayStr);
      await prefs.setInt(_kSimulatedSteps, 0);
      _simulatedSteps = 0;
      _todaySteps = 0;
      if (_lastBootSteps > 0) {
        await prefs.setInt(_kMidnightBootSteps, _lastBootSteps);
      }
    } else {
      _simulatedSteps = prefs.getInt(_kSimulatedSteps) ?? 0;
      final midnightBoot = prefs.getInt(_kMidnightBootSteps) ?? 0;
      if (_lastBootSteps >= midnightBoot && midnightBoot > 0) {
        _todaySteps = (_lastBootSteps - midnightBoot) + _simulatedSteps;
      } else {
        _todaySteps = _simulatedSteps;
      }
    }
    _stepController.add(_todaySteps);
  }

  Future<void> _requestPermissionsAndStart() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) {
          debugPrint('StepSensorService: Permiso de actividad física no concedido.');
          _isSensorAvailable = false;
          _statusController.add('Permiso denegado');
          return;
        }
      }

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _isSensorAvailable = true;
      _statusController.add('Sensor activo');
    } catch (e) {
      debugPrint('StepSensorService init error: $e');
      _isSensorAvailable = false;
      _statusController.add('No disponible');
    }
  }

  Future<void> _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateHelper.formatDate(DateTime.now());
    final savedDate = prefs.getString(_kLastDate);

    _lastBootSteps = event.steps;

    if (savedDate != todayStr) {
      await prefs.setString(_kLastDate, todayStr);
      await prefs.setInt(_kMidnightBootSteps, event.steps);
      await prefs.setInt(_kSimulatedSteps, 0);
      _simulatedSteps = 0;
    }

    final midnightBoot = prefs.getInt(_kMidnightBootSteps) ?? event.steps;
    final realSteps = (event.steps >= midnightBoot) ? (event.steps - midnightBoot) : 0;
    _todaySteps = realSteps + _simulatedSteps;

    _stepController.add(_todaySteps);
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _pedestrianStatus = event.status;
    _statusController.add(_pedestrianStatus);
  }

  void _onStepCountError(dynamic error) {
    debugPrint('StepSensorService step count error: $error');
    _isSensorAvailable = false;
    _statusController.add('Error de sensor');
  }

  void _onPedestrianStatusError(dynamic error) {
    debugPrint('StepSensorService pedestrian status error: $error');
  }

  /// Permite simular / incrementar pasos para pruebas o entornos sin sensor físico
  Future<void> addSimulatedSteps(int count) async {
    final prefs = await SharedPreferences.getInstance();
    _simulatedSteps += count;
    await prefs.setInt(_kSimulatedSteps, _simulatedSteps);
    _updateTotal();
  }

  /// Resetea los pasos del día a 0
  Future<void> resetSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateHelper.formatDate(DateTime.now());
    await prefs.setString(_kLastDate, todayStr);
    await prefs.setInt(_kSimulatedSteps, 0);
    if (_lastBootSteps > 0) {
      await prefs.setInt(_kMidnightBootSteps, _lastBootSteps);
    }
    _simulatedSteps = 0;
    _todaySteps = 0;
    _stepController.add(0);
  }

  void _updateTotal() {
    _todaySteps = _simulatedSteps;
    _stepController.add(_todaySteps);
  }

  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _stepController.close();
    _statusController.close();
  }
}
