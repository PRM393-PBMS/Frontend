import 'package:equatable/equatable.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_read.dart';
import '../../payments/data/payment_models.dart';

/// Giới hạn nạp ví phía backend (số nguyên VND).
class WalletLimits {
  WalletLimits._();
  static const int minTopUp = 2000;
  static const int maxTopUp = 10000000;
}

class WalletTransaction extends Equatable {
  final String id;
  final bool isCredit;
  final String type;
  final double absoluteAmount;
  final double balanceAfter;
  final DateTime? createdAt;
  final String? packageName;
  final String? licensePlate;
  final String? orderCode;

  const WalletTransaction({
    required this.id,
    required this.isCredit,
    required this.type,
    required this.absoluteAmount,
    required this.balanceAfter,
    required this.createdAt,
    required this.packageName,
    required this.licensePlate,
    required this.orderCode,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) =>
      WalletTransaction(
        id: j.str('walletTransactionId'),
        isCredit: j.str('direction').toLowerCase() == 'credit',
        type: j.str('type'),
        absoluteAmount:
            j.numberOrNull('absoluteAmount') ?? j.number('amount').abs(),
        balanceAfter: j.number('balanceAfter'),
        createdAt: j.date('createdAt'),
        packageName: j.strOrNull('packageName'),
        licensePlate: j.strOrNull('licensePlate'),
        orderCode: j.strOrNull('orderCode'),
      );

  @override
  List<Object?> get props => [id, balanceAfter];
}

class Wallet extends Equatable {
  final String id;
  final double balance;
  final List<WalletTransaction> transactions;

  const Wallet(
      {required this.id, required this.balance, this.transactions = const []});

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        id: j.str('walletId'),
        balance: j.number('walletBalance'),
        transactions:
            ApiClient.parseList(j['transactions'], WalletTransaction.fromJson),
      );

  @override
  List<Object?> get props => [id, balance, transactions];
}

class WalletRepository {
  final ApiClient _api;

  WalletRepository(this._api);

  /// Mở ví (tạo nếu chưa có) và trả về mã ví + số dư. Gọi nhiều lần vẫn an toàn.
  Future<Wallet> ensure() async {
    final res = await _api.post<dynamic>(ApiEndpoints.wallet);
    return Wallet.fromJson(res.result as Map<String, dynamic>);
  }

  /// Số dư và lịch sử giao dịch gần nhất (tối đa 200).
  Future<Wallet> mine() async {
    final opened = await ensure();
    final res = await _api.get<dynamic>(ApiEndpoints.walletById(opened.id));
    return Wallet.fromJson(res.result as Map<String, dynamic>);
  }

  /// Tạo liên kết nạp ví qua PayOS. Số dư chỉ tăng sau khi PayOS xác nhận.
  Future<PaymentLink> topUp(String walletId, int amount) async {
    final res = await _api.post<dynamic>(
      ApiEndpoints.walletTopUp(walletId),
      data: {'amount': amount},
    );
    return PaymentLink.fromJson(res.result as Map<String, dynamic>);
  }
}
