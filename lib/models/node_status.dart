/// Health and radio metrics for nRF24 sensor nodes and ESP32 gateway.
class NodeStatus {
  final String bedId;
  final int rssi; // dBm (e.g., -62)
  final int batteryPercent; // 0 - 100%
  final bool isOnline;
  final DateTime lastSeen;

  const NodeStatus({
    required this.bedId,
    required this.rssi,
    required this.batteryPercent,
    required this.isOnline,
    required this.lastSeen,
  });

  NodeStatus copyWith({
    int? rssi,
    int? batteryPercent,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return NodeStatus(
      bedId: bedId,
      rssi: rssi ?? this.rssi,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Status of the central ESP32 Ward Gateway.
class GatewayStatus {
  final bool isConnected;
  final String gatewayId;
  final int activeNodesCount;
  final int uptimeSeconds;
  final String ipAddress;
  final DateTime lastHeartbeat;

  const GatewayStatus({
    this.isConnected = true,
    this.gatewayId = 'ESP32-WARD-3B',
    this.activeNodesCount = 3,
    this.uptimeSeconds = 52340,
    this.ipAddress = '192.168.1.142',
    required this.lastHeartbeat,
  });

  String get uptimeFormatted {
    final hours = uptimeSeconds ~/ 3600;
    final mins = (uptimeSeconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }
}
