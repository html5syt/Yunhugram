import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/theme.dart';

const homeTabs = ['chats', 'contacts', 'community', 'discover', 'profile'];
const _icons = [
  'msg_viewchats',
  'msg_contacts',
  'msg_groups',
  'msg_search',
  'msg_openprofile',
];

/// 五个入口顺序严格按照 prompt，桌面也保留同一入口顺序。
class HomeNavigation extends StatelessWidget {
  const HomeNavigation({
    required this.index,
    required this.onChanged,
    required this.strings,
    super.key,
  });
  final int index;
  final ValueChanged<int> onChanged;
  final Strings strings;
  @override
  Widget build(BuildContext context) => Container(
    height: math.max(56, 40 + MediaQuery.textScalerOf(context).scale(12)),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Tg.divider, width: .5)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < homeTabs.length; i++)
          Expanded(
            child: Semantics(
              selected: index == i,
              child: TgButton(
                key: ValueKey('nav_${homeTabs[i]}'),
                onPressed: () => onChanged(i),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TgIcon(_icons[i], color: index == i ? Tg.blue : Tg.muted),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        strings(homeTabs[i]),
                        style: Tg.text(
                          12,
                          color: index == i ? Tg.blueText : Tg.muted,
                        ).copyWith(height: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
