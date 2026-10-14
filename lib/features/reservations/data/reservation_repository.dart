import 'package:equatable/equatable.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_read.dart';
import '../../payments/data/payment_models.dart';

class Reservation extends Equatable {
  final String id;
  final String vehicleTypeName;
  final DateTime? expectedEntryTime;
  final String status;
  final DateTime? createdAt;
  final Ticket? ticket;

  const Reservation({
    required this.id,
    required this.vehicleTypeName,
    required this.expectedEntryTime,
    required this.status,
    required this.createdAt,
    required this.ticket,
  });

  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
        id: j.str('reservationId'),
        vehicleTypeName: j.str('vehicleTypeName'),
        expectedEntryTime: j.date('expectedEntryTime'),
        status: j.str('status'),
        createdAt: j.date('createdAt'),
        ticket: Ticket.fromJson(j.obj('ticket')),
      );

  String get _s => status.trim().toLowerCase();
  bool get isPending => _s == 'pending';
  bool get isConfirmed => _s == 'confirmed';
  bool get isModified => _s == 'modified';
  bool get isUpcoming => isPending || isConfirmed || isModified;

  /// Backend: chỉ hủy khi chưa check-in / hoàn tất, và chưa bị hủy.
  bool get canCancel => isUpcoming;

  /// Backend: chỉ đơn Confirmed được đổi giờ (1 lần), trước giờ hẹn ít nhất 15 phút.
  bool get canChangeTime {
    if (!isConfirmed || expectedEntryTime == null) return false;
    return DateTime.now()
        .isBefore(expectedEntryTime!.subtract(const Duration(minutes: 15)));
  }

  /// Vé dùng tại cổng khi đơn đã thanh toán cọc.
  bool get showsTicket => isConfirmed || isModified;

  @override
  List<Object?> get props => [id, status, expectedEntryTime];
}

class ReservationRepository {
  final ApiClient _api;

  ReservationRepository(this._api);

  /// Giới hạn từ backend: đặt trước tối đa 5 tiếng.
  static const Duration maxLeadTime = Duration(hours: 5);

  Future<List<Reservation>> mine() async {
    final list =
        await _api.getList(ApiEndpoints.myReservations, Reservation.fromJson);
    list.sort((a, b) => (b.createdAt ?? DateTime(1970))
        .compareTo(a.createdAt ?? DateTime(1970)));
    return list;
  }

  Future<Reservation> byId(String id) async {
    final res = await _api.get<dynamic>(ApiEndpoints.reservationById(id));
    return Reservation.fromJson(res.result as Map<String, dynamic>);
  }

  /// Tạo đặt chỗ (loại xe do backend cố định là Ô tô) và nhận liên kết thanh toán cọc.
  Future<({String reservationId, PaymentLink payment})> create(
      DateTime expectedEntryTime) async {
    final res = await _api.post<dynamic>(
      ApiEndpoints.reservations,
      data: {'expectedEntryTime': expectedEntryTime.toUtc().toIso8601String()},
    );
    final j = res.result as Map<String, dynamic>;
    return (
      reservationId: j.str('reservationId'),
      payment: PaymentLink.fromJson(j)
    );
  }

  Future<PaymentLink> recreatePayment(String id) async {
    final res =
        await _api.post<dynamic>(ApiEndpoints.recreateReservationPayment(id));
    return PaymentLink.fromJson(res.result as Map<String, dynamic>);
  }

  Future<Reservation> changeTime(String id, DateTime newTime) async {
    final res = await _api.put<dynamic>(
      ApiEndpoints.changeReservationTime(id),
      data: {'newExpectedTime': newTime.toUtc().toIso8601String()},
    );
    return Reservation.fromJson(res.result as Map<String, dynamic>);
  }

  Future<void> cancel(String id) =>
      _api.put<dynamic>(ApiEndpoints.cancelReservation(id));

  /// Trạng thái thanh toán theo orderCode (dùng chung cho mọi loại thanh toán PayOS).
  Future<String> paymentStatus(String orderCode) async {
    final res =
        await _api.get<dynamic>(ApiEndpoints.checkPaymentStatus(orderCode));
    final j = res.result as Map<String, dynamic>;
    return j.str('paymentStatus');
  }
}
