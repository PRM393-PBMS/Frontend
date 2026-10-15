import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/error_text.dart';
import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';

String normalizePlate(String raw) =>
    raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

String? validatePlate(String? raw) {
  final v = normalizePlate(raw ?? '');
  if (v.isEmpty) return 'Nhập biển số xe';
  if (v.length < 4 || v.length > 15) return 'Biển số gồm 4–15 chữ và số, ví dụ 51K12345';
  return null;
}

Widget _sheetHeader(BuildContext context, String title, String subtitle) {
  final t = Theme.of(context).textTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: t.headlineSmall),
      const SizedBox(height: 4),
      Text(subtitle, style: t.bodyMedium?.copyWith(color: context.palette.textSecondary)),
    ],
  );
}

Widget _inlineError(BuildContext context, String? message) {
  if (message == null) return const SizedBox.shrink();
  final p = context.palette;
  return Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 18, color: p.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.danger)),
        ),
      ],
    ),
  );
}

Widget _busyLabel(bool busy, String label) => busy
    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
    : Text(label);

/// Ô nhập biển số in hoa, font mono.
class PlateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const PlateField({super.key, required this.controller, this.label = 'Biển số xe'});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-. ]')),
        LengthLimitingTextInputFormatter(18),
      ],
      style: AppTypography.plate(size: 18, color: context.palette.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: '51K-123.45',
        prefixIcon: const Icon(Icons.pin_outlined),
      ),
      validator: validatePlate,
    );
  }
}

// ---------------------------------------------------------------- register

class RegisterPassSheet extends StatefulWidget {
  final SubscriptionPackageModel pkg;

  const RegisterPassSheet({super.key, required this.pkg});

  static Future<PaymentLinkModel?> show(BuildContext context, SubscriptionPackageModel pkg) =>
      showModalBottomSheet<PaymentLinkModel>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RegisterPassSheet(pkg: pkg),
      );

  @override
  State<RegisterPassSheet> createState() => _RegisterPassSheetState();
}

class _RegisterPassSheetState extends State<RegisterPassSheet> {
  final _form = GlobalKey<FormState>();
  final _plate = TextEditingController();
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  AsyncCubit<List<ParkingSlotModel>>? _slots;
  String? _slotId;
  bool _busy = false;
  String? _error;

  bool get _needsSlot => widget.pkg.requireFixedSlot && !widget.pkg.isMotorbike;

  @override
  void initState() {
    super.initState();
    if (_needsSlot) {
      _slots = AsyncCubit(() => _repo.getResidentSlots(widget.pkg.vehicleTypeId));
    }
  }

