import 'package:equatable/equatable.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_read.dart';
import '../../payments/data/payment_models.dart';

class ParkingSession extends Equatable {
  final String id;
  final String? reservationId;
  final String? driverFullName;
  final String licensePlateIn;
  final String? licensePlateOut;
  final String vehicleTypeName;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final String entryGateName;
  final String? exitGateName;
  final String? slotCode;
  final String status;
  final double? paymentAmount;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? entryImageUrl;
  final String? exitImageUrl;
  final Ticket? ticket;

  const ParkingSession({
    required this.id,
    required this.reservationId,
    required this.driverFullName,
    required this.licensePlateIn,
    required this.licensePlateOut,
    required this.vehicleTypeName,
    required this.entryTime,
    required this.exitTime,
    required this.entryGateName,
    required this.exitGateName,
    required this.slotCode,
    required this.status,
    required this.paymentAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.entryImageUrl,
    required this.exitImageUrl,
    required this.ticket,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> j) => ParkingSession(
        id: j.str('sessionId'),
        reservationId: j.strOrNull('reservationId'),
        driverFullName: j.strOrNull('driverFullName'),
        licensePlateIn: j.str('licensePlateIn'),
        licensePlateOut: j.strOrNull('licensePlateOut'),
        vehicleTypeName: j.str('vehicleTypeName'),
        entryTime: j.date('entryTime'),
        exitTime: j.date('exitTime'),
        entryGateName: j.str('entryGateName'),
        exitGateName: j.strOrNull('exitGateName'),
        slotCode:
            j.strOrNull('actualSlotCode') ?? j.strOrNull('assignedSlotCode'),
        status: j.str('status'),
        paymentAmount: j.numberOrNull('paymentAmount'),
        paymentStatus: j.strOrNull('paymentStatus'),
        paymentMethod: j.strOrNull('paymentMethod'),
        entryImageUrl: j.strOrNull('entryImageUrl'),
        exitImageUrl: j.strOrNull('exitImageUrl'),
        ticket: Ticket.fromJson(j.obj('ticket')),
      );

  bool get isActive => status.trim().toLowerCase() == 'active';

  /// Có yêu cầu checkout đang chờ thanh toán (đã quét ra cổng nhưng chưa trả tiền).
  bool get hasPendingCheckout =>
      isActive &&
      (paymentStatus ?? '').toLowerCase() == 'pending' &&
      exitTime != null;

  Duration get elapsed {
    final start = entryTime;
    if (start == null) return Duration.zero;
    return (exitTime ?? DateTime.now()).difference(start);
  }

  @override
  List<Object?> get props => [id, status, exitTime, paymentStatus];
}

/// Yêu cầu thanh toán checkout của tài xế.
class CheckoutPaymentInfo extends Equatable {
  final PaymentRecord? payment;
  final String? paymentUrl;
  final String? orderCode;

  const CheckoutPaymentInfo({this.payment, this.paymentUrl, this.orderCode});

  factory CheckoutPaymentInfo.fromJson(Map<String, dynamic> j) {
    final p = j.obj('payment');
    final online = j.obj('onlinePayment');
    return CheckoutPaymentInfo(
      payment: p == null ? null : PaymentRecord.fromJson(p),
      paymentUrl: online?.strOrNull('paymentUrl'),
      orderCode: online?.strOrNull('orderCode'),
    );
  }

  @override
  List<Object?> get props => [payment, paymentUrl, orderCode];
}

/// Kết quả check-out phía nhân viên.
class CheckoutResult extends Equatable {
  final String message;
  final ParkingSession? session;
  final PaymentRecord? payment;
  final FeeBreakdown? fee;
  final String? paymentUrl;

  const CheckoutResult({
    required this.message,
    this.session,
    this.payment,
    this.fee,
    this.paymentUrl,
  });

  /// Đã hoàn tất (không cần thu thêm tiền).
  bool get isCompleted => payment == null || payment!.isSuccess;

