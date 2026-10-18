import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/pass_sheets.dart';

/// Chọn một xe đã đăng ký vào tài khoản; có thể thêm xe mới ngay tại chỗ.
/// Đặt chỗ và vé tháng của backend đều gắn với xe (`vehicleId`).
class VehiclePicker extends StatefulWidget {
  final String? selectedId;
  final ValueChanged<VehicleModel?> onChanged;

  /// Chỉ hiện xe thoả điều kiện (vd. chỉ ô tô khi đặt chỗ).
  final bool Function(VehicleModel v)? filter;

  /// Loại xe mặc định khi thêm xe mới (vd. loại của gói vé đang chọn).
  final String? preferredTypeId;

  /// Mô tả khi chưa có xe phù hợp.
  final String emptyMessage;

  const VehiclePicker({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.filter,
    this.preferredTypeId,
    this.emptyMessage = 'Thêm xe để tiếp tục.',
  });

  @override
  State<VehiclePicker> createState() => _VehiclePickerState();
}

class _VehiclePickerState extends State<VehiclePicker> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _vehicles = AsyncCubit(_repo.getMyVehicles);

  @override
  void dispose() {
    _vehicles.close();
    super.dispose();
  }

  List<VehicleModel> _eligible(List<VehicleModel> all) =>
      widget.filter == null ? all : all.where(widget.filter!).toList();

  Future<void> _add() async {
    final added = await AddVehicleSheet.show(context, preferredTypeId: widget.preferredTypeId);
    if (added == null || !mounted) return;
    await _vehicles.load();
    if (widget.filter == null || widget.filter!(added)) widget.onChanged(added);
  }

  @override
  void didUpdateWidget(covariant VehiclePicker old) {
    super.didUpdateWidget(old);
    // Bộ lọc đổi (vd. đổi loại xe của gói): bỏ chọn xe không còn hợp lệ.
    final data = _vehicles.state.data;
    if (data != null && widget.selectedId != null) {
      final ok = _eligible(data).any((v) => v.id == widget.selectedId);
      if (!ok) WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PbmsAsync<List<VehicleModel>>(
      cubit: _vehicles,
      loadingHeight: 66,
      errorTitle: 'Không tải được danh sách xe',
      builder: (all) {
        final items = _eligible(all);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.emptyMessage, style: PbmsText.caption),
              ),
            for (final v in items) ...[
              _VehicleOption(
                vehicle: v,
                selected: v.id == widget.selectedId,
                onTap: () => widget.onChanged(v),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                label: const Text('Thêm xe mới'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PbmsTokens.teal,
                  backgroundColor: PbmsTokens.tealTint,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VehicleOption extends StatelessWidget {
  final VehicleModel vehicle;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleOption({required this.vehicle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? PbmsTokens.tealTint : Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? PbmsTokens.teal : PbmsTokens.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : PbmsTokens.surfaceLow,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    vehicle.isMotorbike ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                    color: PbmsTokens.teal,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.licensePlate, style: PbmsText.bodyStrong),
                      const SizedBox(height: 2),
                      Text(vehicle.vehicleTypeName, style: PbmsText.caption),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? PbmsTokens.teal : PbmsTokens.muted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thêm xe vào tài khoản: chọn loại xe và nhập biển số.
class AddVehicleSheet extends StatefulWidget {
  final String? preferredTypeId;

  const AddVehicleSheet({super.key, this.preferredTypeId});

  static Future<VehicleModel?> show(BuildContext context, {String? preferredTypeId}) =>
      PbmsSheetFrame.show<VehicleModel>(
        context,
        (_) => AddVehicleSheet(preferredTypeId: preferredTypeId),
      );

  @override
  State<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<AddVehicleSheet> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _types = AsyncCubit(_repo.getVehicleTypeOptions);
  final _form = GlobalKey<FormState>();
  final _plate = TextEditingController();
  late String? _typeId = widget.preferredTypeId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _types.close();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final typeId = _typeId;
    if (typeId == null) {
      setState(() => _error = 'Chọn loại xe.');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final v = await _repo.addVehicle(
        vehicleTypeId: typeId,
        licensePlate: normalizePlate(_plate.text),
      );
      if (mounted) Navigator.pop(context, v);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Thêm xe',
      subtitle: 'Camera ở cổng nhận diện xe theo biển số này.',
      children: [
        const Text('Loại xe', style: PbmsText.label),
        const SizedBox(height: 6),
        PbmsAsync<List<VehicleTypeOption>>(
          cubit: _types,
          loadingHeight: 48,
          errorTitle: 'Không tải được loại xe',
          builder: (types) {
            if (_typeId == null && types.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _typeId == null) setState(() => _typeId = types.first.id);
              });
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in types)
                  ChoiceChip(
                    label: Text(t.name),
                    selected: _typeId == t.id,
                    selectedColor: PbmsTokens.tealTint,
                    showCheckmark: false,
                    side: BorderSide(color: _typeId == t.id ? PbmsTokens.teal : PbmsTokens.border),
                    onSelected: (_) => setState(() => _typeId = t.id),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        const Text('Biển kiểm soát', style: PbmsText.label),
        const SizedBox(height: 6),
        Form(key: _form, child: PlateField(controller: _plate)),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 18),
        PbmsPrimaryButton(label: 'Lưu xe', busy: _busy, onPressed: _submit),
      ],
    );
  }
}
