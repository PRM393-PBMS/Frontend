import 'package:flutter/material.dart';

enum VehicleType { car, motorcycle }

class VehicleCardModel {
  final String id;
  final String licensePlate;
  final String vehicleName;
  final VehicleType type;
  final String ticketType;
  final String expiryDate;
  final int daysLeft;
  final String parkingSlot;
  final List<Color> gradientColors;
  final Color accentColor;
  final String brand;
  final bool isMonthlyActive;
  final String nfcTagId;

  final String? phoneNumber;
  final String? startDate;
  final int billingMonths;
  final String paymentStatus; // 'Active', 'PendingPayment', 'Expired'
  final double? price;

  const VehicleCardModel({
    required this.id,
    required this.licensePlate,
    required this.vehicleName,
    required this.type,
    required this.ticketType,
    required this.expiryDate,
    required this.daysLeft,
    required this.parkingSlot,
    required this.gradientColors,
    required this.accentColor,
    required this.brand,
    this.isMonthlyActive = true,
    required this.nfcTagId,
    this.phoneNumber,
    this.startDate,
    this.billingMonths = 1,
    this.paymentStatus = 'Active',
    this.price,
  });

  VehicleCardModel copyWith({
    String? id,
    String? licensePlate,
    String? vehicleName,
    VehicleType? type,
    String? ticketType,
    String? expiryDate,
    int? daysLeft,
    String? parkingSlot,
    List<Color>? gradientColors,
    Color? accentColor,
    String? brand,
    bool? isMonthlyActive,
    String? nfcTagId,
    String? phoneNumber,
    String? startDate,
    int? billingMonths,
    String? paymentStatus,
    double? price,
  }) {
    return VehicleCardModel(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleName: vehicleName ?? this.vehicleName,
      type: type ?? this.type,
      ticketType: ticketType ?? this.ticketType,
      expiryDate: expiryDate ?? this.expiryDate,
      daysLeft: daysLeft ?? this.daysLeft,
      parkingSlot: parkingSlot ?? this.parkingSlot,
      gradientColors: gradientColors ?? this.gradientColors,
      accentColor: accentColor ?? this.accentColor,
      brand: brand ?? this.brand,
      isMonthlyActive: isMonthlyActive ?? this.isMonthlyActive,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      startDate: startDate ?? this.startDate,
      billingMonths: billingMonths ?? this.billingMonths,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      price: price ?? this.price,
    );
  }

  bool get isPendingPayment => paymentStatus == 'PendingPayment';

  factory VehicleCardModel.fromSubscription(dynamic sub) {
    final isCar = (sub.vehicleType ?? '').toString().toLowerCase().contains('ô tô') ||
        (sub.vehicleType ?? '').toString().toLowerCase().contains('car') ||
        (sub.vehicleType ?? '').toString().toLowerCase().contains('4');
    final endDate = sub.endDate is DateTime ? sub.endDate as DateTime : DateTime.now();
    final formattedDate =
        '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';
    final slot = sub.fixedSlot != null ? 'Vị trí cố định • Ô ${sub.fixedSlot}' : 'Bãi xe PBMS';
    final colors = isCar
        ? const [Color(0xFF033320), Color(0xFF06482F), Color(0xFF0A5E3E)]
        : const [Color(0xFF0A1B3F), Color(0xFF123473), Color(0xFF1A4FA8)];

    return VehicleCardModel(
      id: sub.subscriptionId.toString(),
      licensePlate: sub.licensePlate.toString(),
      vehicleName: sub.packageName?.toString() ?? (isCar ? 'Ô tô Cư dân' : 'Xe máy Cư dân'),
      type: isCar ? VehicleType.car : VehicleType.motorcycle,
      ticketType: sub.packageName?.toString() ?? 'Vé tháng Cư dân',
      expiryDate: formattedDate,
      daysLeft: sub.daysLeft is int ? sub.daysLeft as int : 30,
      parkingSlot: slot,
      gradientColors: colors,
      accentColor: isCar ? const Color(0xFF84CC16) : const Color(0xFF93C5FD),
      brand: isCar ? 'CAR PASS' : 'MOTO PASS',
      isMonthlyActive: sub.isActive == true,
      nfcTagId: 'PBMS-SUB-${sub.subscriptionId}',
    );
  }

