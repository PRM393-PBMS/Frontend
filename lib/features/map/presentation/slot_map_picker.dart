import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

import '../data/lot_layout.dart';
import '../data/tile_layout.dart';
import 'lot_iso_painter.dart';
import 'lot_map_screen.dart';
import 'tile_iso_painter.dart';

typedef PickedSlot = ({String id, String code});

/// Ô cố định chọn được khi đăng ký vé tháng: tầng cư dân, còn trống, đúng loại xe. Tách riêng để kiểm thử.
Map<String, String> pickableResidentSlots(LotLayout lot, String vehicleTypeId) => {
      for (final f in lot.floors)
        if (f.isResident)
          for (final z in f.zones)
            for (final s in z.slots)
              if (s.isFree && s.vehicleTypeId == vehicleTypeId) s.id: s.code,
    };

typedef _PickerData = ({LotLayout? lot, TileLot? tiles});

/// Chọn ô cố định trên sơ đồ bãi thay vì danh sách mã ô: thấy ô nằm ở tầng nào, gần lối nào.
class SlotMapPicker extends StatefulWidget {
  final String? parkingId;
  final String vehicleTypeId;
  final String? initialSlotId;

  const SlotMapPicker({super.key, this.parkingId, required this.vehicleTypeId, this.initialSlotId});

  static Future<PickedSlot?> open(BuildContext context,
          {String? parkingId, required String vehicleTypeId, String? initialSlotId}) =>
      Navigator.of(context).push<PickedSlot>(MaterialPageRoute(
          builder: (_) =>
              SlotMapPicker(parkingId: parkingId, vehicleTypeId: vehicleTypeId, initialSlotId: initialSlotId)));

  @override
  State<SlotMapPicker> createState() => _SlotMapPickerState();
}

class _SlotMapPickerState extends State<SlotMapPicker> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _data = AsyncCubit<_PickerData>(_load);
  late String? _selected = widget.initialSlotId;
  String? _floorId;
  SlotPickOptions? _pick;

  Future<_PickerData> _load() async {
    final lot = LotMapScreen.pickLot(await _repo.getLotLayouts(), lotId: widget.parkingId);
    return (lot: lot, tiles: lot == null ? null : await _repo.getTileLot(lot.parkingId));
  }

  @override
  void dispose() {
    _data.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PbmsTokens.surfaceLow,
      appBar: AppBar(title: const Text('Chọn ô cố định')),
      body: BlocBuilder<AsyncCubit<_PickerData>, AsyncState<_PickerData>>(
        bloc: _data,
        builder: (context, state) {
          final data = state.data;
          if (data == null) {
            return state.error != null
                ? PbmsErrorView(title: 'Không tải được sơ đồ bãi', message: state.error!, onRetry: _data.load)
                : const PbmsLoadingBox(height: 320);
          }
          final lot = data.lot;
          final codes = lot == null ? const <String, String>{} : pickableResidentSlots(lot, widget.vehicleTypeId);
          if (lot == null || codes.isEmpty) {
            return const PbmsEmptyView(
              icon: Icons.local_parking_rounded,
              title: 'Bãi đã hết ô cố định trống',
              message: 'Chọn bãi khác hoặc gói không cần ô cố định.',
            );
          }
          final tiles = data.tiles;
          // Chỉ các tầng cư dân còn ô trống phù hợp.
          final residentFloors = lot.floors
              .where((f) => f.isResident && f.zones.any((z) => z.slots.any((s) => codes.containsKey(s.id))))
              .toList();
          final chips = <({String id, String name, int free})>[
            for (final f in residentFloors.reversed)
              (id: f.id, name: f.name, free: f.zones.expand((z) => z.slots).where((s) => codes.containsKey(s.id)).length),
          ];
          final floorOfSelected = residentFloors
              .where((f) => f.zones.any((z) => z.slots.any((s) => s.id == _selected)))
              .firstOrNull;
          final floorId = chips.any((c) => c.id == _floorId)
              ? _floorId!
              : (floorOfSelected?.id ?? chips.first.id);
          final status = {
            for (final f in lot.floors)
              for (final z in f.zones)
                for (final s in z.slots) s.id: s.status.toLowerCase(),
          };
          final pick = _pick = SlotPickOptions(selectedSlotId: _selected, pickable: codes.containsKey);
          final selectedCode = codes[_selected];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    const Text('Ô sáng là ô còn trống ở tầng cư dân, đúng loại xe của bạn. Chạm vào ô để chọn.',
                        style: PbmsText.caption),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in chips)
                          ChoiceChip(
                            label: Text('${c.name} · còn ${c.free} ô'),
                            selected: c.id == floorId,
                            showCheckmark: false,
                            selectedColor: PbmsTokens.tealTint,
                            side: BorderSide(color: c.id == floorId ? PbmsTokens.teal : PbmsTokens.border),
                            onSelected: (_) => setState(() => _floorId = c.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 380,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: PbmsTokens.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Semantics(
                        label: 'Sơ đồ chọn ô cố định. Ô đang chọn: ${selectedCode ?? 'chưa chọn'}.',
                        child: InteractiveViewer(
                          maxScale: 5,
                          child: GestureDetector(
                            onTapUp: (d) {
                              final id = _pick?.slotAt(d.localPosition);
                              if (id != null) setState(() => _selected = id);
                            },
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: tiles != null
                                  ? TileIsoPainter(
                                      lot: tiles, selectedFloorId: floorId, slotStatus: status, t: 0.4, pick: pick)
                                  : LotIsoPainter(lot: lot, selectedFloorId: floorId, t: 0.4, pick: pick),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Chụm hai ngón để phóng to khi ô nhỏ.', style: PbmsText.caption),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: PbmsPrimaryButton(
                    label: selectedCode == null ? 'Chạm vào một ô trên sơ đồ' : 'Chọn ô $selectedCode',
                    icon: Icons.check_rounded,
                    onPressed: selectedCode == null
                        ? null
                        : () => Navigator.of(context).pop<PickedSlot>((id: _selected!, code: selectedCode)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
