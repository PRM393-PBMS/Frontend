import 'package:prm393_frontend/core/utils/json_read.dart';

typedef StaffJson = Map<String, dynamic>;

/// Cổng ra/vào mà nhân viên đứng quét.
class GateModel {
  final String gateId;
  final String gateName;
  final String gateType;
  final String floorName;

  const GateModel({
    required this.gateId,
    required this.gateName,
    required this.gateType,
    required this.floorName,
  });

  bool get isExit => gateType.toLowerCase() == 'exit';

  factory GateModel.fromJson(StaffJson json) => GateModel(
        gateId: JsonRead.str(json, 'gateId'),
        gateName: JsonRead.str(json, 'gateName'),
        gateType: JsonRead.str(json, 'gateType', 'Entry'),
        floorName: JsonRead.str(json, 'floorName'),
      );

  StaffJson toJson() => {'gateId': gateId, 'gateName': gateName, 'gateType': gateType, 'floorName': floorName};
}

/// Một lượt quét đã gửi lên máy chủ (máy chủ đã nhận diện và đối chiếu).
class GateScanModel {
  final String scanId;
  final String gateName;
  final String imageUrl;
  final String? licensePlate;
  final DateTime capturedAt;

  /// Reservation, Resident, Guest, Inside, Checkout, Unknown.
  final String suggestedType;
  final bool? reservationOnTime;
  final DateTime? reservationTime;

  /// New, Handled, Dismissed.
  final String status;

  const GateScanModel({
    required this.scanId,
    required this.gateName,
    required this.imageUrl,
    required this.licensePlate,
    required this.capturedAt,
    required this.suggestedType,
    required this.reservationOnTime,
    required this.reservationTime,
    required this.status,
  });

  factory GateScanModel.fromJson(StaffJson json) {
    final reservation = JsonRead.map(JsonRead.map(json, 'match') ?? const {}, 'reservation');
    return GateScanModel(
      scanId: JsonRead.str(json, 'scanId'),
      gateName: JsonRead.str(json, 'gateName'),
      imageUrl: JsonRead.str(json, 'imageUrl'),
      licensePlate: JsonRead.strOrNull(json, 'licensePlate'),
      capturedAt: JsonRead.date(json, 'capturedAt') ?? DateTime.now(),
      suggestedType: JsonRead.str(json, 'suggestedType', 'Unknown'),
      reservationOnTime: reservation == null ? null : JsonRead.bool_(reservation, 'onTime'),
      reservationTime: reservation == null ? null : JsonRead.date(reservation, 'expectedEntryTime'),
      status: JsonRead.str(json, 'status', 'New'),
    );
  }

  bool get isHandled => status.toLowerCase() == 'handled';
  bool get isDismissed => status.toLowerCase() == 'dismissed';
}
