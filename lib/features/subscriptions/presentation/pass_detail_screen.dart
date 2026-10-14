import '../../../core/utils/settle.dart';
import '../../../core/l10n/locale_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../payments/data/payment_models.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../../reservations/data/reservation_repository.dart';
import 'payment_method_sheet.dart';
import '../data/subscription_repository.dart';
import 'plate_change_sheet.dart';

class _PassDetail extends Equatable {
  final MonthlyPass pass;
  final List<RenewalRecord> renewals;

  const _PassDetail(this.pass, this.renewals);

  @override
  List<Object?> get props => [pass, renewals];
}

class PassDetailScreen extends StatefulWidget {
  final String passId;

  const PassDetailScreen({super.key, required this.passId});

  @override
  State<PassDetailScreen> createState() => _PassDetailScreenState();
}

class _PassDetailScreenState extends State<PassDetailScreen> {
  late final SubscriptionRepository _repo =
      context.read<SubscriptionRepository>();
  late final DataCubit<_PassDetail> _cubit = DataCubit(_load)..load();
  bool _busy = false;

  Future<_PassDetail> _load() async {
    final passF = settle(_repo.byId(widget.passId));
    final renewalsF = settle(_repo.renewals(widget.passId));
    final pass = (await passF).require;
    // Lịch sử gia hạn là thông tin phụ: lỗi thì hiển thị vé không kèm lịch sử.
    final renewals = [...?(await renewalsF).value];
    renewals.sort((a, b) => (b.renewalDate ?? DateTime(1970))
        .compareTo(a.renewalDate ?? DateTime(1970)));
    return _PassDetail(pass, renewals);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _cubit.refresh();
    }
  }

  Future<void> _payLink(
      PaymentLink link, String title, String description) async {
    final reservations = context.read<ReservationRepository>();
    final paid = await PaymentSheet.show(
      context,
      title: title,
      description: description,
      link: link,
      checkStatus: () => reservations.paymentStatus(link.orderCode),
    );
    if (paid && mounted) showAppSnack(context, context.l10n.paySuccessShort);
  }

  Future<void> _pay(MonthlyPass pass) async {
    final method = await PaymentMethodSheet.show(context, pass.price);
    if (method == null || !mounted) return;
    await _guard(() async {
      final result = await _repo.pay(pass.id, method);
      if (!mounted) return;
      final link = result.payment;
      if (result.paidByWallet) {
        showAppSnack(context, context.l10n.passPaidByWallet);
      } else if (link != null) {
        await _payLink(
            link,
            context.l10n.passPayTitle,
            context.l10n.passPayDesc(
                pass.packageName ?? context.l10n.passTitle, pass.licensePlate));
      }
    });
  }

  Future<void> _renew(MonthlyPass pass) async {
    final pkg = await showModalBottomSheet<SubscriptionPackageItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RenewSheet(vehicleType: pass.vehicleType),
    );
    if (pkg == null) return;
    await _guard(() async {
      final link = await _repo.renew(pass.id, pkg.id);
      if (mounted) {
        await _payLink(link, context.l10n.passRenewTitle,
            context.l10n.passRenewDesc(pkg.name, pass.licensePlate));
      }
    });
  }

  Future<void> _cancel(MonthlyPass pass) async {
    final ok = await confirmAction(
      context,
      title: context.l10n.passCancelTitle,
      message: pass.fixedSlot != null
          ? context.l10n
              .passCancelMessageSlot(pass.licensePlate, pass.fixedSlot!)
          : context.l10n.passCancelMessage(pass.licensePlate),
      confirmLabel: context.l10n.passCancelAction,
      destructive: true,
    );
    if (!ok) return;
    await _guard(() async {
      await _repo.cancel(pass.id);
      if (mounted) showAppSnack(context, context.l10n.passCancelled);
    });
  }

  Future<void> _changePlate(MonthlyPass pass) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PlateChangeSheet(
        title: context.l10n.passChangePlate,
        currentPlate: pass.licensePlate,
        onSubmit: (plate, reason) => _repo.requestPlateChange(
            subscriptionId: pass.id, newLicensePlate: plate, reason: reason),
      ),
    );
    if (sent == true && mounted) {
      showAppSnack(context, context.l10n.passPlateRequested);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.passTitle)),
      body: LoadStateView<_PassDetail>(
        cubit: _cubit,
        builder: (context, d) {
          final pass = d.pass;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSurface(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EdgeRow(
                        leading: PlateTag(pass.licensePlate, large: true),
                        trailing: StatusBadge(StatusLabels.subscription(
                            context.l10n, pass.status))),
                    const SizedBox(height: AppSpacing.lg),
                    Text(pass.packageName ?? context.l10n.passTitle,
                        style:
                            AppTypography.title.copyWith(color: p.textPrimary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      pass.isValidNow
                          ? context.l10n.passDaysLeftUntil(pass.daysLeft,
                              DateFormatter.formatDate(pass.endDate))
                          : context.l10n.dateRange(
                              DateFormatter.formatDate(pass.startDate),
                              DateFormatter.formatDate(pass.endDate)),
                      style: AppTypography.bodySmall
                          .copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSurface(
                child: Column(
                  children: [
                    if (pass.vehicleType != null)
                      KeyValueRow(
                          context.l10n.fieldVehicleType, pass.vehicleType!),
                    KeyValueRow(context.l10n.passStart,
                        DateFormatter.formatDate(pass.startDate)),
                    KeyValueRow(context.l10n.passEnd,
                        DateFormatter.formatDate(pass.endDate)),
                    KeyValueRow(context.l10n.passFixedSlotLabel,
                        pass.fixedSlot ?? context.l10n.commonNo),
                    KeyValueRow(context.l10n.passPrice,
                        CurrencyFormatter.format(pass.price)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (pass.isPendingPayment)
                AppButton(
                  label: context.l10n
                      .passPay(CurrencyFormatter.format(pass.price)),
                  icon: Icons.payments_outlined,
                  loading: _busy,
                  onPressed: () => _pay(pass),
                ),
              if (pass.canRenew && !pass.isPendingPayment)
                AppButton(
                  label: context.l10n.passRenew,
                  icon: Icons.autorenew_rounded,
                  loading: _busy,
                  onPressed: () => _renew(pass),
                ),
              if (pass.canRequestPlateChange) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton.secondary(
                  label: context.l10n.passChangePlate,
                  icon: Icons.swap_horiz_rounded,
                  onPressed: _busy ? null : () => _changePlate(pass),
                ),
              ],
              if (pass.canCancel) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton.text(
                  label: context.l10n.passCancel,
                  expand: true,
                  onPressed: _busy ? null : () => _cancel(pass),
                ),
              ],
              if (d.renewals.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(context.l10n.passRenewals),
                AppSurface(
                  child: Column(
                    children: [
                      for (final r in d.renewals)
                        KeyValueRow(
                          context.l10n.dateRange(
                              DateFormatter.formatDate(r.oldEndDate),
                              DateFormatter.formatDate(r.newEndDate)),
                          CurrencyFormatter.format(r.amount),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RenewSheet extends StatefulWidget {
  final String? vehicleType;

  const _RenewSheet({required this.vehicleType});

  @override
  State<_RenewSheet> createState() => _RenewSheetState();
}

class _RenewSheetState extends State<_RenewSheet> {
  late final DataCubit<List<SubscriptionPackageItem>> _cubit =
      DataCubit(() async {
    final all = await context.read<CatalogRepository>().packages();
    return all
        .where((p) =>
            p.isActive &&
            (widget.vehicleType == null ||
                p.vehicleTypeName == widget.vehicleType))
        .toList()
      ..sort((a, b) => a.durationMonths.compareTo(b.durationMonths));
  })
        ..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.passRenewPick,
              style: AppTypography.title.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<DataCubit<List<SubscriptionPackageItem>>,
              LoadState<List<SubscriptionPackageItem>>>(
            bloc: _cubit,
            builder: (context, state) {
              final list = state.data;
              if (list == null) {
                return state.isFailure
                    ? ErrorState(
                        message: errorText(state.error, context.l10n),
                        onRetry: _cubit.load)
                    : const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.card_membership_outlined,
                  title: context.l10n.passRenewNoneTitle,
                  message: context.l10n.passRenewNoneMessage,
                );
              }
              return Column(
                children: [
                  for (final pkg in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(pkg.name),
                      subtitle:
                          Text(context.l10n.passMonths(pkg.durationMonths)),
                      trailing: Text(CurrencyFormatter.format(pkg.price),
                          style: AppTypography.label
                              .copyWith(color: p.textPrimary)),
                      onTap: () => Navigator.pop(context, pkg),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
