import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/config/api_endpoints.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/utils/json_read.dart';
import '../features/auth/data/models/user_model.dart';
import 'models/pbms_models.dart';

/// Toàn bộ API phía khách hàng của PBMS.
/// Mọi lỗi được ném ra dưới dạng [AppException] để màn hình hiển thị trạng thái lỗi.
class PbmsRepository {
  final ApiClient _api;

  PbmsRepository({required ApiClient apiClient}) : _api = apiClient;

  // ---------------------------------------------------------------- helpers

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async =>
      (await _api.get<dynamic>(path, queryParameters: query)).result;

  Future<dynamic> _post(String path, [Object? body]) async =>
      (await _api.post<dynamic>(path, data: body ?? const <String, dynamic>{}))
          .result;

  Future<dynamic> _put(String path, [Object? body]) async =>
      (await _api.put<dynamic>(path, data: body ?? const <String, dynamic>{}))
          .result;

  List<T> _list<T>(dynamic raw, T Function(J) parse) =>
      JsonRead.list(raw).map(parse).toList();

  J _obj(dynamic raw, String what) {
    if (raw is J) return raw;
    throw ServerException(message: 'Máy chủ trả về dữ liệu $what không hợp lệ.');
  }

  // ------------------------------------------------------- facility & catalog

  Future<List<FacilityAvailabilityModel>> getAvailability({String? vehicleTypeId}) async =>
      _list(
        await _get(
          ApiEndpoints.parkingAvailability,
          query: vehicleTypeId == null ? null : {'vehicleTypeId': vehicleTypeId},
        ),
        FacilityAvailabilityModel.fromJson,
      );

  Future<List<PricingPolicyModel>> getPricingPolicies() async =>
      _list(await _get(ApiEndpoints.pricingPolicies), PricingPolicyModel.fromJson)
          .where((p) => p.isActive)
          .toList();

  Future<List<SubscriptionPackageModel>> getSubscriptionPackages() async => _list(
        await _get(ApiEndpoints.subscriptionPackages),
        SubscriptionPackageModel.fromJson,
      ).where((p) => p.isActive).toList();

  /// Ô đỗ trống tại tầng cư dân dành cho [vehicleTypeId] (dùng cho gói cố định vị trí).
  Future<List<ParkingSlotModel>> getResidentSlots(String vehicleTypeId) async {
    try {
      return _list(await _get(ApiEndpoints.parkingSlots), ParkingSlotModel.fromJson)
          .where((s) =>
              s.isResident && s.isAvailable && s.vehicleTypeId == vehicleTypeId)
          .toList();
    } on NotFoundException {
      return const [];
    }
  }

  // ------------------------------------------------------------ sessions

  Future<List<ParkingSessionModel>> getMySessions() async {
    final items =
        _list(await _get(ApiEndpoints.mySessions), ParkingSessionModel.fromJson);
    items.sort((a, b) => b.entryTime.compareTo(a.entryTime));
    return items;
  }

  Future<FeePreviewModel> getFeePreview(String sessionId) async => FeePreviewModel.fromJson(
        _obj(await _get(ApiEndpoints.sessionFeePreview(sessionId)), 'phí tạm tính'),
      );

  Future<CheckoutPaymentModel> getCheckoutPayment(String sessionId) async =>
      CheckoutPaymentModel.fromJson(
        _obj(await _get(ApiEndpoints.sessionCheckoutPayment(sessionId)), 'thanh toán'),
      );

  /// Thanh toán trước khi ra bãi: `Wallet` trừ ví ngay, `PayOS` trả về link.
  Future<PrepayResultModel> prepaySession(String sessionId, String method) async =>
      PrepayResultModel.fromJson(_obj(
        await _post(ApiEndpoints.sessionPrepay(sessionId), {'paymentMethod': method}),
        'thanh toán trước',
      ));

  /// Đồng bộ thanh toán PayOS đang chờ và lấy mã ra cổng (nếu đã trả).
  Future<PrepayResultModel> getExitPass(String sessionId) async => PrepayResultModel.fromJson(
        _obj(await _get(ApiEndpoints.sessionExitPass(sessionId)), 'mã ra cổng'),
      );

  // ---------------------------------------------------------------- wallet

  String? _walletId;

  /// Mở ví (tạo nếu chưa có) và nhớ walletId cho các lần gọi sau.
  Future<String> _ensureWalletId() async {
    final cached = _walletId;
    if (cached != null) return cached;
    final raw = _obj(await _post(ApiEndpoints.ensureWallet), 'ví');
    final id = JsonRead.str(raw, 'walletId');
    if (id.isEmpty) {
      throw const ServerException(message: 'Không mở được ví.');
    }
    return _walletId = id;
  }

  Future<WalletModel> getWallet() async {
    final id = await _ensureWalletId();
    return WalletModel.fromJson(_obj(await _get(ApiEndpoints.walletById(id)), 'ví'));
  }

