import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/widgets/password_confirm_dialog.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/pay_pending_sheet.dart';

Widget _host(Future<Object?> Function(BuildContext) open, void Function(Object?) done) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () async => done(await open(context)), child: const Text('mo')),
        ),
      ),
    );

void main() {
  testWidgets('hộp thoại mật khẩu: bỏ trống báo lỗi, nhập rồi trả mật khẩu', (tester) async {
    Object? got = 'chua';
    await tester.pumpWidget(_host(
      (c) => PasswordConfirmDialog.ask(c, title: 'Huỷ vé tháng?', message: 'm', confirmLabel: 'Huỷ vé'),
      (v) => got = v,
    ));
    await tester.tap(find.text('mo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ vé'));
    await tester.pump();
    expect(find.text('Nhập mật khẩu để xác nhận'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'matkhau123');
    await tester.tap(find.text('Huỷ vé'));
    await tester.pumpAndSettle();
    expect(got, 'matkhau123');
  });

  testWidgets('đơn chờ thanh toán: chọn đổi sang trả bằng ví', (tester) async {
    final pass = MonthlySubscriptionModel.fromJson({
      'subscriptionId': 's1',
      'licensePlate': '51H12345',
      'vehicleType': 'Ô tô',
      'packageName': 'Gói tháng ô tô',
      'price': 1500000,
      'status': 'PendingPayment',
    });
    Object? got;
    await tester.pumpWidget(_host((c) => PayPendingSheet.show(c, pass), (v) => got = v));
    await tester.tap(find.text('mo'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán với PayOS'), findsOneWidget);
    await tester.tap(find.text('Ví PBMS'));
    await tester.pump();
    await tester.tap(find.text('Trả bằng ví'));
    await tester.pumpAndSettle();
    expect(got, 'Wallet');
  });

  test('kết quả gia hạn: ví thì đã kích hoạt, PayOS thì có link', () {
    final wallet = RegistrationResultModel.fromJson({'subscriptionId': 's1', 'paymentMethod': 'Wallet', 'status': 'Active'});
    expect(wallet.activated, isTrue);
    expect(wallet.link, isNull);
    final payos = RegistrationResultModel.fromJson({
      'subscriptionId': 's1',
      'paymentId': 'p1',
      'paymentUrl': 'https://pay.payos.vn/web/x',
      'orderCode': '1',
      'amount': 1500000,
    });
    expect(payos.activated, isFalse);
    expect(payos.link?.hasUrl, isTrue);
  });
}
