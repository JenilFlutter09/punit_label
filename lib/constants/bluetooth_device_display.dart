import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BluetoothDeviceDisplay {
  BluetoothDeviceDisplay._();

  static String deviceIdFromDevice(BluetoothDevice device) {
    return device.remoteId.str;
  }

  static String deviceIdFromResult(ScanResult result) {
    return deviceIdFromDevice(result.device);
  }

  static String displayName(ScanResult result) {
    final localName = result.advertisementData.advName.trim();
    if (localName.isNotEmpty) return localName;

    final platformName = result.device.platformName.trim();
    if (platformName.isNotEmpty) return platformName;

    final id = deviceIdFromResult(result);
    final suffix = id.length > 4 ? id.substring(id.length - 4) : id;
    return 'Unknown Device (${suffix.toUpperCase()})';
  }
}
