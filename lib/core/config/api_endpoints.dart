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
  static const String profileAvatar = '/api/profile/avatar';
  static const String changePassword = '/api/profile/change-password';
  static const String deleteAccount = '/api/profile/delete-account';

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
  static String sessionPrepay(String id) => '/api/ParkingSession/my/$id/prepay';
  static String sessionExitPass(String id) =>
      '/api/ParkingSession/my/$id/exit-pass';
  static String sessionCheckoutPayment(String id) =>
      '/api/ParkingSession/my/$id/checkout-payment';
  static String sessionById(String id) => '/api/ParkingSession/$id';

  // ================= Subscriptions (/api/MonthlySubscription) =================
  static const String mySubscriptions = '/api/MonthlySubscription/my';
  static const String registerSubscription =
      '/api/MonthlySubscription/register';
  static String subscriptionById(String id) => '/api/MonthlySubscription/$id';
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
  static String vehicleChangeRequestById(String id) =>
      '/api/VehicleChangeRequest/change-vehicle/$id';

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

  // ================= Notifications (/api/Notification) =================
  static const String myNotifications = '/api/Notification/my';
  static String markNotificationRead(String id) => '/api/Notification/$id/read';
  static const String markAllNotificationsRead = '/api/Notification/read-all';
  static String deleteNotification(String id) => '/api/Notification/$id';

  // ================= Contracts (/api/contracts) =================
  static const String myContracts = '/api/contracts/my';
  static String contractForSubscription(String subscriptionId) =>
      '/api/contracts/subscription/$subscriptionId';
  static String signContract(String id) => '/api/contracts/$id/sign';
  static String verifyContract(String id) => '/api/contracts/$id/verify';

  // ================= Wallet (/api/wallet, module wallets của nhóm) =================
  /// POST: mở ví (tạo nếu chưa có), trả walletId.
  static const String ensureWallet = '/api/wallet';
  static String walletById(String walletId) => '/api/wallet/$walletId';
  static String walletTopUp(String walletId) => '/api/wallet/$walletId/top-up';

  /// Khách tự kiểm tra một thanh toán PayOS của mình (tra trực tiếp PayOS).
  static String syncPayment(String paymentId) => '/api/payments/$paymentId/sync';

  // ================= Parkings (nhiều bãi) =================
  /// Bãi cho app khách: toạ độ + chỗ trống theo loại xe (mảng, không bọc envelope).
  static const String availableParkings = '/parkings/available';

  // ================= Mã QR gửi xe một lần =================
  static const String entryPasses = '/api/entry-passes';
  static const String myEntryPasses = '/api/entry-passes/my';
  static String entryPassById(String id) => '/api/entry-passes/$id';

  // ================= Vehicles (/api/vehicles) =================
  static const String vehicles = '/api/vehicles';
  static const String myVehicles = '/api/vehicles/my';
  static String vehicleById(String id) => '/api/vehicles/$id';
}
