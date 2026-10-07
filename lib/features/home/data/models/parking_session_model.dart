class ParkingSessionModel {
  final String sessionId;
  final String? driverUserId;
  final String? driverFullName;
  final String licensePlateIn;
  final String? licensePlateOut;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? entryGateName;
  final String? exitGateName;
  final String? assignedSlotCode;
  final String? actualSlotCode;
  final String? vehicleTypeName;
  final String status;
  final double? paymentAmount;
  final String? paymentStatus;
  final String? ticket;

  const ParkingSessionModel({
    required this.sessionId,
    this.driverUserId,
    this.driverFullName,
    required this.licensePlateIn,
    this.licensePlateOut,
    required this.entryTime,
    this.exitTime,
    this.entryGateName,
    this.exitGateName,
    this.assignedSlotCode,
    this.actualSlotCode,
    this.vehicleTypeName,
    required this.status,
    this.paymentAmount,
    this.paymentStatus,
    this.ticket,
  });

  bool get isActive => status.toLowerCase() == 'active';

  /// Thời gian đỗ tính theo Duration
  Duration get parkedDuration {
    final end = exitTime ?? DateTime.now();
    return end.isAfter(entryTime) ? end.difference(entryTime) : Duration.zero;
  }

  /// Định dạng chuỗi '02h 45m'
  String get formattedDuration {
    final dur = parkedDuration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
  }

  factory ParkingSessionModel.fromJson(Map<String, dynamic> json) {
    return ParkingSessionModel(
      sessionId: json['sessionId']?.toString() ?? json['id']?.toString() ?? '',
      driverUserId: json['driverUserId']?.toString(),
      driverFullName: json['driverFullName']?.toString(),
      licensePlateIn: json['licensePlateIn']?.toString() ?? '',
      licensePlateOut: json['licensePlateOut']?.toString(),
      entryTime: json['entryTime'] != null
          ? DateTime.tryParse(json['entryTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      exitTime: json['exitTime'] != null
          ? DateTime.tryParse(json['exitTime'].toString())
          : null,
      entryGateName: json['entryGateName']?.toString(),
      exitGateName: json['exitGateName']?.toString(),
      assignedSlotCode: json['assignedSlotCode']?.toString(),
      actualSlotCode: json['actualSlotCode']?.toString(),
      vehicleTypeName: json['vehicleTypeName']?.toString(),
      status: json['status']?.toString() ?? 'Active',
      paymentAmount: json['paymentAmount'] != null
          ? double.tryParse(json['paymentAmount'].toString())
          : null,
      paymentStatus: json['paymentStatus']?.toString(),
      ticket: json['ticket']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'driverUserId': driverUserId,
      'driverFullName': driverFullName,
      'licensePlateIn': licensePlateIn,
      'licensePlateOut': licensePlateOut,
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'entryGateName': entryGateName,
      'exitGateName': exitGateName,
      'assignedSlotCode': assignedSlotCode,
      'actualSlotCode': actualSlotCode,
      'vehicleTypeName': vehicleTypeName,
      'status': status,
      'paymentAmount': paymentAmount,
      'paymentStatus': paymentStatus,
      'ticket': ticket,
    };
  }
}
