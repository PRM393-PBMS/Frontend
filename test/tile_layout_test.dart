import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/features/map/data/tile_layout.dart';
import 'package:prm393_frontend/features/map/presentation/tile_iso_painter.dart';

/// Tầng 1 (8x5): cổng vào (0,2), lối đi hàng y=2 tới x=6, dốc xuống B1 ở (7,2).
/// B1 (8x5): dốc (7,2) nối lên Tầng 1, lối đi hàng y=2 chạy sang trái, ô A01..A05 ở hàng y=1, cột ở (3,3), tường hàng y=4.
TileLot sampleLot({String? oneWayAt}) {
  Map<String, dynamic> cell(int x, int y, String t, [Map<String, dynamic> extra = const {}]) => {'x': x, 'y': y, 't': t, ...extra};
  final ground = TileFloor.fromJson({
    'floorId': 'T1',
    'floorName': 'Tầng 1',
    'layout': {
      'w': 8,
      'h': 5,
      'cells': [
        cell(0, 2, 'gate', {'name': 'Cổng 1', 'gateType': 'Entry'}),
        for (var x = 1; x <= 6; x++) cell(x, 2, 'road'),
        cell(7, 2, 'ramp', {'to': 'B1'}),
        cell(2, 1, 'kiosk'),
      ],
    },
  })!;
  final basement = TileFloor.fromJson({
    'floorId': 'B1',
    'floorName': 'B1',
    'layout': {
      'w': 8,
      'h': 5,
      'cells': [
        cell(7, 2, 'ramp', {'to': 'T1'}),
        for (var x = 1; x <= 6; x++) cell(x, 2, 'road', oneWayAt == '$x' ? {'dir': 'E'} : const {}),
        for (var x = 1; x <= 5; x++) cell(x, 1, 'slot', {'code': 'A0$x', 'slotId': 's$x'}),
        cell(3, 3, 'pillar'),
        for (var x = 0; x < 8; x++) cell(x, 4, 'wall'),
      ],
    },
  })!;
  return TileLot([ground, basement]);
}

void main() {
  test('tầng xếp từ dưới lên, tìm được ô theo mã', () {
    final lot = sampleLot();
    expect(lot.floors.map((f) => f.floorName), ['B1', 'Tầng 1']);
    expect(lot.findSlot('a02')?.cell.slotId, 's2');
  });

  test('đường tới A02: qua cổng, xuống dốc, đi theo lối đi, ô ở bên tay phải', () {
    final guide = buildTileGuide(sampleLot(), targetSlotCode: 'A02', entryGateName: 'Cổng 1');
    expect(guide.path.first, (floorId: 'T1', x: 0, y: 2));
    expect(guide.path.last, (floorId: 'B1', x: 2, y: 2));
    expect(guide.steps, [
      'Bạn đã vào bãi qua Cổng 1 (Tầng 1).',
      'Đi 7 ô.',
      'Theo dốc xuống B1.',
      'Đi tiếp 5 ô.',
      'Ô A02 ở bên tay phải. Đỗ vào ô này.',
    ]);
  });

  test('lối một chiều chặn đi ngược: không có đường thì báo hỏi nhân viên', () {
    // Ô lối đi (4,2) ở B1 chỉ cho đi sang phải: xe từ dốc (bên phải) không đi sang trái qua được.
    final guide = buildTileGuide(sampleLot(oneWayAt: '4'), targetSlotCode: 'A02');
    expect(guide.path, isEmpty);
    expect(guide.steps.single, contains('chưa có lối đi tới'));
  });

  test('chưa có ô: dẫn tới ô trống gần cổng nhất cho ô tô', () {
    final guide = buildTileGuide(sampleLot(),
        slotStatus: {'s1': 'available', 's2': 'occupied', 's3': 'occupied', 's4': 'occupied', 's5': 'available'},
        carSlotIds: {'s1', 's2', 's3', 's4', 's5'});
    expect(guide.slot?.code, 'A05');
    expect(guide.steps.last, contains('Ô trống gần cổng nhất: A05 (B1)'));
  });

  test('không còn ô trống thì báo hết chỗ', () {
    final guide = buildTileGuide(sampleLot(), slotStatus: const {}, carSlotIds: {'s1'});
    expect(guide.steps.single, contains('không còn chỗ trống'));
  });

  testWidgets('vẽ sơ đồ thật kèm đường đi (lưu ảnh khi đặt TILE_MAP_PNG)', (tester) async {
    final lot = sampleLot();
    final guide = buildTileGuide(lot, targetSlotCode: 'A02', entryGateName: 'Cổng 1');
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 380,
            height: 360,
            child: ColoredBox(
              color: Colors.white,
              child: CustomPaint(
                painter: TileIsoPainter(
                  lot: lot,
                  selectedFloorId: 'B1',
                  slotStatus: const {'s1': 'available', 's2': 'occupied', 's3': 'assigned', 's4': 'available', 's5': 'maintenance'},
                  guide: guide,
                  t: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final out = Platform.environment['TILE_MAP_PNG'];
    if (out != null) {
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
