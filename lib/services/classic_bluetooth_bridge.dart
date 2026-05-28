import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class FlutterBluetoothClassic {
  static const MethodChannel _channel = MethodChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic',
  );
  static const EventChannel _stateChannel = EventChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_state',
  );
  static const EventChannel _connectionChannel = EventChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_connection',
  );
  static const EventChannel _dataChannel = EventChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_data',
  );

  static FlutterBluetoothClassic? _instance;

  final _stateStreamController = StreamController<BluetoothState>.broadcast();
  final _connectionStreamController =
      StreamController<BluetoothConnectionState>.broadcast();
  final _dataStreamController = StreamController<BluetoothData>.broadcast();
  final _deviceDiscoveryStreamController =
      StreamController<BluetoothDevice>.broadcast();

  Stream<BluetoothState> get onStateChanged => _stateStreamController.stream;
  Stream<BluetoothConnectionState> get onConnectionChanged =>
      _connectionStreamController.stream;
  Stream<BluetoothData> get onDataReceived => _dataStreamController.stream;
  Stream<BluetoothDevice> get onDeviceDiscovered =>
      _deviceDiscoveryStreamController.stream;

  factory FlutterBluetoothClassic() {
    _instance ??= FlutterBluetoothClassic._();
    return _instance!;
  }

  FlutterBluetoothClassic._() {
    _stateChannel.receiveBroadcastStream().listen((dynamic event) {
      final eventMap = _normalizeMap(event);
      final eventType = eventMap['event']?.toString();

      if (eventType == 'deviceFound') {
        final rawDevice = eventMap['device'];
        if (rawDevice is Map) {
          _deviceDiscoveryStreamController.add(
            BluetoothDevice.fromMap(rawDevice),
          );
        }
        return;
      }

      if (eventMap.containsKey('isEnabled')) {
        _stateStreamController.add(BluetoothState.fromMap(eventMap));
      }
    });

    _connectionChannel.receiveBroadcastStream().listen((dynamic event) {
      final eventMap = _normalizeMap(event);
      _connectionStreamController.add(
        BluetoothConnectionState.fromMap(eventMap),
      );
    });

    _dataChannel.receiveBroadcastStream().listen((dynamic event) {
      final eventMap = _normalizeMap(event);
      _dataStreamController.add(BluetoothData.fromMap(eventMap));
    });
  }

  Future<bool> isBluetoothSupported() async {
    try {
      return await _channel.invokeMethod('isBluetoothSupported') ?? false;
    } catch (e) {
      throw BluetoothException('Failed to check Bluetooth support: $e');
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await _channel.invokeMethod('isBluetoothEnabled') ?? false;
    } catch (e) {
      throw BluetoothException('Failed to check Bluetooth status: $e');
    }
  }

  Future<bool> enableBluetooth() async {
    try {
      return await _channel.invokeMethod('enableBluetooth') ?? false;
    } catch (e) {
      throw BluetoothException('Failed to enable Bluetooth: $e');
    }
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final devices = await _channel.invokeMethod<List<dynamic>>(
        'getPairedDevices',
      );
      return (devices ?? <dynamic>[])
          .whereType<Map>()
          .map(BluetoothDevice.fromMap)
          .toList();
    } catch (e) {
      throw BluetoothException('Failed to get paired devices: $e');
    }
  }

  Future<bool> startDiscovery() async {
    try {
      return await _channel.invokeMethod('startDiscovery') ?? false;
    } catch (e) {
      throw BluetoothException('Failed to start discovery: $e');
    }
  }

  Future<bool> stopDiscovery() async {
    try {
      return await _channel.invokeMethod('stopDiscovery') ?? false;
    } catch (e) {
      throw BluetoothException('Failed to stop discovery: $e');
    }
  }

  Future<bool> connect(String address) async {
    try {
      return await _channel.invokeMethod('connect', {'address': address}) ??
          false;
    } catch (e) {
      throw BluetoothException('Failed to connect to device: $e');
    }
  }

  Future<bool> disconnect() async {
    try {
      return await _channel.invokeMethod('disconnect') ?? false;
    } catch (e) {
      throw BluetoothException('Failed to disconnect: $e');
    }
  }

  Future<bool> sendData(List<int> data) async {
    try {
      return await _channel.invokeMethod('sendData', {'data': data}) ?? false;
    } catch (e) {
      throw BluetoothException('Failed to send data: $e');
    }
  }

  Future<bool> sendString(String message) async {
    try {
      return await sendData(List<int>.from(utf8.encode(message)));
    } catch (e) {
      throw BluetoothException('Failed to send string: $e');
    }
  }

  void dispose() {
    // Intentionally left as a no-op because this bridge is shared app-wide.
  }

  static Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    throw BluetoothException(
      'Expected a map payload but received ${value.runtimeType}.',
    );
  }
}

class BluetoothException implements Exception {
  final String message;

  BluetoothException(this.message);

  @override
  String toString() => 'BluetoothException: $message';
}

class BluetoothState {
  final bool isEnabled;
  final String status;

  BluetoothState({required this.isEnabled, required this.status});

  factory BluetoothState.fromMap(dynamic map) {
    final normalizedMap = FlutterBluetoothClassic._normalizeMap(map);
    return BluetoothState(
      isEnabled: normalizedMap['isEnabled'] == true,
      status: normalizedMap['status']?.toString() ?? '',
    );
  }
}

class BluetoothDevice {
  final String name;
  final String address;
  final bool paired;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.paired,
  });

  factory BluetoothDevice.fromMap(dynamic map) {
    final normalizedMap = FlutterBluetoothClassic._normalizeMap(map);
    return BluetoothDevice(
      name: normalizedMap['name']?.toString() ?? 'Unknown',
      address: normalizedMap['address']?.toString() ?? '',
      paired: normalizedMap['paired'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'address': address, 'paired': paired};
  }
}

class BluetoothConnectionState {
  final bool isConnected;
  final String deviceAddress;
  final String status;

  BluetoothConnectionState({
    required this.isConnected,
    required this.deviceAddress,
    required this.status,
  });

  factory BluetoothConnectionState.fromMap(dynamic map) {
    final normalizedMap = FlutterBluetoothClassic._normalizeMap(map);
    return BluetoothConnectionState(
      isConnected: normalizedMap['isConnected'] == true,
      deviceAddress: normalizedMap['deviceAddress']?.toString() ?? '',
      status: normalizedMap['status']?.toString() ?? '',
    );
  }
}

class BluetoothData {
  final String deviceAddress;
  final List<int> data;

  BluetoothData({required this.deviceAddress, required this.data});

  String asString() {
    return utf8.decode(data);
  }

  factory BluetoothData.fromMap(dynamic map) {
    final normalizedMap = FlutterBluetoothClassic._normalizeMap(map);
    final rawData = normalizedMap['data'];
    return BluetoothData(
      deviceAddress: normalizedMap['deviceAddress']?.toString() ?? '',
      data: rawData is List ? List<int>.from(rawData) : const <int>[],
    );
  }
}
