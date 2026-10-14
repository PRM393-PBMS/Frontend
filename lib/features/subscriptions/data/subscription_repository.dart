import 'package:equatable/equatable.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_read.dart';
import '../../../core/utils/validators.dart';
import '../../payments/data/payment_models.dart';

class MonthlyPass extends Equatable {
  final String id;
  final String licensePlate;
  final String? vehicleType;
  final String? packageName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double price;
  final String status;
  final String? fixedSlot;

  const MonthlyPass({
    required this.id,
    required this.licensePlate,
    required this.vehicleType,
    required this.packageName,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.status,
    required this.fixedSlot,
  });

  factory MonthlyPass.fromJson(Map<String, dynamic> j) => MonthlyPass(
        id: j.str('subscriptionId'),
        licensePlate: j.str('licensePlate'),
        vehicleType: j.strOrNull('vehicleType'),
        packageName: j.strOrNull('packageName'),
        startDate: j.date('startDate'),
        endDate: j.date('endDate'),
        price: j.number('price'),
        status: j.str('status'),
        fixedSlot: j.strOrNull('fixedSlot'),
      );

  String get _s => status.trim().toLowerCase();
  bool get isActive => _s == 'active';
  bool get isPendingPayment => _s == 'pendingpayment';
  bool get isCancelled => _s == 'cancelled';

  /// Còn hiệu lực theo ngày (Active và chưa qua ngày kết thúc).
  bool get isValidNow =>
      isActive && (endDate == null || endDate!.isAfter(DateTime.now()));

  int get daysLeft {
    if (endDate == null) return 0;
    final d = endDate!.difference(DateTime.now()).inHours / 24;
    return d <= 0 ? 0 : d.ceil();
  }

  double get progress {
    if (startDate == null || endDate == null) return 0;
    final total = endDate!.difference(startDate!).inMinutes;
    if (total <= 0) return 0;
    final used = DateTime.now().difference(startDate!).inMinutes;
    return (used / total).clamp(0.0, 1.0);
  }

  bool get canRenew => !isCancelled;
  bool get canCancel => !isCancelled;
  bool get canRequestPlateChange => isActive;

  @override
  List<Object?> get props => [id, status, endDate, licensePlate];
}

class RenewalRecord extends Equatable {
  final String id;
  final DateTime? oldEndDate;
  final DateTime? newEndDate;
  final double amount;
  final DateTime? renewalDate;

  const RenewalRecord({
    required this.id,
    required this.oldEndDate,
    required this.newEndDate,
    required this.amount,
    required this.renewalDate,
  });

  factory RenewalRecord.fromJson(Map<String, dynamic> j) => RenewalRecord(
        id: j.str('renewalId'),
        oldEndDate: j.date('oldEndDate'),
        newEndDate: j.date('newEndDate'),
        amount: j.number('amount'),
        renewalDate: j.date('renewalDate'),
      );

  @override
  List<Object?> get props => [id];
}

class VehicleChangeRequest extends Equatable {
  final String id;
  final String subscriptionId;
  final String oldLicensePlate;
  final String newLicensePlate;
  final String? reason;
  final String? rejectionReason;
  final String status;
  final DateTime? createdAt;
  final DateTime? processedAt;

  const VehicleChangeRequest({
    required this.id,
    required this.subscriptionId,
    required this.oldLicensePlate,
    required this.newLicensePlate,
    required this.reason,
    required this.rejectionReason,
    required this.status,
    required this.createdAt,
    required this.processedAt,
  });

  factory VehicleChangeRequest.fromJson(Map<String, dynamic> j) =>
      VehicleChangeRequest(
        id: j.strOrNull('requestId') ?? j.str('id'),
        subscriptionId: j.str('subscriptionId'),
        oldLicensePlate: j.str('oldLicensePlate'),
        newLicensePlate: j.str('newLicensePlate'),
        reason: j.strOrNull('reason'),
        rejectionReason: j.strOrNull('rejectionReason'),
        status: j.str('status'),
        createdAt: j.date('createdAt'),
        processedAt: j.date('processedAt'),
      );

  bool get isPending => status.trim().toLowerCase() == 'pending';

  @override
  List<Object?> get props => [id, status, newLicensePlate];
}

enum PassPaymentMethod { payos, wallet }

extension PassPaymentMethodApi on PassPaymentMethod {
  String get apiValue => this == PassPaymentMethod.wallet ? 'Wallet' : 'PayOS';
}

