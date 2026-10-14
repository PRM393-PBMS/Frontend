import '../../../core/utils/settle.dart';
import '../../../core/l10n/locale_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../../reservations/data/reservation_repository.dart';
import 'payment_method_sheet.dart';
import '../data/subscription_repository.dart';

class _RegisterData extends Equatable {
  final List<SubscriptionPackageItem> packages;
  final List<ParkingSlotItem> slots;

  const _RegisterData(this.packages, this.slots);

  @override
  List<Object?> get props => [packages, slots];
}

/// Đăng ký vé tháng: chọn gói, nhập biển số, chọn vị trí cố định nếu gói yêu cầu, thanh toán PayOS.
class RegisterPassScreen extends StatefulWidget {
  final String? initialPlate;

  const RegisterPassScreen({super.key, this.initialPlate});

  @override
  State<RegisterPassScreen> createState() => _RegisterPassScreenState();
}

class _RegisterPassScreenState extends State<RegisterPassScreen> {
  late final _plate = TextEditingController(text: widget.initialPlate ?? '');
  final _formKey = GlobalKey<FormState>();
  late final DataCubit<_RegisterData> _cubit = DataCubit(_load)..load();
  SubscriptionPackageItem? _package;
  ParkingSlotItem? _slot;
  bool _submitting = false;
  String? _error;

  Future<_RegisterData> _load() async {
    final catalog = context.read<CatalogRepository>();
    final packagesF = settle(catalog.packages());
    final slotsF = settle(catalog.slots());
    final packages = (await packagesF).require.where((p) => p.isActive).toList()
      ..sort((a, b) => a.vehicleTypeName == b.vehicleTypeName
          ? a.durationMonths.compareTo(b.durationMonths)
          : a.vehicleTypeName.compareTo(b.vehicleTypeName));
    return _RegisterData(packages, (await slotsF).require);
  }

  @override
  void dispose() {
    _plate.dispose();
    _cubit.close();
    super.dispose();
  }

  List<ParkingSlotItem> _slotsFor(
          SubscriptionPackageItem pkg, List<ParkingSlotItem> all) =>
      all
          .where((s) =>
              s.isResident &&
              s.isAvailable &&
              s.vehicleTypeId == pkg.vehicleTypeId)
          .toList();

  Future<void> _submit() async {
    final pkg = _package;
    if (pkg == null) {
      setState(() => _error = context.l10n.regPickPackage);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (pkg.requireFixedSlot && _slot == null) {
      setState(() => _error = context.l10n.regNeedSlot);
      return;
    }
    final method = await PaymentMethodSheet.show(context, pkg.price);
    if (method == null || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await context.read<SubscriptionRepository>().register(
            packageId: pkg.id,
            licensePlate: _plate.text,
            method: method,
            fixedSlotId: pkg.requireFixedSlot ? _slot?.id : null,
          );
      if (!mounted) return;
      final reservations = context.read<ReservationRepository>();
      final link = result.payment;
      if (result.paidByWallet) {
        showAppSnack(context, context.l10n.passPaidByWallet);
      } else if (link != null) {
        await PaymentSheet.show(
          context,
          title: context.l10n.passPayTitle,
          description: context.l10n.passRegisterPayDesc(
              pkg.name, Validators.normalizePlate(_plate.text)),
          link: link,
          checkStatus: () => reservations.paymentStatus(link.orderCode),
        );
      }
      if (mounted) {
        context.pushReplacement(RouteNames.passDetail(result.subscriptionId));
      }
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
      appBar: AppBar(title: Text(context.l10n.regTitle)),
      body: BlocBuilder<DataCubit<_RegisterData>, LoadState<_RegisterData>>(
        bloc: _cubit,
        builder: (context, state) {
          final data = state.data;
          if (data == null) {
            return state.isFailure
                ? ErrorState(
                    message: errorText(state.error, context.l10n),
                    onRetry: _cubit.load)
                : const Padding(
                    padding: EdgeInsets.all(AppSpacing.page),
                    child: SkeletonList(count: 3),
                  );
          }
          if (data.packages.isEmpty) {
            return EmptyState(
              icon: Icons.card_membership_outlined,
              title: context.l10n.regEmptyTitle,
              message: context.l10n.regEmptyMessage,
            );
          }
          final types = <String, List<SubscriptionPackageItem>>{};
          for (final pkg in data.packages) {
            types.putIfAbsent(pkg.vehicleTypeName, () => []).add(pkg);
          }
          final slots = _package == null
              ? const <ParkingSlotItem>[]
              : _slotsFor(_package!, data.slots);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, AppSpacing.sm, AppSpacing.page, 140),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: context.l10n.fieldPlate,
                        controller: _plate,
                        hint: '51H12345',
                        helper: context.l10n.regPlateHelper,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [PlateInputFormatter()],
                        validator: (v) => Validators.plate(context.l10n, v),
                        style: AppTypography.mono
                            .copyWith(fontSize: 17, color: p.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      for (final t in types.entries) ...[
                        SectionHeader(t.key),
                        for (final pkg in t.value) ...[
                          _PackageOption(
                            pkg: pkg,
                            selected: _package?.id == pkg.id,
                            onTap: () => setState(() {
                              _package = pkg;
                              _slot = null;
                              _error = null;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (_package?.requireFixedSlot ?? false) ...[
                        SectionHeader(context.l10n.regFixedSlot),
                        if (slots.isEmpty)
                          InlineMessage(context.l10n.regNoSlot)
                        else
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final s in slots)
                                ChoiceChip(
                                  label: Text('${s.code}, ${s.floorName}'),
                                  selected: _slot?.id == s.id,
                                  onSelected: (_) => setState(() => _slot = s),
                                ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (_error != null) InlineMessage(_error!),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.md),
          child: ContentWidth(
            child: AppButton(
              label: _package == null
                  ? context.l10n.regChoosePackage
                  : context.l10n
                      .passPay(CurrencyFormatter.format(_package!.price)),
              loading: _submitting,
              onPressed: _package == null ? null : _submit,
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageOption extends StatelessWidget {
  final SubscriptionPackageItem pkg;
  final bool selected;
  final VoidCallback onTap;

  const _PackageOption(
      {required this.pkg, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSurface(
      onTap: onTap,
      color: selected ? p.accentSoft : null,
      borderColor: selected ? p.accent : null,
      child: Row(
        children: [
          Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? p.accent : p.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkg.name,
                    style: AppTypography.label.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  [
                    context.l10n.passMonths(pkg.durationMonths),
                    if (pkg.requireFixedSlot) context.l10n.passFixedSlotTag,
                    if (pkg.description != null) pkg.description!,
                  ].join(', '),
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(CurrencyFormatter.format(pkg.price),
              style: AppTypography.titleSmall.copyWith(color: p.textPrimary)),
        ],
      ),
    );
  }
}
