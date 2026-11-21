import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunhugram/app/app.dart';
import 'package:yunhugram/app/controller.dart';
import 'package:yunhugram/core/client.dart';
import 'package:yunhugram/features/auth/controller.dart';
import 'package:yunhugram/features/auth/challenge.dart';
import 'package:yunhugram/l10n/strings.dart';

class FakeClient implements CoreClient {
  final calls = <String>[];
  Map<String, dynamic> reply = {'registered': true};
  @override
  Stream<Map<String, dynamic>> get updates => const Stream.empty();
  @override
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic> args = const {},
  ]) async {
    calls.add(type);
    return reply;
  }

  @override
  void dispose() {}
}

class PreviewController extends AppController {
  void enterLogin() {
    client = FakeClient();
    phase = AppPhase.login;
    notifyListeners();
  }
}

void main() {
  const s = Strings(Locale('zh'));
  test('中文与英文包含相同文本键', () {
    expect(Strings.zh.keys.toSet(), Strings.en.keys.toSet());
  });
  test('验证码位移转换使用服务器尺寸并限制在拼图可移动范围内', () {
    final c = Challenge({
      'id': 'x',
      'master_image': 'AA==',
      'tile_image': 'AA==',
      'master_size': {'width': 300, 'height': 220},
      'tile_size': {'width': 67, 'height': 67},
      'tile_y': 120,
    }, false);
    expect(c.rawX(50, 150), 100);
    expect(c.rawX(300, 150), 233);
    expect(c.rawX(-5, 150), 0);
  });
  test('注册必须有昵称，成功后回到真实登录而非伪造会话', () async {
    final fake = FakeClient();
    final auth = AuthController(fake, (_) async => fail('没有 token 不能进入主页'));
    auth.toggleRegistration();
    await auth.submit({'mobile': '13800138000', 'captcha': '123456'}, s);
    expect(fake.calls, isEmpty);
    expect(auth.error, s('nicknameRequired'));
    await auth.submit({
      'mobile': '13800138000',
      'captcha': '123456',
      'nickname': '测试',
    }, s);
    expect(fake.calls, ['registerPhone']);
    expect(auth.registering, isFalse);
    auth.dispose();
  });
  test('手机号与邮箱的格式检查不接受空格或缺失域名', () async {
    final fake = FakeClient();
    final auth = AuthController(fake, (_) async {});
    expect(auth.validatePhone('13800138000', s), isNull);
    expect(auth.validatePhone('+8613800138000', s), isNull);
    auth.changeMode(LoginMode.email);
    await auth.submit({'email': 'a b@example.com', 'password': 'p'}, s);
    expect(fake.calls, isEmpty);
    await auth.submit({'email': 'a@example.com', 'password': 'p'}, s);
    expect(fake.calls, ['emailLogin']);
    auth.dispose();
  });
  testWidgets('账号状态改变时页面随之切换，中文登录界面不溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PreviewController();
    await tester.pumpWidget(YunhugramApp(controller: controller));
    expect(find.text('正在启动'), findsOneWidget);
    controller.enterLogin();
    await tester.pump();
    expect(find.text('手机号登录'), findsOneWidget);
    await tester.tap(find.text('使用邮箱登录'));
    await tester.pump();
    expect(find.text('邮箱登录'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
