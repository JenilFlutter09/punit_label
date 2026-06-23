import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/scale_models.dart';
import 'scale_transport_adapter.dart';

class BleScaleTransportAdapter extends ScaleTransportAdapter {
  final StreamController<List<DiscoveredScaleDevice>> _scanResultsController =
      StreamController<List<DiscoveredScaleDevice>>.broadcast();
  final StreamController<ScaleConnectionSnapshot> _connectionController =
      StreamController<ScaleConnectionSnapshot>.broadcast();
  final StreamController<ScalePacket> _packetController =
      StreamController<ScalePacket>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  final Map<String, StreamSubscription<List<int>>> _charSubs = {};
  BluetoothDevice? _connectedDevice;

  @override
  ScaleTransportType get transportType => ScaleTransportType.ble;

  @override
  Stream<List<DiscoveredScaleDevice>> get scanResults =>
      _scanResultsController.stream;

  @override
  Stream<ScaleConnectionSnapshot> get connectionState =>
      _connectionController.stream;

  @override
  Stream<ScalePacket> get packets => _packetController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> startScan() async {
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .map(
            (result) => DiscoveredScaleDevice(
              id: result.device.remoteId.str,
              name: result.device.platformName,
              transportType: transportType,
            ),
          )
          .toList();
      _scanResultsController.add(devices);
    });

    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      androidScanMode: AndroidScanMode.lowLatency,
    );
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
  }

  @override
  Future<void> connect(DiscoveredScaleDevice device) async {
    _connectionController.add(ScaleConnectionSnapshot.connecting(device));

    final target = BluetoothDevice.fromId(device.id);
    await target.connect(autoConnect: false);
    _connectedDevice = target;

    await _connectionSub?.cancel();
    _connectionSub = target.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        _connectionController.add(ScaleConnectionSnapshot.connected(device));
      } else if (state == BluetoothConnectionState.disconnected) {
        _connectionController.add(const ScaleConnectionSnapshot.disconnected());
      }
    });

    final services = await target.discoverServices();
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (!(characteristic.properties.notify ||
            characteristic.properties.read)) {
          continue;
        }

        final uuid = characteristic.uuid.toString().toLowerCase();
        if (_charSubs.containsKey(uuid)) continue;

        await characteristic.setNotifyValue(true);
        _charSubs[uuid] = characteristic.lastValueStream.listen((value) {
          _packetController.add(
            ScalePacket(
              deviceId: device.id,
              transportType: transportType,
              bytes: value,
              receivedAt: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  @override
  Future<void> disconnect() async {
    for (final sub in _charSubs.values) {
      await sub.cancel();
    }
    _charSubs.clear();
    await _connectionSub?.cancel();
    _connectionSub = null;

    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _connectionController.add(const ScaleConnectionSnapshot.disconnected());
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _scanSub?.cancel();
    await _scanResultsController.close();
    await _connectionController.close();
    await _packetController.close();
  }
}