  Future<PaymentLinkModel> topUpWallet(int amount) async {
    final id = await _ensureWalletId();
    return PaymentLinkModel.fromJson(
      _obj(await _post(ApiEndpoints.walletTopUp(id), {'amount': amount}), 'nạp ví'),
    );
  }

  /// Tra trực tiếp PayOS; `true` nếu thanh toán đã thành công.
  Future<bool> checkTopUp(String paymentId) async {
    final raw = _obj(await _get(ApiEndpoints.syncPayment(paymentId)), 'thanh toán');
    return JsonRead.str(raw, 'paymentStatus').toLowerCase() == 'success';
  }

  /// Xoá walletId đã nhớ (gọi khi đăng xuất / đổi tài khoản).
  void clearSessionCache() => _walletId = null;

  // ---------------------------------------------------------------- vehicles

  Future<List<VehicleModel>> getMyVehicles() async =>
      _list(await _get(ApiEndpoints.myVehicles), VehicleModel.fromJson);

  Future<VehicleModel> addVehicle({required String vehicleTypeId, required String licensePlate}) async =>
      VehicleModel.fromJson(_obj(
        await _post(ApiEndpoints.vehicles, {
          'vehicleTypeId': vehicleTypeId,
          'licensePlate': licensePlate,
        }),
        'xe',
      ));

  Future<void> removeVehicle(String vehicleId) async {
    await _api.delete<dynamic>(ApiEndpoints.vehicleById(vehicleId));
  }

  /// Loại xe khách có thể đăng ký (từ bảng giá công khai; danh mục loại xe chỉ dành cho quản lý).
  Future<List<VehicleTypeOption>> getVehicleTypeOptions() async {
    final seen = <String, String>{};
    for (final p in await getPricingPolicies()) {
      seen.putIfAbsent(p.vehicleTypeId, () => p.vehicleTypeName);
    }
    return [for (final e in seen.entries) VehicleTypeOption(e.key, e.value)];
  }

  // --------------------------------------------------------- reservations

  Future<List<ReservationModel>> getMyReservations() async =>
      _list(await _get(ApiEndpoints.myReservations), ReservationModel.fromJson);

  Future<ReservationModel> getReservation(String reservationId) async => ReservationModel.fromJson(
        _obj(await _get(ApiEndpoints.getReservationById(reservationId)), 'đặt chỗ'),
      );

  Future<PaymentLinkModel> createReservation(DateTime expectedEntryTime, String vehicleId) async =>
      PaymentLinkModel.fromJson(_obj(
        await _post(ApiEndpoints.reservations, {
          'vehicleId': vehicleId,
          'expectedEntryTime': expectedEntryTime.toUtc().toIso8601String(),
        }),
        'đặt chỗ',
      ));

  Future<PaymentLinkModel> recreateReservationPayment(String reservationId) async =>
      PaymentLinkModel.fromJson(_obj(
        await _post(ApiEndpoints.recreateReservationPayment(reservationId)),
        'thanh toán',
      ));

  Future<PaymentStatusModel> checkPaymentStatus(String orderCode) async =>
      PaymentStatusModel.fromJson(
        _obj(await _get(ApiEndpoints.checkPaymentStatus(orderCode)), 'thanh toán'),
      );

  Future<void> changeReservationTime(String reservationId, DateTime newTime) async {
    await _put(ApiEndpoints.changeReservationTime(reservationId), {
      'newExpectedTime': newTime.toUtc().toIso8601String(),
    });
  }

  Future<void> cancelReservation(String reservationId) async {
    await _put(ApiEndpoints.cancelReservation(reservationId));
  }

  // ------------------------------------------------------- subscriptions

  Future<List<MonthlySubscriptionModel>> getMySubscriptions() async => _list(
        await _get(ApiEndpoints.mySubscriptions),
        MonthlySubscriptionModel.fromJson,
      );

  Future<MonthlySubscriptionModel> getSubscription(String subscriptionId) async =>
      MonthlySubscriptionModel.fromJson(
        _obj(await _get(ApiEndpoints.subscriptionById(subscriptionId)), 'vé tháng'),
      );

  Future<RegistrationResultModel> registerSubscription({
    required String packageId,
    required String vehicleId,
    String? fixedSlotId,
    String paymentMethod = 'PayOS',
  }) async =>
      RegistrationResultModel.fromJson(_obj(
        await _post(ApiEndpoints.registerSubscription, {
          'packageId': packageId,
          'vehicleId': vehicleId,
          'paymentMethod': paymentMethod,
          if (fixedSlotId != null) 'fixedSlotId': fixedSlotId,
        }),
        'đăng ký gói',
      ));

  Future<PaymentLinkModel> repaySubscription(String subscriptionId) async =>
      PaymentLinkModel.fromJson(_obj(
        await _post(ApiEndpoints.subscriptionPayment(subscriptionId)),
        'thanh toán',
      ));

