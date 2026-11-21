import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/theme.dart';

/// 搜索、排序、更多与个人资料设置的位置统一处理。
class HomeToolbar extends StatelessWidget {
  const HomeToolbar({
    required this.tab,
    required this.strings,
    required this.connection,
    required this.onSearch,
    required this.onMenu,
    required this.onSettings,
    required this.searching,
    required this.searchController,
    required this.searchFocus,
    required this.onQuery,
    required this.onBack,
    super.key,
  });
  final int tab;
  final Strings strings;
  final ValueNotifier<String> connection;
  final VoidCallback onSearch, onSettings, onBack;
  final ValueChanged<BuildContext> onMenu;
  final bool searching;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onQuery;
  Widget _icon(String asset, String key, String label, VoidCallback pressed) =>
      TgButton(
        key: ValueKey(key),
        label: label,
        onPressed: pressed,
        padding: const EdgeInsets.all(12),
        child: TgIcon(asset),
      );
  @override
  Widget build(BuildContext context) => Container(
    height: Tg.barHeight,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Tg.divider, width: .5)),
    ),
    child: Row(
      children: [
        if (searching) ...[
          _icon('ic_ab_back', 'close_search', strings('cancel'), onBack),
          Expanded(
            child: EditableText(
              controller: searchController,
              focusNode: searchFocus,
              autofocus: true,
              style: Tg.text(18),
              cursorColor: Tg.blue,
              backgroundCursorColor: Tg.divider,
              selectionColor: Tg.blue.withValues(alpha: .2),
              onChanged: onQuery,
            ),
          ),
        ] else ...[
          const SizedBox(width: 16),
          Expanded(
            child: tab == 0
                ? ValueListenableBuilder<String>(
                    valueListenable: connection,
                    builder: (context, value, _) => Text(
                      strings(value == 'online' ? 'chats' : value),
                      style: Tg.text(20, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Text(
                    strings(
                      [
                        'chats',
                        'contacts',
                        'community',
                        'discover',
                        'profile',
                      ][tab],
                    ),
                    style: Tg.text(20, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (tab < 2)
            _icon('msg_search', 'search', strings('search'), onSearch),
          if (tab == 4)
            _icon('msg_settings', 'settings', strings('settings'), onSettings),
          if (tab == 0 || tab == 1 || tab == 4)
            Builder(
              builder: (anchor) => _icon(
                tab == 1 ? 'msg_contacts_name' : 'ic_ab_other',
                'more',
                strings('more'),
                () => onMenu(anchor),
              ),
            ),
        ],
        const SizedBox(width: 4),
      ],
    ),
  );
}
