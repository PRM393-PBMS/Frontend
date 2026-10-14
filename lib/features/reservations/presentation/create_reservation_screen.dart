import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../data/reservation_repository.dart';
import 'time_slot_picker.dart';

/// Đặt chỗ ô tô: chọn giờ vào, đặt cọc qua PayOS.
class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  late final DataCubit<AvailabilityOverview> _info =
      DataCubit(context.read<CatalogRepository>().overview)..load();
  late List<DateTime> _slots = buildTimeSlots();
  DateTime? _selected;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _info.close();
    super.dispose();
  }

  PricingPolicyItem? _carPolicy(AvailabilityOverview? o) {
    if (o == null) return null;
    for (final p in o.activePricing) {
      if (p.vehicleTypeName.trim().toLowerCase() == 'ô tô') return p;
    }
    return null;
  }

  int? _carAvailable(AvailabilityOverview? o) {
    if (o == null) return null;
    var sum = 0;
    var found = false;
    for (final e in o.entries) {
      final floor = o.floorById(e.floorId);
      if (e.vehicleTypeName.trim().toLowerCase() == 'ô tô' &&
          !(floor?.isResident ?? false)) {
        sum += e.availableSlots;
        found = true;
      }
    }
    return found ? sum : null;
  }

  Future<void> _submit() async {
    final time = _selected;
    if (time == null) {
      setState(() => _error = context.l10n.resPickTime);
      return;
    }
    if (!time.isAfter(DateTime.now())) {
      setState(() {
        _slots = buildTimeSlots();
        _selected = null;
        _error = context.l10n.resSlotPassed;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = context.read<ReservationRepository>();
    try {
      final created = await repo.create(time);
      if (!mounted) return;
      if (created.payment.isUsable) {
        await PaymentSheet.show(
          context,
          title: context.l10n.payTypeDeposit,
          description: context.l10n.resDepositDesc(
              DateFormatter.formatRelativeDay(context.l10n, time)),
          link: created.payment,
          checkStatus: () => repo.paymentStatus(created.payment.orderCode),
        );
      }
      if (!mounted) return;
      context
          .pushReplacement(RouteNames.reservationDetail(created.reservationId));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeBookCar)),
      body: BlocBuilder<DataCubit<AvailabilityOverview>,
          LoadState<AvailabilityOverview>>(
        bloc: _info,
        builder: (context, state) {
          final policy = _carPolicy(state.data);
          final available = _carAvailable(state.data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.page, AppSpacing.sm, AppSpacing.page, 140),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.resNewIntro,
                      style: AppTypography.bodySmall
                          .copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppSurface(
                      color: p.surfaceMuted,
                      borderColor: p.surfaceMuted,
                      child: Column(
                        children: [
                          KeyValueRow(
                            context.l10n.resCarFree,
                            available == null
                                ? (state.isLoading
                                    ? context.l10n.commonLoading
                                    : context.l10n.commonUnknown)
                                : context.l10n.resSpaces('$available'),
                          ),
                          KeyValueRow(
                            context.l10n.resDepositEstimate,
                            policy == null
                                ? (state.isLoading
                                    ? context.l10n.commonLoading
                                    : context.l10n.resPerPricing)
                                : CurrencyFormatter.format(policy.basePrice),
                          ),
                          if (policy != null)
                            KeyValueRow(
                              context.l10n.resPrice,
                              context.l10n.resPriceValue(
                                  CurrencyFormatter.format(policy.basePrice),
                                  '${policy.baseHours}',
                                  CurrencyFormatter.format(
                                      policy.extraHourPrice)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(context.l10n.resEntryTime,
                              style: AppTypography.titleSmall
                                  .copyWith(color: p.textPrimary)),
                        ),
                        IconButton(
                          tooltip: context.l10n.resRefreshSlots,
                          onPressed: () => setState(() {
                            _slots = buildTimeSlots();
                            if (_selected != null &&
                                !_slots.contains(_selected)) {
                              _selected = null;
                            }
                          }),
                          icon: Icon(Icons.refresh_rounded,
                              color: p.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TimeSlotPicker(
                      slots: _slots,
                      selected: _selected,
                      onSelected: (t) => setState(() {
                        _selected = t;
                        _error = null;
                      }),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      InlineMessage(_error!),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.md),
          child: ContentWidth(
            child: AppButton(
              label: _selected == null
                  ? context.l10n.resChooseTime
                  : context.l10n.resBookAt(DateFormatter.formatTime(_selected)),
              loading: _submitting,
              onPressed: _selected == null ? null : _submit,
            ),
          ),
        ),
      ),
    );
  }
}
