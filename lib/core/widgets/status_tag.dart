import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum Tone { neutral, accent, ok, warn, danger }

/// Nhãn trạng thái vuông góc nhỏ, có chấm màu để quét nhanh.
class StatusTag extends StatelessWidget {
  final String label;
  final Tone tone;

  const StatusTag({super.key, required this.label, this.tone = Tone.neutral});

  factory StatusTag.of(StatusInfo info) => StatusTag(label: info.label, tone: info.tone);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fg, bg) = switch (tone) {
      Tone.neutral => (p.textSecondary, p.surfaceRaised),
      Tone.accent => (p.accent, p.accentSoft),
      Tone.ok => (p.ok, p.okSoft),
      Tone.warn => (p.warn, p.warnSoft),
      Tone.danger => (p.danger, p.dangerSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppSpacing.roundedSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class StatusInfo {
  final String label;
  final Tone tone;

  const StatusInfo(this.label, this.tone);

  static String _k(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

  static StatusInfo session(String s) => switch (_k(s)) {
        'active' => const StatusInfo('Đang gửi', Tone.accent),
        'completed' => const StatusInfo('Đã ra bãi', Tone.neutral),
        'cancelled' => const StatusInfo('Đã huỷ', Tone.danger),
        _ => StatusInfo(s, Tone.neutral),
      };

  static StatusInfo reservation(String s) => switch (_k(s)) {
        'pending' => const StatusInfo('Chờ đặt cọc', Tone.warn),
        'confirmed' => const StatusInfo('Đã xác nhận', Tone.ok),
        'modified' => const StatusInfo('Đã đổi giờ', Tone.ok),
        'checkedin' => const StatusInfo('Đã vào bãi', Tone.accent),
        'completed' => const StatusInfo('Hoàn tất', Tone.neutral),
        'cancelled' => const StatusInfo('Đã huỷ', Tone.danger),
        'noshow' => const StatusInfo('Không đến', Tone.danger),
        _ => StatusInfo(s, Tone.neutral),
      };

  static StatusInfo subscription(String s) => switch (_k(s)) {
        'active' => const StatusInfo('Đang hiệu lực', Tone.ok),
        'pendingpayment' || 'pending' => const StatusInfo('Chờ thanh toán', Tone.warn),
        'expired' => const StatusInfo('Hết hạn', Tone.neutral),
        'cancelled' => const StatusInfo('Đã huỷ', Tone.danger),
        _ => StatusInfo(s, Tone.neutral),
      };

  static StatusInfo payment(String s) => switch (_k(s)) {
        'success' || 'paid' => const StatusInfo('Đã thanh toán', Tone.ok),
        'pending' => const StatusInfo('Chờ thanh toán', Tone.warn),
        'cancelled' => const StatusInfo('Đã huỷ', Tone.neutral),
        'failed' => const StatusInfo('Thất bại', Tone.danger),
        _ => StatusInfo(s, Tone.neutral),
      };

  static StatusInfo vehicleChange(String s) => switch (_k(s)) {
        'pending' => const StatusInfo('Chờ duyệt', Tone.warn),
        'approved' => const StatusInfo('Đã duyệt', Tone.ok),
        'rejected' => const StatusInfo('Bị từ chối', Tone.danger),
        _ => StatusInfo(s, Tone.neutral),
      };

  static StatusInfo incident(String s) => switch (_k(s)) {
        'open' => const StatusInfo('Đã tiếp nhận', Tone.warn),
        'assigned' || 'inprogress' => const StatusInfo('Đang xử lý', Tone.accent),
        'resolved' => const StatusInfo('Đã xử lý', Tone.ok),
        'closed' => const StatusInfo('Đã đóng', Tone.neutral),
        _ => StatusInfo(s, Tone.neutral),
      };
}