/// Kết quả đăng ký / thanh toán vé tháng.
class SubscriptionCheckout extends Equatable {
  final String subscriptionId;

  /// Có khi thanh toán qua PayOS (cần mở trang thanh toán).
  final PaymentLink? payment;

  /// Có khi thanh toán bằng ví: số dư còn lại sau khi trừ.
  final double? walletBalance;

  final String status;

  const SubscriptionCheckout({
    required this.subscriptionId,
    required this.payment,
    required this.walletBalance,
    required this.status,
  });

  factory SubscriptionCheckout.fromJson(Map<String, dynamic> j) {
    final link = PaymentLink.fromJson(j);
    return SubscriptionCheckout(
      subscriptionId: j.str('subscriptionId'),
      payment: link.isUsable ? link : null,
      walletBalance: j.numberOrNull('walletBalance'),
      status: j.str('status'),
    );
  }

  /// Thanh toán bằng ví thành công: gói đã kích hoạt, không cần PayOS.
  bool get paidByWallet => payment == null && walletBalance != null;

  @override
  List<Object?> get props => [subscriptionId, payment, walletBalance, status];
}

class SubscriptionRepository {
  final ApiClient _api;

  SubscriptionRepository(this._api);

  Future<List<MonthlyPass>> mine() =>
      _api.getList(ApiEndpoints.mySubscriptions, MonthlyPass.fromJson);

  Future<MonthlyPass> byId(String id) async {
    final res = await _api.get<dynamic>(ApiEndpoints.subscriptionById(id));
    return MonthlyPass.fromJson(res.result as Map<String, dynamic>);
  }

  /// Đăng ký gói tháng. PayOS: trả liên kết thanh toán; Ví: trừ ví và kích hoạt ngay.
  Future<SubscriptionCheckout> register({
    required String packageId,
    required String licensePlate,
    required PassPaymentMethod method,
    String? fixedSlotId,
    DateTime? startDate,
  }) async {
    final res =
        await _api.post<dynamic>(ApiEndpoints.registerSubscription, data: {
      'packageId': packageId,
      'licensePlate': Validators.normalizePlate(licensePlate),
      'paymentMethod': method.apiValue,
      if (fixedSlotId != null) 'fixedSlotId': fixedSlotId,
      if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
    });
    return SubscriptionCheckout.fromJson(res.result as Map<String, dynamic>);
  }

  /// Thanh toán gói đang chờ (PendingPayment) bằng PayOS hoặc Ví.
  Future<SubscriptionCheckout> pay(
      String subscriptionId, PassPaymentMethod method) async {
    final res = await _api.post<dynamic>(
      ApiEndpoints.subscriptionPayment(subscriptionId),
      data: {'paymentMethod': method.apiValue},
    );
    return SubscriptionCheckout.fromJson(res.result as Map<String, dynamic>);
  }

  /// Gia hạn chỉ hỗ trợ PayOS (theo backend).
  Future<PaymentLink> renew(String subscriptionId, String packageId) async {
    final res = await _api.post<dynamic>(
      ApiEndpoints.renewSubscription(subscriptionId),
      data: {'packageId': packageId},
    );
    return PaymentLink.fromJson(res.result as Map<String, dynamic>);
  }

  Future<void> cancel(String subscriptionId) =>
      _api.put<dynamic>(ApiEndpoints.cancelSubscription(subscriptionId));

  Future<List<RenewalRecord>> renewals(String subscriptionId) => _api.getList(
      ApiEndpoints.subscriptionRenewals(subscriptionId),
      RenewalRecord.fromJson);

  Future<List<VehicleChangeRequest>> myChangeRequests() => _api.getList(
      ApiEndpoints.myVehicleChangeRequests, VehicleChangeRequest.fromJson);

  Future<void> requestPlateChange({
    required String subscriptionId,
    required String newLicensePlate,
    String? reason,
  }) =>
      _api.post<dynamic>(ApiEndpoints.changeVehicle, data: {
        'subscriptionId': subscriptionId,
        'newLicensePlate': Validators.normalizePlate(newLicensePlate),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });

  Future<void> updatePlateChange({
    required String requestId,
    required String newLicensePlate,
    String? reason,
  }) =>
      _api.put<dynamic>(ApiEndpoints.vehicleChangeById(requestId), data: {
        'newLicensePlate': Validators.normalizePlate(newLicensePlate),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });

  Future<void> deletePlateChange(String requestId) =>
      _api.delete<dynamic>(ApiEndpoints.vehicleChangeById(requestId));
}
