import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';

/// Data source modes for the SENTINEL-Ward telemetry client
enum TelemetrySourceMode {
  simulation,
  live,
}

/// Immutable configuration state for the telemetry client
class TelemetryModeState {
  final TelemetrySourceMode mode;
  final String serverUrl;
  final SocketConnectionStatus connectionStatus;

  const TelemetryModeState({
    required this.mode,
    required this.serverUrl,
    this.connectionStatus = SocketConnectionStatus.disconnected,
  });

  bool get isLive => mode == TelemetrySourceMode.live;
  bool get isSimulation => mode == TelemetrySourceMode.simulation;
  bool get isConnected => connectionStatus == SocketConnectionStatus.connected;
  bool get isConnecting => connectionStatus == SocketConnectionStatus.connecting;
  bool get isError => connectionStatus == SocketConnectionStatus.error;

  TelemetryModeState copyWith({
    TelemetrySourceMode? mode,
    String? serverUrl,
    SocketConnectionStatus? connectionStatus,
  }) {
    return TelemetryModeState(
      mode: mode ?? this.mode,
      serverUrl: serverUrl ?? this.serverUrl,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}

/// Auto-detects reasonable default host URL depending on platform
String getDefaultServerUrl() {
  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  try {
    if (Platform.isAndroid) {
      // 10.0.2.2 is Android emulator host loopback; on real devices LAN IP is used
      return 'http://10.0.2.2:3000';
    }
  } catch (_) {}
  return 'http://192.168.1.142:3000';
}

/// State notifier managing the telemetry connection mode and backend URL
class TelemetryModeNotifier extends StateNotifier<TelemetryModeState> {
  final SocketService _socketService;

  TelemetryModeNotifier(this._socketService)
      : super(
          TelemetryModeState(
            // Start in simulation by default so app runs offline out of the box
            mode: TelemetrySourceMode.simulation,
            serverUrl: getDefaultServerUrl(),
            connectionStatus: SocketConnectionStatus.disconnected,
          ),
        ) {
    // Listen to socket service status changes to keep state synchronized
    _socketService.onStatusChanged.listen((status) {
      if (mounted) {
        state = state.copyWith(connectionStatus: status);
      }
    });
  }

  /// Switch between Live Gateway Mode and Offline Simulation Mode
  void setMode(TelemetrySourceMode newMode) {
    if (state.mode == newMode) return;

    state = state.copyWith(mode: newMode);

    if (newMode == TelemetrySourceMode.live) {
      _socketService.connect(serverUrl: state.serverUrl);
    } else {
      _socketService.disconnect();
    }
  }

  /// Update the backend server host address
  void setServerUrl(String newUrl) {
    final cleanUrl = newUrl.trim();
    if (cleanUrl.isEmpty) return;

    state = state.copyWith(serverUrl: cleanUrl);

    if (state.isLive) {
      _socketService.connect(serverUrl: cleanUrl);
    }
  }

  /// Reconnect explicitly
  void reconnect() {
    if (state.isLive) {
      _socketService.connect(serverUrl: state.serverUrl);
    }
  }
}

/// Global provider for Telemetry Mode and URL configuration
final telemetryModeProvider =
    StateNotifierProvider<TelemetryModeNotifier, TelemetryModeState>((ref) {
  // We grab the singleton socket service from socketServiceProvider
  final socketService = ref.watch(socketServiceProvider);
  return TelemetryModeNotifier(socketService);
});

/// Singleton SocketService provider
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(serverUrl: getDefaultServerUrl());
  ref.onDispose(() => service.dispose());
  return service;
});
