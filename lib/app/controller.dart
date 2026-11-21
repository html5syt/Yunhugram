import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import '../core/client.dart';
import '../core/credentials.dart';

enum AppPhase { starting, login, home, error }

/// 应用级账号状态；网络不通时保留安全存储中的会话，允许重试。
class AppController extends ChangeNotifier {
  AppPhase phase = AppPhase.starting;
  Locale locale = const Locale('zh');
  final credentials = Credentials();
  CoreClient? client;
  Map<String, dynamic>? user;
  String? error;
  final warning = ValueNotifier<String?>(null);
  int generation = 0;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  bool _disposed = false;
  bool _initializing = false;
  Future<void> initialize() async {
    if (_initializing) return;
    _initializing = true;
    phase = AppPhase.starting;
    error = null;
    notifyListeners();
    try {
      locale = Locale(await credentials.readLanguage() ?? 'zh');
      if (client == null) {
        final directory = await getApplicationSupportDirectory();
        final device = await credentials.deviceId();
        client = YhClient({
          'device_id': device,
          'platform': Platform.operatingSystem,
          'cache_dir': directory.path,
        });
        _subscription = client!.updates.listen((event) {
          if (event['@type'] == 'updateWarning') {
            warning.value = event['message'] as String;
          }
          if (event['@type'] == 'updateAuthorization' &&
              event['state'] == 'loginRequired') {
            user = null;
            phase = AppPhase.login;
            unawaited(
              credentials.clearToken().catchError((Object _) {
                if (!_disposed) {
                  phase = AppPhase.error;
                  error = '无法清除本机登录信息，请检查系统安全存储权限';
                  notifyListeners();
                }
              }),
            );
            if (!_disposed) notifyListeners();
          }
        });
      }
      final token = await credentials.readToken();
      if (_disposed) return;
      if (token == null) {
        phase = AppPhase.login;
      } else {
        try {
          await authenticated(
            await client!.request('restoreSession', {'token': token}),
          );
        } on ClientError catch (e) {
          if (e.kind == 'sessionExpired') {
            await credentials.clearToken();
            phase = AppPhase.login;
          } else {
            rethrow;
          }
        }
      }
    } on ClientError catch (e) {
      phase = AppPhase.error;
      error = e.message;
    } catch (_) {
      phase = AppPhase.error;
      error = '无法读取此设备的安全存储或应用目录，请检查权限后重试';
    } finally {
      _initializing = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> authenticated(Map<String, dynamic> response) async {
    try {
      await credentials.saveToken(response['token'] as String);
    } catch (_) {
      throw const ClientError('storage', '无法保存登录信息，请检查系统安全存储权限');
    }
    if (_disposed) return;
    user = response['user'] as Map<String, dynamic>;
    generation = response['generation'] as int;
    phase = AppPhase.home;
    notifyListeners();
  }

  void toggleLanguage() {
    locale = Locale(locale.languageCode == 'zh' ? 'en' : 'zh');
    notifyListeners();
    unawaited(
      credentials.saveLanguage(locale.languageCode).catchError((Object _) {
        warning.value = '无法保存语言选择，请检查系统安全存储权限';
      }),
    );
  }

  Future<void> logout() async {
    await client!.request('logout');
    await credentials.clearToken();
    user = null;
    phase = AppPhase.login;
    notifyListeners();
  }

  Future<void> clearLocal() async {
    await credentials.clearToken();
    _subscription?.cancel();
    client?.dispose();
    client = null;
    user = null;
    await initialize();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    client?.dispose();
    warning.dispose();
    super.dispose();
  }
}
