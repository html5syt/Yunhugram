import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunhugram/app/app.dart';
import 'package:yunhugram/app/controller.dart';
import 'package:yunhugram/core/client.dart';

class HomeFake implements CoreClient {
  @override
  Stream<Map<String, dynamic>> get updates => const Stream.empty();
  @override
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic> args = const {},
  ]) async => {'list': []};
  @override
  void dispose() {}
}

void main() {
  testWidgets('主页有五个规定入口，个人资料的设置在更多按钮左边', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = AppController()
      ..phase = AppPhase.home
      ..client = HomeFake()
      ..user = {
        'id': '1',
        'name': '测试',
        'avatarUrl': '',
        'phone': '',
        'email': '',
      }
      ..generation = 1;
    await tester.pumpWidget(YunhugramApp(controller: c));
    await tester.pumpAndSettle();
    for (final key in [
      'chats',
      'contacts',
      'community',
      'discover',
      'profile',
    ]) {
      expect(find.byKey(ValueKey('nav_$key')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('nav_profile')));
    await tester.pumpAndSettle();
    final settings = find.byKey(const ValueKey('settings'));
    final more = find.byKey(const ValueKey('more'));
    expect(settings, findsOneWidget);
    expect(more, findsOneWidget);
    expect(tester.getCenter(settings).dx, lessThan(tester.getCenter(more).dx));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
