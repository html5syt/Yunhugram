import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 登录凭据只保存到系统安全存储，不写入 JSON 缓存或配置文件。
class Credentials {
  const Credentials();
  static const _storage = FlutterSecureStorage();
  Future<String?> readToken() => _storage.read(key: 'session');
  Future<void> saveToken(String value) =>
      _storage.write(key: 'session', value: value);
  Future<void> clearToken() => _storage.delete(key: 'session');
  Future<String> deviceId() async {
    final saved = await _storage.read(key: 'device');
    if (saved != null) return saved;
    final random = Random.secure();
    final value = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: 'device', value: value);
    return value;
  }
}
