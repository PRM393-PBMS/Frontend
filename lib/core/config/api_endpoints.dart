/// Định nghĩa tập trung toàn bộ Endpoint Backend PBMS (đóng băng casing)
class ApiEndpoints {
  ApiEndpoints._();

  // ================= Auth (PascalCase /api/Auth) =================
  static const String login = '/api/Auth/login';
  static const String sendRegisterOtp = '/api/Auth/send-register-otp';
  static const String verifyRegisterOtp = '/api/Auth/verify-register-otp';
  static const String requestResetPassword = '/api/Auth/request-reset-password';
  static const String verifyResetPassword = '/api/Auth/verify-reset-password';
  static const String refreshToken = '/api/Auth/refresh-token';
  static const String logout = '/api/Auth/logout';

  // ================= Profile (lowercase /api/profile) =================
  static const String profile = '/api/profile';

  // ================= Reservations (lowercase /api/reservations) =================
  static const String reservations = '/api/reservations';
  static const String myReservations = '/api/reservations/my-reservations';
  static String checkPaymentStatus(String orderCode) =>
      '/api/reservations/check-payment-status/$orderCode';
  static String recreateReservationPayment(String id) =>
      '/api/reservations/$id/recreate-payment';
  static String changeReservationTime(String reservationId) =>
      '/api/reservations/$reservationId/change-time';
  static String cancelReservation(String reservationId) =>
      '/api/reservations/$reservationId/cancel';
  static String getReservationById(String reservationId) =>
      '/api/reservations/$reservationId';

  // ================= Parking Sessions (/api/ParkingSession) =================
  static const String mySessions = '/api/ParkingSession/my';
  static String sessionFeePreview(String id) =>
      '/api/ParkingSession/my/$id/fee-preview';
  static String sessionCheckoutPayment(String id) =>
      '/api/ParkingSession/my/$id/checkout-payment';
  static String sessionById(String id) => '/api/ParkingSession/$id';

  // ================= Subscriptions (/api/MonthlySubscription) =================
  static const String mySubscriptions = '/api/MonthlySubscription/my';
  static const String registerSubscription =
      '/api/MonthlySubscription/register';
  static String cancelSubscription(String id) =>
      '/api/MonthlySubscription/$id/cancel';
  static String subscriptionPayment(String subscriptionId) =>
      '/api/MonthlySubscription/payment/$subscriptionId';

  // ================= Subscription Renewal (/api/SubscriptionRenewal) =================
  static String renewSubscription(String subscriptionId) =>
      '/api/SubscriptionRenewal/$subscriptionId/renew';
  static String subscriptionRenewals(String subscriptionId) =>
      '/api/SubscriptionRenewal/$subscriptionId/renewals';

  // ================= Vehicle Change (/api/VehicleChangeRequest) =================
  static const String requestChangeVehicle =
      '/api/VehicleChangeRequest/change-vehicle';
  static const String myVehicleChangeRequests =
      '/api/VehicleChangeRequest/my-requests';

  // ================= Catalog =================
  static const String vehicleTypes = '/api/VehicleType';
  static const String subscriptionPackages = '/api/SubscriptionPackage';
  static const String pricingPolicies = '/api/PricingPolicy';
  static const String floors = '/api/Floor';
  static const String parkingSlots = '/api/ParkingSlot';

  // ================= Operations & Slot Availability =================
  static const String parkingAvailability = '/api/ParkingOperation/availability';

  // ================= Incident Reports (/api/IncidentReport) =================
  static const String incidentReports = '/api/IncidentReport';
  static const String myIncidentReports = '/api/IncidentReport/my-reports';
  static const String uploadIncidentProof = '/api/IncidentReport/upload-proof';
  static String incidentById(String id) => '/api/IncidentReport/$id';
}
