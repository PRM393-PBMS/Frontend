import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/widgets/pbms_bottom_bar.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/promo_carousel.dart';
import 'package:prm393_frontend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('PbmsPlate', () {
    test('xe máy tách 2 dòng, ô tô 1 dòng, chuỗi lạ giữ nguyên', () {
      expect(PbmsPlate.lines('59-X2 123.45', isMotorbike: true), ['59-X2', '123.45']);
      expect(PbmsPlate.lines('59x21234', isMotorbike: true), ['59-X2', '1234']);
      expect(PbmsPlate.lines('51A12345', isMotorbike: false), ['51A-123.45']);
      expect(PbmsPlate.lines('51LD-123.45', isMotorbike: false), ['51LD-123.45']);
      expect(PbmsPlate.lines('NG-01', isMotorbike: false), ['NG-01']);
    });

    testWidgets('vẽ đúng số dòng và đọc được bằng trình đọc màn hình', (tester) async {
      await tester.pumpWidget(_app(const Center(
        child: PbmsPlate(licensePlate: '59X212345', isMotorbike: true),
      )));
      expect(find.text('59-X2'), findsOneWidget);
      expect(find.text('123.45'), findsOneWidget);
      expect(find.bySemanticsLabel('Biển số 59-X2 123.45'), findsOneWidget);
    });
  });

  testWidgets('bảng LED: còn chỗ hiện số, hết chỗ hiện HẾT', (tester) async {
    await tester.pumpWidget(_app(const PbmsLedCounter(
      entries: [(label: 'Xe máy', available: 128), (label: 'Ô tô', available: 0)],
    )));
    expect(find.text('128'), findsOneWidget);
    expect(find.text('HẾT'), findsOneWidget);
    expect(find.text('đã đầy'), findsOneWidget);
  });

  testWidgets('cuống vé: có thân, cuống và bấm được', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(PbmsTicketStub(
      onTap: () => taps++,
      body: const Text('Thân vé'),
      stub: const Text('Cuống vé'),
    )));
    expect(find.text('Thân vé'), findsOneWidget);
    expect(find.text('Cuống vé'), findsOneWidget);
    await tester.tap(find.text('Thân vé'));
    expect(taps, 1);
  });

  group('mã ra cổng', () {
    testWidgets('mở toàn màn: QR >= 300, có biển số và mã chữ, nút Xong ở nửa dưới', (tester) async {
      _phone(tester);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => PbmsQrDialog.show(
                  context,
                  title: 'Mã ra cổng',
                  payload: 'PBMS-EXIT:abc',
                  plate: '59X212345',
                  isMotorbike: true,
                  code: 'K7M2QX',
                ),
                child: const Text('mở'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();

      expect(find.byType(ExitQrScreen), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.getSize(find.byType(QrImageView)).width, greaterThanOrEqualTo(300));
      expect(find.text('59-X2'), findsOneWidget);
      expect(find.text('K7M2QX'), findsOneWidget);

      final done = find.widgetWithText(FilledButton, 'Xong');
      expect(tester.getCenter(done).dy, greaterThan(844 / 2));
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.byType(ExitQrScreen), findsNothing);
    });

    testWidgets('vuốt xuống cũng đóng', (tester) async {
      _phone(tester);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PbmsQrDialog.show(context, title: 'Vé gửi xe', payload: 'x'),
              child: const Text('mở'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      await tester.fling(find.text('Vé gửi xe'), const Offset(0, 400), 1500);
      await tester.pumpAndSettle();
      expect(find.byType(ExitQrScreen), findsNothing);
    });
  });

  testWidgets('thanh dưới (bản cũ khôi phục): nút ví giữa bấm được, có nhãn cho trình đọc màn hình', (tester) async {
    _phone(tester);
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: PbmsBottomBar(
          currentIndex: 0,
          onTabChanged: (_) {},
          tabs: const [
            NavTab(icon: Icons.local_parking_outlined, activeIcon: Icons.local_parking, label: 'Đặt chỗ'),
            NavTab(icon: Icons.history, activeIcon: Icons.history, label: 'Lịch sử'),
            NavTab(icon: Icons.card_membership, activeIcon: Icons.card_membership, label: 'Vé tháng'),
            NavTab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Cá nhân'),
          ],
          centerIcon: Icons.account_balance_wallet_rounded,
          centerLabel: 'Ví của tôi',
          onCenterTap: () => opened++,
        ),
      ),
    ));
    expect(find.text('Đặt chỗ'), findsOneWidget);
    expect(find.bySemanticsLabel('Ví của tôi'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.account_balance_wallet_rounded));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  test('carousel không tự trượt nếu không truyền interval', () {
    expect(const PromoCarousel(items: []).interval, isNull);
  });

  testWidgets('onboarding: nội dung thật, nút chỉ ghi "Bắt đầu" ở trang cuối', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pump();
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(find.text('Bắt đầu ngay'), findsNothing);
    expect(find.textContaining('ưu đãi'), findsNothing);
    expect(find.text('Ví dụ'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.text('Trả phí trước, quét mã ra cổng'), findsOneWidget);
  });
}
