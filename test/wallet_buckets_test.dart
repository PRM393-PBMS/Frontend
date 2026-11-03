import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/wallet/presentation/screens/wallet_screen.dart';

class _FakeRepo implements PbmsRepository {
  final WalletModel wallet;
  _FakeRepo(this.wallet);

  @override
  Future<WalletModel> getWallet() async => wallet;

  @override
  Future<List<WalletTransactionModel>> getWalletHistory(WalletHistoryFilter filter) async => wallet.transactions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _json = {
  'walletId': 'w1',
  'walletBalance': 150000,
  'cashBalance': 100000,
  'bonusBalance': 50000,
  'bonusExpiresAt': '2026-12-20T05:00:00.000Z',
  'transactions': [
    {
      'walletTransactionId': 't1',
      'direction': 'Credit',
      'type': 'PromoBonus',
      'bucket': 'BONUS',
      'amount': 50000,
      'absoluteAmount': 50000,
      'balanceAfter': 150000,
      'createdAt': '2026-11-03T04:00:00.000Z',
      'description': 'Tặng khuyến mãi nạp ví',
    },
    {
      'walletTransactionId': 't2',
      'direction': 'Credit',
      'type': 'TopUp',
      'bucket': 'CASH',
      'amount': 100000,
      'absoluteAmount': 100000,
      'balanceAfter': 100000,
      'createdAt': '2026-11-03T03:59:00.000Z',
      'description': 'Nạp ví qua PayOS',
    },
  ],
};

void main() {
  setUpAll(() => initializeDateFormatting('vi_VN'));

  test('ví tách ngăn: tiền nạp, khuyến mãi, hạn dùng; giao dịch biết thuộc ngăn nào', () {
    final w = WalletModel.fromJson(_json);
    expect(w.balance, 150000);
    expect(w.cashBalance, 100000);
    expect(w.bonusBalance, 50000);
    // Giữa ngày: múi giờ máy chạy test không làm lệch sang ngày khác.
    expect(w.bonusExpiresAt?.toUtc(), DateTime.utc(2026, 12, 20, 5));
    expect(w.transactions.map((t) => t.isBonus), [true, false]);
  });

  test('máy chủ cũ chưa tách ngăn: toàn bộ là tiền nạp, khuyến mãi 0', () {
    final w = WalletModel.fromJson({'walletId': 'w1', 'walletBalance': 80000});
    expect(w.cashBalance, 80000);
    expect(w.bonusBalance, 0);
    expect(w.bonusExpiresAt, isNull);
  });

  test('lỗi tải lịch sử: vẫn giữ hai ngăn từ bản tóm tắt ví', () {
    final w = WalletModel.fromJson({..._json, 'transactions': const []}, historyError: 'Máy chủ lỗi');
    expect(w.cashBalance, 100000);
    expect(w.bonusBalance, 50000);
    expect(w.historyError, 'Máy chủ lỗi');
  });

  testWidgets('màn ví hiện tổng, tiền nạp, khuyến mãi kèm hạn và nhãn giao dịch khuyến mãi', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepositoryProvider<PbmsRepository>.value(
      value: _FakeRepo(WalletModel.fromJson(_json)),
      child: const MaterialApp(home: WalletScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tiền nạp'), findsOneWidget);
    expect(find.text('Khuyến mãi'), findsOneWidget);
    expect(find.textContaining('Hết hạn 20/12/2026'), findsOneWidget);
    expect(find.textContaining('trừ trước'), findsOneWidget);
    expect(find.textContaining('· Khuyến mãi'), findsOneWidget);
  });

  testWidgets('không có khuyến mãi: khuyến mãi 0 đ, không hiện hạn và lời nhắc trừ trước', (tester) async {
    await tester.pumpWidget(RepositoryProvider<PbmsRepository>.value(
      value: _FakeRepo(WalletModel.fromJson({'walletId': 'w1', 'walletBalance': 80000, 'cashBalance': 80000, 'bonusBalance': 0})),
      child: const MaterialApp(home: WalletScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Khuyến mãi'), findsOneWidget);
    expect(find.textContaining('Hết hạn'), findsNothing);
    expect(find.textContaining('trừ trước'), findsNothing);
  });
}
