import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/subscription_repository.dart';
import 'plate_change_sheet.dart';

class PlateRequestsScreen extends StatefulWidget {
  const PlateRequestsScreen({super.key});

  @override
  State<PlateRequestsScreen> createState() => _PlateRequestsScreenState();
}

class _PlateRequestsScreenState extends State<PlateRequestsScreen> {
  late final SubscriptionRepository _repo =
      context.read<SubscriptionRepository>();
  late final DataCubit<List<VehicleChangeRequest>> _cubit = DataCubit(() async {
    final list = await _repo.myChangeRequests();
    list.sort((a, b) => (b.createdAt ?? DateTime(1970))
        .compareTo(a.createdAt ?? DateTime(1970)));
    return list;
  })
    ..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _edit(VehicleChangeRequest r) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PlateChangeSheet(
        title: context.l10n.plateEditTitle,
        currentPlate: r.oldLicensePlate,
        initialPlate: r.newLicensePlate,
        initialReason: r.reason,
        onSubmit: (plate, reason) => _repo.updatePlateChange(
            requestId: r.id, newLicensePlate: plate, reason: reason),
      ),
    );
    if (ok == true) {
      if (mounted) showAppSnack(context, context.l10n.plateUpdated);
      _cubit.refresh();
    }
  }

  Future<void> _delete(VehicleChangeRequest r) async {
    final ok = await confirmAction(
      context,
      title: context.l10n.plateWithdrawTitle,
      message: context.l10n.plateWithdrawMessage(r.newLicensePlate),
      confirmLabel: context.l10n.plateWithdraw,
      destructive: true,
    );
    if (!ok) return;
    try {
      await _repo.deletePlateChange(r.id);
      if (mounted) showAppSnack(context, context.l10n.plateWithdrawn);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    }
    _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.passesPlateRequests)),
      body: LoadStateView<List<VehicleChangeRequest>>(
        cubit: _cubit,
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(
          icon: Icons.swap_horiz_rounded,
          title: context.l10n.plateEmptyTitle,
          message: context.l10n.plateEmptyMessage,
        ),
        builder: (context, list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in list) ...[
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PlateTag(r.oldLicensePlate),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 16, color: p.textMuted),
                        ),
                        PlateTag(r.newLicensePlate),
                        const Spacer(),
                        StatusBadge(
                            StatusLabels.vehicleChange(context.l10n, r.status)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                        context.l10n.plateSentAt(
                            DateFormatter.formatDateTime(r.createdAt)),
                        style: AppTypography.caption
                            .copyWith(color: p.textSecondary)),
                    if (r.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(context.l10n.plateReasonValue(r.reason!),
                          style: AppTypography.bodySmall
                              .copyWith(color: p.textPrimary)),
                    ],
                    if (r.rejectionReason != null) ...[
                      const SizedBox(height: 4),
                      Text(context.l10n.plateRejectedValue(r.rejectionReason!),
                          style: AppTypography.bodySmall
                              .copyWith(color: p.danger)),
                    ],
                    if (r.isPending) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          TextButton(
                              onPressed: () => _edit(r),
                              child: Text(context.l10n.commonEdit)),
                          TextButton(
                            onPressed: () => _delete(r),
                            child: Text(context.l10n.plateWithdraw,
                                style: TextStyle(color: p.danger)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}
