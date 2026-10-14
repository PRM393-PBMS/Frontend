import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';

/// Chỗ trống theo tầng và loại xe, kèm bảng giá đang áp dụng.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late final DataCubit<AvailabilityOverview> _cubit =
      DataCubit(context.read<CatalogRepository>().overview)..load();
  String? _vehicleFilter;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.availTitle)),
      body: LoadStateView<AvailabilityOverview>(
        cubit: _cubit,
        isEmpty: (o) => o.entries.isEmpty,
        empty: EmptyState(
          icon: Icons.local_parking_rounded,
          title: context.l10n.availEmptyTitle,
          message: context.l10n.availEmptyMessage,
        ),
        builder: (context, o) {
          final types = o.byVehicleType.keys.toList()..sort();
          final filter = types.contains(_vehicleFilter) ? _vehicleFilter : null;
          final entries = o.entries
              .where((e) => filter == null || e.vehicleTypeName == filter)
              .toList();
          final floors = <String, List<AvailabilityEntry>>{};
          for (final e in entries) {
            floors.putIfAbsent(e.floorId, () => []).add(e);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (types.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(context.l10n.commonAll),
                        selected: filter == null,
                        onSelected: (_) =>
                            setState(() => _vehicleFilter = null),
                      ),
                      for (final t in types) ...[
                        const SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: Text(t),
                          selected: filter == t,
                          onSelected: (_) => setState(() => _vehicleFilter = t),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              for (final group in floors.values) ...[
                _FloorCard(
                    entries: group, floor: o.floorById(group.first.floorId)),
                const SizedBox(height: AppSpacing.md),
              ],
              if (o.activePricing.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(context.l10n.availPricing),
                for (final pr in o.activePricing) ...[
                  _PricingCard(policy: pr),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FloorCard extends StatelessWidget {
  final List<AvailabilityEntry> entries;
  final FloorItem? floor;

  const _FloorCard({required this.entries, required this.floor});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = entries.first;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(first.floorName,
                    style: AppTypography.titleSmall
                        .copyWith(color: p.textPrimary)),
              ),
              if (floor?.isResident ?? false)
                Text(context.l10n.availResidentFloor,
                    style:
                        AppTypography.caption.copyWith(color: p.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.vehicleTypeName,
                        style: AppTypography.bodySmall
                            .copyWith(color: p.textSecondary)),
                  ),
                  Text(
                    '${e.availableSlots}',
                    style: AppTypography.titleSmall.copyWith(
                      color: e.availableSlots == 0 ? p.danger : p.success,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(context.l10n.availOfFree('${e.totalSlots}'),
                      style:
                          AppTypography.bodySmall.copyWith(color: p.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final PricingPolicyItem policy;

  const _PricingCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSurface(
      color: p.surfaceMuted,
      borderColor: p.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(policy.vehicleTypeName,
              style: AppTypography.label.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          KeyValueRow(context.l10n.priceFirstHours('${policy.baseHours}'),
              CurrencyFormatter.format(policy.basePrice)),
          KeyValueRow(context.l10n.priceExtraHour,
              CurrencyFormatter.format(policy.extraHourPrice)),
          if (policy.nightSurcharge > 0)
            KeyValueRow(context.l10n.priceNight,
                CurrencyFormatter.format(policy.nightSurcharge)),
        ],
      ),
    );
  }
}
