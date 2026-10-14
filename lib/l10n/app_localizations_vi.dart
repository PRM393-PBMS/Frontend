// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'PBMS Parking';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonAll => 'Tất cả';

  @override
  String get commonDone => 'Xong';

  @override
  String get commonEdit => 'Sửa';

  @override
  String get commonYes => 'Có';

  @override
  String get commonNo => 'Không';

  @override
  String get commonNone => 'Chưa có';

  @override
  String get commonLoading => 'Đang tải';

  @override
  String get commonUnknown => 'Không rõ';

  @override
  String get commonLogout => 'Đăng xuất';

  @override
  String get loadFailedTitle => 'Không tải được dữ liệu';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get imagePickTitle => 'Chọn ảnh';

  @override
  String get imageTakePhoto => 'Chụp ảnh';

  @override
  String get imageFromLibrary => 'Chọn từ thư viện';

  @override
  String get ticketQrSemantics => 'Mã QR vé gửi xe';

  @override
  String get ticketCopied => 'Đã sao chép mã vé';

  @override
  String ticketCode(String code) {
    return 'Mã vé $code';
  }

  @override
  String versionLabel(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get errorGeneric => 'Đã có lỗi xảy ra. Vui lòng thử lại.';

  @override
  String get errorNetwork =>
      'Không thể kết nối máy chủ. Kiểm tra mạng và thử lại.';

  @override
  String errorStatus(String code) {
    return 'Đã xảy ra lỗi ($code).';
  }

  @override
  String get errorSessionExpired =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String timeToday(String time) {
    return 'Hôm nay $time';
  }

  @override
  String timeTomorrow(String time) {
    return 'Ngày mai $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Hôm qua $time';
  }

  @override
  String timeOnDate(String time, String date) {
    return '$time, $date';
  }

  @override
  String durationDaysHours(String days, String hours) {
    return '$days ngày $hours giờ';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes phút';
  }

  @override
  String get agoJustNow => 'Vừa xong';

  @override
  String agoMinutes(int n) {
    return '$n phút trước';
  }

  @override
  String agoHours(int n) {
    return '$n giờ trước';
  }

  @override
  String agoDays(int n) {
    return '$n ngày trước';
  }

  @override
  String dateRange(String from, String to) {
    return '$from đến $to';
  }

  @override
  String vRequired(String field) {
    return 'Vui lòng nhập $field';
  }

  @override
  String get vEmailRequired => 'Vui lòng nhập email';

  @override
  String get vEmailInvalid => 'Email chưa đúng định dạng';

  @override
  String vMaxLength(String field, String max) {
    return '$field tối đa $max ký tự';
  }

  @override
  String get vPhoneRequired => 'Vui lòng nhập số điện thoại';

  @override
  String get vPhoneInvalid => 'Số điện thoại di động Việt Nam chưa hợp lệ';

  @override
  String get vUserNameRequired => 'Vui lòng nhập tên đăng nhập';

  @override
  String get vFullNameRequired => 'Vui lòng nhập họ và tên';

  @override
  String get vPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get vConfirmRequired => 'Vui lòng nhập lại mật khẩu';

  @override
  String get vConfirmMismatch => 'Mật khẩu nhập lại không khớp';

  @override
  String get vOtpInvalid => 'Mã OTP gồm 6 chữ số';

  @override
  String get vPlateRequired => 'Vui lòng nhập biển số';

  @override
  String get vPlateInvalid => 'Biển số gồm 4-15 chữ cái và chữ số';

  @override
  String get vPlateSame => 'Biển số mới phải khác biển số hiện tại';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldUserName => 'Tên đăng nhập';

  @override
  String get fieldFullName => 'Họ và tên';

  @override
  String get fieldPhone => 'Số điện thoại';

  @override
  String get fieldEmailLabel => 'email';

  @override
  String get fieldFullNameLabel => 'Họ và tên';

  @override
  String get fieldUserNameLabel => 'Tên đăng nhập';

  @override
  String get fieldPassword => 'Mật khẩu';

  @override
  String get fieldPasswordConfirm => 'Nhập lại mật khẩu';

  @override
  String get fieldNewPassword => 'Mật khẩu mới';

  @override
  String get fieldNewPasswordConfirm => 'Nhập lại mật khẩu mới';

  @override
  String get fieldOtp => 'Mã OTP';

  @override
  String get fieldPlate => 'Biển số xe';

  @override
  String get fieldVehicleType => 'Loại xe';

  @override
  String get stReservationPending => 'Chờ đặt cọc';

  @override
  String get stReservationConfirmed => 'Đã xác nhận';

  @override
  String get stReservationModified => 'Đã đổi giờ';

  @override
  String get stReservationCheckedIn => 'Đã vào bãi';

  @override
  String get stReservationCompleted => 'Hoàn tất';

  @override
  String get stCancelled => 'Đã hủy';

  @override
  String get stReservationNoShow => 'Quá giờ, không đến';

  @override
  String get stSessionActive => 'Đang gửi';

  @override
  String get stSessionCompleted => 'Đã lấy xe';

  @override
  String get stSessionException => 'Ngoại lệ';

  @override
  String get stPassActive => 'Đang hiệu lực';

  @override
  String get stPendingPayment => 'Chờ thanh toán';

  @override
  String get stPassExpired => 'Hết hạn';

  @override
  String get stPaid => 'Đã thanh toán';

  @override
  String get stIncidentOpen => 'Mới gửi';

  @override
  String get stIncidentInProgress => 'Đang xử lý';

  @override
  String get stIncidentResolved => 'Đã xử lý';

  @override
  String get stChangePending => 'Chờ duyệt';

  @override
  String get stChangeApproved => 'Đã duyệt';

  @override
  String get stChangeRejected => 'Bị từ chối';

  @override
  String get stNoPass => 'Chưa có vé tháng';

  @override
  String get payMethodPayOS => 'Chuyển khoản PayOS';

  @override
  String get payMethodCash => 'Tiền mặt';

  @override
  String get payTypeDeposit => 'Đặt cọc giữ chỗ';

  @override
  String get payTypeCheckout => 'Phí gửi xe';

  @override
  String get payTypeSubscription => 'Phí vé tháng';

  @override
  String get payTypeRenewal => 'Gia hạn vé tháng';

  @override
  String get roleStaff => 'Nhân viên vận hành';

  @override
  String get roleManager => 'Quản lý bãi xe';

  @override
  String get roleAdmin => 'Quản trị viên';

  @override
  String get roleCustomer => 'Khách hàng';

  @override
  String get customerGuest => 'Vãng lai';

  @override
  String get customerResident => 'Vé tháng';

  @override
  String get customerReservation => 'Đặt trước';

  @override
  String get customerGuestFull => 'Khách vãng lai';

  @override
  String get customerResidentFull => 'Khách vé tháng';

  @override
  String get customerReservationFull => 'Khách đặt trước';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navHistory => 'Lịch sử';

  @override
  String get navPasses => 'Vé tháng';

  @override
  String get navAccount => 'Tài khoản';

  @override
  String get navCheckIn => 'Vào bãi';

  @override
  String get navCheckOut => 'Ra bãi';

  @override
  String get navSessions => 'Phiên gửi';

  @override
  String get navIncidents => 'Sự cố';

  @override
  String get unsupportedTitle => 'Vai trò chưa được hỗ trợ';

  @override
  String unsupportedMessage(String email, String role) {
    return 'Tài khoản $email có vai trò \"$role\". Ứng dụng dành cho khách hàng và nhân viên vận hành cổng. Vui lòng dùng trang quản trị.';
  }

  @override
  String get notFoundTitle => 'Không tìm thấy trang';

  @override
  String get notFoundMessage =>
      'Đường dẫn này không tồn tại hoặc đã bị thay đổi.';

  @override
  String get notFoundAction => 'Về trang chính';

  @override
  String get lockReason => 'Xác thực để mở khóa PBMS Parking';

  @override
  String get lockFailed =>
      'Chưa xác thực được. Thử lại hoặc đăng xuất để đăng nhập bằng mật khẩu.';

  @override
  String get lockTitle => 'Ứng dụng đang khóa';

  @override
  String lockMessage(String name) {
    return 'Xin chào $name. Dùng vân tay hoặc khuôn mặt đã đăng ký trên thiết bị để tiếp tục.';
  }

  @override
  String get lockSemantics => 'Mở khóa bằng sinh trắc học';

  @override
  String get lockUnlock => 'Mở khóa';

  @override
  String get splashTagline => 'Gửi xe, đặt chỗ và vé tháng tại một nơi.';

  @override
  String get splashChecking => 'Đang kiểm tra phiên đăng nhập';

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get loginSubtitle =>
      'Dùng email đã đăng ký để quản lý lượt gửi xe, đặt chỗ và vé tháng.';

  @override
  String get loginForgot => 'Quên mật khẩu?';

  @override
  String get loginSubmit => 'Đăng nhập';

  @override
  String get loginNoAccount => 'Chưa có tài khoản?';

  @override
  String get loginRegister => 'Đăng ký';

  @override
  String get loginFailed =>
      'Đăng nhập không thành công. Vui lòng kiểm tra lại.';

  @override
  String get loginRegistered => 'Đăng ký thành công. Vui lòng đăng nhập.';

  @override
  String get loginPasswordReset =>
      'Đặt lại mật khẩu thành công. Hãy đăng nhập bằng mật khẩu mới.';

  @override
  String get registerTitle => 'Tạo tài khoản';

  @override
  String get registerSubtitle =>
      'Mã xác thực 6 số sẽ được gửi tới email của bạn.';

  @override
  String get registerSubmit => 'Gửi mã xác thực';

  @override
  String get otpSendFailed => 'Không thể gửi mã OTP. Vui lòng thử lại sau.';

  @override
  String get otpVerifyFailed => 'Xác thực OTP thất bại. Vui lòng thử lại.';

  @override
  String get otpTitleRegister => 'Xác thực email';

  @override
  String get otpTitleReset => 'Đặt lại mật khẩu';

  @override
  String otpSubtitle(String email) {
    return 'Nhập mã 6 số vừa gửi tới $email. Mã có hiệu lực trong 10 phút.';
  }

  @override
  String get otpSubmitRegister => 'Hoàn tất đăng ký';

  @override
  String get otpSubmitReset => 'Đặt lại mật khẩu';

  @override
  String get otpResend => 'Gửi lại mã';

  @override
  String get otpEditAndResend => 'Sửa thông tin và gửi lại mã';

  @override
  String get otpResent =>
      'Nếu email đã đăng ký, mã OTP đặt lại mật khẩu đã được gửi.';

  @override
  String get resetRequestFailed => 'Yêu cầu đặt lại mật khẩu thất bại.';

  @override
  String get resetFailed => 'Đặt lại mật khẩu thất bại. Kiểm tra mã OTP.';

  @override
  String get forgotTitle => 'Quên mật khẩu';

  @override
  String get forgotSubtitle =>
      'Nhập email đã đăng ký. Chúng tôi sẽ gửi mã OTP để bạn đặt mật khẩu mới.';

  @override
  String get forgotSubmit => 'Gửi mã OTP';

  @override
  String get onbSkip => 'Bỏ qua';

  @override
  String get onbNext => 'Tiếp tục';

  @override
  String get onbStart => 'Bắt đầu';

  @override
  String get onb1Title => 'Xem chỗ trống trước khi đến';

  @override
  String get onb1Body =>
      'Số chỗ còn trống theo từng tầng và loại xe, cập nhật từ hệ thống bãi.';

  @override
  String get onb2Title => 'Đặt chỗ ô tô, vào cổng bằng mã QR';

  @override
  String get onb2Body =>
      'Đặt trước tối đa 5 tiếng, đặt cọc qua PayOS và đưa mã vé cho nhân viên tại cổng.';

  @override
  String get onb3Title => 'Vé tháng và phí gửi xe rõ ràng';

  @override
  String get onb3Body =>
      'Đăng ký, gia hạn vé tháng và xem phí tạm tính của lượt gửi ngay trên điện thoại.';

  @override
  String get notifTooltip => 'Thông báo';

  @override
  String get notifTitle => 'Thông báo';

  @override
  String get notifMarkAll => 'Đánh dấu đã đọc';

  @override
  String get notifEmptyTitle => 'Chưa có thông báo';

  @override
  String get notifEmptyMessage =>
      'Thông báo về đặt chỗ, vé tháng và sự cố sẽ hiện ở đây.';

  @override
  String get homeMorning => 'Chào buổi sáng';

  @override
  String get homeAfternoon => 'Chào buổi chiều';

  @override
  String get homeEvening => 'Chào buổi tối';

  @override
  String get homeServices => 'Dịch vụ';

  @override
  String get homeBookCar => 'Đặt chỗ ô tô';

  @override
  String get homeBookCarSub =>
      'Giữ chỗ trước tối đa 5 tiếng, đặt cọc qua PayOS';

  @override
  String get homeMyBookings => 'Đặt chỗ của tôi';

  @override
  String get homeMyBookingsSub => 'Xem vé, đổi giờ hoặc hủy đặt chỗ';

  @override
  String get homeAvailability => 'Chỗ trống theo tầng';

  @override
  String get homeAvailabilitySub => 'Tình trạng bãi và bảng giá hiện hành';

  @override
  String get homeReport => 'Báo cáo sự cố';

  @override
  String get homeReportSub => 'Gửi phản ánh kèm ảnh và theo dõi xử lý';

  @override
  String homeParkedFor(String duration) {
    return 'Đã gửi $duration';
  }

  @override
  String homeEnteredAt(String time, String gate) {
    return 'Vào lúc $time qua $gate';
  }

  @override
  String homeEnteredSlot(String slot) {
    return ', ô $slot';
  }

  @override
  String get homePayToExit => 'Thanh toán phí để ra bãi';

  @override
  String get homeViewTicket => 'Xem vé và phí tạm tính';

  @override
  String get homeFreeNow => 'Chỗ trống hiện tại';

  @override
  String get homeNoAvailability => 'Chưa có dữ liệu chỗ trống';

  @override
  String get homeNoSlots => 'Bãi chưa cấu hình ô đỗ.';

  @override
  String homeOfSpaces(String total) {
    return '/ $total chỗ';
  }

  @override
  String homeTypeFree(String type, String count) {
    return '$type: $count trống';
  }

  @override
  String get homeByFloor => 'Xem theo tầng';

  @override
  String homeBookingAt(String time) {
    return 'Đặt chỗ $time';
  }

  @override
  String get homeFinishDeposit => 'Hoàn tất đặt cọc để giữ chỗ';

  @override
  String get homeArriveWindow =>
      'Có mặt trong khoảng 30 phút trước hoặc sau giờ hẹn';

  @override
  String get availTitle => 'Chỗ trống';

  @override
  String get availEmptyTitle => 'Chưa có dữ liệu ô đỗ';

  @override
  String get availEmptyMessage =>
      'Bãi xe chưa cấu hình tầng và ô đỗ. Vui lòng quay lại sau.';

  @override
  String get availResidentFloor => 'Tầng cư dân / vé tháng';

  @override
  String availOfFree(String total) {
    return ' / $total trống';
  }

  @override
  String get availPricing => 'Bảng giá gửi xe';

  @override
  String priceFirstHours(String hours) {
    return '$hours giờ đầu';
  }

  @override
  String get priceExtraHour => 'Mỗi giờ tiếp theo';

  @override
  String get priceNight => 'Phụ thu qua đêm (22:00-06:00)';

  @override
  String get resNewTitle => 'Đặt chỗ ô tô';

  @override
  String get resNewIntro =>
      'Đặt trước áp dụng cho ô tô, tối đa 5 tiếng trước giờ vào. Bạn được vào bãi trong khoảng 30 phút trước hoặc sau giờ hẹn.';

  @override
  String get resCarFree => 'Chỗ ô tô vãng lai còn trống';

  @override
  String resSpaces(String count) {
    return '$count chỗ';
  }

  @override
  String get resDepositEstimate => 'Tiền cọc dự kiến';

  @override
  String get resPerPricing => 'Theo bảng giá';

  @override
  String get resPrice => 'Giá gửi';

  @override
  String resPriceValue(String base, String hours, String extra) {
    return '$base / $hours giờ đầu, $extra / giờ sau';
  }

  @override
  String get resEntryTime => 'Giờ vào bãi';

  @override
  String get resRefreshSlots => 'Làm mới khung giờ';

  @override
  String get resPickTime => 'Vui lòng chọn giờ vào bãi.';

  @override
  String get resSlotPassed => 'Khung giờ đã qua. Vui lòng chọn lại.';

  @override
  String get resChooseTime => 'Chọn giờ vào bãi';

  @override
  String resBookAt(String time) {
    return 'Đặt chỗ lúc $time';
  }

  @override
  String get resNoSlots => 'Không còn khung giờ hợp lệ.';

  @override
  String get resDepositTitle => 'Đặt cọc giữ chỗ';

  @override
  String resDepositDesc(String time) {
    return 'Giữ chỗ ô tô lúc $time. Tiền cọc được trừ vào phí gửi xe khi ra bãi.';
  }

  @override
  String resDepositDescShort(String time) {
    return 'Giữ chỗ ô tô lúc $time.';
  }

  @override
  String get resListTitle => 'Đặt chỗ của tôi';

  @override
  String get resNew => 'Đặt chỗ mới';

  @override
  String get resEmptyTitle => 'Chưa có đặt chỗ';

  @override
  String get resEmptyMessage =>
      'Đặt trước chỗ ô tô tối đa 5 tiếng và vào bãi bằng mã QR.';

  @override
  String get resUpcoming => 'Sắp tới';

  @override
  String get resPast => 'Đã qua';

  @override
  String resTileMeta(String type, String ago) {
    return '$type, đặt $ago';
  }

  @override
  String get resDetailTitle => 'Chi tiết đặt chỗ';

  @override
  String get resConfirmed => 'Đã xác nhận đặt chỗ';

  @override
  String get resCancelTitle => 'Hủy đặt chỗ?';

  @override
  String get resCancelPending => 'Đặt chỗ chưa đặt cọc sẽ bị hủy.';

  @override
  String get resCancelPaid =>
      'Đặt chỗ đã đặt cọc sẽ bị hủy và không thể khôi phục.';

  @override
  String get resCancelAction => 'Hủy đặt chỗ';

  @override
  String get resCancelled => 'Đã hủy đặt chỗ';

  @override
  String resRescheduled(String time) {
    return 'Đã đổi giờ sang $time';
  }

  @override
  String resEntryWindow(String from, String to) {
    return 'Vào bãi từ $from đến $to';
  }

  @override
  String get resShowAtEntry => 'Đưa mã này cho nhân viên tại cổng vào';

  @override
  String get resBookedAt => 'Ngày đặt';

  @override
  String get resReschedule => 'Đổi giờ';

  @override
  String get resRescheduleUsed => 'Đã dùng lượt đổi';

  @override
  String get resRescheduleLeft => 'Còn 1 lượt';

  @override
  String get resPendingNote =>
      'Đặt chỗ chỉ được giữ sau khi đặt cọc thành công. Đơn quá giờ hẹn 30 phút sẽ tự hủy.';

  @override
  String get resPayDeposit => 'Thanh toán đặt cọc';

  @override
  String get resChangeTime => 'Đổi giờ vào';

  @override
  String get resChangeRule => 'Chỉ đổi giờ được trước giờ hẹn ít nhất 15 phút.';

  @override
  String get resNewTime => 'Chọn giờ vào mới';

  @override
  String get resOneChange => 'Mỗi đặt chỗ chỉ được đổi giờ 1 lần.';

  @override
  String get resConfirmChange => 'Xác nhận đổi giờ';

  @override
  String get payInvalidLink => 'Liên kết thanh toán không hợp lệ.';

  @override
  String get payCantOpen => 'Không mở được trang thanh toán trên thiết bị này.';

  @override
  String get payNotYet =>
      'Chưa nhận được thanh toán. Hoàn tất trên trang PayOS rồi kiểm tra lại.';

  @override
  String get paySuccessTitle => 'Thanh toán thành công';

  @override
  String get paySuccessMessage =>
      'Hệ thống đã ghi nhận khoản thanh toán của bạn.';

  @override
  String get payFailedTitle => 'Thanh toán không thành công';

  @override
  String get payFailedMessage =>
      'Giao dịch đã bị hủy hoặc thất bại. Bạn có thể tạo lại liên kết thanh toán.';

  @override
  String get payAmount => 'Số tiền';

  @override
  String get payOrderCode => 'Mã đơn hàng';

  @override
  String get payWaiting => 'Đang chờ PayOS xác nhận. Màn hình sẽ tự cập nhật.';

  @override
  String get payHint =>
      'Thanh toán qua ứng dụng ngân hàng bằng VietQR trên trang PayOS.';

  @override
  String get payReopen => 'Mở lại trang thanh toán';

  @override
  String get payWithPayOS => 'Thanh toán qua PayOS';

  @override
  String get payCheckStatus => 'Kiểm tra trạng thái';

  @override
  String get payLater => 'Thanh toán sau';

  @override
  String get paySuccessShort => 'Thanh toán thành công';

  @override
  String get histTitle => 'Lịch sử gửi xe';

  @override
  String get histEmptyTitle => 'Chưa có lượt gửi xe';

  @override
  String get histEmptyMessage =>
      'Lượt gửi xe gắn với tài khoản (vé tháng hoặc đặt trước) sẽ hiện ở đây sau khi bạn vào bãi.';

  @override
  String get histActive => 'Đang gửi';

  @override
  String get histDone => 'Đã hoàn tất';

  @override
  String sessTileActive(String time, String duration) {
    return 'Vào $time, đã gửi $duration';
  }

  @override
  String sessSlot(String slot) {
    return 'Ô $slot';
  }

  @override
  String get feeRunning => 'Phí tạm tính';

  @override
  String get feeFree => 'Miễn phí';

  @override
  String get feeCovered => 'Đã bao gồm trong vé tháng của biển số này.';

  @override
  String get feeDuration => 'Thời gian gửi';

  @override
  String feeHoursValue(String hours) {
    return '$hours giờ';
  }

  @override
  String get feeBilledHours => 'Số giờ tính phí';

  @override
  String feeExtraHours(String hours) {
    return '$hours giờ thêm';
  }

  @override
  String feeNight(String count) {
    return 'Phụ thu qua đêm x$count';
  }

  @override
  String get feeDeposit => 'Trừ tiền cọc';

  @override
  String get sessNotFound => 'Không tìm thấy lượt gửi xe này trong tài khoản.';

  @override
  String get sessPayTitle => 'Thanh toán phí gửi xe';

  @override
  String get sessPayDesc =>
      'Lượt gửi xe được hoàn tất ngay khi PayOS xác nhận thanh toán.';

  @override
  String get sessPaid => 'Đã thanh toán phí gửi xe';

  @override
  String get sessTitle => 'Lượt gửi xe';

  @override
  String sessTotal(String duration) {
    return 'Tổng thời gian $duration';
  }

  @override
  String get sessShowAtExit => 'Đưa mã này cho nhân viên tại cổng ra';

  @override
  String get sessNeedPay => 'Cần thanh toán để ra bãi';

  @override
  String sessNeedPayDetail(String amount, String method) {
    return '$amount bằng $method.';
  }

  @override
  String get sessPayCash => 'Vui lòng trả tiền mặt cho nhân viên tại cổng.';

  @override
  String get sessEntry => 'Giờ vào';

  @override
  String get sessEntryGate => 'Cổng vào';

  @override
  String get sessSpot => 'Vị trí đỗ';

  @override
  String get sessExit => 'Giờ ra';

  @override
  String get sessExitGate => 'Cổng ra';

  @override
  String get sessMode => 'Hình thức';

  @override
  String get sessModeBooked => 'Đặt chỗ trước';

  @override
  String get sessModeDirect => 'Gửi trực tiếp';

  @override
  String get sessPaidAmount => 'Đã thanh toán';

  @override
  String get sessMethod => 'Phương thức';

  @override
  String get sessReport => 'Báo sự cố cho lượt gửi này';

  @override
  String get passesTitle => 'Xe và vé tháng';

  @override
  String get passesRegister => 'Đăng ký vé';

  @override
  String get passesEmptyTitle => 'Chưa có xe nào';

  @override
  String get passesEmptyMessage =>
      'Đăng ký vé tháng cho biển số của bạn để ra vào bãi không cần trả phí theo lượt.';

  @override
  String get passesRegisterPass => 'Đăng ký vé tháng';

  @override
  String get passesPlateRequests => 'Yêu cầu đổi biển số';

  @override
  String passesPendingRequests(String count) {
    return '$count yêu cầu đang chờ duyệt';
  }

  @override
  String get passesTrackRequests => 'Theo dõi yêu cầu đổi xe cho vé tháng';

  @override
  String get passesAll => 'Tất cả vé tháng';

  @override
  String passDaysLeft(int days) {
    return 'Còn $days ngày';
  }

  @override
  String passExpiresOn(String date) {
    return 'Hết hạn $date';
  }

  @override
  String passFixedSlot(String slot) {
    return 'Vị trí cố định $slot';
  }

  @override
  String get passPayToActivate => 'Thanh toán để kích hoạt vé';

  @override
  String passLastParked(String time) {
    return 'Gửi gần nhất $time. Đăng ký vé tháng';
  }

  @override
  String get passRenewOrRegister => 'Gia hạn hoặc đăng ký lại';

  @override
  String get passTitle => 'Vé tháng';

  @override
  String passDaysLeftUntil(int days, String date) {
    return 'Còn $days ngày, hết hạn $date';
  }

  @override
  String get passStart => 'Bắt đầu';

  @override
  String get passEnd => 'Kết thúc';

  @override
  String get passFixedSlotLabel => 'Vị trí cố định';

  @override
  String get passPrice => 'Giá gói';

  @override
  String passPay(String amount) {
    return 'Thanh toán $amount';
  }

  @override
  String get passRenew => 'Gia hạn';

  @override
  String get passChangePlate => 'Đổi biển số';

  @override
  String get passCancel => 'Hủy vé tháng';

  @override
  String get passRenewals => 'Lịch sử gia hạn';

  @override
  String get passPayTitle => 'Thanh toán vé tháng';

  @override
  String passPayDesc(String package, String plate) {
    return '$package cho biển số $plate.';
  }

  @override
  String passRegisterPayDesc(String package, String plate) {
    return '$package cho biển số $plate. Vé được kích hoạt ngay khi thanh toán thành công.';
  }

  @override
  String get passRenewTitle => 'Gia hạn vé tháng';

  @override
  String passRenewDesc(String package, String plate) {
    return '$package cho biển số $plate. Thời hạn được cộng tiếp từ ngày hết hạn hiện tại (hoặc từ hôm nay nếu vé đã hết hạn).';
  }

  @override
  String get passCancelTitle => 'Hủy vé tháng?';

  @override
  String passCancelMessage(String plate) {
    return 'Vé của biển số $plate sẽ ngừng hiệu lực.';
  }

  @override
  String passCancelMessageSlot(String plate, String slot) {
    return 'Vé của biển số $plate sẽ ngừng hiệu lực và vị trí $slot được trả lại.';
  }

  @override
  String get passCancelAction => 'Hủy vé';

  @override
  String get passCancelled => 'Đã hủy vé tháng';

  @override
  String get passPlateRequested => 'Đã gửi yêu cầu đổi biển số';

  @override
  String get passRenewPick => 'Chọn gói gia hạn';

  @override
  String get passRenewNoneTitle => 'Không có gói phù hợp';

  @override
  String get passRenewNoneMessage =>
      'Hiện không có gói đang mở bán cho loại xe này.';

  @override
  String passMonths(int months) {
    return '$months tháng';
  }

  @override
  String get passFixedSlotTag => 'vị trí cố định';

  @override
  String get regTitle => 'Đăng ký vé tháng';

  @override
  String get regPickPackage => 'Vui lòng chọn gói vé tháng.';

  @override
  String get regNeedSlot => 'Gói này yêu cầu chọn vị trí đỗ cố định.';

  @override
  String get regEmptyTitle => 'Chưa có gói vé tháng';

  @override
  String get regEmptyMessage => 'Bãi xe hiện chưa mở bán gói vé tháng nào.';

  @override
  String get regPlateHelper => 'Nhập liền, không cần dấu gạch hoặc chấm.';

  @override
  String get regFixedSlot => 'Vị trí đỗ cố định';

  @override
  String get regNoSlot =>
      'Tầng cư dân hiện không còn vị trí trống cho loại xe này.';

  @override
  String get regChoosePackage => 'Chọn gói vé tháng';

  @override
  String plateSheetCurrent(String plate) {
    return 'Biển số hiện tại $plate. Yêu cầu cần quản lý bãi duyệt.';
  }

  @override
  String get plateNew => 'Biển số mới';

  @override
  String get plateReason => 'Lý do (không bắt buộc)';

  @override
  String get plateReasonField => 'Lý do';

  @override
  String get plateSend => 'Gửi yêu cầu';

  @override
  String get plateEditTitle => 'Sửa yêu cầu đổi biển số';

  @override
  String get plateUpdated => 'Đã cập nhật yêu cầu';

  @override
  String get plateWithdrawTitle => 'Rút yêu cầu?';

  @override
  String plateWithdrawMessage(String plate) {
    return 'Yêu cầu đổi sang biển số $plate sẽ bị xóa.';
  }

  @override
  String get plateWithdraw => 'Rút yêu cầu';

  @override
  String get plateWithdrawn => 'Đã rút yêu cầu';

  @override
  String get plateEmptyTitle => 'Chưa có yêu cầu';

  @override
  String get plateEmptyMessage =>
      'Mở một vé tháng đang hiệu lực và chọn \"Đổi biển số\" để gửi yêu cầu.';

  @override
  String plateSentAt(String time) {
    return 'Gửi $time';
  }

  @override
  String plateReasonValue(String reason) {
    return 'Lý do: $reason';
  }

  @override
  String plateRejectedValue(String reason) {
    return 'Từ chối: $reason';
  }

  @override
  String get incSuggestCollision => 'Va chạm, trầy xước';

  @override
  String get incSuggestFee => 'Sai phí gửi xe';

  @override
  String get incSuggestLost => 'Mất đồ';

  @override
  String get incSuggestNoSpace => 'Không tìm thấy chỗ đỗ';

  @override
  String get incPhotoTitle => 'Ảnh minh chứng';

  @override
  String get incSent => 'Đã gửi báo cáo sự cố';

  @override
  String get incNewTitle => 'Báo sự cố';

  @override
  String get incType => 'Loại sự cố';

  @override
  String get incTypeField => 'loại sự cố';

  @override
  String get incDescription => 'Mô tả chi tiết';

  @override
  String get incDescriptionHint => 'Thời điểm, vị trí, điều đã xảy ra';

  @override
  String get incDescriptionField => 'mô tả';

  @override
  String get incSession => 'Lượt gửi xe liên quan';

  @override
  String get incNoSession => 'Không gắn lượt gửi';

  @override
  String get incSelectedSession => 'Lượt gửi đã chọn';

  @override
  String get incAddPhoto => 'Thêm ảnh';

  @override
  String get incRemovePhoto => 'Bỏ ảnh';

  @override
  String get incSubmit => 'Gửi báo cáo';

  @override
  String get incListTitle => 'Sự cố đã báo';

  @override
  String get incReport => 'Báo sự cố';

  @override
  String get incEmptyTitle => 'Chưa có báo cáo';

  @override
  String get incEmptyMessage =>
      'Gặp vấn đề trong bãi (va chạm, sai phí, mất đồ)? Gửi báo cáo kèm ảnh để nhân viên xử lý.';

  @override
  String get incAssigned => 'Bạn đã nhận xử lý sự cố này';

  @override
  String get incResolvedToast => 'Đã đánh dấu đã xử lý';

  @override
  String get incDetailTitle => 'Chi tiết sự cố';

  @override
  String get incImageFailed => 'Không tải được ảnh';

  @override
  String get incReporter => 'Người báo';

  @override
  String get incLinkedSession => 'Gắn lượt gửi xe';

  @override
  String get incHandler => 'Người xử lý';

  @override
  String get incUnassigned => 'Chưa phân công';

  @override
  String get incResolvedAt => 'Xử lý lúc';

  @override
  String get incResult => 'Kết quả xử lý';

  @override
  String get incTake => 'Nhận xử lý';

  @override
  String get incTakeOver => 'Chuyển cho tôi xử lý';

  @override
  String get incMarkResolved => 'Đánh dấu đã xử lý';

  @override
  String get incNotes => 'Ghi chú xử lý';

  @override
  String get incNotesHint => 'Đã kiểm tra camera, đã liên hệ khách...';

  @override
  String get incNotesField => 'ghi chú xử lý';

  @override
  String get incConfirmResolved => 'Xác nhận đã xử lý';

  @override
  String incReporterValue(String name) {
    return 'Người báo: $name';
  }

  @override
  String incHandlerValue(String name) {
    return 'Xử lý: $name';
  }

  @override
  String get accTitle => 'Tài khoản';

  @override
  String get accBioReasonEnable =>
      'Xác thực để bật khóa ứng dụng bằng sinh trắc học';

  @override
  String get accBioEnabled => 'Đã bật mở khóa bằng sinh trắc học';

  @override
  String get accBioFailed => 'Chưa xác thực được nên chưa bật tính năng';

  @override
  String get accLogoutTitle => 'Đăng xuất?';

  @override
  String get accLogoutMessage =>
      'Bạn sẽ cần đăng nhập lại để sử dụng ứng dụng.';

  @override
  String get accProfileSecurity => 'Hồ sơ và bảo mật';

  @override
  String get accEditProfile => 'Sửa thông tin cá nhân';

  @override
  String get accChangePassword => 'Đổi mật khẩu';

  @override
  String get accBioTitle => 'Mở khóa bằng sinh trắc học';

  @override
  String get accBioOn => 'Yêu cầu vân tay hoặc Face ID mỗi khi mở ứng dụng';

  @override
  String get accBioUnavailable =>
      'Thiết bị chưa hỗ trợ hoặc chưa đăng ký vân tay / khuôn mặt';

  @override
  String get accAppearance => 'Giao diện';

  @override
  String get accThemeSystem => 'Theo máy';

  @override
  String get accThemeLight => 'Sáng';

  @override
  String get accThemeDark => 'Tối';

  @override
  String get accLanguage => 'Ngôn ngữ';

  @override
  String get accAvailability => 'Chỗ trống theo tầng';

  @override
  String get profileUpdated => 'Đã cập nhật thông tin';

  @override
  String get profileTitle => 'Thông tin cá nhân';

  @override
  String get profileEmailHelper => 'Email dùng để đăng nhập và nhận mã OTP.';

  @override
  String get profileSave => 'Lưu thay đổi';

  @override
  String get pwdChanged => 'Đã đổi mật khẩu';

  @override
  String get pwdTitle => 'Đổi mật khẩu';

  @override
  String get pwdNote =>
      'Mật khẩu mới áp dụng cho lần đăng nhập tiếp theo trên mọi thiết bị.';

  @override
  String get pwdSubmit => 'Đổi mật khẩu';

  @override
  String get gateEntry => 'Cổng vào';

  @override
  String get gateExit => 'Cổng ra';

  @override
  String get gateReload => 'Tải lại danh sách cổng';

  @override
  String get gateNoneEntry => 'Bãi chưa cấu hình cổng vào.';

  @override
  String get gateNoneExit => 'Bãi chưa cấu hình cổng ra.';

  @override
  String get gatePick => 'Chọn cổng';

  @override
  String get ciPlatePhoto => 'Ảnh biển số';

  @override
  String ciRecognizedPct(String pct) {
    return 'Nhận diện $pct%. Kiểm tra lại trước khi xác nhận.';
  }

  @override
  String get ciRecognized => 'Đã nhận diện. Kiểm tra lại trước khi xác nhận.';

  @override
  String get ciNotRecognized =>
      'Không nhận diện được biển số. Vui lòng nhập tay.';

  @override
  String get ciQrPhoto => 'Ảnh mã QR đặt chỗ';

  @override
  String get ciNotBookingQr => 'Mã QR này không phải mã đặt chỗ.';

  @override
  String get ciPickGate => 'Vui lòng chọn cổng vào.';

  @override
  String get ciPickType => 'Vui lòng chọn loại xe.';

  @override
  String ciSuccess(String type) {
    return '$type: check-in thành công';
  }

  @override
  String get ciTitle => 'Xe vào bãi';

  @override
  String get ciScanPlate => 'Chụp và nhận diện biển số';

  @override
  String get ciBookingCode => 'Mã đặt chỗ';

  @override
  String get ciBookingHint => 'Quét QR trên ứng dụng của khách';

  @override
  String get ciBookingField => 'mã đặt chỗ';

  @override
  String get ciScanQr => 'Quét mã QR';

  @override
  String get ciBookingWindow =>
      'Chỉ check-in trong khoảng 30 phút trước hoặc sau giờ hẹn.';

  @override
  String get ciResidentNote =>
      'Hệ thống tự kiểm tra vé tháng còn hiệu lực theo biển số.';

  @override
  String get ciSubmit => 'Xác nhận cho xe vào';

  @override
  String ciGuideToSlot(String slot) {
    return 'Hướng dẫn xe tới ô $slot';
  }

  @override
  String get ciEntered => 'Xe đã vào bãi';

  @override
  String ciEnteredAt(String type, String time) {
    return '$type, vào lúc $time';
  }

  @override
  String get ciTicketNote => 'Khách chụp lại mã này để dùng khi ra bãi';

  @override
  String get ciNext => 'Lượt xe tiếp theo';

  @override
  String get coTicketPhoto => 'Ảnh mã QR vé gửi xe';

  @override
  String get coNotActiveQr =>
      'Mã QR không thuộc lượt gửi xe nào đang hoạt động.';

  @override
  String get coPickGate => 'Vui lòng chọn cổng ra.';

  @override
  String get coScanFirst => 'Vui lòng quét mã QR vé của khách.';

  @override
  String get coPayOSReceived => 'Đã nhận thanh toán PayOS';

  @override
  String get coPaymentCancelled => 'Thanh toán đã bị hủy';

  @override
  String get coCancelTitle => 'Hủy yêu cầu ra bãi?';

  @override
  String get coCancelMessage => 'Lượt gửi xe sẽ trở lại trạng thái đang gửi.';

  @override
  String get coCancelAction => 'Hủy yêu cầu';

  @override
  String get coCancelled => 'Đã hủy yêu cầu ra bãi';

  @override
  String get coTitle => 'Xe ra bãi';

  @override
  String get coByTicket => 'Quét vé QR';

  @override
  String get coByPlate => 'Theo biển số';

  @override
  String get coScanPrompt => 'Chụp mã QR trên vé của khách';

  @override
  String get coRescan => 'Chạm để quét lại';

  @override
  String get coAutoFind => 'Hệ thống tự tìm lượt gửi xe';

  @override
  String get coMethod => 'Hình thức thu phí';

  @override
  String get coPassFree => 'Xe có vé tháng hợp lệ được miễn phí tự động.';

  @override
  String get coSubmit => 'Tính phí và cho xe ra';

  @override
  String get coFailedNote =>
      'Thanh toán đã bị hủy. Lượt gửi xe vẫn đang hoạt động.';

  @override
  String get coDone => 'Đã hoàn tất, cho xe ra bãi.';

  @override
  String get coToCollect => 'Cần thu';

  @override
  String get coNoFee => 'Không phát sinh phí (đã bao gồm trong vé tháng).';

  @override
  String coScanToPay(String amount) {
    return 'Khách quét mã để thanh toán $amount';
  }

  @override
  String get coWaitingPayOS => 'Đang chờ PayOS xác nhận';

  @override
  String coCashCollected(String amount) {
    return 'Đã thu $amount tiền mặt';
  }

  @override
  String get coCancelExit => 'Hủy yêu cầu ra bãi';

  @override
  String get coNext => 'Xe tiếp theo';

  @override
  String get ssTitle => 'Phiên gửi xe';

  @override
  String get ssSearch => 'Tìm theo biển số';

  @override
  String get ssActive => 'Đang gửi';

  @override
  String get ssNoMatchTitle => 'Không tìm thấy biển số';

  @override
  String get ssEmptyTitle => 'Không có phiên nào';

  @override
  String get ssNoMatchMessage => 'Kiểm tra lại biển số hoặc chọn \"Tất cả\".';

  @override
  String get ssEmptyMessage => 'Các xe đang gửi trong bãi sẽ hiện ở đây.';

  @override
  String ssCount(int count) {
    return '$count phiên';
  }

  @override
  String get ssDetailTitle => 'Chi tiết phiên';

  @override
  String get ssDriver => 'Tài xế';

  @override
  String get ssPlateOut => 'Biển số lúc ra';

  @override
  String get ssPayment => 'Thanh toán';

  @override
  String get ssImageFailed => 'Không tải được ảnh cổng';

  @override
  String get siTitle => 'Sự cố';

  @override
  String get siOpen => 'Cần xử lý';

  @override
  String get siMine => 'Của tôi';

  @override
  String get siEmptyTitle => 'Không có sự cố';

  @override
  String get siEmptyMessage => 'Không có báo cáo nào trong mục này.';

  @override
  String get walletTitle => 'Ví PBMS';

  @override
  String get walletBalance => 'Số dư khả dụng';

  @override
  String get walletTopUp => 'Nạp tiền';

  @override
  String get walletTopUpTitle => 'Nạp tiền vào ví';

  @override
  String get walletTopUpDesc =>
      'Số dư được cộng ngay khi PayOS xác nhận thanh toán.';

  @override
  String get walletAmount => 'Số tiền nạp';

  @override
  String walletAmountHint(String min, String max) {
    return 'Từ $min đến $max';
  }

  @override
  String vAmountRange(String min, String max) {
    return 'Số tiền phải là số nguyên từ $min đến $max';
  }

  @override
  String walletTopUpSubmit(String amount) {
    return 'Nạp $amount';
  }

  @override
  String get walletHistory => 'Lịch sử giao dịch';

  @override
  String get walletFilterTopUps => 'Nạp';

  @override
  String get walletFilterSpends => 'Chi';

  @override
  String get walletEmptyTitle => 'Chưa có giao dịch';

  @override
  String get walletEmptyMessage =>
      'Nạp tiền để thanh toán vé tháng ngay, không cần chuyển khoản mỗi lần.';

  @override
  String get walletPendingNote =>
      'Lượt nạp chỉ hiện trong lịch sử sau khi PayOS xác nhận.';

  @override
  String get walletTxTopUp => 'Nạp ví qua PayOS';

  @override
  String walletTxSpend(String package) {
    return 'Mua $package';
  }

  @override
  String get walletTxSpendGeneric => 'Thanh toán vé tháng bằng ví';

  @override
  String walletBalanceAfter(String amount) {
    return 'Số dư sau: $amount';
  }

  @override
  String get walletToppedUp => 'Đã nạp tiền vào ví';

  @override
  String get payMethodTitle => 'Phương thức thanh toán';

  @override
  String get payMethodWallet => 'Ví PBMS';

  @override
  String payMethodWalletBalance(String amount) {
    return 'Số dư $amount';
  }

  @override
  String payMethodWalletShort(String amount) {
    return 'Số dư không đủ, thiếu $amount';
  }

  @override
  String get payMethodPayOSHint => 'Chuyển khoản qua VietQR';

  @override
  String get passPaidByWallet =>
      'Đã thanh toán bằng ví. Vé tháng đã được kích hoạt.';

  @override
  String get passPayChoose => 'Chọn cách thanh toán';

  @override
  String passPayConfirm(String amount) {
    return 'Thanh toán $amount';
  }

  @override
  String get accAvatarChange => 'Đổi ảnh đại diện';

  @override
  String get accAvatarUpdated => 'Đã cập nhật ảnh đại diện';

  @override
  String get accAvatarTooLarge =>
      'Ảnh vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn.';
}
