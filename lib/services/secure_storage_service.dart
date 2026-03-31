import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static SecureStorageService? _instance;
  static SecureStorageService get instance =>
      _instance ??= SecureStorageService._();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  late final FlutterSecureStorage _storage;

  void init() {
    _storage = const FlutterSecureStorage(aOptions: _androidOptions);
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    if (value.isEmpty) {
      await delete(key);
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  static const String keyAccessToken = 'secure_ff_accessToken';
  static const String keyRefreshToken = 'secure_ff_refreshToken';
}
