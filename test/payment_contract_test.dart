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

  test('Ví (module wallets): số dư, giao dịch Credit/Debit', () {
    final w = WalletModel.fromJson({
      'walletId': 'w1',
      'userId': 'u1',
      'walletBalance': 120000,
      'transactions': [
        {
          'walletTransactionId': 't1',
          'direction': 'Credit',
          'type': 'TopUp',
          'amount': 200000,
          'absoluteAmount': 200000,
          'balanceAfter': 200000,
          'createdAt': '2026-10-17T04:00:00.000Z',
          'description': 'Nạp ví qua PayOS',
        },
        {
          'walletTransactionId': 't2',
          'direction': 'Debit',
          'type': 'ParkingFee',
          'amount': -80000,
          'absoluteAmount': 80000,
          'balanceAfter': 120000,
          'createdAt': '2026-10-17T05:00:00.000Z',
          'description': 'Thanh toán phí gửi xe bằng ví',
        },
      ],
    });
    expect(w.walletId, 'w1');
    expect(w.balance, 120000);
    expect(w.transactions.first.isTopUp, isTrue);
    expect(w.transactions.last.isTopUp, isFalse);
    expect(w.transactions.last.amount, 80000);
  });

  test('Xe của tôi (/api/vehicles/my)', () {
    final v = VehicleModel.fromJson({
      'vehicleId': 'v1',
      'userId': 'u1',
      'vehicleTypeId': 'vt1',
      'vehicleTypeName': 'Ô tô 2',
      'licensePlate': '51K12345',
    });
    expect(v.id, 'v1');
    expect(v.isCar, isTrue);
    expect(v.isMotorbike, isFalse);
  });

  test('Đăng ký vé trả bằng ví: kích hoạt ngay, không có link PayOS', () {
    final r = RegistrationResultModel.fromJson({
      'subscriptionId': 's1',
      'paymentMethod': 'Wallet',
      'walletBalance': 50000,
      'status': 'Active',
    });
    expect(r.activated, isTrue);
    expect(r.link, isNull);
    expect(r.requiresContract, isFalse);
  });
}
