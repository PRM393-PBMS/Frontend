import '../../core/utils/json_read.dart';

typedef J = Map<String, dynamic>;

bool _is(String? value, String expected) =>
    (value ?? '').toLowerCase() == expected.toLowerCase();

/// Vé QR do backend sinh: `{ qrPayload, qrCodeDataUrl }`.
class TicketModel {
  final String qrPayload;
  final String? qrCodeDataUrl;

  const TicketModel({required this.qrPayload, this.qrCodeDataUrl});

  static TicketModel? fromJson(dynamic json) {
    if (json is! J) return null;
    final payload = JsonRead.str(json, 'qrPayload');
    if (payload.isEmpty) return null;
    return TicketModel(
      qrPayload: payload,
      qrCodeDataUrl: JsonRead.strOrNull(json, 'qrCodeDataUrl'),
    );
  }
}

/// Liên kết thanh toán PayOS (đặt chỗ, đăng ký/gia hạn vé tháng, checkout).
class PaymentLinkModel {
  final String paymentUrl;
  final String? orderCode;
  final String? paymentId;
  final String? paymentLinkId;
  final double? amount;
  final String? reservationId;
  final String? subscriptionId;
  final TicketModel? ticket;

  /// Chuỗi VietQR của đơn PayOS: quét bằng app ngân hàng để trả.
  final String? qrCode;

  const PaymentLinkModel({
    required this.paymentUrl,
    this.orderCode,
    this.paymentId,
    this.paymentLinkId,
    this.amount,
    this.reservationId,
    this.subscriptionId,
    this.ticket,
    this.qrCode,
  });

  factory PaymentLinkModel.fromJson(J json) => PaymentLinkModel(
        paymentUrl: JsonRead.str(json, 'paymentUrl'),
        orderCode: JsonRead.strOrNull(json, 'orderCode'),
        paymentId: JsonRead.strOrNull(json, 'paymentId'),
        paymentLinkId: JsonRead.strOrNull(json, 'paymentLinkId'),
        amount: JsonRead.numOrNull(json, 'amount') ??
            JsonRead.numOrNull(json, 'depositAmount'),
        reservationId: JsonRead.strOrNull(json, 'reservationId'),
        subscriptionId: JsonRead.strOrNull(json, 'subscriptionId'),
        ticket: TicketModel.fromJson(json['ticket']),
        qrCode: JsonRead.strOrNull(json, 'qrCode'),
      );

  bool get hasUrl => paymentUrl.isNotEmpty;
}

class PaymentStatusModel {
  final String paymentStatus;
  final double amount;
  final String? orderCode;
  final String? reservationId;

  const PaymentStatusModel({
    required this.paymentStatus,
    required this.amount,
    this.orderCode,
    this.reservationId,
  });

  bool get isPaid => _is(paymentStatus, 'success') || _is(paymentStatus, 'paid');
  bool get isPending => _is(paymentStatus, 'pending');

  factory PaymentStatusModel.fromJson(J json) => PaymentStatusModel(
        paymentStatus: JsonRead.str(json, 'paymentStatus', 'Pending'),
        amount: JsonRead.num_(json, 'amount'),
        orderCode: JsonRead.strOrNull(json, 'orderCode'),
        reservationId: JsonRead.strOrNull(json, 'reservationId'),
      );
}

class PaymentModel {
  final String paymentId;
  final double amount;
  final String paymentMethod;
  final String? paymentType;
  final String paymentStatus;
  final DateTime? paymentTime;
  final String? transactionReference;

  /// Chỉ có trong lịch sử thanh toán của tôi (`GET /api/payments/my`).
  final String? paymentTypeLabel;
  final String? licensePlate;
  final String? packageName;

  const PaymentModel({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
    this.paymentType,
    required this.paymentStatus,
    this.paymentTime,
    this.transactionReference,
    this.paymentTypeLabel,
    this.licensePlate,
    this.packageName,
  });

  factory PaymentModel.fromJson(J json) => PaymentModel(
        paymentId: JsonRead.str(json, 'paymentId'),
        amount: JsonRead.num_(json, 'amount'),
        paymentMethod: JsonRead.str(json, 'paymentMethod'),
        paymentType: JsonRead.strOrNull(json, 'paymentType'),
        paymentStatus: JsonRead.str(json, 'paymentStatus', 'Pending'),
        paymentTime: JsonRead.date(json, 'paymentTime'),
        transactionReference: JsonRead.strOrNull(json, 'transactionReference'),
        paymentTypeLabel: JsonRead.strOrNull(json, 'paymentTypeLabel'),
        licensePlate: JsonRead.strOrNull(json, 'licensePlate'),
        packageName: JsonRead.strOrNull(json, 'packageName'),
      );
}

/// Một trang của `GET /api/payments/my`.
class PaymentPage {
  final List<PaymentModel> items;
  final int page;
  final int total;
  final bool hasMore;

  const PaymentPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  factory PaymentPage.fromJson(J json) => PaymentPage(
        items: JsonRead.list(json['items']).map(PaymentModel.fromJson).toList(),
        page: JsonRead.int_(json, 'page', 1),
        total: JsonRead.int_(json, 'total'),
        hasMore: JsonRead.bool_(json, 'hasMore'),
      );
}

