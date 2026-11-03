import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/map/data/lot_layout.dart';
import 'package:prm393_frontend/features/map/presentation/lot_iso_painter.dart';
import 'package:prm393_frontend/features/map/presentation/slot_map_picker.dart';

const car = 'vt-car';
const moto = 'vt-moto';

ParkingSlotModel slot(String floor, String code, String status, {String type = car, bool resident = true}) =>
    ParkingSlotModel(
      slotId: '$floor-$code',
      parkingId: 'lot-1',
      vehicleTypeName: type == car ? 'Ô tô' : 'Xe máy',
      floorId: floor,
      floorName: floor,
      slotCode: code,
      vehicleTypeId: type,
      status: status,
      isResident: resident,
    );

LotLayout lot() => LotLayout.buildAll(
      floors: [
        {'floorId': 'B2', 'parkingId': 'lot-1', 'floorName': 'B2', 'isResident': true},
        {'floorId': 'B1', 'parkingId': 'lot-1', 'floorName': 'B1', 'isResident': false},
      ],
      slots: [
        slot('B2', 'R01', 'Available'),
        slot('B2', 'R02', 'Assigned'),
        slot('B2', 'R03', 'Available', type: moto),
        slot('B1', 'A01', 'Available', resident: false),
      ],
      gates: const [],
    ).single;

void main() {
  test('chỉ ô tầng cư dân, còn trống, đúng loại xe là chọn được', () {
    expect(pickableResidentSlots(lot(), car), {'B2-R01': 'R01'});
    expect(pickableResidentSlots(lot(), moto), {'B2-R03': 'R03'});
  });

  testWidgets('chạm vào ô trên sơ đồ: ô hợp lệ thì chọn được, ô đã có người thì không', (tester) async {
    final layout = lot();
    final codes = pickableResidentSlots(layout, car);
    final pick = SlotPickOptions(pickable: codes.containsKey);
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 380,
          height: 360,
          child: CustomPaint(painter: LotIsoPainter(lot: layout, selectedFloorId: 'B2', pick: pick)),
        ),
      ),
    ));
    // Bộ vẽ ghi vùng của 3 ô tầng B2.
    expect(pick.hits.map((h) => h.$2), containsAll(['B2-R01', 'B2-R02', 'B2-R03']));
    Offset centerOf(String id) => pick.hits.firstWhere((h) => h.$2 == id).$1.getBounds().center;
    expect(pick.slotAt(centerOf('B2-R01')), 'B2-R01');
    expect(pick.slotAt(centerOf('B2-R02')), isNull);
    expect(pick.slotAt(const Offset(-50, -50)), isNull);
  });
}
