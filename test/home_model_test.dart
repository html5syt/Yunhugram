import 'package:flutter_test/flutter_test.dart';
import 'package:yunhugram/features/home/models.dart';

void main() {
  test('对话备注优先于真实名称，不混用消息时间与加入列表时间', () {
    final c = Conversation.fromJson({
      'chatId': '1',
      'chatType': 2,
      'remark': '备注',
      'name': '群名',
      'chatContent': '消息',
      'sendTimestamp': 1700000000,
      'timestampMs': 1,
      'unreadMsg': 3,
    });
    expect(c.peer.title, '备注');
    expect(c.sentAt.millisecondsSinceEpoch, 1700000000000);
    expect(c.unread, 3);
  });
  test('相同ID但不同类别的会话不会使用相同界面键', () {
    expect(
      Peer.fromJson({'chatId': '1', 'chatType': 1, 'name': 'a'}).key,
      isNot(Peer.fromJson({'chatId': '1', 'chatType': 2, 'name': 'a'}).key),
    );
  });
  test('通讯录固定好友、加入的聊天、机器人顺序，保留群组和备注', () {
    final groups = ContactGroup.parse([
      {
        'chatType': 3,
        'data': [
          {'chatId': 'b', 'name': 'Bot'},
        ],
      },
      {
        'chatType': 1,
        'data': [
          {'chatId': 'a', 'name': '原名', 'remark': '备注'},
        ],
      },
      {
        'chatType': 2,
        'data': [
          {'chatId': 'g', 'name': '群名', 'permissionLevel': 100},
        ],
      },
    ]);
    expect(groups.map((g) => g.type), [1, 2, 3]);
    expect(groups[0].peers.first.title, '备注');
    expect(groups[1].peers.first.type, 2);
  });
  test('搜索响应的嵌套列表和空列表可解析，不虚构联系人', () {
    final peers = parseSearch({
      'list': [
        {'title': '用户', 'list': null},
        {
          'title': '群组',
          'list': [
            {
              'friendId': 'g',
              'friendType': 2,
              'nickname': '群名',
              'avatarUrl': '',
            },
          ],
        },
      ],
    });
    expect(peers.length, 1);
    expect(peers.single.id, 'g');
    expect(peers.single.type, 2);
  });
}
