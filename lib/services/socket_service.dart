import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Explicit Socket.IO connection status states
enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Production Socket.IO Client for ESP32 Gateway & Ward Telemetry Server.
/// Listens to 'vitals_update', 'node_status', 'critical_alarm', 'alarm_tick', and 'alarm_stats'.
class SocketService {
  io.Socket? _socket;
  String _serverUrl;

  final StreamController<Map<String, dynamic>> _vitalsStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _nodeStatusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _alarmStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _alarmStatsStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<SocketConnectionStatus> _statusStreamController =
      StreamController<SocketConnectionStatus>.broadcast();

  Stream<Map<String, dynamic>> get onVitalsUpdate => _vitalsStreamController.stream;
  Stream<Map<String, dynamic>> get onNodeStatus => _nodeStatusStreamController.stream;
  Stream<List<Map<String, dynamic>>> get onCriticalAlarm => _alarmStreamController.stream;
  Stream<Map<String, dynamic>> get onAlarmStats => _alarmStatsStreamController.stream;
  Stream<SocketConnectionStatus> get onStatusChanged => _statusStreamController.stream;

  SocketConnectionStatus _status = SocketConnectionStatus.disconnected;
  SocketConnectionStatus get status => _status;
  bool get isConnected => _status == SocketConnectionStatus.connected;
  String get serverUrl => _serverUrl;

  SocketService({String serverUrl = 'http://192.168.1.142:3000'})
      : _serverUrl = serverUrl;

  void _setStatus(SocketConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusStreamController.add(newStatus);
    }
  }

  /// Connects to the telemetry socket server with optional new URL.
  void connect({String? serverUrl}) {
    if (serverUrl != null && serverUrl.trim().isNotEmpty) {
      _serverUrl = serverUrl.trim();
    }

    // Clean up existing socket before creating new one
    disconnect();
    _setStatus(SocketConnectionStatus.connecting);

    try {
      debugPrint('⚡ [SocketService] Connecting to Ward Gateway: $_serverUrl');
      _socket = io.io(
        _serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setTimeout(5000)
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('🟢 [SocketService] Connected to Gateway at $_serverUrl');
        _setStatus(SocketConnectionStatus.connected);
      });

      _socket?.onDisconnect((_) {
        debugPrint('🔴 [SocketService] Disconnected from Gateway');
        _setStatus(SocketConnectionStatus.disconnected);
      });

      _socket?.onConnectError((err) {
        debugPrint('⚠️ [SocketService] Connection error: $err');
        _setStatus(SocketConnectionStatus.error);
      });

      _socket?.onError((err) {
        debugPrint('⚠️ [SocketService] Socket error: $err');
        _setStatus(SocketConnectionStatus.error);
      });

      // 1. Live Telemetry Update Event (Map of beds)
      _socket?.on('vitals_update', (data) {
        if (data is Map) {
          final typedMap = Map<String, dynamic>.from(data);
          _vitalsStreamController.add(typedMap);
        }
      });

      // 2. Node Status Update Event (Map of beds)
      _socket?.on('node_status', (data) {
        if (data is Map) {
          final typedMap = Map<String, dynamic>.from(data);
          _nodeStatusStreamController.add(typedMap);
        }
      });

      // 3. Critical Alarms & Escalation Ticks (List of alarms)
      _socket?.on('critical_alarm', (data) {
        _handleAlarmData(data);
      });

      _socket?.on('alarm_tick', (data) {
        _handleAlarmData(data);
      });

      // 4. Alarm Statistics
      _socket?.on('alarm_stats', (data) {
        if (data is Map) {
          final typedMap = Map<String, dynamic>.from(data);
          _alarmStatsStreamController.add(typedMap);
        }
      });

      _socket?.connect();
    } catch (e) {
      debugPrint('⚠️ [SocketService] Socket initialization error: $e');
      _setStatus(SocketConnectionStatus.error);
    }
  }

  void _handleAlarmData(dynamic data) {
    if (data is List) {
      final list = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _alarmStreamController.add(list);
    } else if (data is Map) {
      _alarmStreamController.add([Map<String, dynamic>.from(data)]);
    }
  }

  /// Sends nurse acknowledgment for an active bedside alarm
  void acknowledgeAlarm(String alarmId, String nurseName) {
    debugPrint('🔕 [SocketService] Emitting acknowledge_alarm: $alarmId by $nurseName');
    _socket?.emit('acknowledge_alarm', {
      'alarm_id': alarmId,
      'alarmId': alarmId,
      'nurse': nurseName,
      'nurseName': nurseName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Clears an active alarm on the server
  void clearAlarm(String? alarmId) {
    debugPrint('🔕 [SocketService] Emitting clear_alarm: ${alarmId ?? "ALL"}');
    _socket?.emit('clear_alarm', {
      if (alarmId != null) 'alarm_id': alarmId,
      if (alarmId != null) 'alarmId': alarmId,
    });
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _setStatus(SocketConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _vitalsStreamController.close();
    _nodeStatusStreamController.close();
    _alarmStreamController.close();
    _alarmStatsStreamController.close();
    _statusStreamController.close();
  }
}
