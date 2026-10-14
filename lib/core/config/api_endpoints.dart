/// Endpoint backend PBMS, giữ nguyên casing theo docs/openapi-pbms-paths.md.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth (/api/Auth)
  static const String login = '/api/Auth/login';
  static const String sendRegisterOtp = '/api/Auth/send-register-otp';
  static const String verifyRegisterOtp = '/api/Auth/verify-register-otp';
  static const String requestResetPassword = '/api/Auth/request-reset-password';
  static const String verifyResetPassword = '/api/Auth/verify-reset-password';
  static const String refreshToken = '/api/Auth/refresh-token';
  static const String logout = '/api/Auth/logout';

  // Profile (/api/profile)
  static const String profile = '/api/profile';
  static const String profileAvatar = '/api/profile/avatar';

  // Wallet (/api/wallet)
  static const String wallet = '/api/wallet';
  static String walletById(String id) => '/api/wallet/$id';
  static String walletTopUp(String id) => '/api/wallet/$id/top-up';

  // Catalog
  static const String vehicleTypes = '/api/VehicleType';
  static const String floors = '/api/Floor';
  static const String gates = '/api/Gate';
  static const String parkingSlots = '/api/ParkingSlot';
  static const String pricingPolicies = '/api/PricingPolicy';
  static const String subscriptionPackages = '/api/SubscriptionPackage';

  // Reservations (/api/reservations)
  static const String reservations = '/api/reservations';
  static const String myReservations = '/api/reservations/my-reservations';
  static String reservationById(String id) => '/api/reservations/$id';
  static String changeReservationTime(String id) =>
      '/api/reservations/$id/change-time';
  static String cancelReservation(String id) => '/api/reservations/$id/cancel';
  static String recreateReservationPayment(String id) =>
      '/api/reservations/$id/recreate-payment';
  static String checkPaymentStatus(String orderCode) =>
      '/api/reservations/check-payment-status/$orderCode';

  // Parking sessions (/api/ParkingSession)
  static const String sessions = '/api/ParkingSession';
  static const String mySessions = '/api/ParkingSession/my';
  static String mySessionFeePreview(String id) =>
      '/api/ParkingSession/my/$id/fee-preview';
  static String mySessionCheckoutPayment(String id) =>
      '/api/ParkingSession/my/$id/checkout-payment';
  static String sessionById(String id) => '/api/ParkingSession/$id';

  // Parking operations (/api/ParkingOperation)
  static const String availability = '/api/ParkingOperation/availability';
  static const String recognizePlate =
      '/api/ParkingOperation/upload-and-recognize-plate';
  static const String decodeQr = '/api/ParkingOperation/upload-and-decode-qr';
  static const String uploadGateImage = '/api/ParkingOperation/upload-image';
  static const String resolveQrPayload =
      '/api/ParkingOperation/resolve-qr-payload';
  static const String checkIn = '/api/ParkingOperation/check-in';
  static const String checkOut = '/api/ParkingOperation/check-out';
  static String checkoutPayment(String paymentId) =>
      '/api/ParkingOperation/check-out/payment/$paymentId';
  static String confirmCash(String paymentId) =>
      '/api/ParkingOperation/check-out/payment/$paymentId/confirm-cash';
  static String cancelCheckout(String paymentId) =>
      '/api/ParkingOperation/check-out/payment/$paymentId/cancel';
  static String staffFeePreview(String sessionId) =>
      '/api/ParkingOperation/fee-preview/$sessionId';

  // Monthly subscriptions (/api/MonthlySubscription)
  static const String mySubscriptions = '/api/MonthlySubscription/my';
  static const String registerSubscription =
      '/api/MonthlySubscription/register';
  static String subscriptionById(String id) => '/api/MonthlySubscription/$id';
  static String cancelSubscription(String id) =>
      '/api/MonthlySubscription/$id/cancel';
  static String subscriptionPayment(String id) =>
      '/api/MonthlySubscription/payment/$id';

  // Renewals (/api/SubscriptionRenewal)
  static String renewSubscription(String id) =>
      '/api/SubscriptionRenewal/$id/renew';
  static String subscriptionRenewals(String id) =>
      '/api/SubscriptionRenewal/$id/renewals';

  // Vehicle change requests (/api/VehicleChangeRequest)
  static const String changeVehicle =
      '/api/VehicleChangeRequest/change-vehicle';
  static const String myVehicleChangeRequests =
      '/api/VehicleChangeRequest/my-requests';
  static String vehicleChangeById(String id) =>
      '/api/VehicleChangeRequest/change-vehicle/$id';

  // Incidents (/api/IncidentReport)
  static const String incidents = '/api/IncidentReport';
  static const String myIncidents = '/api/IncidentReport/my-reports';
  static const String uploadIncidentProof = '/api/IncidentReport/upload-proof';
  static String incidentById(String id) => '/api/IncidentReport/$id';
  static String assignIncident(String id, String staffId) =>
      '/api/IncidentReport/$id/assign/$staffId';
  static String resolveIncident(String id, String staffId) =>
      '/api/IncidentReport/$id/resolve/$staffId';

  // Notifications (/api/Notification)
  static const String myNotifications = '/api/Notification/my';
  static const String readAllNotifications = '/api/Notification/read-all';
  static String readNotification(String id) => '/api/Notification/$id/read';
  static String notificationById(String id) => '/api/Notification/$id';
}