  Future<PaymentLinkModel> renewSubscription(String subscriptionId, String packageId) async =>
      PaymentLinkModel.fromJson(_obj(
        await _post(ApiEndpoints.renewSubscription(subscriptionId), {'packageId': packageId}),
        'gia hạn',
      ));

  Future<List<RenewalModel>> getRenewals(String subscriptionId) async => _list(
        await _get(ApiEndpoints.subscriptionRenewals(subscriptionId)),
        RenewalModel.fromJson,
      );

  Future<void> cancelSubscription(String subscriptionId) async {
    await _put(ApiEndpoints.cancelSubscription(subscriptionId));
  }

  Future<List<VehicleChangeRequestModel>> getMyVehicleChangeRequests() async => _list(
        await _get(ApiEndpoints.myVehicleChangeRequests),
        VehicleChangeRequestModel.fromJson,
      );

  Future<void> requestVehicleChange({
    required String subscriptionId,
    required String newLicensePlate,
    required String reason,
  }) async {
    await _post(ApiEndpoints.requestChangeVehicle, {
      'subscriptionId': subscriptionId,
      'newLicensePlate': newLicensePlate,
      'reason': reason,
    });
  }

  Future<void> updateVehicleChangeRequest({
    required String requestId,
    required String newLicensePlate,
    required String reason,
  }) async {
    await _put(ApiEndpoints.vehicleChangeRequestById(requestId), {
      'newLicensePlate': newLicensePlate,
      'reason': reason,
    });
  }

  Future<void> withdrawVehicleChangeRequest(String requestId) async {
    await _api.delete<dynamic>(ApiEndpoints.vehicleChangeRequestById(requestId));
  }

  // ----------------------------------------------------------- contracts

  Future<ContractModel> getContractForSubscription(String subscriptionId) async =>
      ContractModel.fromJson(
        _obj(await _get(ApiEndpoints.contractForSubscription(subscriptionId)), 'hợp đồng'),
      );

  /// Ký hợp đồng. `signaturePng` là ảnh PNG chữ ký tay.
  Future<SignContractResultModel> signContract({
    required String contractId,
    required String signerName,
    required String contentHash,
    required Uint8List signaturePng,
    String paymentMethod = 'PayOS',
  }) async =>
      SignContractResultModel.fromJson(_obj(
        await _post(ApiEndpoints.signContract(contractId), {
          'agreed': true,
          'paymentMethod': paymentMethod,
          'signerName': signerName,
          'contentHash': contentHash,
          'signatureImage': 'data:image/png;base64,${base64Encode(signaturePng)}',
        }),
        'ký hợp đồng',
      ));

  Future<ContractVerificationModel> verifyContract(String contractId) async =>
      ContractVerificationModel.fromJson(
        _obj(await _get(ApiEndpoints.verifyContract(contractId)), 'kiểm tra hợp đồng'),
      );

  // ----------------------------------------------------------- incidents

  Future<IncidentModel> getIncident(String incidentId) async => IncidentModel.fromJson(
        _obj(await _get(ApiEndpoints.incidentById(incidentId)), 'sự cố'),
      );

  Future<List<IncidentModel>> getMyIncidents() async =>
      _list(await _get(ApiEndpoints.myIncidentReports), IncidentModel.fromJson);

  Future<String> uploadIncidentProof(Uint8List bytes, String fileName) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final result = await _api.post<dynamic>(ApiEndpoints.uploadIncidentProof, data: form);
    final raw = result.result;
    final url = raw is J ? JsonRead.str(raw, 'imageUrl') : '';
    if (url.isEmpty) {
      throw const ServerException(message: 'Không tải được ảnh minh chứng.');
    }
    return url;
  }

  Future<void> createIncident({
    required String issueType,
    required String description,
    String? sessionId,
    String? proofImageUrl,
  }) async {
    await _post(ApiEndpoints.incidentReports, {
      'issueType': issueType,
      'description': description,
      if (sessionId != null) 'sessionId': sessionId,
      if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
    });
  }

  // -------------------------------------------------------- notifications

  Future<NotificationPage> getNotifications() async =>
      NotificationPage.fromJson(await _get(ApiEndpoints.myNotifications));

  Future<void> markNotificationRead(String id) async {
    await _put(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> markAllNotificationsRead() async {
    await _put(ApiEndpoints.markAllNotificationsRead);
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete<dynamic>(ApiEndpoints.deleteNotification(id));
  }

  // -------------------------------------------------------------- profile

  Future<UserModel> getProfile() async =>
      UserModel.fromJson(_obj(await _get(ApiEndpoints.profile), 'hồ sơ'));

  Future<UserModel> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? password,
  }) async =>
      UserModel.fromJson(_obj(
        await _put(ApiEndpoints.profile, {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          if (password != null && password.isNotEmpty) 'password': password,
        }),
        'hồ sơ',
      ));
}