/// Kết quả `GET /api/ParkingSession/my/:id/checkout-payment`.
class CheckoutPaymentModel {
  final PaymentModel? payment;
  final PaymentLinkModel? online;

  const CheckoutPaymentModel({this.payment, this.online});

  bool get hasRequest => payment != null;

  factory CheckoutPaymentModel.fromJson(J json) {
    final payment = JsonRead.map(json, 'payment');
    final online = JsonRead.map(json, 'onlinePayment');
    return CheckoutPaymentModel(
      payment: payment == null ? null : PaymentModel.fromJson(payment),
      online: online == null ? null : PaymentLinkModel.fromJson(online),
    );
  }
}

/// Phí tạm tính của một phiên gửi xe.
class FeePreviewModel {
  final double amount;
  final double grossAmount;
  final double depositAmount;
  final double totalHours;
  final int billedHours;
  final double basePrice;
  final int baseHours;
  final double extraHourPrice;
  final double nightSurcharge;
  final int nightSurchargeCount;
  final bool isCoveredBySubscription;

  const FeePreviewModel({
    required this.amount,
    required this.grossAmount,
    required this.depositAmount,
    required this.totalHours,
    required this.billedHours,
    required this.basePrice,
    required this.baseHours,
    required this.extraHourPrice,
    required this.nightSurcharge,
    required this.nightSurchargeCount,
    required this.isCoveredBySubscription,
  });

  factory FeePreviewModel.fromJson(J json) => FeePreviewModel(
        amount: JsonRead.num_(json, 'amount'),
        grossAmount: JsonRead.numOrNull(json, 'grossAmount') ??
            JsonRead.num_(json, 'amount'),
        depositAmount: JsonRead.num_(json, 'depositAmount'),
        totalHours: JsonRead.num_(json, 'totalHours'),
        billedHours: JsonRead.int_(json, 'billedHours'),
        basePrice: JsonRead.num_(json, 'basePrice'),
        baseHours: JsonRead.int_(json, 'baseHours', 1),
        extraHourPrice: JsonRead.num_(json, 'extraHourPrice'),
        nightSurcharge: JsonRead.num_(json, 'nightSurcharge'),
        nightSurchargeCount: JsonRead.int_(json, 'nightSurchargeCount'),
        isCoveredBySubscription: JsonRead.bool_(json, 'isCoveredBySubscription'),
      );
}

class ParkingSessionModel {
  final String sessionId;
  final String? reservationId;
  final String licensePlateIn;
  final String? licensePlateOut;
  final String? vehicleTypeName;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? entryGateName;
  final String? exitGateName;
  final String? assignedSlotCode;
  final String? actualSlotCode;
  final String status;
  final double? paymentAmount;
  final String? paymentStatus;
  final String? paymentMethod;
  final DateTime? paymentTime;
  final TicketModel? ticket;
  final ExitPassModel? exitPass;

  /// Ảnh camera lúc vào/ra và biển số của xe đã đăng ký (để đối chiếu khi OCR đọc sai).
  final String? entryImageUrl;
  final String? exitImageUrl;
  final String? registeredLicensePlate;

  const ParkingSessionModel({
    required this.sessionId,
    this.reservationId,
    required this.licensePlateIn,
    this.licensePlateOut,
    this.vehicleTypeName,
    required this.entryTime,
    this.exitTime,
    this.entryGateName,
    this.exitGateName,
    this.assignedSlotCode,
    this.actualSlotCode,
    required this.status,
    this.paymentAmount,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentTime,
    this.ticket,
    this.exitPass,
    this.entryImageUrl,
    this.exitImageUrl,
    this.registeredLicensePlate,
  });

  bool get isActive => _is(status, 'active');

  /// Biển camera đọc khác biển xe đã đăng ký (bỏ qua dấu, khoảng trắng, hoa thường).
  bool get plateMismatch {
    final registered = registeredLicensePlate;
    if (registered == null || registered.isEmpty) return false;
    String norm(String v) => v.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return norm(registered) != norm(licensePlateIn);
  }
  bool get isPrepaid => exitPass != null;
  bool get isMotorbike => (vehicleTypeName ?? '').toLowerCase().contains('máy');
  String? get slotCode => actualSlotCode ?? assignedSlotCode;

  Duration get parkedDuration {
    final end = exitTime ?? DateTime.now();
    return end.isAfter(entryTime) ? end.difference(entryTime) : Duration.zero;
  }

