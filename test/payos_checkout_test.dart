import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/widgets/payos_checkout_screen.dart';

void main() {
  PayosOutcome? outcome(String url) => PayosCheckoutScreen.outcomeOf(Uri.parse(url));

  group('Nhận ra trang PayOS chuyển về', () {
    test('returnUrl của máy chủ: thanh toán xong', () {
      final o = outcome('https://prm393backend.onrender.com/payment/success'
          '?code=00&id=abc&cancel=false&status=PAID&orderCode=1729300000000');
      expect(o, isNotNull);
      expect(o!.cancelled, isFalse);
      expect(o.orderCode, '1729300000000');
      expect(o.status, 'PAID');
    });

    test('cancelUrl: khách huỷ', () {
      final o = outcome('https://prm393backend.onrender.com/payment/cancel'
          '?code=00&id=abc&cancel=true&status=CANCELLED&orderCode=1');
      expect(o!.cancelled, isTrue);
    });

    test('địa chỉ cũ / trang không tồn tại vẫn chặn được nhờ tham số PayOS', () {
      expect(outcome('http://localhost:5173/payment-success?status=PAID&orderCode=1')!.cancelled, isFalse);
      expect(outcome('https://example.com/xyz?cancel=true&orderCode=1')!.cancelled, isTrue);
    });

    test('trang của PayOS và trang khác thì cho tải bình thường', () {
      expect(outcome('https://pay.payos.vn/web/abc?orderCode=1&status=PENDING'), isNull);
      expect(outcome('https://dl.vietqr.io/pay?app=vcb'), isNull);
      expect(outcome('intent://pay#Intent;scheme=vcb;end'), isNull);
    });
  });

  test('tách link intent:// của app ngân hàng', () {
    final r = PayosCheckoutScreen.parseIntentUrl('intent://pay?amount=1000#Intent;scheme=vcbpay;'
        'package=com.VCB;S.browser_fallback_url=https%3A%2F%2Fvcb.com.vn%2Fapp;end');
    expect(r.target.toString(), 'vcbpay://pay?amount=1000');
    expect(r.package, 'com.VCB');
    expect(r.fallback.toString(), 'https://vcb.com.vn/app');
  });
}
