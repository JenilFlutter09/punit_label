import 'package:shared_preferences/shared_preferences.dart';

abstract class BluetoothDeviceStore {
  BluetoothDeviceStore._();

  static const String scaleKey = 'scale';
  static const String printerKey = 'printer';
  static const String receiptPrinterKey = 'receipt_printer';
  static const String towerLightKey = 'tower_light';

  static String _prefKey(String keyword) => 'bt_device_$keyword';

  static Future<void> saveDevice(String keyword, String deviceIdOrMac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(keyword), deviceIdOrMac);
  }

  static Future<String?> getDevice(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey(keyword));
  }

  static Future<void> clearDevice(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey(keyword));
  }
}
