import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

import '../data/lot_layout.dart';
import '../data/tile_layout.dart';
import 'lot_iso_painter.dart';
import 'tile_iso_painter.dart';

/// Bãi cần vẽ và sơ đồ admin đã xuất bản của bãi đó (null: dùng sơ đồ tự dựng).
typedef _MapData = ({LotLayout? lot, TileLot? tiles});

/// Sơ đồ bãi 2.5D kèm chỉ đường trong bãi. Mở từ thẻ bãi ([lotId]) hoặc từ lượt đang gửi
/// ([targetSlotCode] + [entryGateName]: tìm bãi theo cổng đã vào, dẫn tới đúng ô).
class LotMapScreen extends StatefulWidget {
  final String? lotId;
  final String? lotName;
  final String? targetSlotCode;
  final String? entryGateName;
  final bool car;

  const LotMapScreen({super.key, this.lotId, this.lotName, this.targetSlotCode, this.entryGateName, this.car = true});

  static Future<void> open(BuildContext context,
          {String? lotId, String? lotName, String? targetSlotCode, String? entryGateName, bool car = true}) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LotMapScreen(
              lotId: lotId, lotName: lotName, targetSlotCode: targetSlotCode, entryGateName: entryGateName, car: car)));

  /// Bãi cần vẽ: theo id, rồi theo cổng khách đã vào, rồi theo ô đích, cuối cùng bãi đầu tiên.
  static LotLayout? pickLot(List<LotLayout> lots, {String? lotId, String? entryGateName, String? targetSlotCode}) {
    if (lotId != null) {
      final byId = lots.where((l) => l.parkingId == lotId).firstOrNull;
      if (byId != null) return byId;
    }
    if (entryGateName != null) {
      final byGate = lots
          .where((l) => l.gates.any((g) => g.gateName.toLowerCase() == entryGateName.toLowerCase()))
          .firstOrNull;
      if (byGate != null) return byGate;
    }
    if (targetSlotCode != null) {
      // shortcut: mã ô chỉ duy nhất trong một bãi; trùng mã giữa các bãi thì lấy bãi đầu, cổng vào đã xử lý ở trên.
      final bySlot = lots.where((l) => l.find(targetSlotCode) != null).firstOrNull;
      if (bySlot != null) return bySlot;
    }
    return lots.firstOrNull;
  }

  @override
  State<LotMapScreen> createState() => _LotMapScreenState();
}

class _LotMapScreenState extends State<LotMapScreen> with SingleTickerProviderStateMixin {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _layouts = AsyncCubit<_MapData>(_load);

  Future<_MapData> _load() async {
    final lot = LotMapScreen.pickLot(await _repo.getLotLayouts(),
        lotId: widget.lotId, entryGateName: widget.entryGateName, targetSlotCode: widget.targetSlotCode);
    return (lot: lot, tiles: lot == null ? null : await _repo.getTileLot(lot.parkingId));
  }
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  Timer? _refresh;
  String? _floorId;
  late bool _car = widget.car;