  factory ParkingSessionModel.fromJson(J json) => ParkingSessionModel(
        sessionId: JsonRead.str(json, 'sessionId'),
        reservationId: JsonRead.strOrNull(json, 'reservationId'),
        licensePlateIn: JsonRead.str(json, 'licensePlateIn'),
        licensePlateOut: JsonRead.strOrNull(json, 'licensePlateOut'),
        vehicleTypeName: JsonRead.strOrNull(json, 'vehicleTypeName'),
        entryTime: JsonRead.date(json, 'entryTime') ?? DateTime.now(),
        exitTime: JsonRead.date(json, 'exitTime'),
        entryGateName: JsonRead.strOrNull(json, 'entryGateName'),
        exitGateName: JsonRead.strOrNull(json, 'exitGateName'),
        assignedSlotCode: JsonRead.strOrNull(json, 'assignedSlotCode'),
        actualSlotCode: JsonRead.strOrNull(json, 'actualSlotCode'),
        status: JsonRead.str(json, 'status', 'Active'),
        paymentAmount: JsonRead.numOrNull(json, 'paymentAmount'),
        paymentStatus: JsonRead.strOrNull(json, 'paymentStatus'),
        paymentMethod: JsonRead.strOrNull(json, 'paymentMethod'),
        paymentTime: JsonRead.date(json, 'paymentTime'),
        ticket: TicketModel.fromJson(json['ticket']),
        exitPass: ExitPassModel.fromJson(JsonRead.map(json, 'exitPass')),
        entryImageUrl: JsonRead.strOrNull(json, 'entryImageUrl'),
        exitImageUrl: JsonRead.strOrNull(json, 'exitImageUrl'),
        registeredLicensePlate: JsonRead.strOrNull(json, 'registeredLicensePlate'),
      );
}

/// Mã ra cổng sau khi thanh toán trước; hiệu lực tới khi xe ra khỏi bãi.
class ExitPassModel {
  final String code;
  final String qrPayload;
  final DateTime? prepaidAt;

  const ExitPassModel({required this.code, required this.qrPayload, this.prepaidAt});

  static ExitPassModel? fromJson(J? json) {
    if (json == null) return null;
    final code = JsonRead.str(json, 'code');
    final payload = JsonRead.str(json, 'qrPayload');
    if (code.isEmpty || payload.isEmpty) return null;
    return ExitPassModel(
      code: code,
      qrPayload: payload,
      prepaidAt: JsonRead.date(json, 'prepaidAt'),
    );
  }
}

/// Kết quả `POST /my/:id/prepay` và `GET /my/:id/exit-pass`.
class PrepayResultModel {
  final ExitPassModel? exitPass;
  final PaymentLinkModel? online;
  final String? paymentStatus;
  final double? walletBalance;

  const PrepayResultModel({this.exitPass, this.online, this.paymentStatus, this.walletBalance});

  factory PrepayResultModel.fromJson(J json) {
    final online = JsonRead.map(json, 'onlinePayment');
    final payment = JsonRead.map(json, 'payment');
    final fee = JsonRead.map(json, 'fee');
    return PrepayResultModel(
      exitPass: ExitPassModel.fromJson(JsonRead.map(json, 'exitPass')),
      online: online == null
          ? null
          : PaymentLinkModel(
              paymentUrl: JsonRead.str(online, 'paymentUrl'),
              orderCode: JsonRead.strOrNull(online, 'orderCode'),
              paymentLinkId: JsonRead.strOrNull(online, 'paymentLinkId'),
              paymentId: payment == null ? null : JsonRead.strOrNull(payment, 'paymentId'),
              amount: (payment == null ? null : JsonRead.numOrNull(payment, 'amount')) ??
                  (fee == null ? null : JsonRead.numOrNull(fee, 'amount')),
            ),
      paymentStatus: JsonRead.strOrNull(json, 'paymentStatus'),
      walletBalance: JsonRead.numOrNull(json, 'walletBalance'),
    );
  }
}

/// Bộ lọc lịch sử ví, ứng với `/transactions`, `/top-ups`, `/spends`.
enum WalletHistoryFilter { all, topUps, spends }

/// Giao dịch ví (định dạng của module wallets): nạp (Credit) hoặc chi (Debit).
class WalletTransactionModel {
  final String id;
  final String type;
  final bool isCredit;
  final double amount;
  final double balanceAfter;
  final String? description;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.isCredit,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  bool get isTopUp => isCredit;

  factory WalletTransactionModel.fromJson(J json) {
    final signed = JsonRead.num_(json, 'amount');
    final direction = JsonRead.strOrNull(json, 'direction');
    return WalletTransactionModel(
      id: JsonRead.str(json, 'walletTransactionId'),
      type: JsonRead.str(json, 'type'),
      isCredit: direction == null ? signed > 0 : _is(direction, 'credit'),
      amount: JsonRead.numOrNull(json, 'absoluteAmount') ?? signed.abs(),
      balanceAfter: JsonRead.num_(json, 'balanceAfter'),
      description: JsonRead.strOrNull(json, 'description'),
      createdAt: JsonRead.date(json, 'createdAt') ?? DateTime.now(),
    );
  }
}

class WalletModel {
  /// Hạn mức nạp của backend (WalletsService: 2.000 - 10.000.000 VND, số nguyên).
  static const double minTopUp = 2000;
  static const double maxTopUp = 10000000;

  final String walletId;
  final double balance;
  final List<WalletTransactionModel> transactions;

  /// Máy chủ lỗi khi tải lịch sử: vẫn hiện số dư, báo riêng phần lịch sử.
  final String? historyError;

