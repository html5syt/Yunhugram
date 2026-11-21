import 'package:flutter/widgets.dart';
import '../../app/controller.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/action_row.dart';
import '../../ui/avatar.dart';
import '../../ui/button.dart';
import '../../ui/dialogs.dart';
import '../../ui/theme.dart';

/// 个人资料显示真实账号信息，扫码功能等后续范围保留明确占位。
class ProfileView extends StatelessWidget {
  const ProfileView({required this.app, required this.strings, super.key});
  final AppController app;
  final Strings strings;
  @override
  Widget build(BuildContext context) {
    final user = app.user!;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              TgAvatar(
                id: user['id'] as String,
                name: user['name'] as String,
                url: user['avatarUrl'] as String,
                size: 64,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] as String,
                      style: Tg.text(22, weight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${strings('cloudId')}: ${user['id']}',
                      style: Tg.text(15, color: Tg.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if ((user['phone'] as String).isNotEmpty)
          TgActionRow(
            title: '${strings('phone')}: ${user['phone']}',
            onTap: null,
          ),
        if ((user['email'] as String).isNotEmpty)
          TgActionRow(
            title: '${strings('email')}: ${user['email']}',
            onTap: null,
          ),
        const SizedBox(height: 16),
        // TODO(个人资料阶段)：这里只保留扫码入口，不虚构扫码结果。
        TgActionRow(
          title: strings('qr'),
          icon: 'msg_qrcode',
          onTap: () => noticeTg(context, strings, strings('notReady')),
        ),
      ],
    );
  }
}

/// 设置保留语言切换与有明确后果的退出登录。
Future<void> showSettings(BuildContext context, AppController app, Strings s) =>
    showTgPanel<void>(
      context,
      (panel) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s('settings'), style: Tg.text(20, weight: FontWeight.w600)),
          const SizedBox(height: 16),
          TgActionRow(
            title: s('language'),
            onTap: () {
              app.toggleLanguage();
              Navigator.pop(panel);
            },
            trailing: Text(
              app.locale.languageCode == 'zh' ? '中文' : 'English',
              style: Tg.text(15, color: Tg.muted),
            ),
          ),
          TgActionRow(
            title: s('logout'),
            icon: 'msg_arrowright',
            onTap: () async {
              if (await confirmTg(
                panel,
                s,
                s('logoutConfirm'),
                s('logoutDetail'),
                action: 'logout',
              )) {
                try {
                  await app.logout();
                  if (panel.mounted) Navigator.pop(panel);
                } on ClientError catch (e) {
                  if (panel.mounted) await noticeTg(panel, s, e.message);
                }
              }
            },
          ),
          const SizedBox(height: 8),
          TgTextButton(s('cancel'), onPressed: () => Navigator.pop(panel)),
        ],
      ),
      label: s('settings'),
    );
