import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../features/login/loginmodel.dart';

class TokenStorage {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user';
  static const String _saveTareList = 'tare';

  /// Save token securely
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Retrieve token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  /// Save User object as JSON string
  static Future<void> saveTare(List<String> tareList) async {
    final jsonString = jsonEncode(tareList);
    await _secureStorage.write(key: _saveTareList, value: jsonString);
  }
  static Future<List<String>?> getTare() async {
    final jsonString = await _secureStorage.read(key: _saveTareList);
    if (jsonString == null) return null;

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => item.toString()).toList();
  }

  /// Save User object as JSON string
  static Future<void> saveUser(UserProfile user) async {
    final jsonString = jsonEncode(user.toJson());
    await _secureStorage.write(key: _userKey, value: jsonString);
  }

  /// Retrieve User object from JSON string
  static Future<UserProfile?> getUser() async {
    final jsonString = await _secureStorage.read(key: _userKey);
    if (jsonString == null) return null;

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return UserProfile.fromJson(jsonMap);
  }

  /// Delete token
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  /// Delete user data
  static Future<void> deleteUser() async {
    await _secureStorage.delete(key: _userKey);
  }

  /// Clear everything
  static Future<void> clearAll() async {
    //await _secureStorage.deleteAll();
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }
}