  @override
  void initState() {
    super.initState();
    // Trạng thái ô đổi liên tục: làm mới khi khách đang xem, giữ sơ đồ cũ trong lúc tải.
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _layouts.load());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _pulse.dispose();
    _layouts.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PbmsTokens.surfaceLow,
      appBar: AppBar(title: Text(widget.lotName ?? 'Sơ đồ bãi đỗ')),
      body: BlocBuilder<AsyncCubit<_MapData>, AsyncState<_MapData>>(
        bloc: _layouts,
        builder: (context, state) {
          final data = state.data;
          if (data == null) {
            return state.error != null
                ? PbmsErrorView(title: 'Không tải được sơ đồ bãi', message: state.error!, onRetry: _layouts.load)
                : const PbmsLoadingBox(height: 320);
          }
          final lot = data.lot;
          if (lot == null || lot.floors.isEmpty) {
            return const PbmsEmptyView(
                icon: Icons.map_outlined, title: 'Bãi chưa có sơ đồ', message: 'Admin chưa khai báo tầng và ô đỗ cho bãi này.');
          }
          final tiles = data.tiles;
          final status = {
            for (final f in lot.floors)
              for (final z in f.zones)
                for (final s in z.slots) s.id: s.status.toLowerCase(),
          };
          final carIds = {
            for (final f in lot.floors)
              for (final z in f.zones)
                for (final s in z.slots)
                  if (s.isCar) s.id,
          };
          // Sơ đồ admin vẽ: đường đi thật theo lối đi. Chưa có thì sơ đồ tự dựng theo khu.
          final tileGuide = tiles == null
              ? null
              : buildTileGuide(tiles,
                  targetSlotCode: widget.targetSlotCode,
                  entryGateName: widget.entryGateName,
                  car: _car,
                  slotStatus: status,
                  carSlotIds: carIds);
          final guide = tiles == null
              ? buildGuide(lot, targetSlotCode: widget.targetSlotCode, entryGateName: widget.entryGateName, car: _car)
              : null;
          final chips = <({String id, String label})>[
            if (tiles != null)
              for (final f in tiles.floors.reversed)
                (id: f.floorId, label: _chipLabel(f.floorName, lot.floors.where((l) => l.id == f.floorId).firstOrNull))
            else
              for (final f in lot.floors.reversed) (id: f.id, label: _chipLabel(f.name, f)),
          ];
          final defaultFloor = tiles != null
              ? (tileGuide?.floor?.floorId ?? tiles.floors.first.floorId)
              : (guide!.floor ?? lot.floors.first).id;
          final floorId = chips.any((c) => c.id == _floorId) ? _floorId! : defaultFloor;
          final steps = tileGuide?.steps ?? guide!.steps;
          final targetCode = tileGuide?.slot?.code ?? guide?.slot?.code;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _GuideCard(
                  title: widget.targetSlotCode != null && targetCode != null ? 'Đường tới ô $targetCode' : 'Hướng dẫn vào bãi',
                  steps: steps),
              if (widget.targetSlotCode == null) ...[
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Ô tô'), icon: Icon(Icons.directions_car_rounded)),
                    ButtonSegment(value: false, label: Text('Xe máy'), icon: Icon(Icons.two_wheeler_rounded)),
                  ],
                  selected: {_car},
                  onSelectionChanged: (v) => setState(() {
                    _car = v.first;
                    _floorId = null;
                  }),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in chips)
                    ChoiceChip(
                      label: Text(c.label),
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
                height: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: PbmsTokens.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Semantics(
                  label: 'Sơ đồ bãi. ${steps.join(' ')}',
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => CustomPaint(
                        size: Size.infinite,
                        painter: tiles != null
                            ? TileIsoPainter(
                                lot: tiles, selectedFloorId: floorId, slotStatus: status, guide: tileGuide, t: _pulse.value)
                            : LotIsoPainter(lot: lot, selectedFloorId: floorId, guide: guide, t: _pulse.value),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _Legend(),
              const SizedBox(height: 6),
              Text(
                  tiles != null
                      ? 'Sơ đồ do bãi vẽ. Chụm hai ngón để phóng to.'
                      : 'Sơ đồ minh hoạ theo khu và mã ô, không theo tỉ lệ thật. Chụm hai ngón để phóng to.',
                  style: PbmsText.caption),
            ],
          );
        },
      ),
    );
  }
}

String _chipLabel(String name, LayoutFloor? f) => f == null ? name : '$name · ${f.free}/${f.total}';

class _GuideCard extends StatelessWidget {
  final String title;
  final List<String> steps;

  const _GuideCard({required this.title, required this.steps});

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route_rounded, color: PbmsTokens.teal, size: 20),
              const SizedBox(width: 8),
              Text(title, style: PbmsText.bodyStrong),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: PbmsTokens.tealTint,
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PbmsTokens.teal)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(steps[i], style: PbmsText.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label, style: PbmsText.caption),
        ]);
    return Wrap(spacing: 14, runSpacing: 6, children: [
      item(LotColors.free, 'Trống'),
      item(LotColors.occupied, 'Có xe'),
      item(LotColors.assigned, 'Giữ cho vé tháng'),
      item(LotColors.other, 'Bảo trì/khoá'),
      item(LotColors.target, 'Ô của bạn'),
    ]);
  }
}