  @override
  void dispose() {
    _plate.dispose();
    _slots?.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_needsSlot && _slotId == null) {
      setState(() => _error = 'Chọn một ô đỗ cố định.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final link = await _repo.registerSubscription(
        packageId: widget.pkg.packageId,
        vehicleTypeId: widget.pkg.vehicleTypeId,
        licensePlate: normalizePlate(_plate.text),
        fixedSlotId: _needsSlot ? _slotId : null,
      );
      if (mounted) Navigator.pop(context, link);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final pkg = widget.pkg;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHeader(context, pkg.packageName,
                  '${pkg.vehicleTypeName} · ${pkg.durationMonths} tháng${pkg.description != null ? '\n${pkg.description}' : ''}'),
              const SizedBox(height: AppSpacing.xl),
              PlateField(controller: _plate),
              if (_needsSlot) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('Ô đỗ cố định tại tầng cư dân', style: t.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                BlocBuilder<AsyncCubit<List<ParkingSlotModel>>, AsyncState<List<ParkingSlotModel>>>(
                  bloc: _slots,
                  builder: (context, st) => AsyncView(
                    state: st,
                    onRetry: _slots!.load,
                    loading: const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Skeleton(width: 72, height: 40, radius: 6),
                        Skeleton(width: 72, height: 40, radius: 6),
                        Skeleton(width: 72, height: 40, radius: 6),
                      ],
                    ),
                    isEmpty: (d) => d.isEmpty,
                    empty: const EmptyState(
                      icon: Icons.block_rounded,
                      title: 'Hết ô cố định',
                      message: 'Tầng cư dân không còn ô trống cho loại xe này. Thử gói không cố định vị trí.',
                    ),
                    builder: (slots) {
                      final byFloor = <String, List<ParkingSlotModel>>{};
                      for (final s in slots) {
                        byFloor.putIfAbsent(s.floorName, () => []).add(s);
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in byFloor.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6, top: 4),
                              child: Text('${entry.key} · ${entry.value.length} ô trống', style: t.labelSmall),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final s in entry.value)
                                  ChoiceChip(
                                    label: Text(s.slotCode, style: AppTypography.mono(size: 13, weight: FontWeight.w600)),
                                    selected: _slotId == s.slotId,
                                    onSelected: (_) => setState(() {
                                      _slotId = s.slotId;
                                      _error = null;
                                    }),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: Text('Thanh toán', style: t.titleSmall)),
                  Text(
                    CurrencyFormatter.format(pkg.price),
                    style: AppTypography.mono(size: 22, weight: FontWeight.w700, color: p.text),
                  ),
                ],
              ),
              _inlineError(context, _error),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busyLabel(_busy, 'Đăng ký và thanh toán'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ renew

class RenewPassSheet extends StatefulWidget {
  final MonthlySubscriptionModel pass;
  final List<SubscriptionPackageModel> packages;

  const RenewPassSheet({super.key, required this.pass, required this.packages});

  static Future<PaymentLinkModel?> show(
    BuildContext context,
    MonthlySubscriptionModel pass,
    List<SubscriptionPackageModel> packages,
  ) =>
      showModalBottomSheet<PaymentLinkModel>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RenewPassSheet(pass: pass, packages: packages),
      );

  @override
  State<RenewPassSheet> createState() => _RenewPassSheetState();
}

class _RenewPassSheetState extends State<RenewPassSheet> {
  String? _packageId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final same = widget.packages.where((p) => p.packageName == widget.pass.packageName);
    _packageId = (same.isNotEmpty ? same.first : widget.packages.firstOrNull)?.packageId;
  }

