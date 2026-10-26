import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/config/api_endpoints.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/utils/json_read.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/staff/data/staff_models.dart';
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
    final opened = _obj(await _post(ApiEndpoints.ensureWallet), 'ví');
    final id = JsonRead.str(opened, 'walletId');
    if (id.isEmpty) {
      throw const ServerException(message: 'Không mở được ví.');
    }
    _walletId = id;
    try {
      return WalletModel.fromJson(_obj(await _get(ApiEndpoints.walletById(id)), 'ví'));
    } on ServerException catch (e) {
      // Lịch sử ví lỗi phía máy chủ: vẫn hiện số dư lấy từ lệnh mở ví.
      return WalletModel(
        walletId: id,
        balance: JsonRead.num_(opened, 'walletBalance'),
        transactions: const [],
        historyError: e.message.trim().isEmpty || e.message.contains('Internal')
            ? 'Máy chủ đang lỗi khi tải lịch sử giao dịch.'
            : e.message,
      );
    }
  }

  /// Lịch sử ví theo loại; không phụ thuộc `GET /api/wallet/:id` (lấy cả số dư).
  Future<List<WalletTransactionModel>> getWalletHistory(WalletHistoryFilter filter) async {
    final id = await _ensureWalletId();
    final path = switch (filter) {
      WalletHistoryFilter.all => ApiEndpoints.walletTransactions(id),
      WalletHistoryFilter.topUps => ApiEndpoints.walletTopUps(id),
      WalletHistoryFilter.spends => ApiEndpoints.walletSpends(id),
    };
    return _list(await _get(path), WalletTransactionModel.fromJson);
  }

  Future<PaymentLinkModel> topUpWallet(int amount) async {
    final id = await _ensureWalletId();
    return PaymentLinkModel.fromJson(
      _obj(await _post(ApiEndpoints.walletTopUp(id), {'amount': amount}), 'nạp ví'),
    );
  }

  /// Tra trực tiếp PayOS; `true` nếu thanh toán đã thành công.
  Future<bool> checkPayment(String paymentId) => checkTopUp(paymentId);

  /// Lịch sử thanh toán của tôi, mới nhất trước. [status]: Pending/Success/Failed.
  Future<PaymentPage> getMyPayments({int page = 1, int pageSize = 20, String? status}) async =>
      PaymentPage.fromJson(_obj(
        await _get(ApiEndpoints.myPayments, query: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
        }),
        'lịch sử thanh toán',
      ));

  /// Tra trực tiếp PayOS; `true` nếu thanh toán đã thành công.
  Future<bool> checkTopUp(String paymentId) async {
    final raw = _obj(await _get(ApiEndpoints.syncPayment(paymentId)), 'thanh toán');
    return JsonRead.str(raw, 'paymentStatus').toLowerCase() == 'success';
  }

  /// Xoá walletId đã nhớ (gọi khi đăng xuất / đổi tài khoản).
  void clearSessionCache() => _walletId = null;

  // ---------------------------------------------------------------- parkings

  /// Các bãi đỗ cho khách. Server chưa có API này (404) thì trả rỗng để app
  /// quay về cách hiển thị một bãi.
  Future<List<ParkingLotModel>> getParkingLots() async {
    try {
      return _list(await _get(ApiEndpoints.availableParkings), ParkingLotModel.fromJson);
    } on AppException catch (e) {
      // Server chưa có API này: route bị bắt bởi GET /parkings/:id (chỉ quản lý,
      // trả 403) hoặc không tồn tại (404 / 400). Dựng từ danh mục công khai.
      if (e is ForbiddenException || e is NotFoundException || e is ValidationException) {
        return _lotsFromCatalog();
      }
      rethrow;
    }
  }

  /// Ô đỗ công khai (có parkingId) để dựng bãi và đoán bãi của lượt gửi.
  Future<List<ParkingSlotModel>> getAllSlots() async =>
      _list(await _get(ApiEndpoints.parkingSlots), ParkingSlotModel.fromJson);

  /// Bãi dựng từ /api/Floor (tên bãi) + /api/ParkingSlot (trạng thái ô). Không có toạ độ.
  Future<List<ParkingLotModel>> _lotsFromCatalog() async {
    final results = await Future.wait([_get(ApiEndpoints.floors), getAllSlots()]);
    final names = <String, String>{};
    for (final f in JsonRead.list(results[0])) {
      final id = JsonRead.str(f, 'parkingId');
      if (id.isNotEmpty) names.putIfAbsent(id, () => JsonRead.str(f, 'parkingName'));
    }
    final slots = results[1] as List<ParkingSlotModel>;
    final byLot = <String, Map<String, ({String name, int total, int available})>>{};
    for (final s in slots) {
      if (s.parkingId.isEmpty) continue;
      final types = byLot.putIfAbsent(s.parkingId, () => {});
      final cur = types[s.vehicleTypeId] ?? (name: s.vehicleTypeName, total: 0, available: 0);
      types[s.vehicleTypeId] = (
        name: cur.name,
        total: cur.total + 1,
        available: cur.available + (s.isAvailable ? 1 : 0),
      );
    }
    final ids = {...names.keys, ...byLot.keys};
    return [
      for (final id in ids)
        () {
          final types = byLot[id] ?? const {};
          final availability = [
            for (final e in types.entries)
              LotTypeAvailability(
                vehicleTypeId: e.key,
                vehicleTypeName: e.value.name,
                totalSlots: e.value.total,
                availableSlots: e.value.available,
              ),
          ];
          return ParkingLotModel(
            id: id,
            name: names[id] ?? 'Bãi đỗ',
            location: '',
            totalSlots: availability.fold(0, (s, a) => s + a.totalSlots),
            availableSlots: availability.fold(0, (s, a) => s + a.availableSlots),
            availability: availability,
          );
        }(),
    ];
  }

  // ---------------------------------------------------------------- vehicles

  Future<List<VehicleModel>> getMyVehicles() async =>
      _list(await _get(ApiEndpoints.myVehicles), VehicleModel.fromJson);

  /// Đăng ký xe. Tên tự đặt / mẫu xe chỉ gửi khi có nhập: máy chủ chưa cập nhật
  /// sẽ từ chối trường lạ (400), khi đó lưu xe không kèm tên để khách vẫn thêm được xe.
  Future<VehicleModel> addVehicle({
    required String vehicleTypeId,
    required String licensePlate,
    String? nickname,
    String? modelName,
  }) async {
    final base = {'vehicleTypeId': vehicleTypeId, 'licensePlate': licensePlate};
    final names = {
      if (nickname != null && nickname.trim().isNotEmpty) 'nickname': nickname.trim(),
      if (modelName != null && modelName.trim().isNotEmpty) 'modelName': modelName.trim(),
    };
    try {
      return VehicleModel.fromJson(
          _obj(await _post(ApiEndpoints.vehicles, {...base, ...names}), 'xe'));
    } on ValidationException catch (e) {
      if (names.isEmpty || !_unknownField(e)) rethrow;
      return VehicleModel.fromJson(_obj(await _post(ApiEndpoints.vehicles, base), 'xe'));
    }
  }

  /// Đổi tên tự đặt / mẫu xe. Chuỗi rỗng là xoá.
  Future<VehicleModel> renameVehicle(
    String vehicleId, {
    required String nickname,
    required String modelName,
  }) async {
    try {
      return VehicleModel.fromJson(_obj(
        await _put(ApiEndpoints.vehicleById(vehicleId), {
          'nickname': nickname.trim(),
          'modelName': modelName.trim(),
        }),
        'xe',
      ));
    } on ValidationException catch (e) {
      if (!_unknownField(e)) rethrow;
      throw const ValidationException(
          message: 'Máy chủ chưa hỗ trợ đặt tên xe. Vui lòng thử lại sau khi hệ thống cập nhật.');
    }
  }

  /// Lỗi 400 do máy chủ cũ không biết trường mới ("property x should not exist").
  static bool _unknownField(AppException e) =>
      '${e.message} ${e.details ?? ''}'.contains('should not exist');

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

  /// Huỷ đặt chỗ; trả về lời nhắn của máy chủ (vd. đã hoàn bao nhiêu tiền cọc vào ví).
  Future<String?> cancelReservation(String reservationId) async {
    final res = await _api.put<dynamic>(ApiEndpoints.cancelReservation(reservationId),
        data: const <String, dynamic>{});
    return res.message;
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
    String? parkingId,
    String paymentMethod = 'PayOS',
  }) async =>
      RegistrationResultModel.fromJson(_obj(
        await _post(ApiEndpoints.registerSubscription, {
          'packageId': packageId,
          'vehicleId': vehicleId,
          'paymentMethod': paymentMethod,
          if (fixedSlotId != null) 'fixedSlotId': fixedSlotId,
          if (parkingId != null) 'parkingId': parkingId,
        }),
        'đăng ký gói',
      ));

  Future<PaymentLinkModel> repaySubscription(String subscriptionId) async =>
      PaymentLinkModel.fromJson(_obj(
        await _post(ApiEndpoints.subscriptionPayment(subscriptionId)),
        'thanh toán',
      ));

  /// Thanh toán đơn vé đang chờ bằng PayOS (trả link) hoặc ví (kích hoạt ngay).
  Future<RegistrationResultModel> paySubscription(String subscriptionId, String paymentMethod) async =>
      RegistrationResultModel.fromJson(_obj(
        await _post(ApiEndpoints.subscriptionPayment(subscriptionId), {'paymentMethod': paymentMethod}),
        'thanh toán',
      ));

  /// Gia hạn: PayOS trả link + mã QR; Wallet trừ ví và gia hạn ngay (activated).
  Future<RegistrationResultModel> renewSubscription(
    String subscriptionId,
    String packageId, {
    required String password,
    String paymentMethod = 'PayOS',
  }) async =>
      RegistrationResultModel.fromJson(_obj(
        await _post(ApiEndpoints.renewSubscription(subscriptionId), {
          'packageId': packageId,
          'password': password,
          'paymentMethod': paymentMethod,
        }),
        'gia hạn',
      ));

  Future<List<RenewalModel>> getRenewals(String subscriptionId) async => _list(
        await _get(ApiEndpoints.subscriptionRenewals(subscriptionId)),
        RenewalModel.fromJson,
      );

  Future<void> cancelSubscription(String subscriptionId, {required String password}) async {
    await _put(ApiEndpoints.cancelSubscription(subscriptionId), {'password': password});
  }

  Future<List<VehicleChangeRequestModel>> getMyVehicleChangeRequests() async => _list(
        await _get(ApiEndpoints.myVehicleChangeRequests),
        VehicleChangeRequestModel.fromJson,
      );

  Future<void> requestVehicleChange({
    required String subscriptionId,
    required String newLicensePlate,
    required String reason,
    required String password,
  }) async {
    await _post(ApiEndpoints.requestChangeVehicle, {
      'subscriptionId': subscriptionId,
      'newLicensePlate': newLicensePlate,
      'reason': reason,
      'password': password,
    });
  }

  Future<void> updateVehicleChangeRequest({
    required String requestId,
    required String newLicensePlate,
    required String reason,
    required String password,
  }) async {
    await _put(ApiEndpoints.vehicleChangeRequestById(requestId), {
      'newLicensePlate': newLicensePlate,
      'reason': reason,
      'password': password,
    });
  }

  Future<void> withdrawVehicleChangeRequest(String requestId) async {
    await _api.delete<dynamic>(ApiEndpoints.vehicleChangeRequestById(requestId));
  }

  // ----------------------------------------------------------- contracts

  Future<List<ContractModel>> getMyContracts() async =>
      _list(await _get(ApiEndpoints.myContracts), ContractModel.fromJson);

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

  Future<List<IncidentModel>> getMyIncidents() async {
    final items = _list(await _get(ApiEndpoints.myIncidentReports), IncidentModel.fromJson);
    // Mới nhất trước; máy chủ cũ không có createdAt thì giữ thứ tự trả về.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    items.sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
    return items;
  }

  Future<IncidentModel> cancelIncident(String incidentId) async => IncidentModel.fromJson(
        _obj(await _put(ApiEndpoints.cancelIncident(incidentId)), 'sự cố'),
      );

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

  // ================= Máy quét của nhân viên =================

  Future<List<GateModel>> getGates() async =>
      _list(await _get(ApiEndpoints.gates), GateModel.fromJson);

  /// Gửi ảnh biển số kèm cổng và giờ chụp; nhân viên quét lấy từ token.
  /// Máy chủ nhận diện, đối chiếu đặt chỗ rồi đẩy real-time cho web staff.
  Future<GateScanModel> sendGateScan({
    required String gateId,
    required Uint8List bytes,
    required DateTime capturedAt,
  }) async {
    final form = FormData.fromMap({
      'gateId': gateId,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'file': MultipartFile.fromBytes(bytes,
          filename: 'plate-${capturedAt.millisecondsSinceEpoch}.jpg',
          contentType: DioMediaType('image', 'jpeg')),
    });
    final res = await _api.post<dynamic>(ApiEndpoints.gateScans, data: form);
    return GateScanModel.fromJson(_obj(res.result, 'lượt quét'));
  }

  Future<List<GateScanModel>> getMyRecentGateScans({int limit = 20}) async => _list(
        await _get(ApiEndpoints.recentGateScans, query: {'mine': 'true', 'limit': '$limit'}),
        GateScanModel.fromJson,
      );

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

  Future<NotificationPage> getNotifications() async {
    try {
      return NotificationPage.fromJson(await _get(ApiEndpoints.myNotifications));
    } on NotFoundException {
      return NotificationPage.unavailable;
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _put(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> markAllNotificationsRead() async {
    await _put(ApiEndpoints.markAllNotificationsRead);
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete<dynamic>(ApiEndpoints.deleteNotification(id));
  }

  // ------------------------------------------------------- mã vào bãi 1 lần

  static const _entryPassUnavailable = NotFoundException(
      message: 'Máy chủ chưa bật mã QR gửi xe 1 lần. Bạn vẫn có thể vào bãi bình thường.');

  Future<List<EntryPassModel>> getMyEntryPasses() async {
    try {
      return _list(await _get(ApiEndpoints.myEntryPasses), EntryPassModel.fromJson);
    } on NotFoundException {
      throw _entryPassUnavailable;
    }
  }

  Future<EntryPassModel> createEntryPass(String vehicleId) async {
    try {
      return EntryPassModel.fromJson(
          _obj(await _post(ApiEndpoints.entryPasses, {'vehicleId': vehicleId}), 'mã vào bãi'));
    } on NotFoundException catch (e) {
      // 404 khi máy chủ chưa có API (khác 404 "không tìm thấy xe" có thông báo riêng).
      if (e.message.contains('xe')) rethrow;
      throw _entryPassUnavailable;
    }
  }

  Future<void> cancelEntryPass(String id) async {
    await _api.delete<dynamic>(ApiEndpoints.entryPassById(id));
  }

  // -------------------------------------------------------------- profile

  Future<UserModel> getProfile() async =>
      UserModel.fromJson(_obj(await _get(ApiEndpoints.profile), 'hồ sơ'));

  /// Tải ảnh đại diện (JPEG / PNG / WebP, tối đa 5MB), trả hồ sơ có avatarUrl mới.
  Future<UserModel> uploadAvatar(Uint8List bytes, String fileName) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final result = await _api.post<dynamic>(ApiEndpoints.profileAvatar, data: form);
    return UserModel.fromJson(_obj(result.result, 'hồ sơ'));
  }

  /// Đổi mật khẩu: máy chủ xác minh mật khẩu hiện tại.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _post(ApiEndpoints.changePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Đổi email bước 1: xác minh mật khẩu, máy chủ gửi OTP tới [newEmail].
  Future<void> requestEmailChange({required String newEmail, required String password}) async {
    await _post(ApiEndpoints.requestEmailChange, {'newEmail': newEmail, 'password': password});
  }

  /// Đổi email bước 2: đúng OTP thì email đăng nhập đổi; trả email mới.
  Future<String> verifyEmailChange(String otp) async {
    final raw = _obj(await _post(ApiEndpoints.verifyEmailChange, {'otp': otp}), 'đổi email');
    return JsonRead.str(raw, 'email');
  }

  /// Xoá tài khoản (máy chủ ẩn danh hoá hồ sơ). Máy chủ cũ chưa có API thì báo rõ.
  Future<void> deleteAccount(String password) async {
    try {
      await _post(ApiEndpoints.deleteAccount, {'password': password});
    } on NotFoundException catch (e) {
      if (e.message.contains('người dùng')) rethrow;
      throw const ValidationException(
          message: 'Máy chủ chưa hỗ trợ xoá tài khoản trên app. Vui lòng liên hệ quản lý bãi.');
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async =>
      UserModel.fromJson(_obj(
        await _put(ApiEndpoints.profile, {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
        'hồ sơ',
      ));
}