  const WalletModel({
    required this.walletId,
    required this.balance,
    required this.transactions,
    this.historyError,
  });

  double get topUpMin => minTopUp;
  double get topUpMax => maxTopUp;

  factory WalletModel.fromJson(J json) => WalletModel(
        walletId: JsonRead.str(json, 'walletId'),
        balance: JsonRead.num_(json, 'walletBalance'),
        transactions: JsonRead.list(json['transactions'])
            .map(WalletTransactionModel.fromJson)
            .toList(),
      );
}

class LotTypeAvailability {
  final String vehicleTypeId;
  final String vehicleTypeName;
  final int totalSlots;
  final int availableSlots;

  const LotTypeAvailability({
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.totalSlots,
    required this.availableSlots,
  });

  factory LotTypeAvailability.fromJson(J json) => LotTypeAvailability(
        vehicleTypeId: JsonRead.str(json, 'vehicleTypeId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        totalSlots: JsonRead.int_(json, 'totalSlots'),
        availableSlots: JsonRead.int_(json, 'availableSlots'),
      );
}

/// Một bãi đỗ (`/parkings/available`): toạ độ có thể null nếu quản lý chưa nhập.
class ParkingLotModel {
  final String id;
  final String name;
  final String location;
  final double? latitude;
  final double? longitude;
  final int totalSlots;
  final int availableSlots;
  final List<LotTypeAvailability> availability;

  /// Ảnh và giờ mở cửa do quản lý nhập (null nếu chưa có).
  final String? imageUrl;
  final String? openingHours;

  const ParkingLotModel({
    required this.id,
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    required this.totalSlots,
    required this.availableSlots,
    required this.availability,
    this.imageUrl,
    this.openingHours,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  int get occupiedPercent =>
      totalSlots == 0 ? 0 : ((totalSlots - availableSlots) / totalSlots * 100).round();

  /// Địa chỉ để hiển thị; bỏ giá trị giữ chỗ như "N/A".
  String? get displayLocation {
    final l = location.trim();
    return l.isEmpty || l.toUpperCase() == 'N/A' ? null : l;
  }

  factory ParkingLotModel.fromJson(J json) => ParkingLotModel(
        id: JsonRead.str(json, 'parkingId'),
        name: JsonRead.str(json, 'name'),
        location: JsonRead.str(json, 'location'),
        latitude: JsonRead.numOrNull(json, 'latitude'),
        longitude: JsonRead.numOrNull(json, 'longitude'),
        totalSlots: JsonRead.int_(json, 'totalSlots'),
        availableSlots: JsonRead.int_(json, 'availableSlots'),
        availability: JsonRead.list(json['availability']).map(LotTypeAvailability.fromJson).toList(),
        imageUrl: JsonRead.strOrNull(json, 'imageUrl'),
        openingHours: JsonRead.strOrNull(json, 'openingHours'),
      );
}

/// Xe đã đăng ký vào tài khoản (`/api/vehicles/my`).
class VehicleModel {
  final String id;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final String licensePlate;

  /// Tên khách tự đặt, vd. "Xe của mẹ".
  final String? nickname;

  /// Mẫu xe / tên xe, vd. "Toyota Vios 2020".
  final String? modelName;

  const VehicleModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.licensePlate,
    this.nickname,
    this.modelName,
  });

  /// Tên hiển thị: tên tự đặt, chưa có thì dùng biển số.
  String get displayName => nickname ?? licensePlate;

  /// Dòng phụ: biển số (khi đã có tên), mẫu xe, loại xe.
  String get details => [
        if (nickname != null) licensePlate,
        if (modelName != null) modelName!,
        vehicleTypeName,
      ].join(', ');

  bool get isMotorbike => vehicleTypeName.toLowerCase().contains('máy');
  bool get isCar {
    final n = vehicleTypeName.toLowerCase();
    return n.contains('ô tô') || n.contains('oto') || n.contains('car');
  }

