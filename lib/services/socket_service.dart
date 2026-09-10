import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Production Socket.IO Client for ESP32 Gateway & Ward Telemetry Server.
/// Listens to 'vitals_update', 'node_status', and 'critical_alarm' events.
class SocketService {
  io.Socket? _socket;
  final String _serverUrl;

  final StreamController<Map<String, dynamic>> _vitalsStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _nodeStatusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _alarmStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<int> _resolvedAlarmsCountController =
      StreamController<int>.broadcast();
  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onVitalsUpdate => _vitalsStreamController.stream;
  Stream<Map<String, dynamic>> get onNodeStatus => _nodeStatusStreamController.stream;
  Stream<Map<String, dynamic>> get onCriticalAlarm => _alarmStreamController.stream;
  Stream<int> get onResolvedAlarmsCount => _resolvedAlarmsCountController.stream;
  Stream<bool> get onConnectionChanged => _connectionStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  SocketService({String serverUrl = 'http://localhost:3000'})
      : _serverUrl = serverUrl;

  /// Connects to the telemetry socket server.
  void connect() {
    try {
      _socket = io.io(
        _serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('🟢 [SocketService] Connected to ESP32 Gateway at $_serverUrl');
        _isConnected = true;
        _connectionStreamController.add(true);
      });

      _socket?.onDisconnect((_) {
        debugPrint('🔴 [SocketService] Disconnected from ESP32 Gateway');
        _isConnected = false;
        _connectionStreamController.add(false);
      });

      _socket?.onConnectError((err) {
        debugPrint('⚠️ [SocketService] Connection error: $err');
        _isConnected = false;
        _connectionStreamController.add(false);
      });

      // Register real-time clinical telemetry event listeners
      _socket?.on('vitals_update', (data) {
        if (data is Map<String, dynamic>) {
          _vitalsStreamController.add(data);
        }
      });

      _socket?.on('node_status', (data) {
        if (data is Map<String, dynamic>) {
          _nodeStatusStreamController.add(data);
        }
      });

      _socket?.on('critical_alarm', (data) {
        if (data is Map<String, dynamic>) {
          _alarmStreamController.add(data);
        }
      });

      _socket?.on('alarm_stats', (data) {
        if (data is Map<String, dynamic> && data['resolvedAlarmsCount'] != null) {
          final count = (data['resolvedAlarmsCount'] as num).toInt();
          _resolvedAlarmsCountController.add(count);
        }
      });

      _socket?.on('alarm_acknowledged', (data) {
        if (data is Map<String, dynamic> && data['resolvedAlarmsCount'] != null) {
          final count = (data['resolvedAlarmsCount'] as num).toInt();
          _resolvedAlarmsCountController.add(count);
        }
      });

      _socket?.on('alarm_cleared', (data) {
        if (data is Map<String, dynamic> && data['resolvedAlarmsCount'] != null) {
          final count = (data['resolvedAlarmsCount'] as num).toInt();
          _resolvedAlarmsCountController.add(count);
        }
      });

      _socket?.connect();
    } catch (e) {
      debugPrint('⚠️ [SocketService] Socket initialization error: $e');
      _isConnected = false;
      _connectionStreamController.add(false);
    }
  }

  /// Sends nurse acknowledgment for an active bedside alarm
  void acknowledgeAlarm(String alarmId, String nurseName) {
    _socket?.emit('acknowledge_alarm', {
      'alarm_id': alarmId,
      'nurse': nurseName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Clears an active alarm on the backend
  void clearAlarm(String alarmId) {
    _socket?.emit('clear_alarm', {
      'alarm_id': alarmId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _vitalsStreamController.close();
    _nodeStatusStreamController.close();
    _alarmStreamController.close();
    _connectionStreamController.close();
  }
}
