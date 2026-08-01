import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:habitos_app/config/helpers/date_helper.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';

class WearSyncService extends ChangeNotifier {
  static final WearSyncService _instance = WearSyncService._internal();
  factory WearSyncService() => _instance;
  WearSyncService._internal();

  static const int defaultPort = 8088;

  HttpServer? _server;
  final List<WebSocket> _clients = [];
  bool _isRunning = false;
  String _localIp = '127.0.0.1';
  int _port = defaultPort;

  String? _pairedPin;
  String? _lastWatchDeviceName;
  DateTime? _lastSyncTime;

  HabitProvider? _habitProvider;
  AuthProvider? _authProvider;
  VoidCallback? _habitListener;

  bool get isRunning => _isRunning;
  bool get isConnected => _clients.isNotEmpty;
  int get clientCount => _clients.length;
  String get localIp => _localIp;
  int get port => _port;
  String? get pairedPin => _pairedPin;
  String? get lastWatchDeviceName => _lastWatchDeviceName;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Inicia el servidor local de sincronización
  Future<void> start({
    required HabitProvider habitProvider,
    required AuthProvider authProvider,
    int port = defaultPort,
  }) async {
    if (_isRunning) return;

    _habitProvider = habitProvider;
    _authProvider = authProvider;
    _port = port;

    // Obtener IP de red local
    await _detectLocalIp();

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        _port,
        shared: true,
      );
      _isRunning = true;
      debugPrint('[WearSyncService] Servidor iniciado en http://$_localIp:$_port');

      _server!.listen(
        _handleHttpRequest,
        onError: (e) {
          debugPrint('[WearSyncService] Error en servidor: $e');
        },
      );

      // Escuchar cambios de hábitos en la app móvil para reenviar en vivo al reloj
      _habitListener = () {
        broadcastHabits();
      };
      _habitProvider?.addListener(_habitListener!);

