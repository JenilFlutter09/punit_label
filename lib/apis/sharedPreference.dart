import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../features/login/loginmodel.dart';

class TokenStorage {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user';
  static const String _saveTareList = 'tare';
  static const String _defaultNonBatchLabelFormatKey =
      'default_non_batch_label_format';
  static const String _whiteLabelKey = 'white_label_enabled';
  static const String _printSerialNumberKey = 'print_serial_number_enabled';
  static const String _printTimeKey = 'print_time_enabled';
  static const String _printCopiesKey = 'print_copies';
  static const String _tareStateKey = 'tare_state';
  static const String _labelStateKey = 'label_state';
  static const String _towerLightKey = 'tower_light_enabled';

  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } on PlatformException {
      await clearAll();
      return null;
    }
  }

  static Future<void> saveTare(List<String> tareList) async {
    final jsonString = jsonEncode(tareList);
    await _secureStorage.write(key: _saveTareList, value: jsonString);
  }

  static Future<List<String>?> getTare() async {
    try {
      final jsonString = await _secureStorage.read(key: _saveTareList);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => item.toString()).toList();
    } on PlatformException {
      await _secureStorage.delete(key: _saveTareList);
      return null;
    }
  }

  static Future<void> saveUser(UserProfile user) async {
    final jsonString = jsonEncode(user.toJson());
    await _secureStorage.write(key: _userKey, value: jsonString);
  }

  static Future<UserProfile?> getUser() async {
    try {
      final jsonString = await _secureStorage.read(key: _userKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return UserProfile.fromJson(jsonMap);
    } on PlatformException {
      await _secureStorage.delete(key: _userKey);
      return null;
    }
  }

  static Future<void> saveDefaultNonBatchLabelFormatId(int labelId) async {
    await _secureStorage.write(
      key: _defaultNonBatchLabelFormatKey,
      value: labelId.toString(),
    );
  }

  static Future<int?> getDefaultNonBatchLabelFormatId() async {
    try {
      final value = await _secureStorage.read(key: _defaultNonBatchLabelFormatKey);
      if (value == null) return null;
      return int.tryParse(value);
    } on PlatformException {
      await _secureStorage.delete(key: _defaultNonBatchLabelFormatKey);
      return null;
    }
  }

  static Future<void> saveWhiteLabelEnabled(bool value) async {
    await _secureStorage.write(key: _whiteLabelKey, value: value.toString());
  }

  static Future<bool?> getWhiteLabelEnabled() async {
    try {
      final value = await _secureStorage.read(key: _whiteLabelKey);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } on PlatformException {
      await _secureStorage.delete(key: _whiteLabelKey);
      return null;
    }
  }

  static Future<void> savePrintSerialNumberEnabled(bool value) async {
    await _secureStorage.write(
      key: _printSerialNumberKey,
      value: value.toString(),
    );
  }

  static Future<bool?> getPrintSerialNumberEnabled() async {
    try {
      final value = await _secureStorage.read(key: _printSerialNumberKey);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } on PlatformException {
      await _secureStorage.delete(key: _printSerialNumberKey);
      return null;
    }
  }

  static Future<void> savePrintTimeEnabled(bool value) async {
    await _secureStorage.write(key: _printTimeKey, value: value.toString());
  }

  static Future<bool?> getPrintTimeEnabled() async {
    try {
      final value = await _secureStorage.read(key: _printTimeKey);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } on PlatformException {
      await _secureStorage.delete(key: _printTimeKey);
      return null;
    }
  }

  static Future<void> savePrintCopies(int value) async {
    await _secureStorage.write(key: _printCopiesKey, value: value.toString());
  }

  static Future<int?> getPrintCopies() async {
    try {
      final value = await _secureStorage.read(key: _printCopiesKey);
      if (value == null) return null;
      return int.tryParse(value);
    } on PlatformException {
      await _secureStorage.delete(key: _printCopiesKey);
      return null;
    }
  }

  static Future<void> saveTareState(String value) async {
    await _secureStorage.write(key: _tareStateKey, value: value);
  }

  static Future<String?> getTareState() async {
    try {
      return await _secureStorage.read(key: _tareStateKey);
    } on PlatformException {
      await _secureStorage.delete(key: _tareStateKey);
      return null;
    }
  }

  static Future<void> saveLabelState(String value) async {
    await _secureStorage.write(key: _labelStateKey, value: value);
  }

  static Future<String?> getLabelState() async {
    try {
      return await _secureStorage.read(key: _labelStateKey);
    } on PlatformException {
      await _secureStorage.delete(key: _labelStateKey);
      return null;
    }
  }

  static Future<void> saveTowerLightEnabled(bool value) async {
    await _secureStorage.write(key: _towerLightKey, value: value.toString());
  }

  static Future<bool?> getTowerLightEnabled() async {
    try {
      final value = await _secureStorage.read(key: _towerLightKey);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } on PlatformException {
      await _secureStorage.delete(key: _towerLightKey);
      return null;
    }
  }

  static Future<void> clearAll() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _saveTareList);
    await _secureStorage.delete(key: _defaultNonBatchLabelFormatKey);
    await _secureStorage.delete(key: _whiteLabelKey);
    await _secureStorage.delete(key: _printSerialNumberKey);
    await _secureStorage.delete(key: _printTimeKey);
    await _secureStorage.delete(key: _printCopiesKey);
    await _secureStorage.delete(key: _tareStateKey);
    await _secureStorage.delete(key: _labelStateKey);
    await _secureStorage.delete(key: _towerLightKey);
  }
}
