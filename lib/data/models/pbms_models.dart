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

  const PaymentLinkModel({
    required this.paymentUrl,
    this.orderCode,
    this.paymentId,
    this.paymentLinkId,
    this.amount,
    this.reservationId,
    this.subscriptionId,
    this.ticket,
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

  const PaymentModel({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
    this.paymentType,
    required this.paymentStatus,
    this.paymentTime,
    this.transactionReference,
  });

  factory PaymentModel.fromJson(J json) => PaymentModel(
        paymentId: JsonRead.str(json, 'paymentId'),
        amount: JsonRead.num_(json, 'amount'),
        paymentMethod: JsonRead.str(json, 'paymentMethod'),
        paymentType: JsonRead.strOrNull(json, 'paymentType'),
        paymentStatus: JsonRead.str(json, 'paymentStatus', 'Pending'),
        paymentTime: JsonRead.date(json, 'paymentTime'),
        transactionReference: JsonRead.strOrNull(json, 'transactionReference'),
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
  });

  bool get isActive => _is(status, 'active');
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
      );
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
    this.description,
    required this.status,
  });

  bool get isActive => _is(status, 'active');
  bool get isMotorbike => vehicleTypeName.toLowerCase().contains('máy');

  factory SubscriptionPackageModel.fromJson(J json) => SubscriptionPackageModel(
        packageId: JsonRead.str(json, 'packageId'),
        packageName: JsonRead.str(json, 'packageName'),
        vehicleTypeId: JsonRead.str(json, 'vehicleTypeId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName'),
        durationMonths: JsonRead.int_(json, 'durationMonths', 1),
        price: JsonRead.num_(json, 'price'),
        requireFixedSlot: JsonRead.bool_(json, 'requireFixedSlot'),
        description: JsonRead.strOrNull(json, 'description'),
        status: JsonRead.str(json, 'status', 'Active'),
      );
}

class ParkingSlotModel {
  final String slotId;
  final String floorId;
  final String floorName;
  final String slotCode;
  final String vehicleTypeId;
  final String status;
  final bool isResident;

  const ParkingSlotModel({
    required this.slotId,
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
  final DateTime expectedEntryTime;
  final String status;
  final DateTime? createdAt;
  final TicketModel? ticket;

  const ReservationModel({
    required this.reservationId,
    required this.vehicleTypeName,
    required this.expectedEntryTime,
    required this.status,
    this.createdAt,
    this.ticket,
  });

  /// Còn trong khung giờ có thể vào bãi (trễ tối đa 1 giờ).
  bool get _stillValid =>
      expectedEntryTime.isAfter(DateTime.now().subtract(const Duration(hours: 1)));

  bool get isPending => _is(status, 'pending') && _stillValid;
  bool get isUpcoming => (_is(status, 'confirmed') || _is(status, 'modified')) && _stillValid;
  bool get canModify => isPending || isUpcoming;

  factory ReservationModel.fromJson(J json) => ReservationModel(
        reservationId: JsonRead.str(json, 'reservationId'),
        vehicleTypeName: JsonRead.str(json, 'vehicleTypeName', 'Ô tô'),
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
  });

  bool get isActive => _is(status, 'active');
  bool get isPendingPayment => status.toLowerCase().contains('pending');
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
  });

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

  const NotificationPage({required this.items, required this.unreadCount});

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
