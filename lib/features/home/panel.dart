import 'package:flutter/widgets.dart';
import '../../app/controller.dart';
import '../../l10n/strings.dart';
import '../../ui/theme.dart';
import 'chats.dart';
import 'controller.dart';
import 'models.dart';
import 'navigation.dart';
import 'profile.dart';
import 'search.dart';
import 'toolbar.dart';

/// 主页侧栏的显示组合；业务与异步状态由控制器管理。
class HomePanel extends StatelessWidget {
  const HomePanel({
    required this.app,
    required this.home,
    required this.strings,
    required this.tab,
    required this.search,
    required this.searching,
    required this.input,
    required this.focus,
    required this.onTab,
    required this.onSearch,
    required this.onMenu,
    required this.onSettings,
    required this.onBack,
    required this.onOpen,
    required this.onDelete,
    this.selected,
    super.key,
  });
  final AppController app;
  final HomeController home;
  final Strings strings;
  final int tab;
  final HomeSearch search;
  final bool searching;
  final TextEditingController input;
  final FocusNode focus;
  final ValueChanged<int> onTab;
  final VoidCallback onSearch, onSettings, onBack;
  final ValueChanged<BuildContext> onMenu;
  final ValueChanged<Peer> onOpen;
  final ValueChanged<Conversation> onDelete;
  final String? selected;
  Widget _placeholder(String title) => Center(
    child: Text(strings('notReady'), style: Tg.text(16, color: Tg.muted)),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      HomeToolbar(
        tab: tab,
        strings: strings,
        connection: home.connection,
        onSearch: onSearch,
        onMenu: onMenu,
        onSettings: onSettings,
        searching: searching,
        searchController: input,
        searchFocus: focus,
        onQuery: search.change,
        onBack: onBack,
      ),
      Expanded(
        child: searching
            ? ValueListenableBuilder<List<Conversation>>(
                valueListenable: home.conversations,
                builder: (context, rows, _) => SearchView(
                  search: search,
                  strings: strings,
                  onOpen: onOpen,
                  local: rows,
                ),
              )
            : IndexedStack(
                index: tab,
                children: [
                  ChatsView(
                    controller: home,
                    strings: strings,
                    onOpen: onOpen,
                    onDelete: onDelete,
                    selected: selected,
                  ),
                  // TODO(联系人阶段)：下一功能提交替换此入口占位。
                  _placeholder('contacts'),
                  _placeholder('community'),
                  _placeholder('discover'),
                  ProfileView(app: app, strings: strings),
                ],
              ),
      ),
      HomeNavigation(index: tab, onChanged: onTab, strings: strings),
    ],
  );
}
