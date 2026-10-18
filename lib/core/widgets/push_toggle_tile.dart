import 'package:flutter/material.dart';

import '../services/push_notification_service.dart';
import 'pbms_ui.dart';

/// Công tắc bật / tắt thông báo đẩy trên điện thoại, xin quyền thật của hệ điều hành.
class PushToggleTile extends StatefulWidget {
  const PushToggleTile({super.key});

  @override
  State<PushToggleTile> createState() => _PushToggleTileState();
}

class _PushToggleTileState extends State<PushToggleTile> {
  final _push = PushNotificationService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _push.refresh();
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      if (!value) {
        await _push.disable();
        if (mounted) showPbmsSnack(context, 'Đã tắt thông báo đẩy.');
        return;
      }
      final result = await _push.enable();
      if (!mounted) return;
      switch (result) {
        case PushEnableResult.enabled:
          showPbmsSnack(context, 'Đã bật thông báo đẩy.');
        case PushEnableResult.denied:
          showPbmsSnack(context, 'Bạn chưa cho phép thông báo.', error: true);
        case PushEnableResult.openSettings:
          await _askOpenSettings();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askOpenSettings() async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông báo đang bị chặn'),
        content: const Text(
            'Điện thoại đang chặn thông báo của PBMS. Mở Cài đặt, chọn Thông báo và bật cho ứng dụng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.teal),
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
    if (open == true) await _push.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PushState>(
      valueListenable: _push.state,
      builder: (context, state, _) {
        final supported = state != PushState.unsupported;
        final subtitle = switch (state) {
          PushState.unsupported => 'Chỉ có trên ứng dụng Android và iOS',
          PushState.off => 'Báo đặt chỗ, thanh toán, vé tháng ra khay thông báo của máy',
          PushState.blocked => 'Điện thoại đang chặn thông báo của PBMS. Bật để mở Cài đặt',
          PushState.on => 'Đang bật. Thông báo mới hiện lên khay của điện thoại',
        };
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: state == PushState.on,
          activeTrackColor: PbmsTokens.teal,
          onChanged: !supported || _busy
              ? null
              : (value) => value && state == PushState.blocked
                  ? _askOpenSettings()
                  : _toggle(value),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: state == PushState.blocked
                  ? PbmsTokens.warn.withValues(alpha: 0.1)
                  : PbmsTokens.tealTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              state == PushState.blocked
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined,
              size: 21,
              color: state == PushState.blocked ? PbmsTokens.warn : PbmsTokens.teal,
            ),
          ),
          title: const Text('Thông báo đẩy', style: PbmsText.bodyStrong),
          subtitle: Text(subtitle, style: PbmsText.caption),
        );
      },
    );
  }
}
