import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/signature_pad.dart';

void main() {
  group('Hợp đồng vé tháng', () {
    test('Đăng ký gói >= 3 tháng trả về hợp đồng cần ký, không có link', () {
      final r = RegistrationResultModel.fromJson({
        'subscriptionId': 's1',
        'requiresContract': true,
        'contractId': 'c1',
        'contractNumber': 'HD-20261017-ABC123',
        'amount': 4860000,
      });
      expect(r.requiresContract, isTrue);
      expect(r.contractId, 'c1');
      expect(r.link, isNull);
    });

    test('Gói 1 tháng vẫn trả link PayOS như cũ', () {
      final r = RegistrationResultModel.fromJson({
        'subscriptionId': 's2',
        'paymentId': 'p2',
        'paymentUrl': 'https://pay.payos.vn/web/x',
        'orderCode': '1',
        'amount': 1800000,
      });
      expect(r.requiresContract, isFalse);
      expect(r.link?.hasUrl, isTrue);
    });

    test('Vé chờ ký: needsSignature; đã ký: còn hợp đồng để xem', () {
      MonthlySubscriptionModel sub(String? status) => MonthlySubscriptionModel.fromJson({
            'subscriptionId': 's1',
            'licensePlate': '51K12345',
            'vehicleType': 'Ô tô',
            'packageName': 'Gói 6 tháng',
            'price': 9000000,
            'status': 'PendingPayment',
            'durationMonths': 6,
            'contractId': 'c1',
            'contractStatus': status,
          });
      expect(sub('PendingSignature').needsSignature, isTrue);
      expect(sub('Signed').needsSignature, isFalse);
      expect(sub('Signed').hasContract, isTrue);
    });

    test('Ký xong: đọc Contract và Payment (khoá PascalCase)', () {
      final r = SignContractResultModel.fromJson({
        'Contract': {
          'contractId': 'c1',
          'subscriptionId': 's1',
          'contractNumber': 'HD-20261017-ABC123',
          'content': 'HỢP ĐỒNG',
          'contentHash': 'abc',
          'status': 'Signed',
          'signedAt': '2026-10-17T07:00:00.000Z',
        },
        'Payment': {'paymentUrl': 'https://pay.payos.vn/web/y', 'orderCode': '9', 'amount': 9000000},
        'PaymentError': null,
      });
      expect(r.contract.isSigned, isTrue);
      expect(r.payment?.orderCode, '9');
      expect(r.paymentError, isNull);
    });

    test('Kết quả kiểm tra niêm phong', () {
      final v = ContractVerificationModel.fromJson({
        'valid': false,
        'contentIntact': false,
        'signatureIntact': true,
        'sealValid': false,
        'keyMatches': true,
      });
      expect(v.valid, isFalse);
      expect(v.contentIntact, isFalse);
      expect(v.signatureIntact, isTrue);
    });
  });

  testWidgets('Bảng ký: cần đủ nét, xuất được PNG, xoá được', (tester) async {
    final controller = SignatureController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SignaturePad(controller: controller)),
    ));
    expect(controller.hasSignature, isFalse);

    final pad = tester.getRect(find.byType(SignaturePad));
    final gesture = await tester.startGesture(pad.center - const Offset(80, 0));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(8, 2));
    }
    await gesture.up();
    await tester.pump();
    expect(controller.hasSignature, isTrue);

    final png = await tester.runAsync(controller.toPng);
    expect(png, isNotNull);
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);

    controller.clear();
    expect(controller.hasSignature, isFalse);
  });
}
