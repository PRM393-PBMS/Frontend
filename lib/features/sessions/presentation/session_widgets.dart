import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_badge.dart';
import '../../payments/data/payment_models.dart';
import '../data/session_repository.dart';

/// Thẻ tóm tắt một lượt gửi xe (dùng cho cả khách và nhân viên).
class SessionTile extends StatelessWidget {
  final ParkingSession session;
  final VoidCallback onTap;
  final bool showDriver;

  const SessionTile(
      {super.key,
      required this.session,
      required this.onTap,
      this.showDriver = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = session;
    final amount = s.paymentAmount;
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlateTag(s.licensePlateIn),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(s.vehicleTypeName,
                    style:
                        AppTypography.caption.copyWith(color: p.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
              StatusBadge(StatusLabels.session(context.l10n, s.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.isActive
                ? context.l10n.sessTileActive(
                    DateFormatter.formatRelativeDay(context.l10n, s.entryTime),
                    DateFormatter.formatDuration(context.l10n, s.elapsed))
                : context.l10n.dateRange(
                    DateFormatter.formatRelativeDay(context.l10n, s.entryTime),
                    DateFormatter.formatRelativeDay(context.l10n, s.exitTime)),
            style: AppTypography.bodySmall.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (showDriver && s.driverFullName != null)
                      s.driverFullName!,
                    s.entryGateName,
                    if (s.slotCode != null) context.l10n.sessSlot(s.slotCode!),
                  ].join(', '),
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!s.isActive && amount != null)
                Text(CurrencyFormatter.format(amount),
                    style: AppTypography.label.copyWith(color: p.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bảng chi tiết phí gửi xe.
class FeeBreakdownView extends StatelessWidget {
  final FeeBreakdown fee;
  final String? title;

  const FeeBreakdownView({super.key, required this.fee, this.title});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title ?? context.l10n.feeRunning,
            style: AppTypography.labelSmall.copyWith(color: p.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          fee.isCoveredBySubscription
              ? context.l10n.feeFree
              : CurrencyFormatter.format(fee.amount),
          style: AppTypography.figure.copyWith(color: p.textPrimary),
        ),
        if (fee.isCoveredBySubscription)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(context.l10n.feeCovered,
                style: AppTypography.caption.copyWith(color: p.success)),
          ),
        const SizedBox(height: AppSpacing.md),
        KeyValueRow(context.l10n.feeDuration,
            context.l10n.feeHoursValue(fee.totalHours.toStringAsFixed(2))),
        KeyValueRow(context.l10n.feeBilledHours,
            context.l10n.feeHoursValue('${fee.billedHours}')),
        if (!fee.isCoveredBySubscription) ...[
          KeyValueRow(context.l10n.priceFirstHours('${fee.baseHours}'),
              CurrencyFormatter.format(fee.basePrice)),
          if (fee.extraHours > 0)
            KeyValueRow(context.l10n.feeExtraHours('${fee.extraHours}'),
                CurrencyFormatter.format(fee.extraHours * fee.extraHourPrice)),
          if (fee.nightSurchargeCount > 0)
            KeyValueRow(
                context.l10n.feeNight('${fee.nightSurchargeCount}'),
                CurrencyFormatter.format(
                    fee.nightSurchargeCount * fee.nightSurcharge)),
          if (fee.depositAmount > 0)
            KeyValueRow(context.l10n.feeDeposit,
                '-${CurrencyFormatter.format(fee.depositAmount)}'),
        ],
      ],
    );
  }
}
