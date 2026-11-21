import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';

enum LoginMode { phone, email }

/// 登录流程、短信冷却和错误状态；不保存密码。
class AuthController extends ChangeNotifier {
  AuthController(this.client, this.onAuthenticated);
  final CoreClient client;
  final Future<void> Function(Map<String, dynamic>) onAuthenticated;
  LoginMode mode = LoginMode.phone;
  bool registering = false;
  bool busy = false;
  bool sending = false;
  bool _disposed = false;
  int cooldown = 0;
  String? error;
  String? info;
  Timer? _cooldown;
  void changeMode(LoginMode next) {
    if (busy || sending) return;
    mode = next;
    error = null;
    info = null;
    notifyListeners();
  }

  void toggleRegistration() {
    if (busy || sending) return;
    registering = !registering;
    if (registering) mode = LoginMode.phone;
    error = null;
    info = null;
    notifyListeners();
  }

  String? validatePhone(String mobile, Strings s) =>
      RegExp(r'^\+?[0-9]{7,15}$').hasMatch(mobile.trim())
      ? null
      : s('phoneInvalid');
  Future<void> sendCode(
    String mobile,
    Strings s,
    Future<Map<String, dynamic>?> Function() challenge,
  ) async {
    if (sending || busy || cooldown > 0) return;
    error = validatePhone(mobile, s);
    if (error != null) {
      notifyListeners();
      return;
    }
    sending = true;
    info = null;
    notifyListeners();
    try {
      final proof = await challenge();
      if (_disposed || proof == null) return;
      await client.request('sendCode', {'mobile': mobile.trim(), ...proof});
      cooldown = 60;
      _cooldown?.cancel();
      _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (--cooldown <= 0) timer.cancel();
        if (!_disposed) notifyListeners();
      });
    } on ClientError catch (e) {
      error = e.kind == 'network' ? s('network') : e.message;
    } finally {
      sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> submit(Map<String, String> form, Strings s) async {
    if (busy || sending) return;
    final phone = mode == LoginMode.phone;
    error = phone
        ? validatePhone(form['mobile'] ?? '', s)
        : (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(form['email'] ?? '')
              ? null
              : s('emailInvalid'));
    if (error == null && phone && (form['captcha'] ?? '').isEmpty) {
      error = s('codeRequired');
    }
    if (error == null && !phone && (form['password'] ?? '').isEmpty) {
      error = s('passwordRequired');
    }
    if (error == null &&
        registering &&
        (form['nickname'] ?? '').trim().isEmpty) {
      error = s('nicknameRequired');
    }
    if (error != null) {
      notifyListeners();
      return;
    }
    busy = true;
    info = null;
    notifyListeners();
    try {
      final response = await client.request(
        registering
            ? 'registerPhone'
            : phone
            ? 'phoneLogin'
            : 'emailLogin',
        form,
      );
      if (_disposed) return;
      if (response['registered'] == true && response['token'] == null) {
        registering = false;
        info = s('registeredNotice');
      } else {
        await onAuthenticated(response);
      }
    } on ClientError catch (e) {
      error = e.kind == 'network' ? s('network') : e.message;
    } catch (_) {
      error = s('failed');
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cooldown?.cancel();
    super.dispose();
  }
}