      notifyListeners();
    } catch (e) {
      debugPrint('[WearSyncService] No se pudo iniciar el servidor: $e');
      _isRunning = false;
      notifyListeners();
    }
  }

  /// Detiene el servidor y cierra conexiones
  Future<void> stop() async {
    if (_habitListener != null) {
      _habitProvider?.removeListener(_habitListener!);
      _habitListener = null;
    }

    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();

    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    notifyListeners();
  }

  /// Detecta la IP Wi-Fi o de red local del dispositivo
  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.')) {
            _localIp = addr.address;
            return;
          }
        }
      }

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            _localIp = addr.address;
            return;
          }
        }
      }
    } catch (_) {
      _localIp = '127.0.0.1';
    }
  }

  /// Maneja peticiones HTTP y actualizaciones a WebSocket
  Future<void> _handleHttpRequest(HttpRequest request) async {
    // Permitir CORS para cualquier cliente
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    // Si es una solicitud de WebSocket
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleNewWebSocketClient(socket);
      } catch (e) {
        debugPrint('[WearSyncService] Error en WebSocket upgrade: $e');
      }
      return;
    }

    // Endpoints REST de contingencia / comprobación rápida
    final path = request.uri.path;
    if (path == '/status') {
      final data = {
        'status': 'online',
        'server': 'HabitosAPP Wear Sync Bridge',
        'user': _authProvider?.user?.name ?? 'Usuario',
        'connectedClients': _clients.length,
      };
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(data));
      await request.response.close();
      return;
    }

    if (path == '/habits') {
      final snapshot = await _buildHabitsSnapshot();
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(snapshot));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  /// Maneja un nuevo cliente WebSocket conectado (reloj inteligente)
  void _handleNewWebSocketClient(WebSocket socket) {
    _clients.add(socket);
    _lastSyncTime = DateTime.now();
    notifyListeners();

    debugPrint('[WearSyncService] Reloj conectado. Total clientes: ${_clients.length}');

    // Enviar snapshot inicial inmediatamente
    _sendSnapshotToSocket(socket);

    socket.listen(
      (data) {
        _handleIncomingMessage(data, socket);
      },
      onDone: () {
        _clients.remove(socket);
        debugPrint('[WearSyncService] Reloj desconectado. Total clientes: ${_clients.length}');
        notifyListeners();
      },
      onError: (e) {
        _clients.remove(socket);
        debugPrint('[WearSyncService] Error en socket del reloj: $e');
        notifyListeners();
      },
    );
  }

  /// Procesa los mensajes JSON recibidos desde el reloj
  Future<void> _handleIncomingMessage(dynamic raw, WebSocket socket) async {
    try {
      final String text = raw is String ? raw : utf8.decode(raw as List<int>);
      final Map<String, dynamic> json = jsonDecode(text);
      final action = json['action'] as String?;

      debugPrint('[WearSyncService] Mensaje recibido del reloj: $action -> $json');

      switch (action) {
        case 'PAIR_REQUEST':
          final pin = json['pin']?.toString();
          final deviceName = json['deviceName']?.toString() ?? 'Smartwatch';
          _lastWatchDeviceName = deviceName;
          _pairedPin = pin;
          notifyListeners();

          // Responder confirmación de emparejamiento
          socket.add(jsonEncode({
            'type': 'PAIR_SUCCESS',
            'userName': _authProvider?.user?.name ?? 'Usuario',
            'userId': _authProvider?.user?.id ?? '',
          }));
          await broadcastHabits();
          break;

        case 'TOGGLE_HABIT':
          final habitId = json['habitId'] as String?;
          final habitName = json['habitName'] as String? ?? '';
          if (habitId != null && _habitProvider != null) {
            await _habitProvider!.toggleHabit(
              habitId,
              DateTime.now(),
              habitName: habitName,
            );
          }
          break;

        case 'ADD_WATER':
          final habitId = json['habitId'] as String?;
          final amount = (json['amount'] as num?)?.toInt() ?? 250;
          final targetMl = (json['targetMl'] as num?)?.toInt() ?? 2000;
          final habitName = json['habitName'] as String? ?? 'Tomar Agua';
          if (habitId != null && _habitProvider != null) {
            await _habitProvider!.addWaterIntake(
              habitId,
              DateTime.now(),
              amountMl: amount,
              targetMl: targetMl,
              habitName: habitName,
            );
          }
          break;

        case 'COMPLETE_TIMER':
          final habitId = json['habitId'] as String?;
          final minutes = (json['minutes'] as num?)?.toInt() ?? 20;
          final habitName = json['habitName'] as String? ?? 'Hábito de tiempo';
          if (habitId != null && _habitProvider != null) {
            await _habitProvider!.completeTimerHabit(
              habitId,
              DateTime.now(),
              habitName: habitName,
              minutes: minutes,
            );
          }
          break;

        case 'GET_HABITS':
          await _sendSnapshotToSocket(socket);
          break;

        case 'PING':
          socket.add(jsonEncode({'type': 'PONG', 'timestamp': DateTime.now().toIso8601String()}));
          break;
      }
    } catch (e) {
      debugPrint('[WearSyncService] Error al procesar mensaje del reloj: $e');
    }
  }

  /// Construye el paquete de hábitos del día actual para el reloj
  Future<Map<String, dynamic>> _buildHabitsSnapshot() async {
    final today = DateTime.now();
    final allHabits = _habitProvider?.habits ?? [];
    final todayHabits = allHabits.where((h) => h.isScheduledForDate(today)).toList();

    int completedCount = 0;
    final List<Map<String, dynamic>> serializedHabits = [];

    for (final habit in todayHabits) {
      final isCompleted = await _habitProvider?.isCompletedOnDate(habit.id, today) ?? false;
      final count = await _habitProvider?.getCountForDate(habit.id, today) ?? 0;

      if (isCompleted) completedCount++;

      int currentProgress = 0;
      if (habit.targetType == HabitTargetType.water) {
        currentProgress = count * 250; // ml
      } else if (habit.targetType == HabitTargetType.counter) {
        currentProgress = count;
      } else {
        currentProgress = isCompleted ? habit.targetValue : 0;
      }

      serializedHabits.add({
        'id': habit.id,
        'name': habit.name,
        'title': habit.name,
        'description': habit.description ?? '',
        'category': habit.category.name,
        'targetType': habit.targetType.name,
        'targetValue': habit.targetValue,
        'currentProgress': currentProgress,
        'unit': habit.unit,
        'isCompleted': isCompleted,
      });
    }

    final double completionRate = todayHabits.isEmpty
        ? 0.0
        : completedCount / todayHabits.length;

    return {
      'type': 'HABITS_UPDATE',
      'userName': _authProvider?.user?.name ?? 'Usuario',
      'userId': _authProvider?.user?.id ?? '',
      'date': DateHelper.formatDate(today),
      'completedCount': completedCount,
      'totalCount': todayHabits.length,
      'completionRate': completionRate,
      'habits': serializedHabits,
    };
  }

  /// Envía el snapshot a un socket específico
  Future<void> _sendSnapshotToSocket(WebSocket socket) async {
    try {
      final snapshot = await _buildHabitsSnapshot();
      socket.add(jsonEncode(snapshot));
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('[WearSyncService] Error enviando snapshot a socket: $e');
    }
  }

  /// Emite la lista de hábitos a todos los relojes conectados
  Future<void> broadcastHabits() async {
    if (_clients.isEmpty) return;
    try {
      final snapshot = await _buildHabitsSnapshot();
      final payload = jsonEncode(snapshot);
      for (final client in List<WebSocket>.from(_clients)) {
        try {
          client.add(payload);
        } catch (_) {
          _clients.remove(client);
        }
      }
      _lastSyncTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('[WearSyncService] Error en broadcastHabits: $e');
    }
  }

  /// Registra el PIN manualmente introducido desde el móvil para autorizar
  void confirmPairing(String pin) {
    _pairedPin = pin;
    notifyListeners();
    broadcastHabits();
  }
}
