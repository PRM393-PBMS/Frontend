import '../datasources/parking_remote_datasource.dart';
import '../models/facility_availability_model.dart';
import '../models/monthly_subscription_model.dart';
import '../models/notification_model.dart';
import '../models/parking_session_model.dart';

abstract class ParkingRepository {
  Future<List<ParkingSessionModel>> getMySessions();
  Future<Map<String, dynamic>> getSessionFeePreview(String sessionId);
  Future<Map<String, dynamic>> getCheckoutPayment(String sessionId);
  Future<List<FacilityAvailabilityModel>> getFacilityAvailability();
  Future<List<MonthlySubscriptionModel>> getMySubscriptions();
  Future<List<NotificationModel>> getMyNotifications();
  Future<bool> markNotificationRead(String id);
  Future<bool> markAllNotificationsRead();
  Future<Map<String, dynamic>> registerSubscription(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getSubscriptionPackages();
}

class ParkingRepositoryImpl implements ParkingRepository {
  final ParkingRemoteDataSource remoteDataSource;

  ParkingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ParkingSessionModel>> getMySessions() => remoteDataSource.getMySessions();

  @override
  Future<Map<String, dynamic>> getSessionFeePreview(String sessionId) =>
      remoteDataSource.getSessionFeePreview(sessionId);

  @override
  Future<Map<String, dynamic>> getCheckoutPayment(String sessionId) =>
      remoteDataSource.getCheckoutPayment(sessionId);

  @override
  Future<List<FacilityAvailabilityModel>> getFacilityAvailability() =>
      remoteDataSource.getFacilityAvailability();

  @override
  Future<List<MonthlySubscriptionModel>> getMySubscriptions() =>
      remoteDataSource.getMySubscriptions();

  @override
  Future<List<NotificationModel>> getMyNotifications() =>
      remoteDataSource.getMyNotifications();

  @override
  Future<bool> markNotificationRead(String id) =>
      remoteDataSource.markNotificationRead(id);

  @override
  Future<bool> markAllNotificationsRead() =>
      remoteDataSource.markAllNotificationsRead();

  @override
  Future<Map<String, dynamic>> registerSubscription(Map<String, dynamic> data) =>
      remoteDataSource.registerSubscription(data);

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionPackages() =>
      remoteDataSource.getSubscriptionPackages();
}
