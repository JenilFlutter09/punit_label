import 'dart:async';

import '../models/scale_models.dart';
import '../parsers/generic_scale_packet_parser.dart';
import '../parsers/scale_packet_parser.dart';
import '../transports/ble_scale_transport_adapter.dart';
import '../transports/classic_scale_transport_adapter.dart';
import '../transports/scale_transport_adapter.dart';

class AndroidScaleService {
  AndroidScaleService({
    List<ScaleTransportAdapter>? transports,
    List<ScalePacketParser>? parsers,
  }) : _transports =
           transports ??
           <ScaleTransportAdapter>[
             ClassicScaleTransportAdapter(),
             BleScaleTransportAdapter(),
           ],
       _parsers = parsers ?? <ScalePacketParser>[const GenericScalePacketParser()];

  final List<ScaleTransportAdapter> _transports;
  final List<ScalePacketParser> _parsers;

  final StreamController<List<DiscoveredScaleDevice>> _scanResultsController =
      StreamController<List<DiscoveredScaleDevice>>.broadcast();
  final StreamController<ScaleConnectionSnapshot> _connectionController =
      StreamController<ScaleConnectionSnapshot>.broadcast();
  final StreamController<ScalePacket> _rawPacketController =
      StreamController<ScalePacket>.broadcast();
  final StreamController<ScaleReading> _readingController =
      StreamController<ScaleReading>.broadcast();

  final Map<ScaleTransportType, List<DiscoveredScaleDevice>> _latestDevices =
      {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  ScaleTransportAdapter? _activeTransport;

  Stream<List<DiscoveredScaleDevice>> get scanResults =>
      _scanResultsController.stream;

  Stream<ScaleConnectionSnapshot> get connectionState =>
      _connectionController.stream;

  Stream<ScalePacket> get rawPackets => _rawPacketController.stream;

  Stream<ScaleReading> get readings => _readingController.stream;

  Future<void> initialize() async {
    if (_subscriptions.isNotEmpty) return;

    for (final transport in _transports) {
      await transport.initialize();

      _subscriptions.add(
        transport.scanResults.listen((devices) {
          _latestDevices[transport.transportType] = devices;
          _emitMergedDevices();
        }),
      );

      _subscriptions.add(
        transport.connectionState.listen((snapshot) {
          if (snapshot.status == ScaleConnectionStatus.connected) {
            _activeTransport = transport;
          } else if (_activeTransport == transport &&
              snapshot.status == ScaleConnectionStatus.disconnected) {
            _activeTransport = null;
          }
          _connectionController.add(snapshot);
        }),
      );

      _subscriptions.add(
        transport.packets.listen((packet) {
          _rawPacketController.add(packet);
          for (final parser in _parsers) {
            final weight = parser.parse(packet);
            if (weight == null) continue;
            _readingController.add(
              ScaleReading(
                weight: weight,
                rawPacket: packet.asString,
                transportType: packet.transportType,
                deviceId: packet.deviceId,
                receivedAt: packet.receivedAt,
              ),
            );
            break;
          }
        }),
      );
    }
  }

  Future<void> startScan() async {
    await initialize();
    for (final transport in _transports) {
      await transport.startScan();
    }
  }

  Future<void> stopScan() async {
    for (final transport in _transports) {
      await transport.stopScan();
    }
  }

  Future<void> connect(DiscoveredScaleDevice device) async {
    await initialize();
    final transport = _transports.firstWhere(
      (item) => item.transportType == device.transportType,
    );
    await transport.connect(device);
  }

  Future<void> disconnect() async {
    await _activeTransport?.disconnect();
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    for (final transport in _transports) {
      await transport.dispose();
    }

    await _scanResultsController.close();
    await _connectionController.close();
    await _rawPacketController.close();
    await _readingController.close();
  }

  void _emitMergedDevices() {
    final devices = _latestDevices.values.expand((items) => items).toList()
      ..sort((a, b) {
        final transportOrder = a.transportType.index.compareTo(
          b.transportType.index,
        );
        if (transportOrder != 0) return transportOrder;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
    _scanResultsController.add(devices);
  }
}
