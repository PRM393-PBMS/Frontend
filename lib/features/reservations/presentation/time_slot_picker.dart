import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';

/// Các mốc giờ cách nhau 15 phút trong khung cho phép đặt (bắt đầu sau [minLead], tối đa [maxLead]).
List<DateTime> buildTimeSlots({
  Duration minLead = const Duration(minutes: 15),
  Duration maxLead = const Duration(hours: 5),
  DateTime? now,
}) {
  final base = now ?? DateTime.now();
  final earliest = base.add(minLead);
  final minutesUp = (15 - earliest.minute % 15) % 15;
  var t = DateTime(earliest.year, earliest.month, earliest.day, earliest.hour,
          earliest.minute)
      .add(Duration(minutes: minutesUp));
  final latest = base.add(maxLead).subtract(const Duration(minutes: 1));
  final slots = <DateTime>[];
  while (!t.isAfter(latest)) {
    slots.add(t);
    t = t.add(const Duration(minutes: 15));
  }
  return slots;
}

class TimeSlotPicker extends StatelessWidget {
  final List<DateTime> slots;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  const TimeSlotPicker({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (slots.isEmpty) {
      return Text(context.l10n.resNoSlots,
          style: AppTypography.bodySmall.copyWith(color: p.textSecondary));
    }
    final groups = <String, List<DateTime>>{};
    for (final s in slots) {
      groups
          .putIfAbsent(DateFormatter.dayLabel(context.l10n, s), () => [])
          .add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in groups.entries) ...[
          Text(g.key,
              style: AppTypography.labelSmall.copyWith(color: p.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in g.value)
                ChoiceChip(
                  label: Text(
                    DateFormatter.formatTime(s),
                    style: AppTypography.label.copyWith(
                      color: s == selected ? p.accent : p.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  selected: s == selected,
                  onSelected: (_) => onSelected(s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