  factory VehicleModel.fromJson(J json) => VehicleModel(
        id: JsonRead.str(json, 'vehicleId'),
        vehicleTypeId: JsonRead.str(json, 'vehicleTypeId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        licensePlate: JsonRead.str(json, 'licensePlate'),
        nickname: _blankToNull(JsonRead.strOrNull(json, 'nickname')),
        modelName: _blankToNull(JsonRead.strOrNull(json, 'modelName')),
      );

  static String? _blankToNull(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
}

/// Loại xe khách được chọn (lấy từ bảng giá công khai).
class VehicleTypeOption {
  final String id;
  final String name;

  const VehicleTypeOption(this.id, this.name);
}

class FacilityAvailabilityModel {
  final String floorId;
  final String floorName;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final int totalSlots;
  final int availableSlots;
  final int occupiedSlots;
  final int assignedSlots;

  const FacilityAvailabilityModel({
    required this.floorId,
    required this.floorName,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.totalSlots,
    required this.availableSlots,
    required this.occupiedSlots,
    required this.assignedSlots,
  });

  double get availabilityRatio => totalSlots > 0 ? availableSlots / totalSlots : 0;

  factory FacilityAvailabilityModel.fromJson(J json) => FacilityAvailabilityModel(
        floorId: JsonRead.str(json, 'floorId'),
        floorName: JsonRead.str(json, 'floorName'),
        vehicleTypeId: JsonRead.str(json, 'vehicleTypeId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        totalSlots: JsonRead.int_(json, 'totalSlots'),
        availableSlots: JsonRead.int_(json, 'availableSlots'),
        occupiedSlots: JsonRead.int_(json, 'occupiedSlots'),
        assignedSlots: JsonRead.int_(json, 'assignedSlots'),
      );
}

class PricingPolicyModel {
  final String policyId;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final double basePrice;
  final int baseHours;
  final double extraHourPrice;
  final double nightSurcharge;
  final String status;

  const PricingPolicyModel({
    required this.policyId,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.basePrice,
    required this.baseHours,
    required this.extraHourPrice,
    required this.nightSurcharge,
    required this.status,
  });

  bool get isActive => _is(status, 'active');

  factory PricingPolicyModel.fromJson(J json) => PricingPolicyModel(
        policyId: JsonRead.str(json, 'policyId'),
        vehicleTypeId: JsonRead.str(json, 'vehicleTypeId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        basePrice: JsonRead.num_(json, 'basePrice'),
        baseHours: JsonRead.int_(json, 'baseHours', 1),
        extraHourPrice: JsonRead.num_(json, 'extraHourPrice'),
        nightSurcharge: JsonRead.num_(json, 'nightSurcharge'),
        status: JsonRead.str(json, 'status', 'Active'),
      );
}

class SubscriptionPackageModel {
  final String packageId;
  final String packageName;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final int durationMonths;
  final double price;
  final bool requireFixedSlot;

  /// Gói dùng được ở mọi bãi (không gắn bãi, không cố định ô).
  final bool allParkings;
  final String? description;
  final String status;

  const SubscriptionPackageModel({
    required this.packageId,
    required this.packageName,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.durationMonths,
    required this.price,
    required this.requireFixedSlot,
    this.allParkings = false,
    this.description,
    required this.status,
  });

  bool get isActive => _is(status, 'active');
  bool get isMotorbike => vehicleTypeName.toLowerCase().contains('máy');

  /// Cần chọn ô cố định khi đăng ký.
  bool get needsFixedSlot => requireFixedSlot && !isMotorbike && !allParkings;

  factory SubscriptionPackageModel.fromJson(J json) => SubscriptionPackageModel(
        packageId: JsonRead.str(json, 'packageId'),
        packageName: JsonRead.str(json, 'packageName'),
        vehicleTypeId: JsonRead.str(json, 'vehicleTypeId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        durationMonths: JsonRead.int_(json, 'durationMonths', 1),
        price: JsonRead.num_(json, 'price'),
        requireFixedSlot: JsonRead.bool_(json, 'requireFixedSlot'),
        allParkings: JsonRead.bool_(json, 'allParkings'),
        description: JsonRead.strOrNull(json, 'description'),
        status: JsonRead.str(json, 'status', 'Active'),
      );
}

class ParkingSlotModel {
  final String slotId;
  final String parkingId;
  final String vehicleTypeName;
  final String floorId;
  final String floorName;
  final String slotCode;
  final String vehicleTypeId;
  final String status;
  final bool isResident;

  const ParkingSlotModel({
    required this.slotId,
    this.parkingId = '',
    this.vehicleTypeName = '',
    required this.floorId,
    required this.floorName,
    required this.slotCode,
    required this.vehicleTypeId,
    required this.status,
    required this.isResident,
  });

  bool get isAvailable => _is(status, 'available');

  factory ParkingSlotModel.fromJson(J json) => ParkingSlotModel(
        slotId: JsonRead.str(json, 'slotId'),
        parkingId: JsonRead.str(json, 'parkingId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        floorId: JsonRead.str(json, 'floorId'),
        floorName: JsonRead.str(json, 'floorName'),
        slotCode: JsonRead.str(json, 'slotCode'),
        vehicleTypeId: JsonRead.str(json, 'vehicleTypeId'),
        status: JsonRead.str(json, 'status'),
        isResident: JsonRead.bool_(json, 'isResident'),
      );
}

/// Trạng thái: Pending, Confirmed, Modified, CheckedIn, Completed, Cancelled, NoShow.
class ReservationModel {
  final String reservationId;
  final String vehicleTypeName;
  final String? vehicleId;
  final String? licensePlate;

  /// Tiền cọc đã/đang thu cho đơn; null với máy chủ cũ chưa trả trường này.
  final double? depositAmount;
  final DateTime expectedEntryTime;
  final String status;
  final DateTime? createdAt;
  final TicketModel? ticket;

  const ReservationModel({
    required this.reservationId,
    required this.vehicleTypeName,
    this.vehicleId,
    this.licensePlate,
    this.depositAmount,
    required this.expectedEntryTime,
    required this.status,
    this.createdAt,
    this.ticket,
  });

  /// Được vào trễ tối đa 30 phút; quá hạn máy chủ chuyển đơn sang NoShow.
  static const lateGrace = Duration(minutes: 30);

  /// Còn trong khung giờ có thể vào bãi.
  bool get _stillValid => expectedEntryTime.isAfter(DateTime.now().subtract(lateGrace));

  bool get isPending => _is(status, 'pending') && _stillValid;
  bool get isUpcoming => (_is(status, 'confirmed') || _is(status, 'modified')) && _stillValid;
  bool get canModify => isPending || isUpcoming;

  /// Máy chủ chỉ cho đổi giờ một lần, khi đơn đã đặt cọc (Confirmed, chưa Modified).
  bool get canChangeTime => _is(status, 'confirmed') && _stillValid;

  factory ReservationModel.fromJson(J json) => ReservationModel(
        reservationId: JsonRead.str(json, 'reservationId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName', 'Ô tô'),
        vehicleId: JsonRead.strOrNull(json, 'vehicleId'),
        licensePlate: JsonRead.strOrNull(json, 'licensePlate'),
        depositAmount: JsonRead.numOrNull(json, 'depositAmount'),
        expectedEntryTime: JsonRead.date(json, 'expectedEntryTime') ?? DateTime.now(),
        status: JsonRead.str(json, 'status', 'Pending'),
        createdAt: JsonRead.date(json, 'createdAt'),
        ticket: TicketModel.fromJson(json['ticket']),
      );
}

class MonthlySubscriptionModel {
  final String subscriptionId;
  final String licensePlate;
  final String vehicleType;
  final String packageName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double price;
  final String status;
  final String? fixedSlot;

  /// Bãi áp dụng vé; null với gói mọi bãi hoặc máy chủ cũ.
  final String? parkingName;
  final bool allParkings;
  final int? durationMonths;
  final String? contractId;
  final String? contractNumber;
  final String? contractStatus;

  const MonthlySubscriptionModel({
    required this.subscriptionId,
    required this.licensePlate,
    required this.vehicleType,
    required this.packageName,
    this.startDate,
    this.endDate,
    required this.price,
    required this.status,
    this.fixedSlot,
    this.parkingName,
    this.allParkings = false,
    this.durationMonths,
    this.contractId,
    this.contractNumber,
    this.contractStatus,
  });

  /// Đã quá ngày hết hạn (máy chủ có thể chưa kịp chuyển trạng thái sang Expired).
  bool get isExpired {
    if (_is(status, 'expired')) return true;
    final end = endDate;
    return end != null && end.isBefore(DateTime.now());
  }

  bool get isActive => _is(status, 'active') && !isExpired;

  /// Trạng thái để hiển thị: vé Active đã quá hạn hiện là Expired.
  String get displayStatus => _is(status, 'active') && isExpired ? 'Expired' : status;

  bool get isPendingPayment => status.toLowerCase().contains('pending');
  bool get hasContract => contractId != null;
  bool get needsSignature => hasContract && _is(contractStatus, 'pendingsignature');
  bool get isCancelled => _is(status, 'cancelled');

  int get daysLeft {
    final end = endDate;
    if (end == null) return 0;
    final diff = end.difference(DateTime.now()).inHours;
    return diff <= 0 ? 0 : (diff / 24).ceil();
  }

  double get elapsedRatio {
    final s = startDate, e = endDate;
    if (s == null || e == null || !e.isAfter(s)) return 0;
    final total = e.difference(s).inMinutes;
    final done = DateTime.now().difference(s).inMinutes;
    return (done / total).clamp(0.0, 1.0);
  }

  factory MonthlySubscriptionModel.fromJson(J json) => MonthlySubscriptionModel(
        subscriptionId: JsonRead.str(json, 'subscriptionId'),
        licensePlate: JsonRead.str(json, 'licensePlate'),
        vehicleType: JsonRead.str(json, 'vehicleType'),
        packageName: JsonRead.str(json, 'packageName'),
        startDate: JsonRead.date(json, 'startDate'),
        endDate: JsonRead.date(json, 'endDate'),
        price: JsonRead.num_(json, 'price'),
        status: JsonRead.str(json, 'status'),
        fixedSlot: JsonRead.strOrNull(json, 'fixedSlot'),
        parkingName: JsonRead.strOrNull(json, 'parkingName'),
        allParkings: JsonRead.bool_(json, 'allParkings'),
        durationMonths: JsonRead.numOrNull(json, 'durationMonths')?.round(),
        contractId: JsonRead.strOrNull(json, 'contractId'),
        contractNumber: JsonRead.strOrNull(json, 'contractNumber'),
        contractStatus: JsonRead.strOrNull(json, 'contractStatus'),
      );
}

/// Kết quả đăng ký vé: gói >= 3 tháng trả về hợp đồng cần ký thay vì link thanh toán.
class RegistrationResultModel {
  final String? subscriptionId;
  final String? contractId;
  final PaymentLinkModel? link;

  /// Trả bằng ví: gói được kích hoạt ngay, không có link PayOS.
  final bool activated;

  const RegistrationResultModel({
    this.subscriptionId,
    this.contractId,
    this.link,
    this.activated = false,
  });

  bool get requiresContract => contractId != null;

  factory RegistrationResultModel.fromJson(J json) {
    final contractId = JsonRead.bool_(json, 'requiresContract')
        ? JsonRead.strOrNull(json, 'contractId')
        : null;
    final activated = _is(JsonRead.strOrNull(json, 'status'), 'active');
    return RegistrationResultModel(
      subscriptionId: JsonRead.strOrNull(json, 'subscriptionId'),
      contractId: contractId,
      link: contractId == null && !activated ? PaymentLinkModel.fromJson(json) : null,
      activated: activated,
    );
  }
}

/// Hợp đồng vé tháng dài hạn, ký điện tử và được bãi niêm phong.
class ContractModel {
  final String id;
  final String subscriptionId;
  final String contractNumber;
  final String content;
  final String contentHash;
  final String status;
  final String? signerName;
  final String? signatureImageDataUrl;
  final DateTime? signedAt;
  final String? sealKeyId;
  final DateTime? createdAt;

  const ContractModel({
    required this.id,
    required this.subscriptionId,
    required this.contractNumber,
    required this.content,
    required this.contentHash,
    required this.status,
    this.signerName,
    this.signatureImageDataUrl,
    this.signedAt,
    this.sealKeyId,
    this.createdAt,
  });

  bool get isSigned => _is(status, 'signed');
  bool get isPending => _is(status, 'pendingsignature');

  factory ContractModel.fromJson(J json) => ContractModel(
        id: JsonRead.str(json, 'contractId'),
        subscriptionId: JsonRead.str(json, 'subscriptionId'),
        contractNumber: JsonRead.str(json, 'contractNumber'),
        content: JsonRead.str(json, 'content'),
        contentHash: JsonRead.str(json, 'contentHash'),
        status: JsonRead.str(json, 'status', 'PendingSignature'),
        signerName: JsonRead.strOrNull(json, 'signerName'),
        signatureImageDataUrl: JsonRead.strOrNull(json, 'signatureImage'),
        signedAt: JsonRead.date(json, 'signedAt'),
        sealKeyId: JsonRead.strOrNull(json, 'sealKeyId'),
        createdAt: JsonRead.date(json, 'createdAt'),
      );
}

class SignContractResultModel {
  final ContractModel contract;
  final PaymentLinkModel? payment;
  final String? paymentError;

  const SignContractResultModel({required this.contract, this.payment, this.paymentError});

  factory SignContractResultModel.fromJson(J json) {
    final payment = JsonRead.map(json, 'payment');
    return SignContractResultModel(
      contract: ContractModel.fromJson(JsonRead.map(json, 'contract') ?? const <String, dynamic>{}),
      payment: payment == null ? null : PaymentLinkModel.fromJson(payment),
      paymentError: JsonRead.strOrNull(json, 'paymentError'),
    );
  }
}

class ContractVerificationModel {
  final bool valid;
  final bool contentIntact;
  final bool signatureIntact;
  final bool sealValid;
  final bool keyMatches;
  final String? sealKeyId;

  const ContractVerificationModel({
    required this.valid,
    required this.contentIntact,
    required this.signatureIntact,
    required this.sealValid,
    required this.keyMatches,
    this.sealKeyId,
  });

  factory ContractVerificationModel.fromJson(J json) => ContractVerificationModel(
        valid: JsonRead.bool_(json, 'valid'),
        contentIntact: JsonRead.bool_(json, 'contentIntact'),
        signatureIntact: JsonRead.bool_(json, 'signatureIntact'),
        sealValid: JsonRead.bool_(json, 'sealValid'),
        keyMatches: JsonRead.bool_(json, 'keyMatches'),
        sealKeyId: JsonRead.strOrNull(json, 'sealKeyId'),
      );
}

class RenewalModel {
  final String renewalId;
  final DateTime? oldEndDate;
  final DateTime? newEndDate;
  final double amount;
  final DateTime? renewalDate;

  const RenewalModel({
    required this.renewalId,
    this.oldEndDate,
    this.newEndDate,
    required this.amount,
    this.renewalDate,
  });

  factory RenewalModel.fromJson(J json) => RenewalModel(
        renewalId: JsonRead.str(json, 'renewalId'),
        oldEndDate: JsonRead.date(json, 'oldEndDate'),
        newEndDate: JsonRead.date(json, 'newEndDate'),
        amount: JsonRead.num_(json, 'amount'),
        renewalDate: JsonRead.date(json, 'renewalDate'),
      );
}

class VehicleChangeRequestModel {
  final String requestId;
  final String subscriptionId;
  final String oldLicensePlate;
  final String newLicensePlate;
  final String? reason;
  final String? rejectionReason;
  final String status;
  final DateTime? createdAt;
  final String? packageName;

  const VehicleChangeRequestModel({
    required this.requestId,
    required this.subscriptionId,
    required this.oldLicensePlate,
    required this.newLicensePlate,
    this.reason,
    this.rejectionReason,
    required this.status,
    this.createdAt,
    this.packageName,
  });

  factory VehicleChangeRequestModel.fromJson(J json) => VehicleChangeRequestModel(
        requestId: JsonRead.str(json, 'requestId'),
        subscriptionId: JsonRead.str(json, 'subscriptionId'),
        oldLicensePlate: JsonRead.str(json, 'oldLicensePlate'),
        newLicensePlate: JsonRead.str(json, 'newLicensePlate'),
        reason: JsonRead.strOrNull(json, 'reason'),
        rejectionReason: JsonRead.strOrNull(json, 'rejectionReason'),
        status: JsonRead.str(json, 'status', 'Pending'),
        createdAt: JsonRead.date(json, 'createdAt'),
        packageName: JsonRead.strOrNull(json, 'packageName'),
      );
}

class IncidentModel {
  final String incidentId;
  final String? sessionId;
  final String issueType;
  final String description;
  final String? proofImageUrl;
  final String status;
  final String? handledByStaffFullName;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  /// Thời điểm khách báo (máy chủ cũ không có).
  final DateTime? createdAt;

  const IncidentModel({
    required this.incidentId,
    this.sessionId,
    required this.issueType,
    required this.description,
    this.proofImageUrl,
    required this.status,
    this.handledByStaffFullName,
    this.resolvedAt,
    this.resolutionNotes,
    this.createdAt,
  });

  /// Khách chỉ huỷ được khi bãi chưa xử lý xong.
  bool get canCancel => _is(status, 'open') || _is(status, 'inprogress');

  factory IncidentModel.fromJson(J json) => IncidentModel(
        incidentId: JsonRead.str(json, 'incidentId'),
        sessionId: JsonRead.strOrNull(json, 'sessionId'),
        issueType: JsonRead.str(json, 'issueType'),
        description: JsonRead.str(json, 'description'),
        proofImageUrl: JsonRead.strOrNull(json, 'proofImageUrl'),
        status: JsonRead.str(json, 'status', 'Open'),
        handledByStaffFullName: JsonRead.strOrNull(json, 'handledByStaffFullName'),
        resolvedAt: JsonRead.date(json, 'resolvedAt'),
        resolutionNotes: JsonRead.strOrNull(json, 'resolutionNotes'),
        createdAt: JsonRead.date(json, 'createdAt'),
      );
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory NotificationModel.fromJson(J json) => NotificationModel(
        id: JsonRead.str(json, 'id'),
        title: JsonRead.str(json, 'title'),
        message: JsonRead.str(json, 'message'),
        type: JsonRead.str(json, 'type', 'system'),
        isRead: JsonRead.bool_(json, 'isRead'),
        createdAt: JsonRead.date(json, 'createdAt') ?? DateTime.now(),
      );
}

/// `GET /api/Notification/my` → `{ items, unreadCount, total }`.
class NotificationPage {
  final List<NotificationModel> items;
  final int unreadCount;

  /// false: máy chủ chưa có dịch vụ thông báo (404), không phải lỗi mạng.
  final bool available;

  const NotificationPage({required this.items, required this.unreadCount, this.available = true});

  static const unavailable = NotificationPage(items: [], unreadCount: 0, available: false);

  factory NotificationPage.fromJson(dynamic json) {
    if (json is List) {
      final items = JsonRead.list(json).map(NotificationModel.fromJson).toList();
      return NotificationPage(
        items: items,
        unreadCount: items.where((n) => !n.isRead).length,
      );
    }
    if (json is J) {
      final items =
          JsonRead.list(json['items']).map(NotificationModel.fromJson).toList();
      return NotificationPage(
        items: items,
        unreadCount: JsonRead.numOrNull(json, 'unreadCount')?.round() ??
            items.where((n) => !n.isRead).length,
      );
    }
    return const NotificationPage(items: [], unreadCount: 0);
  }
}

/// Mã QR gửi xe một lần (POST/GET /api/entry-passes).
class EntryPassModel {
  final String id;
  final String code;
  final String status;
  final String licensePlate;
  final String? vehicleName;
  final String vehicleTypeName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? qrPayload;

  const EntryPassModel({
    required this.id,
    required this.code,
    required this.status,
    required this.licensePlate,
    this.vehicleName,
    required this.vehicleTypeName,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.qrPayload,
  });

  bool get isActive =>
      _is(status, 'active') && qrPayload != null && expiresAt.isAfter(DateTime.now());
  bool get isMotorbike => vehicleTypeName.toLowerCase().contains('máy');

  factory EntryPassModel.fromJson(J json) => EntryPassModel(
        id: JsonRead.str(json, 'entryPassId'),
        code: JsonRead.str(json, 'code'),
        status: JsonRead.str(json, 'status'),
        licensePlate: JsonRead.str(json, 'licensePlate'),
        vehicleName: JsonRead.strOrNull(json, 'vehicleName'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        createdAt: JsonRead.date(json, 'createdAt') ?? DateTime.now(),
        expiresAt: JsonRead.date(json, 'expiresAt') ?? DateTime.now(),
        usedAt: JsonRead.date(json, 'usedAt'),
        qrPayload: JsonRead.strOrNull(json, 'qrPayload'),
      );
}
