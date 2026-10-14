/// Đường dẫn màn hình trong ứng dụng.
class RouteNames {
  RouteNames._();

  // Khởi động & xác thực
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String unsupportedRole = '/unsupported';

  // Khách hàng: tab
  static const String home = '/home';
  static const String history = '/history';
  static const String passes = '/passes';
  static const String account = '/account';

  // Khách hàng: màn hình con
  static const String availability = '/availability';
  static const String reservations = '/reservations';
  static const String newReservation = '/reservations/new';
  static String reservationDetail(String id) => '/reservations/$id';
  static String sessionDetail(String id) => '/history/$id';
  static const String registerPass = '/passes/register';
  static const String plateRequests = '/passes/plate-requests';
  static String passDetail(String id) => '/passes/$id';
  static const String incidents = '/incidents';
  static const String newIncident = '/incidents/new';
  static String incidentDetail(String id) => '/incidents/$id';
  static const String editProfile = '/account/edit';
  static const String changePassword = '/account/password';
  static const String wallet = '/account/wallet';

  // Nhân viên: tab
  static const String staffCheckIn = '/staff/check-in';
  static const String staffCheckOut = '/staff/check-out';
  static const String staffSessions = '/staff/sessions';
  static const String staffIncidents = '/staff/incidents';
  static const String staffAccount = '/staff/account';

  // Nhân viên: màn hình con
  static String staffSessionDetail(String id) => '/staff/sessions/$id';
  static String staffIncidentDetail(String id) => '/staff/incidents/$id';
  static const String staffAvailability = '/staff/availability';
}
