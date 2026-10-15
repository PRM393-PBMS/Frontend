import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/panels.dart';
import '../../../data/models/pbms_models.dart';

/// Danh sách chỗ trống theo tầng & loại xe (dữ liệu thời gian thực).
class FloorAvailabilityList extends StatelessWidget {
  final List<FacilityAvailabilityModel> items;

  const FloorAvailabilityList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: p.line, indent: 16, endIndent: 16),
            _FloorRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _FloorRow extends StatelessWidget {
  final FacilityAvailabilityModel item;

  const _FloorRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final tone = CapacityBar.toneFor(context, item.availableSlots, item.totalSlots);
    final full = item.availableSlots == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.floorName, style: t.titleSmall),
                    const SizedBox(height: 2),
                    Text(item.vehicleTypeName, style: t.bodySmall),
                  ],
                ),
              ),
              if (full)
                Text('Hết chỗ',
                    style: t.labelMedium?.copyWith(color: p.danger, fontWeight: FontWeight.w700))
              else
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${item.availableSlots}',
                      style: AppTypography.mono(size: 20, weight: FontWeight.w700, color: tone),
                    ),
                    TextSpan(
                      text: ' / ${item.totalSlots} trống',
                      style: t.labelSmall,
                    ),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 10),
          CapacityBar(available: item.availableSlots, total: item.totalSlots),
        ],
      ),
    );
  }
}

/// Bảng giá theo loại xe (chính sách giá đang áp dụng).
class PricingTable extends StatelessWidget {
  final List<PricingPolicyModel> policies;

  const PricingTable({super.key, required this.policies});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return AppPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < policies.length; i++) ...[
            if (i > 0) Divider(height: 1, color: p.line, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(policies[i].vehicleTypeName, style: t.titleSmall),
                        const SizedBox(height: 3),
                        Text(
                          '+${CurrencyFormatter.format(policies[i].extraHourPrice)} mỗi giờ tiếp theo'
                          '${policies[i].nightSurcharge > 0 ? '\nPhụ thu qua đêm ${CurrencyFormatter.format(policies[i].nightSurcharge)}' : ''}',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(policies[i].basePrice),
                        style: AppTypography.mono(size: 16, weight: FontWeight.w700, color: p.text),
                      ),
                      const SizedBox(height: 3),
                      Text('${policies[i].baseHours} giờ đầu', style: t.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Đồng hồ thời gian đỗ, tự cập nhật mỗi 15 giây.
class LiveDuration extends StatefulWidget {
  final DateTime since;
  final TextStyle? style;

  const LiveDuration({super.key, required this.since, this.style});

  @override
  State<LiveDuration> createState() => _LiveDurationState();
}

class _LiveDurationState extends State<LiveDuration> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.since);
    final safe = d.isNegative ? Duration.zero : d;
    return Semantics(
      label: 'Đã đỗ ${DateFormatter.humanDuration(safe)}',
      excludeSemantics: true,
      child: Text(DateFormatter.clock(safe), style: widget.style),
    );
  }
}
