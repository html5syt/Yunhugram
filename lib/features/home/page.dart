import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../app/controller.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/dialogs.dart';
import '../../ui/theme.dart';
import '../messages/page.dart';
import 'adaptive.dart';
import 'bot_panel.dart';
import 'controller.dart';
import 'menu_actions.dart';
import 'models.dart';
import 'panel.dart';
import 'profile.dart';
import 'search.dart';

/// 只管理选择、菜单和页面切换；布局与列表显示由独立组件承担。
class HomePage extends StatefulWidget {
  const HomePage({required this.app, required this.strings, super.key});
  final AppController app;
  final Strings strings;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _home = HomeController(widget.app.client!, widget.app.generation)
    ..refresh();
  late final _search = HomeSearch(widget.app.client!);
  final _input = TextEditingController();
  final _focus = FocusNode();
  int _tab = 0;
  bool _searching = false;
  bool _sortName = false;
  Peer? _selected;
  Strings get s => widget.strings;
  @override
  void dispose() {
    _home.dispose();
    _search.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _tabChanged(int value) {
    setState(() {
      _tab = value;
      _searching = false;
    });
    _focus.unfocus();
    _input.clear();
    _search.change('');
  }

  void _startSearch() => setState(() => _searching = true);
  void _back() {
    if (_searching) {
      _tabChanged(_tab);
    } else {
      setState(() => _selected = null);
    }
  }

  void _open(Peer p) {
    setState(() => _selected = p);
    unawaited(_markRead(p));
  }

  Future<void> _markRead(Peer p) async {
    try {
      await widget.app.client!.request('markRead', {'chatId': p.id});
      if (mounted) {
        await _home.refresh();
      }
    } on ClientError catch (e) {
      if (mounted) {
        _home.chatError.value = e.message;
      }
    }
  }

  Future<void> _delete(Conversation c) async {
    if (!await confirmTg(
      context,
      s,
      s('deleteChatConfirm'),
      '',
      action: 'delete',
    )) {
      return;
    }
    try {
      await widget.app.client!.request('removeConversation', {
        'chatId': c.peer.id,
      });
      if (mounted) {
        await _home.refresh(force: true);
      }
    } on ClientError catch (e) {
      if (mounted) {
        await noticeTg(context, s, e.message);
      }
    }
  }

  Future<void> _menu(BuildContext anchor) async {
    final action = await chooseHomeMenu(anchor, _tab, _sortName, s);
    if (!mounted) {
      return;
    }
    switch (action) {
      case 'newChat':
        _tabChanged(1);
      case 'createBot':
        final created = await showTgPanel<bool>(
          context,
          (_) => BotPanel(
            client: widget.app.client!,
            strings: s,
            avatar: widget.app.user!['avatarUrl'] as String,
          ),
          label: s('createBot'),
        );
        if (created == true && mounted) {
          await _home.refresh(force: true);
        }
      case 'refresh':
        await _home.refresh(force: true);
      case 'sort':
        setState(() => _sortName = !_sortName);
      case 'logout':
        if (await confirmTg(
          context,
          s,
          s('logoutConfirm'),
          s('logoutDetail'),
          action: 'logout',
        )) {
          try {
            await widget.app.logout();
          } on ClientError catch (e) {
            if (mounted) {
              await noticeTg(context, s, e.message);
            }
          }
        }
    }
  }

  Widget _details(bool back) => MessagePage(
    key: ValueKey(_selected!.key),
    client: widget.app.client!,
    peer: _selected!,
    generation: widget.app.generation,
    strings: s,
    onBack: back ? _back : null,
    onSent: () => _home.refresh(),
  );
  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          _startSearch,
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _startSearch,
      const SingleActivator(LogicalKeyboardKey.escape): _back,
    },
    child: Focus(
      autofocus: true,
      child: HomeAdaptive(
        left: HomePanel(
          app: widget.app,
          home: _home,
          strings: s,
          tab: _tab,
          search: _search,
          searching: _searching,
          input: _input,
          focus: _focus,
          onTab: _tabChanged,
          onSearch: _startSearch,
          onMenu: _menu,
          onSettings: () => showSettings(context, widget.app, s),
          onBack: _back,
          onOpen: _open,
          onDelete: _delete,
          selected: _selected?.key,
        ),
        details: _details,
        placeholder: Center(
          child: Text(s('chooseChat'), style: Tg.text(18, color: Tg.muted)),
        ),
        selected: _selected != null,
        searching: _searching,
        onBack: _back,
      ),
    ),
  );
}
