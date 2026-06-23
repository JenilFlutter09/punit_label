enum ScaleTransportType { classic, ble }

enum ScaleConnectionStatus { disconnected, connecting, connected }

class DiscoveredScaleDevice {
  final String id;
  final String name;
  final ScaleTransportType transportType;
  final bool isBonded;

  const DiscoveredScaleDevice({
    required this.id,
    required this.name,
    required this.transportType,
    this.isBonded = false,
  });

  String get displayName => name.trim().isEmpty ? 'Unknown Scale' : name.trim();
}

class ScaleConnectionSnapshot {
  final ScaleConnectionStatus status;
  final DiscoveredScaleDevice? device;
  final String? reason;

  const ScaleConnectionSnapshot({
    required this.status,
    this.device,
    this.reason,
  });

  const ScaleConnectionSnapshot.disconnected({String? reason})
    : this(status: ScaleConnectionStatus.disconnected, reason: reason);

  const ScaleConnectionSnapshot.connecting(DiscoveredScaleDevice device)
    : this(status: ScaleConnectionStatus.connecting, device: device);

  const ScaleConnectionSnapshot.connected(DiscoveredScaleDevice device)
    : this(status: ScaleConnectionStatus.connected, device: device);
}

class ScalePacket {
  final String deviceId;
  final ScaleTransportType transportType;
  final List<int> bytes;
  final DateTime receivedAt;

  const ScalePacket({
    required this.deviceId,
    required this.transportType,
    required this.bytes,
    required this.receivedAt,
  });

  String get asString => String.fromCharCodes(bytes);
}

class ScaleReading {
  final double weight;
  final String rawPacket;
  final ScaleTransportType transportType;
  final String deviceId;
  final DateTime receivedAt;

  const ScaleReading({
    required this.weight,
    required this.rawPacket,
    required this.transportType,
    required this.deviceId,
    required this.receivedAt,
  });
}
