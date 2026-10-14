import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/incident_repository.dart';

class IncidentTile extends StatelessWidget {
  final IncidentReport incident;
  final VoidCallback onTap;
  final bool showReporter;

  const IncidentTile(
      {super.key,
      required this.incident,
      required this.onTap,
      this.showReporter = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final i = incident;
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(i.issueType,
                    style: AppTypography.label.copyWith(color: p.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
              StatusBadge(StatusLabels.incident(context.l10n, i.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(i.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(color: p.textSecondary)),
          if (showReporter || i.handledByStaffName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                if (showReporter && i.reporterName != null)
                  context.l10n.incReporterValue(i.reporterName!),
                if (i.handledByStaffName != null)
                  context.l10n.incHandlerValue(i.handledByStaffName!),
              ].join(', '),
              style: AppTypography.caption.copyWith(color: p.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
