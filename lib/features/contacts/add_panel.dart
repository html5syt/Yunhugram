import 'package:flutter/widgets.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/field.dart';
import '../../ui/progress.dart';
import '../../ui/theme.dart';

/// 添加申请只表示服务器接受请求，不把待审核对象当作已有联系人。
class AddContactPanel extends StatefulWidget {
  const AddContactPanel({
    required this.client,
    required this.strings,
    super.key,
  });
  final CoreClient client;
  final Strings strings;
  @override
  State<AddContactPanel> createState() => _AddContactPanelState();
}

class _AddContactPanelState extends State<AddContactPanel> {
  final _id = TextEditingController(), _remark = TextEditingController();
  int _type = 1;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _id.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_id.text.trim().isEmpty) {
      setState(() => _error = widget.strings('idRequired'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client.request('addContact', {
        'chatId': _id.text.trim(),
        'chatType': _type,
        'remark': _remark.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ClientError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s('addContact'), style: Tg.text(20, weight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var type = 1; type <= 3; type++)
              Expanded(
                child: Semantics(
                  selected: _type == type,
                  child: TgTextButton(
                    s(
                      type == 1
                          ? 'friends'
                          : type == 2
                          ? 'groups'
                          : 'bots',
                    ),
                    filled: _type == type,
                    onPressed: _busy
                        ? null
                        : () => setState(() => _type = type),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TgField(controller: _id, label: s('cloudId'), enabled: !_busy),
        TgField(
          controller: _remark,
          label: s('contactRemark'),
          enabled: !_busy,
          onSubmitted: (_) => _add(),
        ),
        if (_error != null) Text(_error!, style: Tg.text(15, color: Tg.danger)),
        if (_busy) const Center(child: TgProgress()),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TgTextButton(
              s('cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TgTextButton(s('add'), onPressed: _busy ? null : _add),
          ],
        ),
      ],
    );
  }
}
