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
  });

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
