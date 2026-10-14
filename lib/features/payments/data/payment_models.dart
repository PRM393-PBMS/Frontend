import 'package:equatable/equatable.dart';

import '../../../core/utils/json_read.dart';

/// Liên kết thanh toán PayOS do backend tạo.
class PaymentLink extends Equatable {
  final String paymentId;
  final String paymentUrl;
  final String orderCode;
  final double amount;

  const PaymentLink({
    required this.paymentId,
    required this.paymentUrl,
    required this.orderCode,
    required this.amount,
  });

  /// Đọc từ kết quả tạo đặt chỗ (`depositAmount`) hoặc gói tháng / gia hạn (`amount`).
  factory PaymentLink.fromJson(Map<String, dynamic> j) => PaymentLink(
        paymentId: j.str('paymentId'),
        paymentUrl: j.str('paymentUrl'),
        orderCode: j.str('orderCode'),
        amount: j.numberOrNull('depositAmount') ?? j.number('amount'),
      );

  bool get isUsable => paymentUrl.isNotEmpty && orderCode.isNotEmpty;

  @override
  List<Object?> get props => [paymentId, orderCode, paymentUrl, amount];
}

/// Bản ghi thanh toán (checkout / đặt cọc).
class PaymentRecord extends Equatable {
  final String id;
  final String? sessionId;
  final String? reservationId;
  final double amount;
  final String method;
  final String? type;
  final DateTime? time;
  final String status;
  final String? reference;

  const PaymentRecord({
    required this.id,
    this.sessionId,
    this.reservationId,
    required this.amount,
    required this.method,
    this.type,
    this.time,
    required this.status,
    this.reference,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
        id: j.str('paymentId'),
        sessionId: j.strOrNull('sessionId'),
        reservationId: j.strOrNull('reservationId'),
        amount: j.number('amount'),
        method: j.str('paymentMethod'),
        type: j.strOrNull('paymentType'),
        time: j.date('paymentTime'),
        status: j.str('paymentStatus'),
        reference: j.strOrNull('transactionReference'),
      );

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSuccess => status.toLowerCase() == 'success';
  bool get isPayOS => method.toLowerCase() == 'payos';

  @override
  List<Object?> get props => [id, status, amount];
}

/// Chi tiết phí gửi xe (tạm tính hoặc lúc checkout).
class FeeBreakdown extends Equatable {
  final String sessionId;
  final String licensePlate;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final double totalHours;
  final int billedHours;
  final double grossAmount;
  final double depositAmount;
  final double amount;
  final double basePrice;
  final int baseHours;
  final double extraHourPrice;
  final double nightSurcharge;
  final int nightSurchargeCount;
  final bool isCoveredBySubscription;

  const FeeBreakdown({
    required this.sessionId,
    required this.licensePlate,
    required this.entryTime,
    required this.exitTime,
    required this.totalHours,
    required this.billedHours,
    required this.grossAmount,
    required this.depositAmount,
    required this.amount,
    required this.basePrice,
    required this.baseHours,
    required this.extraHourPrice,
    required this.nightSurcharge,
    required this.nightSurchargeCount,
    required this.isCoveredBySubscription,
  });

  factory FeeBreakdown.fromJson(Map<String, dynamic> j) => FeeBreakdown(
        sessionId: j.str('sessionId'),
        licensePlate: j.str('licensePlate'),
        entryTime: j.date('entryTime'),
        exitTime: j.date('exitTime'),
        totalHours: j.number('totalHours'),
        billedHours: j.integer('billedHours'),
        grossAmount: j.numberOrNull('grossAmount') ?? j.number('amount'),
        depositAmount: j.number('depositAmount'),
        amount: j.number('amount'),
        basePrice: j.number('basePrice'),
        baseHours: j.integer('baseHours'),
        extraHourPrice: j.number('extraHourPrice'),
        nightSurcharge: j.number('nightSurcharge'),
        nightSurchargeCount: j.integer('nightSurchargeCount'),
        isCoveredBySubscription: j.boolean('isCoveredBySubscription'),
      );

  int get extraHours => (billedHours - baseHours).clamp(0, 1 << 30);

  @override
  List<Object?> get props => [sessionId, amount, billedHours, exitTime];
}

/// Mã vé QR backend cấp cho đặt chỗ / phiên gửi xe.
class Ticket extends Equatable {
  final String qrPayload;

  const Ticket(this.qrPayload);

  static Ticket? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final payload = j.str('qrPayload');
    return payload.isEmpty ? null : Ticket(payload);
  }

  @override
  List<Object?> get props => [qrPayload];
}
