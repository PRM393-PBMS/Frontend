import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prm393_frontend/core/widgets/parking/exit_qr_screen.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/history/presentation/widgets/exit_payment_sheet.dart';
import 'package:prm393_frontend/features/staff/data/staff_models.dart';
import 'package:prm393_frontend/features/staff/presentation/scan_verdict.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  testWidgets('đã trả trước: ra cổng bằng biển số, mã QR chỉ là dự phòng', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ExitPassCard(
            pass: ExitPassModel(code: 'AB23CD', qrPayload: 'PBMS-EXIT:s1:AB23CD', prepaidAt: DateTime(2026, 11, 2, 9)),
            plate: '51A12345',
          ),
        ),
      ),
    ));

    expect(find.text('Ra cổng bằng biển số'), findsOneWidget);
    expect(find.text('51A-123.45'), findsOneWidget);
    // Mã chữ không còn là nội dung chính của thẻ.
    expect(find.text('AB23CD'), findsNothing);

    await tester.tap(find.text('Mã QR dự phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(ExitQrScreen), findsOneWidget);
    expect(find.text('Mã QR dự phòng ra cổng'), findsOneWidget);
    expect(find.text('AB23CD'), findsOneWidget);
    expect(find.text('Camera không đọc được biển số'), findsOneWidget);
  });

  test('máy quét staff: xe đã đăng ký gửi 1 lần', () {
    final scan = GateScanModel.fromJson({
      'gateScanId': 'g1',
      'gateId': 'gate',
      'licensePlate': '51H12345',
      'suggestedType': 'EntryPass',
      'status': 'New',
      'createdAt': '2026-11-02T02:00:00.000Z',
    });
    expect(ScanVerdict.of(scan).label, 'Đã đăng ký gửi 1 lần');
  });
}
