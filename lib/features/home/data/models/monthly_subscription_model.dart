class MonthlySubscriptionModel {
  final String subscriptionId;
  final String userId;
  final String? fullName;
  final String licensePlate;
  final String? vehicleType;
  final String? packageName;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String status;
  final String? fixedSlot;

  const MonthlySubscriptionModel({
    required this.subscriptionId,
    required this.userId,
    this.fullName,
    required this.licensePlate,
    this.vehicleType,
    this.packageName,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.status,
    this.fixedSlot,
  });

  bool get isActive => status.toLowerCase() == 'active';

  int get daysLeft {
    final now = DateTime.now();
    return endDate.isAfter(now) ? endDate.difference(now).inDays : 0;
  }

  factory MonthlySubscriptionModel.fromJson(Map<String, dynamic> json) {
    return MonthlySubscriptionModel(
      subscriptionId: json['subscriptionId']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      licensePlate: json['licensePlate']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? 'Ô tô',
      packageName: json['packageName']?.toString() ?? 'Gói tháng PBMS',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Active',
      fixedSlot: json['fixedSlot']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'userId': userId,
      'fullName': fullName,
      'licensePlate': licensePlate,
      'vehicleType': vehicleType,
      'packageName': packageName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'price': price,
      'status': status,
      'fixedSlot': fixedSlot,
    };
  }
}
