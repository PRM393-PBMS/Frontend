import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/payment/payment_result_screen.dart';

void main() {
  test('đọc kết quả thanh toán từ máy chủ', () {
    final r = PaymentResultModel.fromJson({'state': 'success', 'amount': 50000, 'typeLabel': 'Nạp ví PBMS'});
    expect(r.state, PaymentResultState.success);
    expect(r.amount, 50000);
    expect(PaymentResultModel.fromJson({'state': 'abc'}).state, PaymentResultState.unknown);
  });

  test('bản web: URL PayOS chuyển về thành trang kết quả', () {
    final cancel = PaymentResultScreen.fromUri(Uri.parse('https://app/payment/cancel?orderCode=1&cancel=true&status=CANCELLED'));
    expect(cancel.initialState, PaymentResultState.cancelled);
    expect(cancel.orderCode, '1');
    final ok = PaymentResultScreen.fromUri(Uri.parse('https://app/payment/success?orderCode=2&status=PAID'));
    // Thành công hay chưa do máy chủ xác nhận, URL chỉ là "đang chờ".
    expect(ok.initialState, PaymentResultState.pending);
  });
}
