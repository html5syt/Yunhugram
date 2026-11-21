import 'package:flutter/widgets.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/dialogs.dart';
import '../../ui/progress.dart';
import '../../ui/theme.dart';
import 'captcha_panel.dart';
import 'controller.dart';
import 'form.dart';

/// 登录／手机号注册入口，桌面限制内容宽度，移动端避让键盘。
class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.client,
    required this.strings,
    required this.onAuthenticated,
    required this.onLanguage,
    super.key,
  });
  final CoreClient client;
  final Strings strings;
  final Future<void> Function(Map<String, dynamic>) onAuthenticated;
  final VoidCallback onLanguage;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final _auth = AuthController(widget.client, widget.onAuthenticated);
  final _form = AuthFormData();
  @override
  void dispose() {
    _auth.dispose();
    _form.dispose();
    super.dispose();
  }

  void _submit() => _auth.submit(_form.values(), widget.strings);
  Future<void> _send() => _auth.sendCode(
    _form.mobile.text,
    widget.strings,
    () => showTgPanel<Map<String, dynamic>>(
      context,
      (_) => CaptchaPanel(client: widget.client, strings: widget.strings),
      label: widget.strings('verify'),
    ),
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: _body(context),
  );
  Widget _body(BuildContext context) => SafeArea(
    child: AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        final s = widget.strings;
        final phone = _auth.mode == LoginMode.phone;
        final disabled = _auth.busy || _auth.sending;
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TgTextButton(
                s.locale.languageCode == 'zh' ? 'English' : '中文',
                onPressed: widget.onLanguage,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.sizeOf(context).height > 650 ? 48 : 12,
                  24,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/app_icon.png',
                              width: 80,
                              height: 80,
                              excludeFromSemantics: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            s(
                              _auth.registering
                                  ? 'register'
                                  : phone
                                  ? 'phoneLogin'
                                  : 'emailLogin',
                            ),
                            textAlign: TextAlign.center,
                            style: Tg.text(26, weight: FontWeight.w500),
                          ),
                          const SizedBox(height: 32),
                          AuthFields(
                            form: _form,
                            auth: _auth,
                            strings: s,
                            onSubmit: _submit,
                            onSend: _send,
                          ),
                          if (_auth.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '! ',
                                      style: Tg.text(
                                        16,
                                        color: Tg.danger,
                                        weight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _auth.error!,
                                        style: Tg.text(15, color: Tg.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_auth.info != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _auth.info!,
                                style: Tg.text(15, color: Tg.blueText),
                              ),
                            ),
                          if (disabled)
                            Center(
                              child: Semantics(
                                label: s('checking'),
                                child: const TgProgress(),
                              ),
                            ),
                          TgTextButton(
                            s(_auth.registering ? 'createAccount' : 'login'),
                            filled: true,
                            onPressed: disabled ? null : _submit,
                          ),
                          const SizedBox(height: 12),
                          if (!_auth.registering)
                            TgTextButton(
                              s(phone ? 'useEmail' : 'usePhone'),
                              onPressed: disabled
                                  ? null
                                  : () {
                                      _form.password.clear();
                                      _auth.changeMode(
                                        phone
                                            ? LoginMode.email
                                            : LoginMode.phone,
                                      );
                                    },
                            ),
                          TgTextButton(
                            s(_auth.registering ? 'backToLogin' : 'register'),
                            onPressed: disabled
                                ? null
                                : _auth.toggleRegistration,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
