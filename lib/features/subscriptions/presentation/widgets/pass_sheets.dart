import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

String normalizePlate(String raw) =>
    raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

String? validatePlate(String? raw) {
  final v = normalizePlate(raw ?? '');
  if (v.isEmpty) return 'Nhập biển số xe';
  if (v.length < 4 || v.length > 15) {
    return 'Biển số gồm 4 đến 15 chữ và số, ví dụ 51K12345';
  }
  return null;
}

/// Ô nhập biển số in hoa.
class PlateField extends StatelessWidget {
  final TextEditingController controller;

  const PlateField({super.key, required this.controller});

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
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      decoration: pbmsInputDecoration(hint: 'Ví dụ: 51H-999.88'),
      validator: validatePlate,
    );
  }
}

Widget _inlineError(String? message) {
  if (message == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 18, color: PbmsTokens.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ),
      ],
    ),
  );
}

/// Lựa chọn gói (radio) theo thiết kế gốc.
class PlanOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  const PlanOption({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? PbmsTokens.tealTint : PbmsTokens.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
                border: Border.all(
                    color: selected ? PbmsTokens.teal : PbmsTokens.border),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: selected ? PbmsTokens.teal : PbmsTokens.muted),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: PbmsText.bodyStrong),
                      const SizedBox(height: 2),
                      Text(subtitle, style: PbmsText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(price, style: PbmsText.figure(14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chọn ô đỗ cố định tại tầng cư dân: một ô chọn gọn trong form,
/// chạm vào mới mở hộp thoại liệt kê các ô còn trống theo tầng.
class FixedSlotPicker extends StatelessWidget {
  final AsyncCubit<List<ParkingSlotModel>> slots;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const FixedSlotPicker({
    super.key,
    required this.slots,
    required this.selectedId,
    required this.onSelected,
  });

  Future<void> _open(BuildContext context, List<ParkingSlotModel> items) async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => _SlotDialog(slots: items, selectedId: selectedId),
    );
    if (id != null) onSelected(id);
  }

  @override
  Widget build(BuildContext context) {
    return PbmsAsync<List<ParkingSlotModel>>(
      cubit: slots,
      loadingHeight: 56,
      errorTitle: 'Không tải được ô đỗ',
      isEmpty: (d) => d.isEmpty,
      empty: const PbmsEmptyView(
        icon: Icons.block_rounded,
        title: 'Hết ô cố định',
        message:
            'Tầng cư dân không còn ô trống cho loại xe này. Thử gói không cố định vị trí.',
      ),
      builder: (items) {
        final chosen = items.where((s) => s.slotId == selectedId).firstOrNull;
        return Semantics(
          button: true,
          label: chosen == null
              ? 'Chọn ô đỗ cố định, còn ${items.length} ô trống'
              : 'Ô đỗ đã chọn ${chosen.slotCode}, chạm để đổi',
          excludeSemantics: true,
          child: Material(
            color: chosen == null ? Colors.white : PbmsTokens.tealTint,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => _open(context, items),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: chosen == null ? PbmsTokens.border : PbmsTokens.teal),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: chosen == null ? PbmsTokens.surfaceLow : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_parking_rounded,
                          size: 20, color: PbmsTokens.teal),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              chosen == null
                                  ? 'Chọn ô đỗ'
                                  : 'Ô ${chosen.slotCode}',
                              style: PbmsText.bodyStrong),
                          const SizedBox(height: 2),
                          Text(
                              chosen == null
                                  ? 'Còn ${items.length} ô trống, chạm để xem'
                                  : '${chosen.floorName}, chạm để đổi ô',
                              style: PbmsText.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, color: PbmsTokens.muted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chọn bãi áp dụng vé tháng. Chỉ có một bãi thì hiện cố định, không cần chọn.
class ParkingLotPicker extends StatelessWidget {
  final AsyncCubit<List<ParkingLotModel>> lots;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const ParkingLotPicker({
    super.key,
    required this.lots,
    required this.selectedId,
    required this.onSelected,
  });

  Future<void> _open(BuildContext context, List<ParkingLotModel> items) async {
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Chọn bãi đỗ', style: PbmsText.title),
        children: [
          for (final l in items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l.id),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    l.id == selectedId ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: l.id == selectedId ? PbmsTokens.teal : PbmsTokens.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name, style: PbmsText.bodyStrong),
                        if (l.location.trim().isNotEmpty)
                          Text(l.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: PbmsText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (id != null) onSelected(id);
  }

  @override
  Widget build(BuildContext context) {
    return PbmsAsync<List<ParkingLotModel>>(
      cubit: lots,
      loadingHeight: 56,
      errorTitle: 'Không tải được danh sách bãi',
      isEmpty: (d) => d.isEmpty,
      empty: const PbmsEmptyView(icon: Icons.local_parking_rounded, title: 'Chưa có bãi đỗ nào'),
      builder: (items) {
        final chosen = items.where((l) => l.id == selectedId).firstOrNull;
        final single = items.length == 1;
        return Material(
          color: chosen == null ? Colors.white : PbmsTokens.tealTint,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: single ? null : () => _open(context, items),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: chosen == null ? PbmsTokens.border : PbmsTokens.teal),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: PbmsTokens.teal, size: 21),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chosen?.name ?? 'Chọn bãi đỗ', style: PbmsText.bodyStrong),
                        const SizedBox(height: 2),
                        Text(
                          single
                              ? 'Hiện hệ thống có một bãi'
                              : (chosen == null ? '${items.length} bãi, chạm để chọn' : 'Chạm để đổi bãi'),
                          style: PbmsText.caption,
                        ),
                      ],
                    ),
                  ),
                  if (!single) const Icon(Icons.expand_more_rounded, color: PbmsTokens.muted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hộp thoại chọn ô: các ô trống nhóm theo tầng, chạm một ô là chọn và đóng.
class _SlotDialog extends StatelessWidget {
  final List<ParkingSlotModel> slots;
  final String? selectedId;

  const _SlotDialog({required this.slots, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final byFloor = <String, List<ParkingSlotModel>>{};
    for (final s in slots) {
      byFloor.putIfAbsent(s.floorName, () => []).add(s);
    }
    for (final list in byFloor.values) {
      list.sort((a, b) => a.slotCode.compareTo(b.slotCode));
    }
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Chọn ô đỗ cố định', style: PbmsText.title),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: PbmsTokens.muted),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                    'Ô này giữ riêng cho xe của bạn trong suốt thời hạn vé.',
                    style: PbmsText.caption),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in byFloor.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${entry.key}, ${entry.value.length} ô trống',
                              style: PbmsText.label),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in entry.value)
                              ChoiceChip(
                                label: Text(s.slotCode),
                                selected: selectedId == s.slotId,
                                selectedColor: PbmsTokens.tealTint,
                                showCheckmark: false,
                                side: BorderSide(
                                    color: selectedId == s.slotId
                                        ? PbmsTokens.teal
                                        : PbmsTokens.border),
                                labelStyle: PbmsText.figure(13),
                                onSelected: (_) => Navigator.pop(context, s.slotId),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
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
      PbmsSheetFrame.show<PaymentLinkModel>(
          context, (_) => RenewPassSheet(pass: pass, packages: packages));

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
    final same = widget.packages
        .where((p) => p.packageName == widget.pass.packageName);
    _packageId =
        (same.isNotEmpty ? same.first : widget.packages.firstOrNull)?.packageId;
  }

  Future<void> _submit() async {
    final id = _packageId;
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final link = await context
          .read<PbmsRepository>()
          .renewSubscription(widget.pass.subscriptionId, id);
      if (mounted) Navigator.pop(context, link);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final end = widget.pass.endDate;
    return PbmsSheetFrame(
      title: 'Gia hạn vé tháng',
      subtitle:
          'Xe ${widget.pass.licensePlate}${end == null ? '' : ', hết hạn ${DateFormatter.formatDate(end)}'}',
      children: [
        if (widget.packages.isEmpty)
          const PbmsEmptyView(
            icon: Icons.inventory_2_outlined,
            title: 'Chưa có gói phù hợp',
            message: 'Bãi chưa mở gói gia hạn cho loại xe này.',
          )
        else
          for (final p in widget.packages) ...[
            PlanOption(
              selected: _packageId == p.packageId,
              title: p.packageName,
              subtitle: 'Thêm ${p.durationMonths} tháng',
              price: CurrencyFormatter.format(p.price),
              onTap: () => setState(() => _packageId = p.packageId),
            ),
            const SizedBox(height: 8),
          ],
        _inlineError(_error),
        const SizedBox(height: 14),
        PbmsPrimaryButton(
          label: 'Gia hạn và thanh toán',
          busy: _busy,
          onPressed: _packageId == null ? null : _submit,
        ),
      ],
    );
  }
}

// --------------------------------------------------------- renewal history

class RenewalHistorySheet extends StatefulWidget {
  final MonthlySubscriptionModel pass;

  const RenewalHistorySheet({super.key, required this.pass});

  static Future<void> show(BuildContext context, MonthlySubscriptionModel pass) =>
      PbmsSheetFrame.show<void>(context, (_) => RenewalHistorySheet(pass: pass));

  @override
  State<RenewalHistorySheet> createState() => _RenewalHistorySheetState();
}

class _RenewalHistorySheetState extends State<RenewalHistorySheet> {
  late final _items = AsyncCubit(() => context
      .read<PbmsRepository>()
      .getRenewals(widget.pass.subscriptionId));

  @override
  void dispose() {
    _items.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Lịch sử gia hạn',
      subtitle: '${widget.pass.packageName}, xe ${widget.pass.licensePlate}',
      children: [
        PbmsAsync<List<RenewalModel>>(
          cubit: _items,
          loadingHeight: 120,
          isEmpty: (d) => d.isEmpty,
          empty: const PbmsEmptyView(
            icon: Icons.history_toggle_off_rounded,
            title: 'Chưa gia hạn lần nào',
          ),
          builder: (items) => Column(
            children: [
              for (final r in items)
                PbmsDetailRow(
                  icon: Icons.autorenew_rounded,
                  label:
                      '${DateFormatter.formatDate(r.oldEndDate)} đến ${DateFormatter.formatDate(r.newEndDate)}',
                  value: CurrencyFormatter.format(r.amount),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- vehicle change

class VehicleChangeSheet extends StatefulWidget {
  final MonthlySubscriptionModel? pass;
  final VehicleChangeRequestModel? request;

  const VehicleChangeSheet({super.key, this.pass, this.request});

  static Future<bool?> show(BuildContext context, MonthlySubscriptionModel pass) =>
      PbmsSheetFrame.show<bool>(context, (_) => VehicleChangeSheet(pass: pass));

  static Future<bool?> edit(
          BuildContext context, VehicleChangeRequestModel request) =>
      PbmsSheetFrame.show<bool>(
          context, (_) => VehicleChangeSheet(request: request));

  @override
  State<VehicleChangeSheet> createState() => _VehicleChangeSheetState();
}

class _VehicleChangeSheetState extends State<VehicleChangeSheet> {
  final _form = GlobalKey<FormState>();
  late final _plate =
      TextEditingController(text: widget.request?.newLicensePlate ?? '');
  late final _reason =
      TextEditingController(text: widget.request?.reason ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    _reason.dispose();
    super.dispose();
  }

  String get _oldPlate =>
      widget.pass?.licensePlate ?? widget.request?.oldLicensePlate ?? '';

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final repo = context.read<PbmsRepository>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final request = widget.request;
      if (request != null) {
        await repo.updateVehicleChangeRequest(
          requestId: request.requestId,
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
    return PbmsSheetFrame(
      title: widget.request == null ? 'Đổi biển số xe' : 'Sửa yêu cầu đổi biển',
      subtitle: 'Biển số hiện tại: $_oldPlate. Quản lý bãi sẽ duyệt yêu cầu.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Biển số mới', style: PbmsText.label),
              const SizedBox(height: 6),
              PlateField(controller: _plate),
              const SizedBox(height: 14),
              const Text('Lý do', style: PbmsText.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reason,
                maxLines: 3,
                maxLength: 500,
                decoration: pbmsInputDecoration(hint: 'Ví dụ: đổi xe mới'),
                validator: (v) => (v ?? '').trim().length < 5
                    ? 'Nhập lý do (ít nhất 5 ký tự)'
                    : null,
              ),
            ],
          ),
        ),
        _inlineError(_error),
        const SizedBox(height: 14),
        PbmsPrimaryButton(
          label: widget.request == null ? 'Gửi yêu cầu' : 'Lưu thay đổi',
          busy: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