  Future<void> _submit() async {
    final id = _packageId;
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final link = await context.read<PbmsRepository>().renewSubscription(widget.pass.subscriptionId, id);
      if (mounted) Navigator.pop(context, link);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHeader(
            context,
            'Gia hạn vé tháng',
            'Xe ${PlateBadge.format(widget.pass.licensePlate)} · hết hạn ${DateFormatter.formatDate(widget.pass.endDate)}',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (widget.packages.isEmpty)
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có gói phù hợp',
              message: 'Không có gói đang bán cho loại xe này. Vui lòng thử lại sau.',
            )
          else
            AppPanel(
              padding: EdgeInsets.zero,
              child: RadioGroup<String>(
                groupValue: _packageId,
                onChanged: (v) => setState(() => _packageId = v),
                child: Column(
                  children: [
                    for (var i = 0; i < widget.packages.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: p.line),
                      RadioListTile<String>(
                        value: widget.packages[i].packageId,
                        title: Text(widget.packages[i].packageName),
                        subtitle: Text('${widget.packages[i].durationMonths} tháng'),
                        secondary: Text(
                          CurrencyFormatter.format(widget.packages[i].price),
                          style: AppTypography.mono(size: 14, weight: FontWeight.w700, color: p.text),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          _inlineError(context, _error),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _busy || _packageId == null ? null : _submit,
            child: _busyLabel(_busy, 'Tiếp tục thanh toán'),
          ),
          Text(
            'Thời hạn mới được cộng nối tiếp ngày hết hạn hiện tại.',
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ).withTopGap(AppSpacing.sm),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget withTopGap(double gap) => Padding(padding: EdgeInsets.only(top: gap), child: this);
}

// ---------------------------------------------------------- vehicle change

class VehicleChangeSheet extends StatefulWidget {
  final MonthlySubscriptionModel? pass;

  /// Khi có: sửa yêu cầu đang chờ (PUT) thay vì tạo mới.
  final VehicleChangeRequestModel? existing;

  const VehicleChangeSheet({super.key, this.pass, this.existing})
      : assert(pass != null || existing != null);

  static Future<bool?> show(BuildContext context, MonthlySubscriptionModel pass) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => VehicleChangeSheet(pass: pass),
      );

  static Future<bool?> edit(BuildContext context, VehicleChangeRequestModel request) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => VehicleChangeSheet(existing: request),
      );

  @override
  State<VehicleChangeSheet> createState() => _VehicleChangeSheetState();
}

class _VehicleChangeSheetState extends State<VehicleChangeSheet> {
  final _form = GlobalKey<FormState>();
  late final _plate = TextEditingController(text: widget.existing?.newLicensePlate ?? '');
  late final _reason = TextEditingController(text: widget.existing?.reason ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = context.read<PbmsRepository>();
      final existing = widget.existing;
      if (existing != null) {
        await repo.updateVehicleChangeRequest(
          requestId: existing.requestId,
          newLicensePlate: normalizePlate(_plate.text),
          reason: _reason.text.trim(),
        );
      } else {
        await repo.requestVehicleChange(
          subscriptionId: widget.pass!.subscriptionId,
          newLicensePlate: normalizePlate(_plate.text),
          reason: _reason.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHeader(
                context,
                widget.existing != null ? 'Sửa yêu cầu đổi biển số' : 'Đổi biển số',
                widget.existing != null
                    ? 'Biển số hiện tại ${PlateBadge.format(widget.existing!.oldLicensePlate)}. Yêu cầu vẫn chờ quản lý duyệt.'
                    : 'Vé ${widget.pass!.packageName} đang gắn với ${PlateBadge.format(widget.pass!.licensePlate)}. Yêu cầu cần quản lý duyệt.',
              ),
              const SizedBox(height: AppSpacing.xl),
              PlateField(controller: _plate, label: 'Biển số mới'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reason,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Lý do',
                  hintText: 'Ví dụ: đã bán xe cũ, đổi sang xe mới',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Cho biết lý do đổi xe' : null,
              ),
              _inlineError(context, _error),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busyLabel(_busy, widget.existing != null ? 'Lưu thay đổi' : 'Gửi yêu cầu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------- renewal history

class RenewalHistorySheet extends StatefulWidget {
  final MonthlySubscriptionModel pass;

  const RenewalHistorySheet({super.key, required this.pass});

  static Future<void> show(BuildContext context, MonthlySubscriptionModel pass) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RenewalHistorySheet(pass: pass),
      );

  @override
  State<RenewalHistorySheet> createState() => _RenewalHistorySheetState();
}

class _RenewalHistorySheetState extends State<RenewalHistorySheet> {
  late final _renewals = AsyncCubit(
    () => context.read<PbmsRepository>().getRenewals(widget.pass.subscriptionId),
  );

  @override
  void dispose() {
    _renewals.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHeader(context, 'Lịch sử gia hạn', '${widget.pass.packageName} · ${PlateBadge.format(widget.pass.licensePlate)}'),
          const SizedBox(height: AppSpacing.xl),
          BlocBuilder<AsyncCubit<List<RenewalModel>>, AsyncState<List<RenewalModel>>>(
            bloc: _renewals,
            builder: (context, st) => AsyncView(
              state: st,
              onRetry: _renewals.load,
              loading: const SkeletonList(count: 2, itemHeight: 64),
              isEmpty: (d) => d.isEmpty,
              empty: const EmptyState(
                icon: Icons.history_rounded,
                title: 'Chưa gia hạn lần nào',
                message: 'Các lần gia hạn đã thanh toán sẽ hiện ở đây.',
              ),
              builder: (items) => AppPanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: p.line),
                      InfoRow(
                        label: '${DateFormatter.formatDate(items[i].renewalDate)}\n'
                            'đến ${DateFormatter.formatDate(items[i].newEndDate)}',
                        value: CurrencyFormatter.format(items[i].amount),
                        mono: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
