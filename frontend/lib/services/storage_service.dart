import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user.dart';
import '../config/app_config.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    // Android: use EncryptedSharedPreferences (AES-256 via Tink)
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // iOS: token available immediately after first device unlock
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
  }

  static Future<void> saveUser(User user) async {
    await _storage.write(
        key: AppConfig.userKey, value: jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final json = await _storage.read(key: AppConfig.userKey);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser() async {
    await _storage.delete(key: AppConfig.userKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
