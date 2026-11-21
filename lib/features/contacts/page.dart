import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/action_row.dart';
import '../../ui/button.dart';
import '../../ui/list_cell.dart';
import '../../ui/progress.dart';
import '../../ui/theme.dart';
import '../home/controller.dart';
import '../home/models.dart';
import 'header.dart';
import 'invitations.dart';

typedef _Entry = ({ContactGroup? group, Peer? peer, InviteTarget? invite});

/// 好友、加入的聊天、机器人独立折叠；不添加不存在的最近通话入口。
class ContactsView extends StatefulWidget {
  const ContactsView({
    required this.home,
    required this.strings,
    required this.sortName,
    required this.onOpen,
    required this.onInvite,
    this.selected,
    this.onAdd,
    super.key,
  });
  final HomeController home;
  final Strings strings;
  final bool sortName;
  final ValueChanged<Peer> onOpen;
  final ValueChanged<InviteTarget> onInvite;
  final String? selected;
  final VoidCallback? onAdd;
  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final _expanded = <int>{1, 2, 3};
  void _toggle(int type) => setState(() {
    if (!_expanded.remove(type)) _expanded.add(type);
  });
  String _subtitle(Peer p) => p.type == 3
      ? widget.strings('bots')
      : p.permission == 100
      ? widget.strings('owner')
      : p.permission == 2
      ? widget.strings('admin')
      : '${widget.strings('cloudId')}: ${p.id}';
  List<_Entry> _rows() {
    final rows = <_Entry>[
      (group: null, peer: null, invite: InviteTarget.wechat),
      (group: null, peer: null, invite: InviteTarget.qq),
    ];
    for (final g in widget.home.contacts.value) {
      rows.add((group: g, peer: null, invite: null));
      if (_expanded.contains(g.type)) {
        final peers = [...g.peers];
        if (widget.sortName) {
          peers.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        }
        rows.addAll(peers.map((p) => (group: null, peer: p, invite: null)));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      widget.home.contacts,
      widget.home.contactError,
      widget.home.contactLoading,
    ]),
    builder: (context, _) {
      final rows = _rows(), s = widget.strings;
      return Stack(
        children: [
          Column(
            children: [
              if (widget.home.contactLoading.value)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TgProgress(size: 16),
                      const SizedBox(width: 8),
                      Text(s('loading'), style: Tg.text(14, color: Tg.muted)),
                    ],
                  ),
                ),
              if (widget.home.contactError.value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Text('! ', style: Tg.text(15, color: Tg.danger)),
                      Expanded(
                        child: Text(
                          widget.home.contactError.value!,
                          style: Tg.text(14, color: Tg.danger),
                        ),
                      ),
                      TgTextButton(
                        s('retry'),
                        onPressed: () => widget.home.refresh(force: true),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  key: const PageStorageKey('contacts'),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row.invite != null) {
                      return TgActionRow(
                        title: s(
                          row.invite == InviteTarget.wechat
                              ? 'inviteWechat'
                              : 'inviteQQ',
                        ),
                        icon: 'msg_invited',
                        onTap: () => widget.onInvite(row.invite!),
                      );
                    }
                    if (row.group != null) {
                      final g = row.group!;
                      return ContactsHeader(
                        key: ValueKey('contact_group_${g.type}'),
                        title: g.titleKey,
                        count: g.peers.length,
                        expanded: _expanded.contains(g.type),
                        onTap: () => _toggle(g.type),
                        strings: s,
                        loading: widget.home.contactLoading.value,
                      );
                    }
                    final p = row.peer!;
                    return TgListCell(
                      key: ValueKey('peer_${p.key}'),
                      id: p.key,
                      title: p.title,
                      subtitle: _subtitle(p),
                      avatar: p.avatar,
                      contact: true,
                      selected: p.key == widget.selected,
                      onTap: () => widget.onOpen(p),
                    );
                  },
                ),
              ),
            ],
          ),
          if (widget.onAdd != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: ClipOval(
                child: TgButton(
                  label: s('addContact'),
                  onPressed: widget.onAdd,
                  filled: true,
                  padding: const EdgeInsets.all(16),
                  child: const SizedBox.square(
                    dimension: 24,
                    child: Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 28,
                          height: .8,
                          color: Tg.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
