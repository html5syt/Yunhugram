import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/list_cell.dart';
import '../../ui/load_state.dart';
import 'models.dart';

/// 输入停止后查询；过期响应不覆盖最新关键词结果。
class HomeSearch extends ChangeNotifier {
  HomeSearch(this.client);
  final CoreClient client;
  String query = '';
  List<Peer> peers = [];
  bool loading = false;
  String? error;
  Timer? _timer;
  int _revision = 0;
  bool _disposed = false;
  void change(String value) {
    query = value.trim();
    _revision++;
    _timer?.cancel();
    error = null;
    peers = [];
    if (query.isEmpty) {
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    final revision = _revision;
    _timer = Timer(const Duration(milliseconds: 300), () => _load(revision));
  }

  Future<void> _load(int revision) async {
    try {
      final data = await client.request('search', {'word': query});
      if (!_disposed && revision == _revision) peers = parseSearch(data);
    } on ClientError catch (e) {
      if (!_disposed && revision == _revision) error = e.message;
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class SearchView extends StatelessWidget {
  const SearchView({
    required this.search,
    required this.strings,
    required this.onOpen,
    required this.local,
    super.key,
  });
  final HomeSearch search;
  final Strings strings;
  final ValueChanged<Peer> onOpen;
  final List<Conversation> local;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: search,
    builder: (context, _) {
      final q = search.query.toLowerCase();
      final byKey = <String, Peer>{
        for (final c in local)
          if (c.peer.title.toLowerCase().contains(q) ||
              c.preview.toLowerCase().contains(q))
            c.peer.key: c.peer,
        for (final p in search.peers) p.key: p,
      };
      final rows = byKey.values.toList();
      return LoadState(
        strings: strings,
        loading: search.loading,
        error: search.error,
        emptyLabel: 'noResults',
        isEmpty: rows.isEmpty,
        onRetry: () => search.change(search.query),
        child: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final p = rows[i];
            return TgListCell(
              id: p.key,
              title: p.title,
              subtitle: strings(
                p.type == 2
                    ? 'groups'
                    : p.type == 3
                    ? 'bots'
                    : 'people',
              ),
              avatar: p.avatar,
              contact: true,
              onTap: () => onOpen(p),
            );
          },
        ),
      );
    },
  );
}
