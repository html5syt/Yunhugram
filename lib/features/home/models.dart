import 'package:flutter/foundation.dart';

/// UI 使用的聊天对象标识；对象类别参与键，防止跨类别重用状态。
@immutable
class Peer {
  const Peer({
    required this.id,
    required this.type,
    required this.name,
    this.remark = '',
    this.avatar = '',
    this.permission = 0,
  });
  factory Peer.fromJson(Map<String, dynamic> v) => Peer(
    id: (v['chatId'] ?? v['friendId'] ?? '') as String,
    type: ((v['chatType'] ?? v['friendType'] ?? 0) as num).toInt(),
    name: (v['name'] as String?)?.isNotEmpty == true
        ? v['name'] as String
        : (v['nickname'] ?? '') as String,
    remark: (v['remark'] ?? '') as String,
    avatar: (v['avatarUrl'] ?? '') as String,
    permission: ((v['permissionLevel'] ?? 0) as num).toInt(),
  );
  final String id, name, remark, avatar;
  final int type, permission;
  String get key => '$type:$id';
  String get title => remark.isNotEmpty
      ? remark
      : name.isNotEmpty
      ? name
      : id;
  @override
  bool operator ==(Object other) =>
      other is Peer &&
      other.id == id &&
      other.type == type &&
      other.name == name &&
      other.remark == remark &&
      other.avatar == avatar &&
      other.permission == permission;
  @override
  int get hashCode => Object.hash(id, type, name, remark, avatar, permission);
}

/// 对话摘要不等同于完整聊天记录；只使用消息发送时间展示时间。
@immutable
class Conversation {
  const Conversation({
    required this.peer,
    required this.preview,
    required this.sentAt,
    required this.unread,
    this.muted = false,
    this.mentioned = false,
  });
  factory Conversation.fromJson(Map<String, dynamic> v) => Conversation(
    peer: Peer.fromJson(v),
    preview: (v['chatContent'] ?? '') as String,
    sentAt: DateTime.fromMillisecondsSinceEpoch(
      ((v['sendTimestamp'] ?? 0) as num).toInt() * 1000,
    ),
    unread: ((v['unreadMsg'] ?? 0) as num).toInt(),
    muted: v['doNotDisturb'] == true,
    mentioned: v['at'] == true,
  );
  final Peer peer;
  final String preview;
  final DateTime sentAt;
  final int unread;
  final bool muted, mentioned;
  @override
  bool operator ==(Object other) =>
      other is Conversation &&
      other.peer == peer &&
      other.preview == preview &&
      other.sentAt == sentAt &&
      other.unread == unread &&
      other.muted == muted &&
      other.mentioned == mentioned;
  @override
  int get hashCode =>
      Object.hash(peer, preview, sentAt, unread, muted, mentioned);
}

/// 展示分组固定为 prompt 的顺序，服务端缺失的分组保持为空。
@immutable
class ContactGroup {
  const ContactGroup(this.type, this.peers);
  final int type;
  final List<Peer> peers;
  String get titleKey => switch (type) {
    1 => 'friends',
    2 => 'joined',
    _ => 'bots',
  };
  static List<ContactGroup> parse(List<dynamic> data) {
    final groups = <int, List<Peer>>{1: [], 2: [], 3: []};
    for (final raw in data.cast<Map<String, dynamic>>()) {
      final type = (raw['chatType'] as num).toInt();
      if (groups.containsKey(type)) {
        groups[type]!.addAll(
          (raw['data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
              .map((v) => Peer.fromJson({...v, 'chatType': type})),
        );
      }
    }
    return [
      for (final type in [1, 2, 3])
        ContactGroup(type, List.unmodifiable(groups[type]!)),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is ContactGroup &&
      other.type == type &&
      listEquals(other.peers, peers);
  @override
  int get hashCode => Object.hash(type, Object.hashAll(peers));
}

/// 搜索接口返回标题／子列表，null 列表不是模拟联系人。
List<Peer> parseSearch(Map<String, dynamic> data) => [
  for (final section
      in (data['list'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>())
    for (final item
        in (section['list'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>())
      Peer.fromJson(item),
];
