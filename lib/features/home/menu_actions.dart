import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/menu.dart';

/// 不同主页入口的菜单只包含本阶段可用操作。
Future<String?> chooseHomeMenu(
  BuildContext anchor,
  int tab,
  bool sortName,
  Strings s,
) => showTgMenu(
  anchor,
  tab == 4
      ? [TgMenuItem('logout', s('logout'), 'msg_arrowright')]
      : tab == 1
      ? [
          TgMenuItem(
            'sort',
            s(sortName ? 'sortDefault' : 'sortName'),
            'msg_contacts_name',
          ),
          TgMenuItem('refresh', s('refresh'), 'msg_arrowright'),
        ]
      : [
          TgMenuItem('newChat', s('newChat'), 'msg_contacts'),
          TgMenuItem('createBot', s('createBot'), 'msg_addbot'),
          TgMenuItem('refresh', s('refresh'), 'msg_arrowright'),
        ],
  label: s('more'),
);