  factory VehicleCardModel.fromSession(dynamic session) {
    final isCar = (session.vehicleTypeName ?? '').toString().toLowerCase().contains('ô tô') ||
        (session.vehicleTypeName ?? '').toString().toLowerCase().contains('car');
    final slot = session.assignedSlotCode != null
        ? 'Ô ${session.assignedSlotCode}'
        : (session.actualSlotCode != null ? 'Ô ${session.actualSlotCode}' : 'Khu vãng lai');

    return VehicleCardModel(
      id: session.sessionId.toString(),
      licensePlate: session.licensePlateIn.toString(),
      vehicleName: session.vehicleTypeName?.toString() ?? (isCar ? 'Ô tô vãng lai' : 'Xe máy vãng lai'),
      type: isCar ? VehicleType.car : VehicleType.motorcycle,
      ticketType: 'Vé lượt PBMS',
      expiryDate: 'Trong phiên',
      daysLeft: 1,
      parkingSlot: slot,
      gradientColors: const [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
      accentColor: const Color(0xFFA5B4FC),
      brand: 'PBMS PASS',
      isMonthlyActive: false,
      nfcTagId: 'PBMS-SES-${session.sessionId}',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'licensePlate': licensePlate,
    'vehicleName': vehicleName,
    'type': type.name,
    'ticketType': ticketType,
    'expiryDate': expiryDate,
    'daysLeft': daysLeft,
    'parkingSlot': parkingSlot,
    'gradientColors': gradientColors.map((c) => c.toARGB32()).toList(),
    'accentColor': accentColor.toARGB32(),
    'brand': brand,
    'isMonthlyActive': isMonthlyActive,
    'nfcTagId': nfcTagId,
    'phoneNumber': phoneNumber,
    'startDate': startDate,
    'billingMonths': billingMonths,
    'paymentStatus': paymentStatus,
    'price': price,
  };

  factory VehicleCardModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString().toLowerCase() ?? 'car';
    final isCar = typeStr.contains('car');
    final gradientInts = json['gradientColors'] as List<dynamic>?;
    final gradients = gradientInts != null && gradientInts.isNotEmpty
        ? gradientInts.map((c) => Color((c as num).toInt())).toList()
        : (isCar
            ? const [Color(0xFF033320), Color(0xFF06482F), Color(0xFF0A5E3E)]
            : const [Color(0xFF0A1B3F), Color(0xFF123473), Color(0xFF1A4FA8)]);
    final accentInt = json['accentColor'] as num?;
    final accent = accentInt != null
        ? Color(accentInt.toInt())
        : (isCar ? const Color(0xFF84CC16) : const Color(0xFF93C5FD));

    return VehicleCardModel(
      id: json['id']?.toString() ?? 'veh_${DateTime.now().millisecondsSinceEpoch}',
      licensePlate: json['licensePlate']?.toString() ?? '29A-999.99',
      vehicleName: json['vehicleName']?.toString() ?? (isCar ? 'Ô tô Cư dân' : 'Xe máy Cư dân'),
      type: isCar ? VehicleType.car : VehicleType.motorcycle,
      ticketType: json['ticketType']?.toString() ?? 'Vé tháng Cư dân',
      expiryDate: json['expiryDate']?.toString() ?? '31/12/2026',
      daysLeft: (json['daysLeft'] as num?)?.toInt() ?? 30,
      parkingSlot: json['parkingSlot']?.toString() ?? 'Bãi xe PBMS',
      gradientColors: gradients,
      accentColor: accent,
      brand: json['brand']?.toString() ?? (isCar ? 'CAR PASS' : 'MOTO PASS'),
      isMonthlyActive: json['isMonthlyActive'] as bool? ?? true,
      nfcTagId: json['nfcTagId']?.toString() ?? 'PBMS-NFC-${json['licensePlate']}',
      phoneNumber: json['phoneNumber'] as String?,
      startDate: json['startDate'] as String?,
      billingMonths: (json['billingMonths'] as num?)?.toInt() ?? 1,
      paymentStatus: json['paymentStatus'] as String? ?? 'Active',
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  static const VehicleCardModel defaultEmpty = VehicleCardModel(
    id: 'empty_veh',
    licensePlate: 'CHƯA ĐĂNG KÝ',
    vehicleName: 'Chưa có phương tiện',
    type: VehicleType.car,
    ticketType: 'Chưa kích hoạt',
    expiryDate: '--/--',
    daysLeft: 0,
    parkingSlot: 'Chưa có vị trí',
    gradientColors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
    accentColor: Color(0xFF94A3B8),
    brand: 'PBMS',
    isMonthlyActive: false,
    nfcTagId: 'PBMS-EMPTY',
  );

  /// Danh sách Mock Data thẻ xe đô thị cao cấp phong cách Digital Wallet
  static List<VehicleCardModel> get mockVehicles => [
    const VehicleCardModel(
      id: 'veh_01',
      licensePlate: '29A - 888.88',
      vehicleName: 'VinFast VF 8 Plus',
      type: VehicleType.car,
      ticketType: 'Vé tháng Cư dân VIP',
      expiryDate: '31/10/2026',
      daysLeft: 36,
      parkingSlot: 'Tầng Hầm B2 • Ô C-18',
      gradientColors: [
        Color(0xFF033320), // Vietcombank Deep Forest Green (Samsung Wallet)
        Color(0xFF06482F),
        Color(0xFF0A5E3E),
      ],
      accentColor: Color(0xFF84CC16), // Lime green tech nodes
      brand: 'VINFAST',
      nfcTagId: 'PBMS-VF8-29A88888',
    ),
    const VehicleCardModel(
      id: 'veh_02',
      licensePlate: '59B - 678.90',
      vehicleName: 'Honda SH 150i ABS',
      type: VehicleType.motorcycle,
      ticketType: 'Vé tháng Tiêu chuẩn',
      expiryDate: '15/11/2026',
      daysLeft: 51,
      parkingSlot: 'Khu A1 • Vị trí M-04',
      gradientColors: [
        Color(0xFF111318), // Midnight Obsidian (Samsung Wallet Dark)
        Color(0xFF1E222B),
        Color(0xFF2C323F),
      ],
      accentColor: Color(0xFF94A3B8),
      brand: 'HONDA',
      nfcTagId: 'PBMS-SH-59B67890',
    ),
    const VehicleCardModel(
      id: 'veh_03',
      licensePlate: '30H - 567.89',
      vehicleName: 'Mazda 3 Sport Luxury',
      type: VehicleType.car,
      ticketType: 'Vé đối tác Doanh nghiệp',
      expiryDate: '28/12/2026',
      daysLeft: 94,
      parkingSlot: 'Tầng Hầm B1 • Ô A-05',
      gradientColors: [
        Color(0xFF0A1B3F), // Samsung Galaxy Sapphire Blue
        Color(0xFF123473),
        Color(0xFF1A4FA8),
      ],
      accentColor: Color(0xFF93C5FD),
      brand: 'MAZDA',
      nfcTagId: 'PBMS-MZ3-30H56789',
    ),
    const VehicleCardModel(
      id: 'veh_04',
      licensePlate: '51K - 123.45',
      vehicleName: 'Vespa Primavera 125',
      type: VehicleType.motorcycle,
      ticketType: 'Vé lượt Thông minh',
      expiryDate: 'Không thời hạn',
      daysLeft: 999,
      parkingSlot: 'Khu B • Vị trí V-12',
      gradientColors: [
        Color(0xFF3B0D1C), // Samsung Burgundy Velvet
        Color(0xFF5C142C),
        Color(0xFF831C3E),
      ],
      accentColor: Color(0xFFF472B6),
      brand: 'VESPA',
      isMonthlyActive: false,
      nfcTagId: 'PBMS-VES-51K12345',
    ),
  ];
}