  @override
  List<Object?> get props => [message, session, payment, fee, paymentUrl];
}

enum CustomerType { guest, resident, reservation }

extension CustomerTypeApi on CustomerType {
  String get apiValue => switch (this) {
        CustomerType.guest => 'Guest',
        CustomerType.resident => 'Resident',
        CustomerType.reservation => 'Reservation',
      };
}

/// Kết quả nhận diện biển số (endpoint trả JSON thô).
class PlateRecognition extends Equatable {
  final String? licensePlate;
  final double? confidence;
  final String? message;
  final String? imageUrl;
  final List<String> candidates;

  const PlateRecognition({
    this.licensePlate,
    this.confidence,
    this.message,
    this.imageUrl,
    this.candidates = const [],
  });

  factory PlateRecognition.fromJson(Map<String, dynamic> j) => PlateRecognition(
        licensePlate: j.strOrNull('licensePlate'),
        confidence: j.numberOrNull('confidence'),
        message: j.strOrNull('message') ?? j.strOrNull('providerError'),
        imageUrl: j.strOrNull('imageUrl'),
        candidates: (j['candidates'] is List)
            ? (j['candidates'] as List)
                .whereType<Map<String, dynamic>>()
                .map((c) => c.str('licensePlate'))
                .where((s) => s.isNotEmpty)
                .toList()
            : const [],
      );

  @override
  List<Object?> get props => [licensePlate, confidence, message];
}

/// Kết quả giải mã QR tại cổng.
class QrResolution extends Equatable {
  final String qrPayload;
  final String codeType;
  final String? reservationId;
  final String? sessionId;

  const QrResolution({
    required this.qrPayload,
    required this.codeType,
    this.reservationId,
    this.sessionId,
  });

  factory QrResolution.fromJson(Map<String, dynamic> j) => QrResolution(
        qrPayload: j.str('qrPayload'),
        codeType: j.str('codeType'),
        reservationId: j.strOrNull('reservationId'),
        sessionId: j.strOrNull('sessionId'),
      );

  @override
  List<Object?> get props => [qrPayload, codeType, reservationId, sessionId];
}

class SessionRepository {
  final ApiClient _api;

  SessionRepository(this._api);

  // ---------- Customer ----------

  Future<List<ParkingSession>> mine() async {
    final list =
        await _api.getList(ApiEndpoints.mySessions, ParkingSession.fromJson);
    list.sort((a, b) => (b.entryTime ?? DateTime(1970))
        .compareTo(a.entryTime ?? DateTime(1970)));
    return list;
  }

  Future<FeeBreakdown> myFeePreview(String sessionId) async {
    final res =
        await _api.get<dynamic>(ApiEndpoints.mySessionFeePreview(sessionId));
    return FeeBreakdown.fromJson(res.result as Map<String, dynamic>);
  }

  Future<CheckoutPaymentInfo> myCheckoutPayment(String sessionId) async {
    final res = await _api
        .get<dynamic>(ApiEndpoints.mySessionCheckoutPayment(sessionId));
    return CheckoutPaymentInfo.fromJson(res.result as Map<String, dynamic>);
  }

  // ---------- Staff ----------

  Future<List<ParkingSession>> all() async {
    final list =
        await _api.getList(ApiEndpoints.sessions, ParkingSession.fromJson);
    list.sort((a, b) => (b.entryTime ?? DateTime(1970))
        .compareTo(a.entryTime ?? DateTime(1970)));
    return list;
  }

  Future<ParkingSession> byId(String id) async {
    final res = await _api.get<dynamic>(ApiEndpoints.sessionById(id));
    return ParkingSession.fromJson(res.result as Map<String, dynamic>);
  }

  Future<FeeBreakdown> staffFeePreview(String sessionId) async {
    final res =
        await _api.get<dynamic>(ApiEndpoints.staffFeePreview(sessionId));
    return FeeBreakdown.fromJson(res.result as Map<String, dynamic>);
  }

  Future<PlateRecognition> recognizePlate(UploadFile file) async {
    final raw = await _api
        .upload(ApiEndpoints.recognizePlate, file, acceptStatuses: {422});
    if (raw is Map<String, dynamic>) return PlateRecognition.fromJson(raw);
    return const PlateRecognition();
  }

