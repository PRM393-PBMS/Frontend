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

  double get occupancyRatio => totalSlots > 0 ? (occupiedSlots + assignedSlots) / totalSlots : 0.0;
  double get availabilityRatio => totalSlots > 0 ? availableSlots / totalSlots : 0.0;

  factory FacilityAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityAvailabilityModel(
      floorId: json['floorId']?.toString() ?? '',
      floorName: json['floorName']?.toString() ?? '',
      vehicleTypeId: json['vehicleTypeId']?.toString() ?? '',
      vehicleTypeName: json['vehicleTypeName']?.toString() ?? '',
      totalSlots: (json['totalSlots'] as num?)?.toInt() ?? 0,
      availableSlots: (json['availableSlots'] as num?)?.toInt() ?? 0,
      occupiedSlots: (json['occupiedSlots'] as num?)?.toInt() ?? 0,
      assignedSlots: (json['assignedSlots'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floorId': floorId,
      'floorName': floorName,
      'vehicleTypeId': vehicleTypeId,
      'vehicleTypeName': vehicleTypeName,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'occupiedSlots': occupiedSlots,
      'assignedSlots': assignedSlots,
    };
  }
}
