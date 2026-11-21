import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/client.dart';
import 'models.dart';

/// 列表和连接状态独立通知，推送只触发摘要更新，不重建整个应用。
class HomeController {
  HomeController(this.client, this.generation) {
    _events = client.updates.listen((v) {
      if (v['generation'] != generation) return;
      if (v['@type'] == 'updateConnection') {
        connection.value = v['state'] as String;
      }
      if (v['@type'] == 'updateRefresh') {
        _refreshTimer?.cancel();
        _refreshTimer = Timer(const Duration(milliseconds: 300), refresh);
      }
    });
  }
  final CoreClient client;
  final int generation;
  final conversations = ValueNotifier<List<Conversation>>([]);
  final contacts = ValueNotifier<List<ContactGroup>>(ContactGroup.parse([]));
  final chatError = ValueNotifier<String?>(null),
      contactError = ValueNotifier<String?>(null);
  final chatLoading = ValueNotifier<bool>(true),
      contactLoading = ValueNotifier<bool>(true);
  final connection = ValueNotifier<String>('connecting');
  late final StreamSubscription<Map<String, dynamic>> _events;
  Timer? _refreshTimer;
  bool _disposed = false;
  Future<void>? _refreshing;
  Future<void> refresh({bool force = false}) {
    if (_disposed) return Future.value();
    return _refreshing ??= _load(force).whenComplete(() => _refreshing = null);
  }

  Future<void> _load(bool force) async {
    chatError.value = null;
    contactError.value = null;
    chatLoading.value = true;
    contactLoading.value = true;
    try {
      final data = await client.request('getConversations', {'force': force});
      if (!_disposed) {
        final next = (data['list'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Conversation.fromJson)
            .toList(growable: false);
        if (!listEquals(next, conversations.value)) conversations.value = next;
      }
    } on ClientError catch (e) {
      if (!_disposed) chatError.value = e.message;
    } finally {
      if (!_disposed) chatLoading.value = false;
    }
    if (_disposed) return;
    try {
      final data = await client.request('getContacts', {'force': force});
      if (!_disposed) {
        final next = ContactGroup.parse(data['list'] as List<dynamic>);
        if (!listEquals(next, contacts.value)) contacts.value = next;
      }
    } on ClientError catch (e) {
      if (!_disposed) contactError.value = e.message;
    } finally {
      if (!_disposed) contactLoading.value = false;
    }
  }

  void dispose() {
    _disposed = true;
    _events.cancel();
    _refreshTimer?.cancel();
    for (final n in [
      conversations,
      contacts,
      chatError,
      contactError,
      chatLoading,
      contactLoading,
      connection,
    ]) {
      n.dispose();
    }
  }
}
