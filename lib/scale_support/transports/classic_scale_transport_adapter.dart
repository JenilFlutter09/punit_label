import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../../services/classic_bluetooth_bridge.dart' as classic;
import '../models/scale_models.dart';
import 'scale_transport_adapter.dart';

class ClassicScaleTransportAdapter extends ScaleTransportAdapter {
  final classic.FlutterBluetoothClassic _bluetooth =
      classic.FlutterBluetoothClassic();

  final StreamController<List<DiscoveredScaleDevice>> _scanResultsController =
      StreamController<List<DiscoveredScaleDevice>>.broadcast();
  final StreamController<ScaleConnectionSnapshot> _connectionController =
      StreamController<ScaleConnectionSnapshot>.broadcast();
  final StreamController<ScalePacket> _packetController =
      StreamController<ScalePacket>.broadcast();

  final Map<String, classic.BluetoothDevice> _deviceMap = {};

  StreamSubscription<classic.BluetoothDevice>? _discoverySub;
  StreamSubscription<classic.BluetoothConnectionState>? _connectionSub;
  StreamSubscription<classic.BluetoothData>? _dataSub;
  bool _initialized = false;
  String? _connectedDeviceId;

  @override
  ScaleTransportType get transportType => ScaleTransportType.classic;

  @override
  Stream<List<DiscoveredScaleDevice>> get scanResults =>
      _scanResultsController.stream;

  @override
  Stream<ScaleConnectionSnapshot> get connectionState =>
      _connectionController.stream;

  @override
  Stream<ScalePacket> get packets => _packetController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _connectionSub = _bluetooth.onConnectionChanged.listen((state) {
      final device = _toDiscoveredDevice(
        classic.BluetoothDevice(
          name: '',
          address: state.deviceAddress,
          paired: true,
        ),
      );

      if (state.isConnected) {
        _connectedDeviceId = state.deviceAddress;
        _connectionController.add(ScaleConnectionSnapshot.connected(device));
      } else {
        _connectedDeviceId = null;
        _connectionController.add(
          ScaleConnectionSnapshot.disconnected(reason: state.status),
        );
      }
    });

    _dataSub = _bluetooth.onDataReceived.listen((data) {
      if (_connectedDeviceId != null &&
          data.deviceAddress.isNotEmpty &&
          data.deviceAddress != _connectedDeviceId) {
        return;
      }

      _packetController.add(
        ScalePacket(
          deviceId: data.deviceAddress,
          transportType: transportType,
          bytes: data.data,
          receivedAt: DateTime.now(),
        ),
      );
    });

    _initialized = true;
  }

  @override
  Future<void> startScan() async {
    await initialize();
    await _prepareBluetooth();
    _deviceMap.clear();

    final pairedDevices = await _bluetooth.getPairedDevices();
    for (final device in pairedDevices) {
      _deviceMap[device.address] = device;
    }
    _publishDevices();

    await _discoverySub?.cancel();
    final discoveryStarted = await _bluetooth.startDiscovery();
    if (!discoveryStarted) return;

    _discoverySub = _bluetooth.onDeviceDiscovered.listen((device) {
      _deviceMap[device.address] = device;
      _publishDevices();
    });
  }

  @override
  Future<void> stopScan() async {
    await _bluetooth.stopDiscovery();
    await _discoverySub?.cancel();
    _discoverySub = null;
  }

  @override
  Future<void> connect(DiscoveredScaleDevice device) async {
    await initialize();
    await _prepareBluetooth();
    _connectionController.add(ScaleConnectionSnapshot.connecting(device));
    final connected = await _bluetooth.connect(device.id);
    if (!connected) {
      _connectionController.add(
        const ScaleConnectionSnapshot.disconnected(
          reason: 'Classic Bluetooth connection failed.',
        ),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _connectedDeviceId = null;
    _connectionController.add(const ScaleConnectionSnapshot.disconnected());
  }

  @override
  Future<void> dispose() async {
    await _discoverySub?.cancel();
    await _connectionSub?.cancel();
    await _dataSub?.cancel();
    await _scanResultsController.close();
    await _connectionController.close();
    await _packetController.close();
  }

  void _publishDevices() {
    final devices = _deviceMap.values
        .map(_toDiscoveredDevice)
        .toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      ));
    _scanResultsController.add(devices);
  }

  DiscoveredScaleDevice _toDiscoveredDevice(classic.BluetoothDevice device) {
    return DiscoveredScaleDevice(
      id: device.address,
      name: device.name,
      transportType: transportType,
      isBonded: device.paired,
    );
  }

  Future<void> _prepareBluetooth() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        throw Exception(
          '${permission.toString().split('.').last} permission is required.',
        );
      }
    }

    final supported = await _bluetooth.isBluetoothSupported();
    if (!supported) {
      throw Exception('Bluetooth classic is not supported on this device.');
    }

    var enabled = await _bluetooth.isBluetoothEnabled();
    if (!enabled) {
      enabled = await _bluetooth.enableBluetooth();
    }
    if (!enabled) {
      throw Exception('Bluetooth is off.');
    }
  }
}
