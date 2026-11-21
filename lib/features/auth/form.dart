import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/field.dart';
import 'controller.dart';

/// 输入控件的生命周期属于界面；密码不进入业务控制器状态。
class AuthFormData {
  final mobile = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  final sms = TextEditingController(),
      name = TextEditingController(),
      invite = TextEditingController();
  Map<String, String> values() => {
    'mobile': mobile.text.trim(),
    'email': email.text.trim(),
    'password': password.text,
    'captcha': sms.text.trim(),
    'nickname': name.text.trim(),
    'inviteCode': invite.text.trim(),
  };
  void dispose() {
    for (final c in [mobile, email, password, sms, name, invite]) {
      c.dispose();
    }
  }
}

class AuthFields extends StatelessWidget {
  const AuthFields({
    required this.form,
    required this.auth,
    required this.strings,
    required this.onSubmit,
    required this.onSend,
    super.key,
  });
  final AuthFormData form;
  final AuthController auth;
  final Strings strings;
  final VoidCallback onSubmit, onSend;
  @override
  Widget build(BuildContext context) {
    final s = strings;
    final enabled = !auth.busy && !auth.sending;
    return Column(
      children: [
        if (auth.mode == LoginMode.phone) ...[
          TgField(
            controller: form.mobile,
            label: s('phone'),
            keyboardType: TextInputType.phone,
            enabled: enabled,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TgField(
                  controller: form.sms,
                  label: s('code'),
                  keyboardType: TextInputType.number,
                  enabled: enabled,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  onSubmitted: auth.registering ? null : (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              TgTextButton(
                auth.cooldown > 0
                    ? '${auth.cooldown} ${s('seconds')}'
                    : s('sendCode'),
                onPressed: enabled && auth.cooldown == 0 ? onSend : null,
              ),
            ],
          ),
        ] else ...[
          TgField(
            controller: form.email,
            label: s('email'),
            keyboardType: TextInputType.emailAddress,
            enabled: enabled,
            autofillHints: const [AutofillHints.username],
          ),
          TgField(
            controller: form.password,
            label: s('password'),
            password: true,
            enabled: enabled,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onSubmit(),
          ),
        ],
        if (auth.registering) ...[
          TgField(
            controller: form.name,
            label: s('nickname'),
            enabled: enabled,
          ),
          TgField(
            controller: form.invite,
            label: s('inviteCode'),
            enabled: enabled,
            onSubmitted: (_) => onSubmit(),
          ),
        ],
      ],
    );
  }
}
