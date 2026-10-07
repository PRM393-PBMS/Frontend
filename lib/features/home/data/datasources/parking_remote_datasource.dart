import 'package:prm393_frontend/core/config/api_endpoints.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import '../models/facility_availability_model.dart';
import '../models/monthly_subscription_model.dart';
import '../models/notification_model.dart';
import '../models/parking_session_model.dart';

abstract class ParkingRemoteDataSource {
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

class ParkingRemoteDataSourceImpl implements ParkingRemoteDataSource {
  final ApiClient apiClient;

  ParkingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ParkingSessionModel>> getMySessions() async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.mySessions);
      if (response.result is List) {
        return (response.result as List)
            .map((item) => ParkingSessionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getSessionFeePreview(String sessionId) async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.sessionFeePreview(sessionId));
      if (response.result is Map<String, dynamic>) {
        return response.result as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getCheckoutPayment(String sessionId) async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.sessionCheckoutPayment(sessionId));
      if (response.result is Map<String, dynamic>) {
        return response.result as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<List<FacilityAvailabilityModel>> getFacilityAvailability() async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.parkingAvailability);
      if (response.result is List) {
        return (response.result as List)
            .map((item) => FacilityAvailabilityModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MonthlySubscriptionModel>> getMySubscriptions() async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.mySubscriptions);
      if (response.result is List) {
        return (response.result as List)
            .map((item) => MonthlySubscriptionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.myNotifications);
      if (response.result is List) {
        return (response.result as List)
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> markNotificationRead(String id) async {
    try {
      await apiClient.put<dynamic>(ApiEndpoints.markNotificationRead(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> markAllNotificationsRead() async {
    try {
      await apiClient.put<dynamic>(ApiEndpoints.markAllNotificationsRead);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> registerSubscription(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post<dynamic>(
        ApiEndpoints.registerSubscription,
        data: data,
      );
      if (response.result is Map<String, dynamic>) {
        return response.result as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionPackages() async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.subscriptionPackages);
      if (response.result is List) {
        return (response.result as List)
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