  Future<QrResolution> decodeQrImage(UploadFile file) async {
    final raw = await _api.upload(ApiEndpoints.decodeQr, file);
    return QrResolution.fromJson(raw as Map<String, dynamic>);
  }

  Future<QrResolution> resolveQrPayload(String payload) async {
    final res = await _api.post<dynamic>(
      ApiEndpoints.resolveQrPayload,
      data: {'qrPayload': payload.trim()},
    );
    return QrResolution.fromJson(res.result as Map<String, dynamic>);
  }

  /// Upload ảnh cổng (check-in / check-out), trả về URL ảnh.
  Future<String?> uploadGateImage(UploadFile file) async {
    final raw = await _api.upload(ApiEndpoints.uploadGateImage, file);
    if (raw is Map<String, dynamic>) return raw.strOrNull('imageUrl');
    return null;
  }

  Future<ParkingSession> checkIn({
    required CustomerType customerType,
    required String gateId,
    required String licensePlate,
    String? vehicleTypeId,
    String? reservationId,
    String? entryImageUrl,
  }) async {
    final res = await _api.post<dynamic>(ApiEndpoints.checkIn, data: {
      'customerType': customerType.apiValue,
      'gateId': gateId,
      'licensePlate': licensePlate,
      if (vehicleTypeId != null) 'vehicleTypeId': vehicleTypeId,
      if (reservationId != null) 'reservationId': reservationId,
      if (entryImageUrl != null) 'entryImageUrl': entryImageUrl,
    });
    return ParkingSession.fromJson(res.result as Map<String, dynamic>);
  }

  /// Check-out theo sessionId (từ QR vé) hoặc biển số.
  Future<CheckoutResult> checkOut({
    required String gateId,
    String? sessionId,
    String? licensePlate,
    required String paymentMethod,
    String? exitImageUrl,
  }) async {
    final res = await _api.post<dynamic>(ApiEndpoints.checkOut, data: {
      'gateId': gateId,
      if (sessionId != null) 'sessionId': sessionId,
      if (licensePlate != null) 'licensePlate': licensePlate,
      if (licensePlate != null) 'licensePlateOut': licensePlate,
      'paymentMethod': paymentMethod,
      if (exitImageUrl != null) 'exitImageUrl': exitImageUrl,
    });
    return _parseCheckout(res.message ?? '', res.result);
  }

  Future<CheckoutResult> checkoutPaymentStatus(String paymentId) async {
    final res =
        await _api.get<dynamic>(ApiEndpoints.checkoutPayment(paymentId));
    return _parseCheckout(res.message ?? '', res.result);
  }

  Future<CheckoutResult> confirmCash(String paymentId) async {
    final res = await _api.post<dynamic>(ApiEndpoints.confirmCash(paymentId));
    return _parseCheckout(res.message ?? '', res.result);
  }

  Future<void> cancelCheckout(String paymentId) =>
      _api.post<dynamic>(ApiEndpoints.cancelCheckout(paymentId));

  /// Kết quả checkout có 3 dạng: phiên trực tiếp (vé tháng), {Session, Fee},
  /// hoặc {Payment, Fee, OnlinePayment?}.
  CheckoutResult _parseCheckout(String message, dynamic raw) {
    if (raw is! Map<String, dynamic>) return CheckoutResult(message: message);
    if (raw.containsKey('sessionId')) {
      return CheckoutResult(
          message: message, session: ParkingSession.fromJson(raw));
    }
    final session = raw.obj('session');
    final payment = raw.obj('payment');
    final fee = raw.obj('fee');
    final online = raw.obj('onlinePayment');
    return CheckoutResult(
      message: message,
      session: session == null ? null : ParkingSession.fromJson(session),
      payment: payment == null ? null : PaymentRecord.fromJson(payment),
      fee: fee == null ? null : FeeBreakdown.fromJson(fee),
      paymentUrl: online?.strOrNull('paymentUrl'),
    );
  }
}
