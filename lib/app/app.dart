import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../features/auth/page.dart';
import '../l10n/strings.dart';
import '../ui/button.dart';
import '../ui/dialogs.dart';
import '../ui/progress.dart';
import '../ui/theme.dart';
import 'controller.dart';

/// 应用顶层只在账号状态和语言切换时重建；列表更新独立处理。
class YunhugramApp extends StatelessWidget {
  const YunhugramApp({required this.controller, super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => WidgetsApp(
      color: Tg.blue,
      debugShowCheckedModeBanner: false,
      title: 'Yunhugram',
      locale: controller.locale,
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      textStyle: Tg.text(16),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => _Root(controller),
      ),
    ),
  );
}

class _Root extends StatelessWidget {
  const _Root(this.controller);
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final s = Strings(controller.locale);
    Widget content;
    switch (controller.phase) {
      case AppPhase.starting:
        content = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TgProgress(),
              const SizedBox(height: 16),
              Text(s('starting')),
            ],
          ),
        );
      case AppPhase.login:
        content = AuthPage(
          client: controller.client!,
          strings: s,
          onAuthenticated: controller.authenticated,
          onLanguage: controller.toggleLanguage,
        );
      case AppPhase.home:
        // TODO(主页阶段)：下一功能提交替换此占位，不伪装为已完成的主页。
        content = Center(child: Text(s('chats')));
      case AppPhase.error:
        content = SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.error ?? s('failed'),
                      style: Tg.text(16, color: Tg.danger),
                    ),
                    const SizedBox(height: 16),
                    TgTextButton(s('retry'), onPressed: controller.initialize),
                    if (controller.client != null)
                      TgTextButton(
                        s('logoutLocal'),
                        onPressed: () async {
                          if (await confirmTg(
                            context,
                            s,
                            s('logoutLocal'),
                            s('logoutLocalDetail'),
                            action: 'logoutLocal',
                          )) {
                            await controller.clearLocal();
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
    return ColoredBox(color: Tg.background, child: content);
  }
}
