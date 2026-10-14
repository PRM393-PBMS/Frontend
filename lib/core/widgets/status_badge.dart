import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/status_labels.dart';

/// Huy hiệu trạng thái (bo 8, nền nhạt theo tông ngữ nghĩa).
class StatusBadge extends StatelessWidget {
  final StatusInfo info;

  const StatusBadge(this.info, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (info.tone) {
      StatusTone.success => (p.successSoft, p.success),
      StatusTone.warning => (p.warningSoft, p.warning),
      StatusTone.danger => (p.dangerSoft, p.danger),
      StatusTone.accent => (p.accentSoft, p.accent),
      StatusTone.neutral => (p.surfaceMuted, p.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppSpacing.badge),
      child: Text(
        info.label,
        style: AppTypography.labelSmall
            .copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
