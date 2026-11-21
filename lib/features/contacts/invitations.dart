import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/dialogs.dart';

enum InviteTarget { wechat, qq }

/// 生成本人分享链接后交给目标应用；不声称好友已收到或邀请已发送。
Future<void> inviteFriend(
  BuildContext context,
  CoreClient client,
  InviteTarget target,
  Strings s,
) async {
  try {
    final data = await client.request('createShare');
    final text = '${s('inviteText')}${data['url']}';
    if (!context.mounted) return;
    if (Platform.isAndroid) {
      const channel = MethodChannel('yunhugram/sharing');
      final result = await channel.invokeMethod<String>('shareText', {
        'target': target.name,
        'text': text,
      });
      if (result == 'copy') {
        await Clipboard.setData(ClipboardData(text: text));
        await channel.invokeMethod<void>('openTarget', {'target': target.name});
        if (context.mounted) await noticeTg(context, s, s('inviteCopied'));
      }
    } else {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? const Rect.fromLTWH(0, 0, 1, 1)
          : box.localToGlobal(Offset.zero) & box.size;
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Yunhugram',
          sharePositionOrigin: origin,
        ),
      );
      if (result.status == ShareResultStatus.unavailable) {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) await noticeTg(context, s, s('inviteCopied'));
      }
    }
  } on ClientError catch (e) {
    if (context.mounted) await noticeTg(context, s, e.message);
  } on PlatformException catch (e) {
    if (context.mounted) {
      await noticeTg(
        context,
        s,
        s(
          e.code == 'missing'
              ? (target == InviteTarget.wechat ? 'wechatMissing' : 'qqMissing')
              : 'shareFailure',
        ),
      );
    }
  }
}
