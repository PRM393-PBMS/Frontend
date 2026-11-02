import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';
import 'package:prm393_frontend/features/payments/receipt_sheet.dart';

void main() {
  test('mã khuyến mãi: chỉ tặng khi nạp đủ mức', () {
    final p = PromoCodeModel.fromJson({'code': 'NAP500K', 'minTopUp': 500000, 'bonusAmount': 50000});
    expect(p.bonusFor(499000), 0);
    expect(p.bonusFor(500000), 50000);
    expect(p.bonusValidDays, 30);
  });

  test('hoá đơn GTGT: kiểm tra mã số thuế, email; nạp ví không xuất', () {
    expect(ReceiptSheet.validateInvoice('ABC', '0312345678', 'HCM', 'kt@abc.vn'), isNull);
    expect(ReceiptSheet.validateInvoice('ABC', '0312345678-001', 'HCM', 'kt@abc.vn'), isNull);
    expect(ReceiptSheet.validateInvoice('ABC', '123', 'HCM', 'kt@abc.vn'), contains('Mã số thuế'));
    expect(ReceiptSheet.validateInvoice('ABC', '0312345678', 'HCM', 'abc'), contains('Email'));
    expect(ReceiptSheet.validateInvoice('', '0312345678', 'HCM', 'kt@abc.vn'), contains('tên công ty'));
    const topUp = PaymentModel(paymentId: 'p', amount: 1, paymentMethod: 'PayOS', paymentType: 'WalletTopUp', paymentStatus: 'Success');
    const fee = PaymentModel(paymentId: 'p', amount: 1, paymentMethod: 'PayOS', paymentType: 'CheckoutFee', paymentStatus: 'Success');
    expect(ReceiptSheet.canInvoice(topUp), isFalse);
    expect(ReceiptSheet.canInvoice(fee), isTrue);
  });

  test('chỗ trống: tầng gắn đúng bãi, tầng cư dân được đánh dấu', () async {
    FacilityAvailabilityModel floor(String lot, String name, {bool resident = false}) => FacilityAvailabilityModel.fromJson({
          'parkingId': lot, 'floorId': name, 'floorName': name, 'isResident': resident,
          'vehicleTypeId': 'vt', 'vehicleTypeName': 'Ô tô', 'totalSlots': 10, 'availableSlots': 4,
        });
    final lots = await LotView.load(
      lots: () async => [
        ParkingLotModel.fromJson({'parkingId': 'A', 'name': 'Bãi A', 'location': 'Q1'}),
        ParkingLotModel.fromJson({'parkingId': 'B', 'name': 'Bãi B', 'location': 'Q3'}),
      ],
      facility: () async => [floor('A', 'B1'), floor('A', 'B2', resident: true), floor('B', 'Tầng 1')],
      pricing: () async => const [],
    );
    expect(lots.firstWhere((l) => l.id == 'A').floors.map((f) => f.floorName), ['B1', 'B2']);
    expect(lots.firstWhere((l) => l.id == 'A').floors.last.isResident, isTrue);
    expect(lots.firstWhere((l) => l.id == 'B').floors.single.floorName, 'Tầng 1');
  });

  test('chỗ trống: không tải được số theo tầng thì vẫn hiện bãi', () async {
    final lots = await LotView.load(
      lots: () async => [ParkingLotModel.fromJson({'parkingId': 'A', 'name': 'Bãi A', 'location': 'Q1'})],
      facility: () async => throw Exception('mạng lỗi'),
      pricing: () async => const [],
    );
    expect(lots.single.floors, isEmpty);
  });
}
