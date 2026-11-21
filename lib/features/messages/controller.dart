import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/client.dart';
import '../home/models.dart';

/// 历史记录只来自真实响应，按消息 ID 合并翻页、编辑与推送后的刷新。
class MessageController extends ChangeNotifier {
  MessageController(this.client, this.peer, this.generation) {
    _events = client.updates.listen((e) {
      if (e['@type'] == 'updateRefresh' && e['generation'] == generation) {
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 350), load);
      }
    });
  }
  final CoreClient client;
  final Peer peer;
  final int generation;
  List<Map<String, dynamic>> messages = [];
  bool loading = false, sending = false, hasMore = false;
  String? error;
  bool _disposed = false;
  late final StreamSubscription<Map<String, dynamic>> _events;
  Timer? _timer;
  Future<void> load({bool older = false}) async {
    if (_disposed || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await client.request('getMessages', {
        'chatId': peer.id,
        'chatType': peer.type,
        if (older && messages.isNotEmpty) 'before': messages.last['msgId'],
      });
      if (_disposed) return;
      final byId = {
        for (final m in messages) m['msgId'] as String: m,
        for (final m
            in (data['list'] as List<dynamic>).cast<Map<String, dynamic>>())
          m['msgId'] as String: m,
      };
      messages = byId.values.toList()
        ..sort((a, b) => (b['msgSeq'] as num).compareTo(a['msgSeq'] as num));
      hasMore = data['hasMore'] == true;
    } on ClientError catch (e) {
      error = e.message;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> send(String text) async {
    if (sending || text.trim().isEmpty) return false;
    sending = true;
    error = null;
    notifyListeners();
    try {
      await client.request('sendMessage', {
        'chatId': peer.id,
        'chatType': peer.type,
        'text': text,
      });
      await load();
      return true;
    } on ClientError catch (e) {
      error = e.message;
      return false;
    } finally {
      sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _events.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
