import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunhugram/core/client.dart';
import 'package:yunhugram/features/home/controller.dart';
import 'package:yunhugram/features/contacts/page.dart';
import 'package:yunhugram/l10n/strings.dart';

class ContactsFake implements CoreClient {
  @override
  Stream<Map<String, dynamic>> get updates => const Stream.empty();
  @override
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic> args = const {},
  ]) async => {
    'list': type == 'getContacts'
        ? [
            {
              'chatType': 1,
              'data': [
                {'chatId': 'u', 'name': '测试好友'},
              ],
            },
            {
              'chatType': 2,
              'data': [
                {'chatId': 'g', 'name': '测试群组'},
              ],
            },
            {
              'chatType': 3,
              'data': [
                {'chatId': 'b', 'name': '测试机器人'},
              ],
            },
          ]
        : [],
  };
  @override
  void dispose() {}
}

void main() {
  testWidgets('联系人提供两种邀请并可独立折叠，更新列表不丢失折叠状态', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final home = HomeController(ContactsFake(), 1);
    await home.refresh();
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xffffffff),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, a, b) => ContactsView(
            home: home,
            strings: const Strings(Locale('zh')),
            sortName: false,
            onOpen: (_) {},
            onInvite: (_) {},
            selected: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('邀请微信好友'), findsOneWidget);
    expect(find.text('邀请QQ好友'), findsOneWidget);
    expect(find.text('最近通话'), findsNothing);
    expect(find.byKey(const ValueKey('peer_1:u')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('contact_group_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('peer_1:u')), findsNothing);
    expect(find.byKey(const ValueKey('peer_2:g')), findsOneWidget);
    await home.refresh(force: true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('peer_1:u')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    home.dispose();
  });
}
