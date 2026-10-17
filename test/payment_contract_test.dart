import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';

void main() {
  test('Thanh toán trước bằng PayOS: đọc OnlinePayment và số tiền từ Payment', () {
    final r = PrepayResultModel.fromJson({
      'Payment': {'paymentId': 'pay-1', 'amount': 25000},
      'OnlinePayment': {
        'paymentUrl': 'https://pay.payos.vn/web/abc',
        'paymentLinkId': 'abc',
        'orderCode': '1792216717',
      },
      'Fee': {'amount': 25000},
    });
    expect(r.exitPass, isNull);
    expect(r.online?.paymentUrl, 'https://pay.payos.vn/web/abc');
    expect(r.online?.orderCode, '1792216717');
    expect(r.online?.amount, 25000);
  });

  test('Thanh toán bằng ví: nhận mã ra cổng và số dư mới', () {
    final r = PrepayResultModel.fromJson({
      'ExitPass': {
        'code': 'ABC234',
        'qrPayload': 'PBMS-EXIT:11111111-2222-3333-4444-555555555555:ABC234',
        'prepaidAt': '2026-10-17T06:00:00.000Z',
      },
      'WalletBalance': 75000,
    });
    expect(r.exitPass?.code, 'ABC234');
    expect(r.exitPass?.qrPayload, startsWith('PBMS-EXIT:'));
    expect(r.walletBalance, 75000);
  });

  test('Phiên gửi xe đọc exitPass, null khi chưa trả trước', () {
    final base = {
      'sessionId': 's1',
      'licensePlateIn': '51K12345',
      'entryTime': '2026-10-17T05:00:00.000Z',
      'status': 'Active',
    };
    expect(ParkingSessionModel.fromJson(base).isPrepaid, isFalse);
    final paid = ParkingSessionModel.fromJson({
      ...base,
      'exitPass': {'code': 'XY7K9M', 'qrPayload': 'PBMS-EXIT:s1:XY7K9M'},
    });
    expect(paid.isPrepaid, isTrue);
    expect(paid.exitPass?.code, 'XY7K9M');
  });

  test('Ví: số dư, giao dịch nạp/trả và lệnh nạp đang chờ', () {
    final w = WalletModel.fromJson({
      'balance': 120000,
      'transactions': [
        {'transactionId': 't1', 'type': 'TopUp', 'amount': 200000, 'balanceAfter': 200000,
          'createdAt': '2026-10-17T04:00:00.000Z'},
        {'transactionId': 't2', 'type': 'Payment', 'amount': 80000, 'balanceAfter': 120000,
          'createdAt': '2026-10-17T05:00:00.000Z'},
      ],
      'pendingTopUps': [{'paymentId': 'p'}],
      'topUpMin': 10000,
      'topUpMax': 5000000,
    });
    expect(w.balance, 120000);
    expect(w.transactions.first.isTopUp, isTrue);
    expect(w.transactions.last.isTopUp, isFalse);
    expect(w.pendingTopUps, 1);
  });
}
