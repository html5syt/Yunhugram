import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 会话保存与清除按顺序执行；失败结果返回调用方，但后续操作仍可重试。
class SerialWrites {
  Future<void> _tail = Future.value();
  Future<void> get settled => _tail;
  Future<void> run(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.catchError((Object _) {});
    return result;
  }
}

/// 仅使用系统安全存储，键名包含应用命名空间，避免与其他应用冲突。
class Credentials {
  static const _storage = FlutterSecureStorage();
  static const _session = 'yunhugram.session.v1',
      _device = 'yunhugram.device.v1',
      _language = 'yunhugram.language.v1';
  final _writes = SerialWrites();
  Future<String?> readToken() async {
    await _writes.settled;
    return _storage.read(key: _session);
  }

  Future<void> saveToken(String value) =>
      _writes.run(() => _storage.write(key: _session, value: value));
  Future<void> clearToken() =>
      _writes.run(() => _storage.delete(key: _session));
  Future<String?> readLanguage() => _storage.read(key: _language);
  Future<void> saveLanguage(String value) =>
      _writes.run(() => _storage.write(key: _language, value: value));
  Future<String> deviceId() async {
    final saved = await _storage.read(key: _device);
    if (saved != null) return saved;
    final random = Random.secure();
    final value = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _writes.run(() => _storage.write(key: _device, value: value));
    return value;
  }
}
