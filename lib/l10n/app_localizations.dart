import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('vi')
  ];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'PBMS Parking'**
  String get appName;

  /// No description provided for @commonBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get commonBack;

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get commonAll;

  /// No description provided for @commonDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get commonDone;

  /// No description provided for @commonEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get commonEdit;

  /// No description provided for @commonYes.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get commonNo;

  /// No description provided for @commonNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get commonNone;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải'**
  String get commonLoading;

  /// No description provided for @commonUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ'**
  String get commonUnknown;

  /// No description provided for @commonLogout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get commonLogout;

  /// No description provided for @loadFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được dữ liệu'**
  String get loadFailedTitle;

  /// No description provided for @showPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get hidePassword;

  /// No description provided for @imagePickTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get imagePickTitle;

  /// No description provided for @imageTakePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get imageTakePhoto;

  /// No description provided for @imageFromLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get imageFromLibrary;

  /// No description provided for @ticketQrSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR vé gửi xe'**
  String get ticketQrSemantics;

  /// No description provided for @ticketCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã vé'**
  String get ticketCopied;

  /// No description provided for @ticketCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã vé {code}'**
  String ticketCode(String code);

  /// No description provided for @versionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version}'**
  String versionLabel(String version);

  /// No description provided for @errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra. Vui lòng thử lại.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối máy chủ. Kiểm tra mạng và thử lại.'**
  String get errorNetwork;

  /// No description provided for @errorStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi ({code}).'**
  String errorStatus(String code);

  /// No description provided for @errorSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'**
  String get errorSessionExpired;

  /// No description provided for @timeToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay {time}'**
  String timeToday(String time);

  /// No description provided for @timeTomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai {time}'**
  String timeTomorrow(String time);

  /// No description provided for @timeYesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua {time}'**
  String timeYesterday(String time);

  /// No description provided for @timeOnDate.
  ///
  /// In vi, this message translates to:
  /// **'{time}, {date}'**
  String timeOnDate(String time, String date);

  /// No description provided for @durationDaysHours.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày {hours} giờ'**
  String durationDaysHours(String days, String hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ {minutes} phút'**
  String durationHoursMinutes(String hours, String minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String durationMinutes(String minutes);

  /// No description provided for @agoJustNow.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get agoJustNow;

  /// No description provided for @agoMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{n} phút trước'**
  String agoMinutes(int n);

  /// No description provided for @agoHours.
  ///
  /// In vi, this message translates to:
  /// **'{n} giờ trước'**
  String agoHours(int n);

  /// No description provided for @agoDays.
  ///
  /// In vi, this message translates to:
  /// **'{n} ngày trước'**
  String agoDays(int n);

  /// No description provided for @dateRange.
  ///
  /// In vi, this message translates to:
  /// **'{from} đến {to}'**
  String dateRange(String from, String to);

  /// No description provided for @vRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập {field}'**
  String vRequired(String field);

  /// No description provided for @vEmailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get vEmailRequired;

  /// No description provided for @vEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng định dạng'**
  String get vEmailInvalid;

  /// No description provided for @vMaxLength.
  ///
  /// In vi, this message translates to:
  /// **'{field} tối đa {max} ký tự'**
  String vMaxLength(String field, String max);

  /// No description provided for @vPhoneRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số điện thoại'**
  String get vPhoneRequired;

  /// No description provided for @vPhoneInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại di động Việt Nam chưa hợp lệ'**
  String get vPhoneInvalid;

  /// No description provided for @vUserNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên đăng nhập'**
  String get vUserNameRequired;

  /// No description provided for @vFullNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên'**
  String get vFullNameRequired;

  /// No description provided for @vPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get vPasswordRequired;

  /// No description provided for @vConfirmRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập lại mật khẩu'**
  String get vConfirmRequired;

  /// No description provided for @vConfirmMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu nhập lại không khớp'**
  String get vConfirmMismatch;

  /// No description provided for @vOtpInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP gồm 6 chữ số'**
  String get vOtpInvalid;

  /// No description provided for @vPlateRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập biển số'**
  String get vPlateRequired;

  /// No description provided for @vPlateInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Biển số gồm 4-15 chữ cái và chữ số'**
  String get vPlateInvalid;

  /// No description provided for @vPlateSame.
  ///
  /// In vi, this message translates to:
  /// **'Biển số mới phải khác biển số hiện tại'**
  String get vPlateSame;

  /// No description provided for @fieldEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldUserName.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập'**
  String get fieldUserName;

  /// No description provided for @fieldFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fieldFullName;

  /// No description provided for @fieldPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get fieldPhone;

  /// No description provided for @fieldEmailLabel.
  ///
  /// In vi, this message translates to:
  /// **'email'**
  String get fieldEmailLabel;

  /// No description provided for @fieldFullNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fieldFullNameLabel;

  /// No description provided for @fieldUserNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập'**
  String get fieldUserNameLabel;

  /// No description provided for @fieldPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu'**
  String get fieldPasswordConfirm;

  /// No description provided for @fieldNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get fieldNewPassword;

  /// No description provided for @fieldNewPasswordConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu mới'**
  String get fieldNewPasswordConfirm;

  /// No description provided for @fieldOtp.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP'**
  String get fieldOtp;

  /// No description provided for @fieldPlate.
  ///
  /// In vi, this message translates to:
  /// **'Biển số xe'**
  String get fieldPlate;

  /// No description provided for @fieldVehicleType.
  ///
  /// In vi, this message translates to:
  /// **'Loại xe'**
  String get fieldVehicleType;

  /// No description provided for @stReservationPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ đặt cọc'**
  String get stReservationPending;

  /// No description provided for @stReservationConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận'**
  String get stReservationConfirmed;

  /// No description provided for @stReservationModified.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi giờ'**
  String get stReservationModified;

  /// No description provided for @stReservationCheckedIn.
  ///
  /// In vi, this message translates to:
  /// **'Đã vào bãi'**
  String get stReservationCheckedIn;

  /// No description provided for @stReservationCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get stReservationCompleted;

  /// No description provided for @stCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get stCancelled;

  /// No description provided for @stReservationNoShow.
  ///
  /// In vi, this message translates to:
  /// **'Quá giờ, không đến'**
  String get stReservationNoShow;

  /// No description provided for @stSessionActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi'**
  String get stSessionActive;

  /// No description provided for @stSessionCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy xe'**
  String get stSessionCompleted;

  /// No description provided for @stSessionException.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại lệ'**
  String get stSessionException;

  /// No description provided for @stPassActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang hiệu lực'**
  String get stPassActive;

  /// No description provided for @stPendingPayment.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get stPendingPayment;

  /// No description provided for @stPassExpired.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn'**
  String get stPassExpired;

  /// No description provided for @stPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get stPaid;

  /// No description provided for @stIncidentOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mới gửi'**
  String get stIncidentOpen;

  /// No description provided for @stIncidentInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get stIncidentInProgress;

  /// No description provided for @stIncidentResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xử lý'**
  String get stIncidentResolved;

  /// No description provided for @stChangePending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get stChangePending;

  /// No description provided for @stChangeApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt'**
  String get stChangeApproved;

  /// No description provided for @stChangeRejected.
  ///
  /// In vi, this message translates to:
  /// **'Bị từ chối'**
  String get stChangeRejected;

  /// No description provided for @stNoPass.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có vé tháng'**
  String get stNoPass;

  /// No description provided for @payMethodPayOS.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản PayOS'**
  String get payMethodPayOS;

  /// No description provided for @payMethodCash.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt'**
  String get payMethodCash;

  /// No description provided for @payTypeDeposit.
  ///
  /// In vi, this message translates to:
  /// **'Đặt cọc giữ chỗ'**
  String get payTypeDeposit;

  /// No description provided for @payTypeCheckout.
  ///
  /// In vi, this message translates to:
  /// **'Phí gửi xe'**
  String get payTypeCheckout;

  /// No description provided for @payTypeSubscription.
  ///
  /// In vi, this message translates to:
  /// **'Phí vé tháng'**
  String get payTypeSubscription;

  /// No description provided for @payTypeRenewal.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn vé tháng'**
  String get payTypeRenewal;

  /// No description provided for @roleStaff.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên vận hành'**
  String get roleStaff;

  /// No description provided for @roleManager.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý bãi xe'**
  String get roleManager;

  /// No description provided for @roleAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị viên'**
  String get roleAdmin;

  /// No description provided for @roleCustomer.
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng'**
  String get roleCustomer;

  /// No description provided for @customerGuest.
  ///
  /// In vi, this message translates to:
  /// **'Vãng lai'**
  String get customerGuest;

  /// No description provided for @customerResident.
  ///
  /// In vi, this message translates to:
  /// **'Vé tháng'**
  String get customerResident;

  /// No description provided for @customerReservation.
  ///
  /// In vi, this message translates to:
  /// **'Đặt trước'**
  String get customerReservation;

  /// No description provided for @customerGuestFull.
  ///
  /// In vi, this message translates to:
  /// **'Khách vãng lai'**
  String get customerGuestFull;

  /// No description provided for @customerResidentFull.
  ///
  /// In vi, this message translates to:
  /// **'Khách vé tháng'**
  String get customerResidentFull;

  /// No description provided for @customerReservationFull.
  ///
  /// In vi, this message translates to:
  /// **'Khách đặt trước'**
  String get customerReservationFull;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get navHistory;

  /// No description provided for @navPasses.
  ///
  /// In vi, this message translates to:
  /// **'Vé tháng'**
  String get navPasses;

  /// No description provided for @navAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get navAccount;

  /// No description provided for @navCheckIn.
  ///
  /// In vi, this message translates to:
  /// **'Vào bãi'**
  String get navCheckIn;

  /// No description provided for @navCheckOut.
  ///
  /// In vi, this message translates to:
  /// **'Ra bãi'**
  String get navCheckOut;

  /// No description provided for @navSessions.
  ///
  /// In vi, this message translates to:
  /// **'Phiên gửi'**
  String get navSessions;

  /// No description provided for @navIncidents.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố'**
  String get navIncidents;

  /// No description provided for @unsupportedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò chưa được hỗ trợ'**
  String get unsupportedTitle;

  /// No description provided for @unsupportedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản {email} có vai trò \"{role}\". Ứng dụng dành cho khách hàng và nhân viên vận hành cổng. Vui lòng dùng trang quản trị.'**
  String unsupportedMessage(String email, String role);

  /// No description provided for @notFoundTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy trang'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đường dẫn này không tồn tại hoặc đã bị thay đổi.'**
  String get notFoundMessage;

  /// No description provided for @notFoundAction.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chính'**
  String get notFoundAction;

  /// No description provided for @lockReason.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để mở khóa PBMS Parking'**
  String get lockReason;

  /// No description provided for @lockFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác thực được. Thử lại hoặc đăng xuất để đăng nhập bằng mật khẩu.'**
  String get lockFailed;

  /// No description provided for @lockTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng đang khóa'**
  String get lockTitle;

  /// No description provided for @lockMessage.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào {name}. Dùng vân tay hoặc khuôn mặt đã đăng ký trên thiết bị để tiếp tục.'**
  String lockMessage(String name);

  /// No description provided for @lockSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa bằng sinh trắc học'**
  String get lockSemantics;

  /// No description provided for @lockUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa'**
  String get lockUnlock;

  /// No description provided for @splashTagline.
  ///
  /// In vi, this message translates to:
  /// **'Gửi xe, đặt chỗ và vé tháng tại một nơi.'**
  String get splashTagline;

  /// No description provided for @splashChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra phiên đăng nhập'**
  String get splashChecking;

  /// No description provided for @loginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dùng email đã đăng ký để quản lý lượt gửi xe, đặt chỗ và vé tháng.'**
  String get loginSubtitle;

  /// No description provided for @loginForgot.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get loginForgot;

  /// No description provided for @loginSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginSubmit;

  /// No description provided for @loginNoAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản?'**
  String get loginNoAccount;

  /// No description provided for @loginRegister.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get loginRegister;

  /// No description provided for @loginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập không thành công. Vui lòng kiểm tra lại.'**
  String get loginFailed;

  /// No description provided for @loginRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công. Vui lòng đăng nhập.'**
  String get loginRegistered;

  /// No description provided for @loginPasswordReset.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu thành công. Hãy đăng nhập bằng mật khẩu mới.'**
  String get loginPasswordReset;

  /// No description provided for @registerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực 6 số sẽ được gửi tới email của bạn.'**
  String get registerSubtitle;

  /// No description provided for @registerSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã xác thực'**
  String get registerSubmit;

  /// No description provided for @otpSendFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi mã OTP. Vui lòng thử lại sau.'**
  String get otpSendFailed;

  /// No description provided for @otpVerifyFailed.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực OTP thất bại. Vui lòng thử lại.'**
  String get otpVerifyFailed;

  /// No description provided for @otpTitleRegister.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực email'**
  String get otpTitleRegister;

  /// No description provided for @otpTitleReset.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get otpTitleReset;

  /// No description provided for @otpSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã 6 số vừa gửi tới {email}. Mã có hiệu lực trong 10 phút.'**
  String otpSubtitle(String email);

  /// No description provided for @otpSubmitRegister.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất đăng ký'**
  String get otpSubmitRegister;

  /// No description provided for @otpSubmitReset.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get otpSubmitReset;

  /// No description provided for @otpResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get otpResend;

  /// No description provided for @otpEditAndResend.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin và gửi lại mã'**
  String get otpEditAndResend;

  /// No description provided for @otpResent.
  ///
  /// In vi, this message translates to:
  /// **'Nếu email đã đăng ký, mã OTP đặt lại mật khẩu đã được gửi.'**
  String get otpResent;

  /// No description provided for @resetRequestFailed.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đặt lại mật khẩu thất bại.'**
  String get resetRequestFailed;

  /// No description provided for @resetFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu thất bại. Kiểm tra mã OTP.'**
  String get resetFailed;

  /// No description provided for @forgotTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email đã đăng ký. Chúng tôi sẽ gửi mã OTP để bạn đặt mật khẩu mới.'**
  String get forgotSubtitle;

  /// No description provided for @forgotSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã OTP'**
  String get forgotSubmit;

  /// No description provided for @onbSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onbSkip;

  /// No description provided for @onbNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onbNext;

  /// No description provided for @onbStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get onbStart;

  /// No description provided for @onb1Title.
  ///
  /// In vi, this message translates to:
  /// **'Xem chỗ trống trước khi đến'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In vi, this message translates to:
  /// **'Số chỗ còn trống theo từng tầng và loại xe, cập nhật từ hệ thống bãi.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ ô tô, vào cổng bằng mã QR'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In vi, this message translates to:
  /// **'Đặt trước tối đa 5 tiếng, đặt cọc qua PayOS và đưa mã vé cho nhân viên tại cổng.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In vi, this message translates to:
  /// **'Vé tháng và phí gửi xe rõ ràng'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký, gia hạn vé tháng và xem phí tạm tính của lượt gửi ngay trên điện thoại.'**
  String get onb3Body;

  /// No description provided for @notifTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifTooltip;

  /// No description provided for @notifTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifTitle;

  /// No description provided for @notifMarkAll.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã đọc'**
  String get notifMarkAll;

  /// No description provided for @notifEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo'**
  String get notifEmptyTitle;

  /// No description provided for @notifEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo về đặt chỗ, vé tháng và sự cố sẽ hiện ở đây.'**
  String get notifEmptyMessage;

  /// No description provided for @homeMorning.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng'**
  String get homeMorning;

  /// No description provided for @homeAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi chiều'**
  String get homeAfternoon;

  /// No description provided for @homeEvening.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi tối'**
  String get homeEvening;

  /// No description provided for @homeServices.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get homeServices;

  /// No description provided for @homeBookCar.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ ô tô'**
  String get homeBookCar;

  /// No description provided for @homeBookCarSub.
  ///
  /// In vi, this message translates to:
  /// **'Giữ chỗ trước tối đa 5 tiếng, đặt cọc qua PayOS'**
  String get homeBookCarSub;

  /// No description provided for @homeMyBookings.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ của tôi'**
  String get homeMyBookings;

  /// No description provided for @homeMyBookingsSub.
  ///
  /// In vi, this message translates to:
  /// **'Xem vé, đổi giờ hoặc hủy đặt chỗ'**
  String get homeMyBookingsSub;

  /// No description provided for @homeAvailability.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ trống theo tầng'**
  String get homeAvailability;

  /// No description provided for @homeAvailabilitySub.
  ///
  /// In vi, this message translates to:
  /// **'Tình trạng bãi và bảng giá hiện hành'**
  String get homeAvailabilitySub;

  /// No description provided for @homeReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo sự cố'**
  String get homeReport;

  /// No description provided for @homeReportSub.
  ///
  /// In vi, this message translates to:
  /// **'Gửi phản ánh kèm ảnh và theo dõi xử lý'**
  String get homeReportSub;

  /// No description provided for @homeParkedFor.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi {duration}'**
  String homeParkedFor(String duration);

  /// No description provided for @homeEnteredAt.
  ///
  /// In vi, this message translates to:
  /// **'Vào lúc {time} qua {gate}'**
  String homeEnteredAt(String time, String gate);

  /// No description provided for @homeEnteredSlot.
  ///
  /// In vi, this message translates to:
  /// **', ô {slot}'**
  String homeEnteredSlot(String slot);

  /// No description provided for @homePayToExit.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán phí để ra bãi'**
  String get homePayToExit;

  /// No description provided for @homeViewTicket.
  ///
  /// In vi, this message translates to:
  /// **'Xem vé và phí tạm tính'**
  String get homeViewTicket;

  /// No description provided for @homeFreeNow.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ trống hiện tại'**
  String get homeFreeNow;

  /// No description provided for @homeNoAvailability.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu chỗ trống'**
  String get homeNoAvailability;

  /// No description provided for @homeNoSlots.
  ///
  /// In vi, this message translates to:
  /// **'Bãi chưa cấu hình ô đỗ.'**
  String get homeNoSlots;

  /// No description provided for @homeOfSpaces.
  ///
  /// In vi, this message translates to:
  /// **'/ {total} chỗ'**
  String homeOfSpaces(String total);

  /// No description provided for @homeTypeFree.
  ///
  /// In vi, this message translates to:
  /// **'{type}: {count} trống'**
  String homeTypeFree(String type, String count);

  /// No description provided for @homeByFloor.
  ///
  /// In vi, this message translates to:
  /// **'Xem theo tầng'**
  String get homeByFloor;

  /// No description provided for @homeBookingAt.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ {time}'**
  String homeBookingAt(String time);

  /// No description provided for @homeFinishDeposit.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất đặt cọc để giữ chỗ'**
  String get homeFinishDeposit;

  /// No description provided for @homeArriveWindow.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt trong khoảng 30 phút trước hoặc sau giờ hẹn'**
  String get homeArriveWindow;

  /// No description provided for @availTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ trống'**
  String get availTitle;

  /// No description provided for @availEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu ô đỗ'**
  String get availEmptyTitle;

  /// No description provided for @availEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bãi xe chưa cấu hình tầng và ô đỗ. Vui lòng quay lại sau.'**
  String get availEmptyMessage;

  /// No description provided for @availResidentFloor.
  ///
  /// In vi, this message translates to:
  /// **'Tầng cư dân / vé tháng'**
  String get availResidentFloor;

  /// No description provided for @availOfFree.
  ///
  /// In vi, this message translates to:
  /// **' / {total} trống'**
  String availOfFree(String total);

  /// No description provided for @availPricing.
  ///
  /// In vi, this message translates to:
  /// **'Bảng giá gửi xe'**
  String get availPricing;

  /// No description provided for @priceFirstHours.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ đầu'**
  String priceFirstHours(String hours);

  /// No description provided for @priceExtraHour.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi giờ tiếp theo'**
  String get priceExtraHour;

  /// No description provided for @priceNight.
  ///
  /// In vi, this message translates to:
  /// **'Phụ thu qua đêm (22:00-06:00)'**
  String get priceNight;

  /// No description provided for @resNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ ô tô'**
  String get resNewTitle;

  /// No description provided for @resNewIntro.
  ///
  /// In vi, this message translates to:
  /// **'Đặt trước áp dụng cho ô tô, tối đa 5 tiếng trước giờ vào. Bạn được vào bãi trong khoảng 30 phút trước hoặc sau giờ hẹn.'**
  String get resNewIntro;

  /// No description provided for @resCarFree.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ ô tô vãng lai còn trống'**
  String get resCarFree;

  /// No description provided for @resSpaces.
  ///
  /// In vi, this message translates to:
  /// **'{count} chỗ'**
  String resSpaces(String count);

  /// No description provided for @resDepositEstimate.
  ///
  /// In vi, this message translates to:
  /// **'Tiền cọc dự kiến'**
  String get resDepositEstimate;

  /// No description provided for @resPerPricing.
  ///
  /// In vi, this message translates to:
  /// **'Theo bảng giá'**
  String get resPerPricing;

  /// No description provided for @resPrice.
  ///
  /// In vi, this message translates to:
  /// **'Giá gửi'**
  String get resPrice;

  /// No description provided for @resPriceValue.
  ///
  /// In vi, this message translates to:
  /// **'{base} / {hours} giờ đầu, {extra} / giờ sau'**
  String resPriceValue(String base, String hours, String extra);

  /// No description provided for @resEntryTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ vào bãi'**
  String get resEntryTime;

  /// No description provided for @resRefreshSlots.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới khung giờ'**
  String get resRefreshSlots;

  /// No description provided for @resPickTime.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn giờ vào bãi.'**
  String get resPickTime;

  /// No description provided for @resSlotPassed.
  ///
  /// In vi, this message translates to:
  /// **'Khung giờ đã qua. Vui lòng chọn lại.'**
  String get resSlotPassed;

  /// No description provided for @resChooseTime.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ vào bãi'**
  String get resChooseTime;

  /// No description provided for @resBookAt.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ lúc {time}'**
  String resBookAt(String time);

  /// No description provided for @resNoSlots.
  ///
  /// In vi, this message translates to:
  /// **'Không còn khung giờ hợp lệ.'**
  String get resNoSlots;

  /// No description provided for @resDepositTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt cọc giữ chỗ'**
  String get resDepositTitle;

  /// No description provided for @resDepositDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giữ chỗ ô tô lúc {time}. Tiền cọc được trừ vào phí gửi xe khi ra bãi.'**
  String resDepositDesc(String time);

  /// No description provided for @resDepositDescShort.
  ///
  /// In vi, this message translates to:
  /// **'Giữ chỗ ô tô lúc {time}.'**
  String resDepositDescShort(String time);

  /// No description provided for @resListTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ của tôi'**
  String get resListTitle;

  /// No description provided for @resNew.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ mới'**
  String get resNew;

  /// No description provided for @resEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đặt chỗ'**
  String get resEmptyTitle;

  /// No description provided for @resEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đặt trước chỗ ô tô tối đa 5 tiếng và vào bãi bằng mã QR.'**
  String get resEmptyMessage;

  /// No description provided for @resUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get resUpcoming;

  /// No description provided for @resPast.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua'**
  String get resPast;

  /// No description provided for @resTileMeta.
  ///
  /// In vi, this message translates to:
  /// **'{type}, đặt {ago}'**
  String resTileMeta(String type, String ago);

  /// No description provided for @resDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết đặt chỗ'**
  String get resDetailTitle;

  /// No description provided for @resConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận đặt chỗ'**
  String get resConfirmed;

  /// No description provided for @resCancelTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đặt chỗ?'**
  String get resCancelTitle;

  /// No description provided for @resCancelPending.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ chưa đặt cọc sẽ bị hủy.'**
  String get resCancelPending;

  /// No description provided for @resCancelPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ đã đặt cọc sẽ bị hủy và không thể khôi phục.'**
  String get resCancelPaid;

  /// No description provided for @resCancelAction.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đặt chỗ'**
  String get resCancelAction;

  /// No description provided for @resCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy đặt chỗ'**
  String get resCancelled;

  /// No description provided for @resRescheduled.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi giờ sang {time}'**
  String resRescheduled(String time);

  /// No description provided for @resEntryWindow.
  ///
  /// In vi, this message translates to:
  /// **'Vào bãi từ {from} đến {to}'**
  String resEntryWindow(String from, String to);

  /// No description provided for @resShowAtEntry.
  ///
  /// In vi, this message translates to:
  /// **'Đưa mã này cho nhân viên tại cổng vào'**
  String get resShowAtEntry;

  /// No description provided for @resBookedAt.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đặt'**
  String get resBookedAt;

  /// No description provided for @resReschedule.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ'**
  String get resReschedule;

  /// No description provided for @resRescheduleUsed.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng lượt đổi'**
  String get resRescheduleUsed;

  /// No description provided for @resRescheduleLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn 1 lượt'**
  String get resRescheduleLeft;

  /// No description provided for @resPendingNote.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ chỉ được giữ sau khi đặt cọc thành công. Đơn quá giờ hẹn 30 phút sẽ tự hủy.'**
  String get resPendingNote;

  /// No description provided for @resPayDeposit.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán đặt cọc'**
  String get resPayDeposit;

  /// No description provided for @resChangeTime.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ vào'**
  String get resChangeTime;

  /// No description provided for @resChangeRule.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đổi giờ được trước giờ hẹn ít nhất 15 phút.'**
  String get resChangeRule;

  /// No description provided for @resNewTime.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ vào mới'**
  String get resNewTime;

  /// No description provided for @resOneChange.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi đặt chỗ chỉ được đổi giờ 1 lần.'**
  String get resOneChange;

  /// No description provided for @resConfirmChange.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đổi giờ'**
  String get resConfirmChange;

  /// No description provided for @payInvalidLink.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết thanh toán không hợp lệ.'**
  String get payInvalidLink;

  /// No description provided for @payCantOpen.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trang thanh toán trên thiết bị này.'**
  String get payCantOpen;

  /// No description provided for @payNotYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận được thanh toán. Hoàn tất trên trang PayOS rồi kiểm tra lại.'**
  String get payNotYet;

  /// No description provided for @paySuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công'**
  String get paySuccessTitle;

  /// No description provided for @paySuccessMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đã ghi nhận khoản thanh toán của bạn.'**
  String get paySuccessMessage;

  /// No description provided for @payFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán không thành công'**
  String get payFailedTitle;

  /// No description provided for @payFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch đã bị hủy hoặc thất bại. Bạn có thể tạo lại liên kết thanh toán.'**
  String get payFailedMessage;

  /// No description provided for @payAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get payAmount;

  /// No description provided for @payOrderCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng'**
  String get payOrderCode;

  /// No description provided for @payWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ PayOS xác nhận. Màn hình sẽ tự cập nhật.'**
  String get payWaiting;

  /// No description provided for @payHint.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán qua ứng dụng ngân hàng bằng VietQR trên trang PayOS.'**
  String get payHint;

  /// No description provided for @payReopen.
  ///
  /// In vi, this message translates to:
  /// **'Mở lại trang thanh toán'**
  String get payReopen;

  /// No description provided for @payWithPayOS.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán qua PayOS'**
  String get payWithPayOS;

  /// No description provided for @payCheckStatus.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra trạng thái'**
  String get payCheckStatus;

  /// No description provided for @payLater.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán sau'**
  String get payLater;

  /// No description provided for @paySuccessShort.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công'**
  String get paySuccessShort;

  /// No description provided for @histTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử gửi xe'**
  String get histTitle;

  /// No description provided for @histEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lượt gửi xe'**
  String get histEmptyTitle;

  /// No description provided for @histEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Lượt gửi xe gắn với tài khoản (vé tháng hoặc đặt trước) sẽ hiện ở đây sau khi bạn vào bãi.'**
  String get histEmptyMessage;

  /// No description provided for @histActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi'**
  String get histActive;

  /// No description provided for @histDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất'**
  String get histDone;

  /// No description provided for @sessTileActive.
  ///
  /// In vi, this message translates to:
  /// **'Vào {time}, đã gửi {duration}'**
  String sessTileActive(String time, String duration);

  /// No description provided for @sessSlot.
  ///
  /// In vi, this message translates to:
  /// **'Ô {slot}'**
  String sessSlot(String slot);

  /// No description provided for @feeRunning.
  ///
  /// In vi, this message translates to:
  /// **'Phí tạm tính'**
  String get feeRunning;

  /// No description provided for @feeFree.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí'**
  String get feeFree;

  /// No description provided for @feeCovered.
  ///
  /// In vi, this message translates to:
  /// **'Đã bao gồm trong vé tháng của biển số này.'**
  String get feeCovered;

  /// No description provided for @feeDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian gửi'**
  String get feeDuration;

  /// No description provided for @feeHoursValue.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ'**
  String feeHoursValue(String hours);

  /// No description provided for @feeBilledHours.
  ///
  /// In vi, this message translates to:
  /// **'Số giờ tính phí'**
  String get feeBilledHours;

  /// No description provided for @feeExtraHours.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ thêm'**
  String feeExtraHours(String hours);

  /// No description provided for @feeNight.
  ///
  /// In vi, this message translates to:
  /// **'Phụ thu qua đêm x{count}'**
  String feeNight(String count);

  /// No description provided for @feeDeposit.
  ///
  /// In vi, this message translates to:
  /// **'Trừ tiền cọc'**
  String get feeDeposit;

  /// No description provided for @sessNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lượt gửi xe này trong tài khoản.'**
  String get sessNotFound;

  /// No description provided for @sessPayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán phí gửi xe'**
  String get sessPayTitle;

  /// No description provided for @sessPayDesc.
  ///
  /// In vi, this message translates to:
  /// **'Lượt gửi xe được hoàn tất ngay khi PayOS xác nhận thanh toán.'**
  String get sessPayDesc;

  /// No description provided for @sessPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán phí gửi xe'**
  String get sessPaid;

  /// No description provided for @sessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lượt gửi xe'**
  String get sessTitle;

  /// No description provided for @sessTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thời gian {duration}'**
  String sessTotal(String duration);

  /// No description provided for @sessShowAtExit.
  ///
  /// In vi, this message translates to:
  /// **'Đưa mã này cho nhân viên tại cổng ra'**
  String get sessShowAtExit;

  /// No description provided for @sessNeedPay.
  ///
  /// In vi, this message translates to:
  /// **'Cần thanh toán để ra bãi'**
  String get sessNeedPay;

  /// No description provided for @sessNeedPayDetail.
  ///
  /// In vi, this message translates to:
  /// **'{amount} bằng {method}.'**
  String sessNeedPayDetail(String amount, String method);

  /// No description provided for @sessPayCash.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng trả tiền mặt cho nhân viên tại cổng.'**
  String get sessPayCash;

  /// No description provided for @sessEntry.
  ///
  /// In vi, this message translates to:
  /// **'Giờ vào'**
  String get sessEntry;

  /// No description provided for @sessEntryGate.
  ///
  /// In vi, this message translates to:
  /// **'Cổng vào'**
  String get sessEntryGate;

  /// No description provided for @sessSpot.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí đỗ'**
  String get sessSpot;

  /// No description provided for @sessExit.
  ///
  /// In vi, this message translates to:
  /// **'Giờ ra'**
  String get sessExit;

  /// No description provided for @sessExitGate.
  ///
  /// In vi, this message translates to:
  /// **'Cổng ra'**
  String get sessExitGate;

  /// No description provided for @sessMode.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức'**
  String get sessMode;

  /// No description provided for @sessModeBooked.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chỗ trước'**
  String get sessModeBooked;

  /// No description provided for @sessModeDirect.
  ///
  /// In vi, this message translates to:
  /// **'Gửi trực tiếp'**
  String get sessModeDirect;

  /// No description provided for @sessPaidAmount.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get sessPaidAmount;

  /// No description provided for @sessMethod.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức'**
  String get sessMethod;

  /// No description provided for @sessReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo sự cố cho lượt gửi này'**
  String get sessReport;

  /// No description provided for @passesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xe và vé tháng'**
  String get passesTitle;

  /// No description provided for @passesRegister.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký vé'**
  String get passesRegister;

  /// No description provided for @passesEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có xe nào'**
  String get passesEmptyTitle;

  /// No description provided for @passesEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký vé tháng cho biển số của bạn để ra vào bãi không cần trả phí theo lượt.'**
  String get passesEmptyMessage;

  /// No description provided for @passesRegisterPass.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký vé tháng'**
  String get passesRegisterPass;

  /// No description provided for @passesPlateRequests.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đổi biển số'**
  String get passesPlateRequests;

  /// No description provided for @passesPendingRequests.
  ///
  /// In vi, this message translates to:
  /// **'{count} yêu cầu đang chờ duyệt'**
  String passesPendingRequests(String count);

  /// No description provided for @passesTrackRequests.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi yêu cầu đổi xe cho vé tháng'**
  String get passesTrackRequests;

  /// No description provided for @passesAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả vé tháng'**
  String get passesAll;

  /// No description provided for @passDaysLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String passDaysLeft(int days);

  /// No description provided for @passExpiresOn.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn {date}'**
  String passExpiresOn(String date);

  /// No description provided for @passFixedSlot.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí cố định {slot}'**
  String passFixedSlot(String slot);

  /// No description provided for @passPayToActivate.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán để kích hoạt vé'**
  String get passPayToActivate;

  /// No description provided for @passLastParked.
  ///
  /// In vi, this message translates to:
  /// **'Gửi gần nhất {time}. Đăng ký vé tháng'**
  String passLastParked(String time);

  /// No description provided for @passRenewOrRegister.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn hoặc đăng ký lại'**
  String get passRenewOrRegister;

  /// No description provided for @passTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vé tháng'**
  String get passTitle;

  /// No description provided for @passDaysLeftUntil.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày, hết hạn {date}'**
  String passDaysLeftUntil(int days, String date);

  /// No description provided for @passStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get passStart;

  /// No description provided for @passEnd.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get passEnd;

  /// No description provided for @passFixedSlotLabel.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí cố định'**
  String get passFixedSlotLabel;

  /// No description provided for @passPrice.
  ///
  /// In vi, this message translates to:
  /// **'Giá gói'**
  String get passPrice;

  /// No description provided for @passPay.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán {amount}'**
  String passPay(String amount);

  /// No description provided for @passRenew.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn'**
  String get passRenew;

  /// No description provided for @passChangePlate.
  ///
  /// In vi, this message translates to:
  /// **'Đổi biển số'**
  String get passChangePlate;

  /// No description provided for @passCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy vé tháng'**
  String get passCancel;

  /// No description provided for @passRenewals.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử gia hạn'**
  String get passRenewals;

  /// No description provided for @passPayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán vé tháng'**
  String get passPayTitle;

  /// No description provided for @passPayDesc.
  ///
  /// In vi, this message translates to:
  /// **'{package} cho biển số {plate}.'**
  String passPayDesc(String package, String plate);

  /// No description provided for @passRegisterPayDesc.
  ///
  /// In vi, this message translates to:
  /// **'{package} cho biển số {plate}. Vé được kích hoạt ngay khi thanh toán thành công.'**
  String passRegisterPayDesc(String package, String plate);

  /// No description provided for @passRenewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn vé tháng'**
  String get passRenewTitle;

  /// No description provided for @passRenewDesc.
  ///
  /// In vi, this message translates to:
  /// **'{package} cho biển số {plate}. Thời hạn được cộng tiếp từ ngày hết hạn hiện tại (hoặc từ hôm nay nếu vé đã hết hạn).'**
  String passRenewDesc(String package, String plate);

  /// No description provided for @passCancelTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy vé tháng?'**
  String get passCancelTitle;

  /// No description provided for @passCancelMessage.
  ///
  /// In vi, this message translates to:
  /// **'Vé của biển số {plate} sẽ ngừng hiệu lực.'**
  String passCancelMessage(String plate);

  /// No description provided for @passCancelMessageSlot.
  ///
  /// In vi, this message translates to:
  /// **'Vé của biển số {plate} sẽ ngừng hiệu lực và vị trí {slot} được trả lại.'**
  String passCancelMessageSlot(String plate, String slot);

  /// No description provided for @passCancelAction.
  ///
  /// In vi, this message translates to:
  /// **'Hủy vé'**
  String get passCancelAction;

  /// No description provided for @passCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy vé tháng'**
  String get passCancelled;

  /// No description provided for @passPlateRequested.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu đổi biển số'**
  String get passPlateRequested;

  /// No description provided for @passRenewPick.
  ///
  /// In vi, this message translates to:
  /// **'Chọn gói gia hạn'**
  String get passRenewPick;

  /// No description provided for @passRenewNoneTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có gói phù hợp'**
  String get passRenewNoneTitle;

  /// No description provided for @passRenewNoneMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hiện không có gói đang mở bán cho loại xe này.'**
  String get passRenewNoneMessage;

  /// No description provided for @passMonths.
  ///
  /// In vi, this message translates to:
  /// **'{months} tháng'**
  String passMonths(int months);

  /// No description provided for @passFixedSlotTag.
  ///
  /// In vi, this message translates to:
  /// **'vị trí cố định'**
  String get passFixedSlotTag;

  /// No description provided for @regTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký vé tháng'**
  String get regTitle;

  /// No description provided for @regPickPackage.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn gói vé tháng.'**
  String get regPickPackage;

  /// No description provided for @regNeedSlot.
  ///
  /// In vi, this message translates to:
  /// **'Gói này yêu cầu chọn vị trí đỗ cố định.'**
  String get regNeedSlot;

  /// No description provided for @regEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gói vé tháng'**
  String get regEmptyTitle;

  /// No description provided for @regEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bãi xe hiện chưa mở bán gói vé tháng nào.'**
  String get regEmptyMessage;

  /// No description provided for @regPlateHelper.
  ///
  /// In vi, this message translates to:
  /// **'Nhập liền, không cần dấu gạch hoặc chấm.'**
  String get regPlateHelper;

  /// No description provided for @regFixedSlot.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí đỗ cố định'**
  String get regFixedSlot;

  /// No description provided for @regNoSlot.
  ///
  /// In vi, this message translates to:
  /// **'Tầng cư dân hiện không còn vị trí trống cho loại xe này.'**
  String get regNoSlot;

  /// No description provided for @regChoosePackage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn gói vé tháng'**
  String get regChoosePackage;

  /// No description provided for @plateSheetCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Biển số hiện tại {plate}. Yêu cầu cần quản lý bãi duyệt.'**
  String plateSheetCurrent(String plate);

  /// No description provided for @plateNew.
  ///
  /// In vi, this message translates to:
  /// **'Biển số mới'**
  String get plateNew;

  /// No description provided for @plateReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do (không bắt buộc)'**
  String get plateReason;

  /// No description provided for @plateReasonField.
  ///
  /// In vi, this message translates to:
  /// **'Lý do'**
  String get plateReasonField;

  /// No description provided for @plateSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu'**
  String get plateSend;

  /// No description provided for @plateEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa yêu cầu đổi biển số'**
  String get plateEditTitle;

  /// No description provided for @plateUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật yêu cầu'**
  String get plateUpdated;

  /// No description provided for @plateWithdrawTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rút yêu cầu?'**
  String get plateWithdrawTitle;

  /// No description provided for @plateWithdrawMessage.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đổi sang biển số {plate} sẽ bị xóa.'**
  String plateWithdrawMessage(String plate);

  /// No description provided for @plateWithdraw.
  ///
  /// In vi, this message translates to:
  /// **'Rút yêu cầu'**
  String get plateWithdraw;

  /// No description provided for @plateWithdrawn.
  ///
  /// In vi, this message translates to:
  /// **'Đã rút yêu cầu'**
  String get plateWithdrawn;

  /// No description provided for @plateEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có yêu cầu'**
  String get plateEmptyTitle;

  /// No description provided for @plateEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mở một vé tháng đang hiệu lực và chọn \"Đổi biển số\" để gửi yêu cầu.'**
  String get plateEmptyMessage;

  /// No description provided for @plateSentAt.
  ///
  /// In vi, this message translates to:
  /// **'Gửi {time}'**
  String plateSentAt(String time);

  /// No description provided for @plateReasonValue.
  ///
  /// In vi, this message translates to:
  /// **'Lý do: {reason}'**
  String plateReasonValue(String reason);

  /// No description provided for @plateRejectedValue.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối: {reason}'**
  String plateRejectedValue(String reason);

  /// No description provided for @incSuggestCollision.
  ///
  /// In vi, this message translates to:
  /// **'Va chạm, trầy xước'**
  String get incSuggestCollision;

  /// No description provided for @incSuggestFee.
  ///
  /// In vi, this message translates to:
  /// **'Sai phí gửi xe'**
  String get incSuggestFee;

  /// No description provided for @incSuggestLost.
  ///
  /// In vi, this message translates to:
  /// **'Mất đồ'**
  String get incSuggestLost;

  /// No description provided for @incSuggestNoSpace.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy chỗ đỗ'**
  String get incSuggestNoSpace;

  /// No description provided for @incPhotoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh minh chứng'**
  String get incPhotoTitle;

  /// No description provided for @incSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi báo cáo sự cố'**
  String get incSent;

  /// No description provided for @incNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo sự cố'**
  String get incNewTitle;

  /// No description provided for @incType.
  ///
  /// In vi, this message translates to:
  /// **'Loại sự cố'**
  String get incType;

  /// No description provided for @incTypeField.
  ///
  /// In vi, this message translates to:
  /// **'loại sự cố'**
  String get incTypeField;

  /// No description provided for @incDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả chi tiết'**
  String get incDescription;

  /// No description provided for @incDescriptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Thời điểm, vị trí, điều đã xảy ra'**
  String get incDescriptionHint;

  /// No description provided for @incDescriptionField.
  ///
  /// In vi, this message translates to:
  /// **'mô tả'**
  String get incDescriptionField;

  /// No description provided for @incSession.
  ///
  /// In vi, this message translates to:
  /// **'Lượt gửi xe liên quan'**
  String get incSession;

  /// No description provided for @incNoSession.
  ///
  /// In vi, this message translates to:
  /// **'Không gắn lượt gửi'**
  String get incNoSession;

  /// No description provided for @incSelectedSession.
  ///
  /// In vi, this message translates to:
  /// **'Lượt gửi đã chọn'**
  String get incSelectedSession;

  /// No description provided for @incAddPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get incAddPhoto;

  /// No description provided for @incRemovePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh'**
  String get incRemovePhoto;

  /// No description provided for @incSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi báo cáo'**
  String get incSubmit;

  /// No description provided for @incListTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố đã báo'**
  String get incListTitle;

  /// No description provided for @incReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo sự cố'**
  String get incReport;

  /// No description provided for @incEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có báo cáo'**
  String get incEmptyTitle;

  /// No description provided for @incEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Gặp vấn đề trong bãi (va chạm, sai phí, mất đồ)? Gửi báo cáo kèm ảnh để nhân viên xử lý.'**
  String get incEmptyMessage;

  /// No description provided for @incAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã nhận xử lý sự cố này'**
  String get incAssigned;

  /// No description provided for @incResolvedToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đánh dấu đã xử lý'**
  String get incResolvedToast;

  /// No description provided for @incDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết sự cố'**
  String get incDetailTitle;

  /// No description provided for @incImageFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh'**
  String get incImageFailed;

  /// No description provided for @incReporter.
  ///
  /// In vi, this message translates to:
  /// **'Người báo'**
  String get incReporter;

  /// No description provided for @incLinkedSession.
  ///
  /// In vi, this message translates to:
  /// **'Gắn lượt gửi xe'**
  String get incLinkedSession;

  /// No description provided for @incHandler.
  ///
  /// In vi, this message translates to:
  /// **'Người xử lý'**
  String get incHandler;

  /// No description provided for @incUnassigned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân công'**
  String get incUnassigned;

  /// No description provided for @incResolvedAt.
  ///
  /// In vi, this message translates to:
  /// **'Xử lý lúc'**
  String get incResolvedAt;

  /// No description provided for @incResult.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả xử lý'**
  String get incResult;

  /// No description provided for @incTake.
  ///
  /// In vi, this message translates to:
  /// **'Nhận xử lý'**
  String get incTake;

  /// No description provided for @incTakeOver.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển cho tôi xử lý'**
  String get incTakeOver;

  /// No description provided for @incMarkResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã xử lý'**
  String get incMarkResolved;

  /// No description provided for @incNotes.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú xử lý'**
  String get incNotes;

  /// No description provided for @incNotesHint.
  ///
  /// In vi, this message translates to:
  /// **'Đã kiểm tra camera, đã liên hệ khách...'**
  String get incNotesHint;

  /// No description provided for @incNotesField.
  ///
  /// In vi, this message translates to:
  /// **'ghi chú xử lý'**
  String get incNotesField;

  /// No description provided for @incConfirmResolved.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đã xử lý'**
  String get incConfirmResolved;

  /// No description provided for @incReporterValue.
  ///
  /// In vi, this message translates to:
  /// **'Người báo: {name}'**
  String incReporterValue(String name);

  /// No description provided for @incHandlerValue.
  ///
  /// In vi, this message translates to:
  /// **'Xử lý: {name}'**
  String incHandlerValue(String name);

  /// No description provided for @accTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get accTitle;

  /// No description provided for @accBioReasonEnable.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để bật khóa ứng dụng bằng sinh trắc học'**
  String get accBioReasonEnable;

  /// No description provided for @accBioEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật mở khóa bằng sinh trắc học'**
  String get accBioEnabled;

  /// No description provided for @accBioFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác thực được nên chưa bật tính năng'**
  String get accBioFailed;

  /// No description provided for @accLogoutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất?'**
  String get accLogoutTitle;

  /// No description provided for @accLogoutMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ cần đăng nhập lại để sử dụng ứng dụng.'**
  String get accLogoutMessage;

  /// No description provided for @accProfileSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ và bảo mật'**
  String get accProfileSecurity;

  /// No description provided for @accEditProfile.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin cá nhân'**
  String get accEditProfile;

  /// No description provided for @accChangePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get accChangePassword;

  /// No description provided for @accBioTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa bằng sinh trắc học'**
  String get accBioTitle;

  /// No description provided for @accBioOn.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu vân tay hoặc Face ID mỗi khi mở ứng dụng'**
  String get accBioOn;

  /// No description provided for @accBioUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chưa hỗ trợ hoặc chưa đăng ký vân tay / khuôn mặt'**
  String get accBioUnavailable;

  /// No description provided for @accAppearance.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get accAppearance;

  /// No description provided for @accThemeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo máy'**
  String get accThemeSystem;

  /// No description provided for @accThemeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get accThemeLight;

  /// No description provided for @accThemeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get accThemeDark;

  /// No description provided for @accLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get accLanguage;

  /// No description provided for @accAvailability.
  ///
  /// In vi, this message translates to:
  /// **'Chỗ trống theo tầng'**
  String get accAvailability;

  /// No description provided for @profileUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật thông tin'**
  String get profileUpdated;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get profileTitle;

  /// No description provided for @profileEmailHelper.
  ///
  /// In vi, this message translates to:
  /// **'Email dùng để đăng nhập và nhận mã OTP.'**
  String get profileEmailHelper;

  /// No description provided for @profileSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get profileSave;

  /// No description provided for @pwdChanged.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi mật khẩu'**
  String get pwdChanged;

  /// No description provided for @pwdTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get pwdTitle;

  /// No description provided for @pwdNote.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới áp dụng cho lần đăng nhập tiếp theo trên mọi thiết bị.'**
  String get pwdNote;

  /// No description provided for @pwdSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get pwdSubmit;

  /// No description provided for @gateEntry.
  ///
  /// In vi, this message translates to:
  /// **'Cổng vào'**
  String get gateEntry;

  /// No description provided for @gateExit.
  ///
  /// In vi, this message translates to:
  /// **'Cổng ra'**
  String get gateExit;

  /// No description provided for @gateReload.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại danh sách cổng'**
  String get gateReload;

  /// No description provided for @gateNoneEntry.
  ///
  /// In vi, this message translates to:
  /// **'Bãi chưa cấu hình cổng vào.'**
  String get gateNoneEntry;

  /// No description provided for @gateNoneExit.
  ///
  /// In vi, this message translates to:
  /// **'Bãi chưa cấu hình cổng ra.'**
  String get gateNoneExit;

  /// No description provided for @gatePick.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cổng'**
  String get gatePick;

  /// No description provided for @ciPlatePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh biển số'**
  String get ciPlatePhoto;

  /// No description provided for @ciRecognizedPct.
  ///
  /// In vi, this message translates to:
  /// **'Nhận diện {pct}%. Kiểm tra lại trước khi xác nhận.'**
  String ciRecognizedPct(String pct);

  /// No description provided for @ciRecognized.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận diện. Kiểm tra lại trước khi xác nhận.'**
  String get ciRecognized;

  /// No description provided for @ciNotRecognized.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận diện được biển số. Vui lòng nhập tay.'**
  String get ciNotRecognized;

  /// No description provided for @ciQrPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mã QR đặt chỗ'**
  String get ciQrPhoto;

  /// No description provided for @ciNotBookingQr.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR này không phải mã đặt chỗ.'**
  String get ciNotBookingQr;

  /// No description provided for @ciPickGate.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn cổng vào.'**
  String get ciPickGate;

  /// No description provided for @ciPickType.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn loại xe.'**
  String get ciPickType;

  /// No description provided for @ciSuccess.
  ///
  /// In vi, this message translates to:
  /// **'{type}: check-in thành công'**
  String ciSuccess(String type);

  /// No description provided for @ciTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xe vào bãi'**
  String get ciTitle;

  /// No description provided for @ciScanPlate.
  ///
  /// In vi, this message translates to:
  /// **'Chụp và nhận diện biển số'**
  String get ciScanPlate;

  /// No description provided for @ciBookingCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã đặt chỗ'**
  String get ciBookingCode;

  /// No description provided for @ciBookingHint.
  ///
  /// In vi, this message translates to:
  /// **'Quét QR trên ứng dụng của khách'**
  String get ciBookingHint;

  /// No description provided for @ciBookingField.
  ///
  /// In vi, this message translates to:
  /// **'mã đặt chỗ'**
  String get ciBookingField;

  /// No description provided for @ciScanQr.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get ciScanQr;

  /// No description provided for @ciBookingWindow.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ check-in trong khoảng 30 phút trước hoặc sau giờ hẹn.'**
  String get ciBookingWindow;

  /// No description provided for @ciResidentNote.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống tự kiểm tra vé tháng còn hiệu lực theo biển số.'**
  String get ciResidentNote;

  /// No description provided for @ciSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận cho xe vào'**
  String get ciSubmit;

  /// No description provided for @ciGuideToSlot.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn xe tới ô {slot}'**
  String ciGuideToSlot(String slot);

  /// No description provided for @ciEntered.
  ///
  /// In vi, this message translates to:
  /// **'Xe đã vào bãi'**
  String get ciEntered;

  /// No description provided for @ciEnteredAt.
  ///
  /// In vi, this message translates to:
  /// **'{type}, vào lúc {time}'**
  String ciEnteredAt(String type, String time);

  /// No description provided for @ciTicketNote.
  ///
  /// In vi, this message translates to:
  /// **'Khách chụp lại mã này để dùng khi ra bãi'**
  String get ciTicketNote;

  /// No description provided for @ciNext.
  ///
  /// In vi, this message translates to:
  /// **'Lượt xe tiếp theo'**
  String get ciNext;

  /// No description provided for @coTicketPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mã QR vé gửi xe'**
  String get coTicketPhoto;

  /// No description provided for @coNotActiveQr.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không thuộc lượt gửi xe nào đang hoạt động.'**
  String get coNotActiveQr;

  /// No description provided for @coPickGate.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn cổng ra.'**
  String get coPickGate;

  /// No description provided for @coScanFirst.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng quét mã QR vé của khách.'**
  String get coScanFirst;

  /// No description provided for @coPayOSReceived.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận thanh toán PayOS'**
  String get coPayOSReceived;

  /// No description provided for @coPaymentCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán đã bị hủy'**
  String get coPaymentCancelled;

  /// No description provided for @coCancelTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy yêu cầu ra bãi?'**
  String get coCancelTitle;

  /// No description provided for @coCancelMessage.
  ///
  /// In vi, this message translates to:
  /// **'Lượt gửi xe sẽ trở lại trạng thái đang gửi.'**
  String get coCancelMessage;

  /// No description provided for @coCancelAction.
  ///
  /// In vi, this message translates to:
  /// **'Hủy yêu cầu'**
  String get coCancelAction;

  /// No description provided for @coCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy yêu cầu ra bãi'**
  String get coCancelled;

  /// No description provided for @coTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xe ra bãi'**
  String get coTitle;

  /// No description provided for @coByTicket.
  ///
  /// In vi, this message translates to:
  /// **'Quét vé QR'**
  String get coByTicket;

  /// No description provided for @coByPlate.
  ///
  /// In vi, this message translates to:
  /// **'Theo biển số'**
  String get coByPlate;

  /// No description provided for @coScanPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Chụp mã QR trên vé của khách'**
  String get coScanPrompt;

  /// No description provided for @coRescan.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để quét lại'**
  String get coRescan;

  /// No description provided for @coAutoFind.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống tự tìm lượt gửi xe'**
  String get coAutoFind;

  /// No description provided for @coMethod.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức thu phí'**
  String get coMethod;

  /// No description provided for @coPassFree.
  ///
  /// In vi, this message translates to:
  /// **'Xe có vé tháng hợp lệ được miễn phí tự động.'**
  String get coPassFree;

  /// No description provided for @coSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Tính phí và cho xe ra'**
  String get coSubmit;

  /// No description provided for @coFailedNote.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán đã bị hủy. Lượt gửi xe vẫn đang hoạt động.'**
  String get coFailedNote;

  /// No description provided for @coDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất, cho xe ra bãi.'**
  String get coDone;

  /// No description provided for @coToCollect.
  ///
  /// In vi, this message translates to:
  /// **'Cần thu'**
  String get coToCollect;

  /// No description provided for @coNoFee.
  ///
  /// In vi, this message translates to:
  /// **'Không phát sinh phí (đã bao gồm trong vé tháng).'**
  String get coNoFee;

  /// No description provided for @coScanToPay.
  ///
  /// In vi, this message translates to:
  /// **'Khách quét mã để thanh toán {amount}'**
  String coScanToPay(String amount);

  /// No description provided for @coWaitingPayOS.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ PayOS xác nhận'**
  String get coWaitingPayOS;

  /// No description provided for @coCashCollected.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu {amount} tiền mặt'**
  String coCashCollected(String amount);

  /// No description provided for @coCancelExit.
  ///
  /// In vi, this message translates to:
  /// **'Hủy yêu cầu ra bãi'**
  String get coCancelExit;

  /// No description provided for @coNext.
  ///
  /// In vi, this message translates to:
  /// **'Xe tiếp theo'**
  String get coNext;

  /// No description provided for @ssTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phiên gửi xe'**
  String get ssTitle;

  /// No description provided for @ssSearch.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo biển số'**
  String get ssSearch;

  /// No description provided for @ssActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi'**
  String get ssActive;

  /// No description provided for @ssNoMatchTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy biển số'**
  String get ssNoMatchTitle;

  /// No description provided for @ssEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có phiên nào'**
  String get ssEmptyTitle;

  /// No description provided for @ssNoMatchMessage.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại biển số hoặc chọn \"Tất cả\".'**
  String get ssNoMatchMessage;

  /// No description provided for @ssEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Các xe đang gửi trong bãi sẽ hiện ở đây.'**
  String get ssEmptyMessage;

  /// No description provided for @ssCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} phiên'**
  String ssCount(int count);

  /// No description provided for @ssDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết phiên'**
  String get ssDetailTitle;

  /// No description provided for @ssDriver.
  ///
  /// In vi, this message translates to:
  /// **'Tài xế'**
  String get ssDriver;

  /// No description provided for @ssPlateOut.
  ///
  /// In vi, this message translates to:
  /// **'Biển số lúc ra'**
  String get ssPlateOut;

  /// No description provided for @ssPayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get ssPayment;

  /// No description provided for @ssImageFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh cổng'**
  String get ssImageFailed;

  /// No description provided for @siTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố'**
  String get siTitle;

  /// No description provided for @siOpen.
  ///
  /// In vi, this message translates to:
  /// **'Cần xử lý'**
  String get siOpen;

  /// No description provided for @siMine.
  ///
  /// In vi, this message translates to:
  /// **'Của tôi'**
  String get siMine;

  /// No description provided for @siEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có sự cố'**
  String get siEmptyTitle;

  /// No description provided for @siEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Không có báo cáo nào trong mục này.'**
  String get siEmptyMessage;

  /// No description provided for @walletTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ví PBMS'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư khả dụng'**
  String get walletBalance;

  /// No description provided for @walletTopUp.
  ///
  /// In vi, this message translates to:
  /// **'Nạp tiền'**
  String get walletTopUp;

  /// No description provided for @walletTopUpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nạp tiền vào ví'**
  String get walletTopUpTitle;

  /// No description provided for @walletTopUpDesc.
  ///
  /// In vi, this message translates to:
  /// **'Số dư được cộng ngay khi PayOS xác nhận thanh toán.'**
  String get walletTopUpDesc;

  /// No description provided for @walletAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền nạp'**
  String get walletAmount;

  /// No description provided for @walletAmountHint.
  ///
  /// In vi, this message translates to:
  /// **'Từ {min} đến {max}'**
  String walletAmountHint(String min, String max);

  /// No description provided for @vAmountRange.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền phải là số nguyên từ {min} đến {max}'**
  String vAmountRange(String min, String max);

  /// No description provided for @walletTopUpSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Nạp {amount}'**
  String walletTopUpSubmit(String amount);

  /// No description provided for @walletHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử giao dịch'**
  String get walletHistory;

  /// No description provided for @walletFilterTopUps.
  ///
  /// In vi, this message translates to:
  /// **'Nạp'**
  String get walletFilterTopUps;

  /// No description provided for @walletFilterSpends.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get walletFilterSpends;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nạp tiền để thanh toán vé tháng ngay, không cần chuyển khoản mỗi lần.'**
  String get walletEmptyMessage;

  /// No description provided for @walletPendingNote.
  ///
  /// In vi, this message translates to:
  /// **'Lượt nạp chỉ hiện trong lịch sử sau khi PayOS xác nhận.'**
  String get walletPendingNote;

  /// No description provided for @walletTxTopUp.
  ///
  /// In vi, this message translates to:
  /// **'Nạp ví qua PayOS'**
  String get walletTxTopUp;

  /// No description provided for @walletTxSpend.
  ///
  /// In vi, this message translates to:
  /// **'Mua {package}'**
  String walletTxSpend(String package);

  /// No description provided for @walletTxSpendGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán vé tháng bằng ví'**
  String get walletTxSpendGeneric;

  /// No description provided for @walletBalanceAfter.
  ///
  /// In vi, this message translates to:
  /// **'Số dư sau: {amount}'**
  String walletBalanceAfter(String amount);

  /// No description provided for @walletToppedUp.
  ///
  /// In vi, this message translates to:
  /// **'Đã nạp tiền vào ví'**
  String get walletToppedUp;

  /// No description provided for @payMethodTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức thanh toán'**
  String get payMethodTitle;

  /// No description provided for @payMethodWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví PBMS'**
  String get payMethodWallet;

  /// No description provided for @payMethodWalletBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư {amount}'**
  String payMethodWalletBalance(String amount);

  /// No description provided for @payMethodWalletShort.
  ///
  /// In vi, this message translates to:
  /// **'Số dư không đủ, thiếu {amount}'**
  String payMethodWalletShort(String amount);

  /// No description provided for @payMethodPayOSHint.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản qua VietQR'**
  String get payMethodPayOSHint;

  /// No description provided for @passPaidByWallet.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán bằng ví. Vé tháng đã được kích hoạt.'**
  String get passPaidByWallet;

  /// No description provided for @passPayChoose.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cách thanh toán'**
  String get passPayChoose;

  /// No description provided for @passPayConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán {amount}'**
  String passPayConfirm(String amount);

  /// No description provided for @accAvatarChange.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get accAvatarChange;

  /// No description provided for @accAvatarUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ảnh đại diện'**
  String get accAvatarUpdated;

  /// No description provided for @accAvatarTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn.'**
  String get accAvatarTooLarge;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
