import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/map/data/lot_layout.dart';
import 'package:prm393_frontend/features/map/presentation/lot_iso_painter.dart';
import 'package:prm393_frontend/features/map/presentation/lot_map_screen.dart';
import 'package:prm393_frontend/features/staff/data/staff_models.dart';

ParkingSlotModel _slot(String floorId, String code, String status, {String type = 'Ô tô'}) => ParkingSlotModel(
      slotId: '$floorId-$code',
      parkingId: 'lot-1',
      vehicleTypeName: type,
      floorId: floorId,
      floorName: floorId,
      slotCode: code,
      vehicleTypeId: type,
      status: status,
      isResident: false,
    );

/// Bãi mẫu: cổng vào ở Tầng 1 (xe máy, không chia ô); ô tô ở B1 (khu A, B) và B2 (cư dân).
List<LotLayout> _sample() => LotLayout.buildAll(
      floors: [
        {'floorId': 'T1', 'parkingId': 'lot-1', 'floorName': 'Tầng 1', 'dedicatedVehicleTypeName': 'Xe máy', 'totalCapacity': 80},
        {'floorId': 'B1', 'parkingId': 'lot-1', 'floorName': 'B1', 'totalCapacity': 14},
        {'floorId': 'B2', 'parkingId': 'lot-1', 'floorName': 'B2', 'isResident': true, 'totalCapacity': 6},
      ],
      slots: [
        for (var i = 1; i <= 8; i++) _slot('B1', 'A${i.toString().padLeft(2, '0')}', i.isEven ? 'Occupied' : 'Available'),
        for (var i = 1; i <= 6; i++) _slot('B1', 'B${i.toString().padLeft(2, '0')}', i <= 4 ? 'Occupied' : 'Available'),
        for (var i = 1; i <= 6; i++) _slot('B2', 'R${i.toString().padLeft(2, '0')}', i == 1 ? 'Available' : 'Assigned'),
      ],
      gates: const [
        GateModel(gateId: 'g1', gateName: 'Cổng 1', gateType: 'Entry', floorName: 'Tầng 1', floorId: 'T1'),
        GateModel(gateId: 'g2', gateName: 'Cổng ra', gateType: 'Exit', floorName: 'Tầng 1', floorId: 'T1'),
      ],
      availability: const [
        FacilityAvailabilityModel(
            floorId: 'T1', floorName: 'Tầng 1', vehicleTypeId: 'm', vehicleTypeName: 'Xe máy',
            totalSlots: 80, availableSlots: 35, occupiedSlots: 45, assignedSlots: 0),
      ],
    );

void main() {
  test('mã ô -> khu và số; tên tầng -> thứ tự từ dưới lên', () {
    expect(slotZone('A01'), 'A');
    expect(slotZone('B1-A01'), 'B1-A');
    expect(slotZone('001'), '');
    expect(slotNumber('A12'), 12);
    expect(floorLevel('B2') < floorLevel('B1'), isTrue);
    expect(floorLevel('Hầm 1'), -1);
    expect(floorLevel('Tầng 2'), 2);
    expect(_sample().single.floors.map((f) => f.name), ['B2', 'B1', 'Tầng 1']);
  });

  test('khu chia đúng, ô trong khu theo số', () {
    final b1 = _sample().single.floors[1];
    expect(b1.zones.map((z) => z.name), ['A', 'B']);
    expect(b1.zones.first.slots.map((s) => s.code).take(3), ['A01', 'A02', 'A03']);
    expect(b1.free, 4 + 2);
  });

  test('có ô của lượt gửi: cổng đã vào -> xuống B1 -> khu A -> ô A05', () {
    final guide = buildGuide(_sample().single, targetSlotCode: 'a05', entryGateName: 'Cổng 1');
    expect(guide.slot?.code, 'A05');
    expect(guide.floor?.name, 'B1');
    expect(guide.steps, [
      'Bạn đã vào bãi qua cổng Cổng 1.',
      'Theo dốc/thang xuống B1.',
      'Tới khu A: ô A05 là ô thứ 5/8 tính từ lối đi chính.',
      'Đỗ vào ô A05 (ô nhấp nháy trên sơ đồ).',
    ]);
  });

  test('chưa vào bãi, ô tô: gợi ý tầng và khu còn nhiều chỗ, bỏ tầng cư dân', () {
    final guide = buildGuide(_sample().single);
    expect(guide.gate?.gateName, 'Cổng 1');
    expect(guide.floor?.name, 'B1');
    expect(guide.zone?.name, 'A');
    expect(guide.steps[1], 'Theo dốc/thang xuống B1, còn 6 chỗ ô tô.');
  });

  test('xe máy: tầng không chia ô, đếm theo sức chứa', () {
    final guide = buildGuide(_sample().single, car: false);
    expect(guide.floor?.name, 'Tầng 1');
    expect(guide.steps[1], 'Ở ngay Tầng 1, còn 35 chỗ xe máy.');
  });

  test('ô không có trên sơ đồ thì báo hỏi nhân viên', () {
    final guide = buildGuide(_sample().single, targetSlotCode: 'Z99');
    expect(guide.slot, isNull);
    expect(guide.steps.single, contains('Hỏi nhân viên'));
  });

  test('chọn bãi theo cổng khách đã vào khi không có id', () {
    final other = LotLayout('lot-2', const []);
    final lots = [other, ..._sample()];
    expect(LotMapScreen.pickLot(lots, entryGateName: 'cổng 1')?.parkingId, 'lot-1');
    expect(LotMapScreen.pickLot(lots, lotId: 'lot-2')?.parkingId, 'lot-2');
  });

  testWidgets('vẽ được sơ đồ có đường đi (lưu ảnh khi đặt LOT_MAP_PNG)', (tester) async {
    final lot = _sample().single;
    final guide = buildGuide(lot, targetSlotCode: 'A05', entryGateName: 'Cổng 1');
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
              child: CustomPaint(painter: LotIsoPainter(lot: lot, selectedFloorId: 'B1', guide: guide, t: 0.3)),
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final out = Platform.environment['LOT_MAP_PNG'];
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
