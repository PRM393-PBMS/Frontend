// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PBMS Parking';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonAll => 'All';

  @override
  String get commonDone => 'Done';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonNone => 'Not set';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonLogout => 'Sign out';

  @override
  String get loadFailedTitle => 'Couldn\'t load data';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get imagePickTitle => 'Choose a photo';

  @override
  String get imageTakePhoto => 'Take a photo';

  @override
  String get imageFromLibrary => 'Choose from library';

  @override
  String get ticketQrSemantics => 'Parking ticket QR code';

  @override
  String get ticketCopied => 'Ticket code copied';

  @override
  String ticketCode(String code) {
    return 'Ticket $code';
  }

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String errorStatus(String code) {
    return 'Request failed ($code).';
  }

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String timeToday(String time) {
    return 'Today $time';
  }

  @override
  String timeTomorrow(String time) {
    return 'Tomorrow $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String timeOnDate(String time, String date) {
    return '$time, $date';
  }

  @override
  String durationDaysHours(String days, String hours) {
    return '${days}d ${hours}h';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get agoJustNow => 'Just now';

  @override
  String agoMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String agoHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String dateRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String vRequired(String field) {
    return 'Please enter $field';
  }

  @override
  String get vEmailRequired => 'Please enter your email';

  @override
  String get vEmailInvalid => 'That email address doesn\'t look right';

  @override
  String vMaxLength(String field, String max) {
    return '$field must be at most $max characters';
  }

  @override
  String get vPhoneRequired => 'Please enter your phone number';

  @override
  String get vPhoneInvalid => 'Enter a valid Vietnamese mobile number';

  @override
  String get vUserNameRequired => 'Please enter a username';

  @override
  String get vFullNameRequired => 'Please enter your full name';

  @override
  String get vPasswordRequired => 'Please enter a password';

  @override
  String get vConfirmRequired => 'Please re-enter the password';

  @override
  String get vConfirmMismatch => 'Passwords don\'t match';

  @override
  String get vOtpInvalid => 'The code has 6 digits';

  @override
  String get vPlateRequired => 'Please enter the license plate';

  @override
  String get vPlateInvalid => 'Plates have 4-15 letters and digits';

  @override
  String get vPlateSame => 'The new plate must differ from the current one';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldUserName => 'Username';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldPhone => 'Phone number';

  @override
  String get fieldEmailLabel => 'email';

  @override
  String get fieldFullNameLabel => 'Full name';

  @override
  String get fieldUserNameLabel => 'Username';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordConfirm => 'Confirm password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldNewPasswordConfirm => 'Confirm new password';

  @override
  String get fieldOtp => 'Verification code';

  @override
  String get fieldPlate => 'License plate';

  @override
  String get fieldVehicleType => 'Vehicle type';

  @override
  String get stReservationPending => 'Awaiting deposit';

  @override
  String get stReservationConfirmed => 'Confirmed';

  @override
  String get stReservationModified => 'Rescheduled';

  @override
  String get stReservationCheckedIn => 'Checked in';

  @override
  String get stReservationCompleted => 'Completed';

  @override
  String get stCancelled => 'Cancelled';

  @override
  String get stReservationNoShow => 'No-show';

  @override
  String get stSessionActive => 'Parked';

  @override
  String get stSessionCompleted => 'Picked up';

  @override
  String get stSessionException => 'Exception';

  @override
  String get stPassActive => 'Active';

  @override
  String get stPendingPayment => 'Awaiting payment';

  @override
  String get stPassExpired => 'Expired';

  @override
  String get stPaid => 'Paid';

  @override
  String get stIncidentOpen => 'New';

  @override
  String get stIncidentInProgress => 'In progress';

  @override
  String get stIncidentResolved => 'Resolved';

  @override
  String get stChangePending => 'Pending review';

  @override
  String get stChangeApproved => 'Approved';

  @override
  String get stChangeRejected => 'Rejected';

  @override
  String get stNoPass => 'No monthly pass';

  @override
  String get payMethodPayOS => 'PayOS bank transfer';

  @override
  String get payMethodCash => 'Cash';

  @override
  String get payTypeDeposit => 'Booking deposit';

  @override
  String get payTypeCheckout => 'Parking fee';

  @override
  String get payTypeSubscription => 'Monthly pass fee';

  @override
  String get payTypeRenewal => 'Pass renewal';

  @override
  String get roleStaff => 'Gate operator';

  @override
  String get roleManager => 'Parking manager';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get customerGuest => 'Walk-in';

  @override
  String get customerResident => 'Monthly';

  @override
  String get customerReservation => 'Booked';

  @override
  String get customerGuestFull => 'Walk-in customer';

  @override
  String get customerResidentFull => 'Monthly pass holder';

  @override
  String get customerReservationFull => 'Booked customer';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navPasses => 'Passes';

  @override
  String get navAccount => 'Account';

  @override
  String get navCheckIn => 'Entry';

  @override
  String get navCheckOut => 'Exit';

  @override
  String get navSessions => 'Sessions';

  @override
  String get navIncidents => 'Incidents';

  @override
  String get unsupportedTitle => 'Role not supported';

  @override
  String unsupportedMessage(String email, String role) {
    return 'The account $email has the \"$role\" role. This app is for customers and gate operators. Please use the admin portal.';
  }

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'This link doesn\'t exist or has changed.';

  @override
  String get notFoundAction => 'Go to home';

  @override
  String get lockReason => 'Authenticate to unlock PBMS Parking';

  @override
  String get lockFailed =>
      'Couldn\'t verify you. Try again, or sign out and use your password.';

  @override
  String get lockTitle => 'App locked';

  @override
  String lockMessage(String name) {
    return 'Hi $name. Use the fingerprint or face registered on this device to continue.';
  }

  @override
  String get lockSemantics => 'Unlock with biometrics';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get splashTagline =>
      'Parking, bookings and monthly passes in one place.';

  @override
  String get splashChecking => 'Checking your session';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle =>
      'Use your registered email to manage parking, bookings and monthly passes.';

  @override
  String get loginForgot => 'Forgot password?';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginRegister => 'Sign up';

  @override
  String get loginFailed => 'Sign-in failed. Please check your details.';

  @override
  String get loginRegistered => 'Account created. Please sign in.';

  @override
  String get loginPasswordReset =>
      'Password reset. Sign in with your new password.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle =>
      'We\'ll email you a 6-digit verification code.';

  @override
  String get registerSubmit => 'Send verification code';

  @override
  String get otpSendFailed =>
      'Couldn\'t send the code. Please try again later.';

  @override
  String get otpVerifyFailed => 'Verification failed. Please try again.';

  @override
  String get otpTitleRegister => 'Verify your email';

  @override
  String get otpTitleReset => 'Reset password';

  @override
  String otpSubtitle(String email) {
    return 'Enter the 6-digit code sent to $email. It expires in 10 minutes.';
  }

  @override
  String get otpSubmitRegister => 'Finish sign-up';

  @override
  String get otpSubmitReset => 'Reset password';

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpEditAndResend => 'Edit details and resend';

  @override
  String get otpResent =>
      'If the email is registered, we\'ve sent a reset code.';

  @override
  String get resetRequestFailed => 'Couldn\'t request a password reset.';

  @override
  String get resetFailed => 'Password reset failed. Check the code.';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotSubtitle =>
      'Enter your registered email and we\'ll send a code to set a new password.';

  @override
  String get forgotSubmit => 'Send code';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onb1Title => 'See free spaces before you arrive';

  @override
  String get onb1Body =>
      'Free spaces by floor and vehicle type, straight from the parking system.';

  @override
  String get onb2Title => 'Book a car space, enter with a QR code';

  @override
  String get onb2Body =>
      'Book up to 5 hours ahead, pay the deposit with PayOS and show your ticket at the gate.';

  @override
  String get onb3Title => 'Clear monthly passes and fees';

  @override
  String get onb3Body =>
      'Register or renew monthly passes and check the running fee of your stay on your phone.';

  @override
  String get notifTooltip => 'Notifications';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifMarkAll => 'Mark all read';

  @override
  String get notifEmptyTitle => 'No notifications yet';

  @override
  String get notifEmptyMessage =>
      'Updates about bookings, passes and incidents will show up here.';

  @override
  String get homeMorning => 'Good morning';

  @override
  String get homeAfternoon => 'Good afternoon';

  @override
  String get homeEvening => 'Good evening';

  @override
  String get homeServices => 'Services';

  @override
  String get homeBookCar => 'Book a car space';

  @override
  String get homeBookCarSub =>
      'Hold a space up to 5 hours ahead, deposit via PayOS';

  @override
  String get homeMyBookings => 'My bookings';

  @override
  String get homeMyBookingsSub => 'View tickets, reschedule or cancel';

  @override
  String get homeAvailability => 'Free spaces by floor';

  @override
  String get homeAvailabilitySub => 'Occupancy and current prices';

  @override
  String get homeReport => 'Report an incident';

  @override
  String get homeReportSub => 'Send a report with photos and track it';

  @override
  String homeParkedFor(String duration) {
    return 'Parked for $duration';
  }

  @override
  String homeEnteredAt(String time, String gate) {
    return 'Entered $time via $gate';
  }

  @override
  String homeEnteredSlot(String slot) {
    return ', space $slot';
  }

  @override
  String get homePayToExit => 'Pay the fee to exit';

  @override
  String get homeViewTicket => 'View ticket and running fee';

  @override
  String get homeFreeNow => 'Free right now';

  @override
  String get homeNoAvailability => 'No availability data yet';

  @override
  String get homeNoSlots => 'No parking spaces are configured yet.';

  @override
  String homeOfSpaces(String total) {
    return '/ $total spaces';
  }

  @override
  String homeTypeFree(String type, String count) {
    return '$type: $count free';
  }

  @override
  String get homeByFloor => 'View by floor';

  @override
  String homeBookingAt(String time) {
    return 'Booking $time';
  }

  @override
  String get homeFinishDeposit => 'Pay the deposit to hold your space';

  @override
  String get homeArriveWindow => 'Arrive within 30 minutes of your booked time';

  @override
  String get availTitle => 'Free spaces';

  @override
  String get availEmptyTitle => 'No parking spaces yet';

  @override
  String get availEmptyMessage =>
      'Floors and spaces haven\'t been set up yet. Please check back later.';

  @override
  String get availResidentFloor => 'Residents / monthly pass floor';

  @override
  String availOfFree(String total) {
    return ' / $total free';
  }

  @override
  String get availPricing => 'Parking prices';

  @override
  String priceFirstHours(String hours) {
    return 'First $hours h';
  }

  @override
  String get priceExtraHour => 'Each additional hour';

  @override
  String get priceNight => 'Overnight surcharge (22:00-06:00)';

  @override
  String get resNewTitle => 'Book a car space';

  @override
  String get resNewIntro =>
      'Bookings are for cars, up to 5 hours ahead. You can enter within 30 minutes of your booked time.';

  @override
  String get resCarFree => 'Free walk-in car spaces';

  @override
  String resSpaces(String count) {
    return '$count spaces';
  }

  @override
  String get resDepositEstimate => 'Estimated deposit';

  @override
  String get resPerPricing => 'Per price list';

  @override
  String get resPrice => 'Rate';

  @override
  String resPriceValue(String base, String hours, String extra) {
    return '$base for the first $hours h, then $extra/h';
  }

  @override
  String get resEntryTime => 'Arrival time';

  @override
  String get resRefreshSlots => 'Refresh time slots';

  @override
  String get resPickTime => 'Please choose an arrival time.';

  @override
  String get resSlotPassed => 'That time has passed. Please choose again.';

  @override
  String get resChooseTime => 'Choose arrival time';

  @override
  String resBookAt(String time) {
    return 'Book for $time';
  }

  @override
  String get resNoSlots => 'No valid time slots left.';

  @override
  String get resDepositTitle => 'Booking deposit';

  @override
  String resDepositDesc(String time) {
    return 'Car space held for $time. The deposit is deducted from your parking fee at exit.';
  }

  @override
  String resDepositDescShort(String time) {
    return 'Car space held for $time.';
  }

  @override
  String get resListTitle => 'My bookings';

  @override
  String get resNew => 'New booking';

  @override
  String get resEmptyTitle => 'No bookings yet';

  @override
  String get resEmptyMessage =>
      'Book a car space up to 5 hours ahead and enter with a QR code.';

  @override
  String get resUpcoming => 'Upcoming';

  @override
  String get resPast => 'Past';

  @override
  String resTileMeta(String type, String ago) {
    return '$type, booked $ago';
  }

  @override
  String get resDetailTitle => 'Booking details';

  @override
  String get resConfirmed => 'Booking confirmed';

  @override
  String get resCancelTitle => 'Cancel booking?';

  @override
  String get resCancelPending => 'This unpaid booking will be cancelled.';

  @override
  String get resCancelPaid =>
      'This paid booking will be cancelled and can\'t be restored.';

  @override
  String get resCancelAction => 'Cancel booking';

  @override
  String get resCancelled => 'Booking cancelled';

  @override
  String resRescheduled(String time) {
    return 'Rescheduled to $time';
  }

  @override
  String resEntryWindow(String from, String to) {
    return 'Enter between $from and $to';
  }

  @override
  String get resShowAtEntry => 'Show this code to staff at the entry gate';

  @override
  String get resBookedAt => 'Booked on';

  @override
  String get resReschedule => 'Reschedule';

  @override
  String get resRescheduleUsed => 'Already used';

  @override
  String get resRescheduleLeft => '1 change left';

  @override
  String get resPendingNote =>
      'Your space is held only after the deposit is paid. Bookings expire 30 minutes after the booked time.';

  @override
  String get resPayDeposit => 'Pay deposit';

  @override
  String get resChangeTime => 'Change arrival time';

  @override
  String get resChangeRule =>
      'You can reschedule up to 15 minutes before the booked time.';

  @override
  String get resNewTime => 'Choose a new arrival time';

  @override
  String get resOneChange => 'Each booking can be rescheduled once.';

  @override
  String get resConfirmChange => 'Confirm new time';

  @override
  String get payInvalidLink => 'The payment link is invalid.';

  @override
  String get payCantOpen => 'Couldn\'t open the payment page on this device.';

  @override
  String get payNotYet =>
      'Payment not received yet. Finish on the PayOS page, then check again.';

  @override
  String get paySuccessTitle => 'Payment successful';

  @override
  String get paySuccessMessage => 'We\'ve recorded your payment.';

  @override
  String get payFailedTitle => 'Payment unsuccessful';

  @override
  String get payFailedMessage =>
      'The transaction was cancelled or failed. You can create a new payment link.';

  @override
  String get payAmount => 'Amount';

  @override
  String get payOrderCode => 'Order code';

  @override
  String get payWaiting =>
      'Waiting for PayOS to confirm. This screen updates automatically.';

  @override
  String get payHint =>
      'Pay with your banking app using VietQR on the PayOS page.';

  @override
  String get payReopen => 'Reopen payment page';

  @override
  String get payWithPayOS => 'Pay with PayOS';

  @override
  String get payCheckStatus => 'Check status';

  @override
  String get payLater => 'Pay later';

  @override
  String get paySuccessShort => 'Payment successful';

  @override
  String get histTitle => 'Parking history';

  @override
  String get histEmptyTitle => 'No parking sessions yet';

  @override
  String get histEmptyMessage =>
      'Sessions linked to your account (monthly pass or booking) appear here after you enter.';

  @override
  String get histActive => 'Parked now';

  @override
  String get histDone => 'Completed';

  @override
  String sessTileActive(String time, String duration) {
    return 'Entered $time, parked $duration';
  }

  @override
  String sessSlot(String slot) {
    return 'Space $slot';
  }

  @override
  String get feeRunning => 'Running fee';

  @override
  String get feeFree => 'Free';

  @override
  String get feeCovered => 'Included in this plate\'s monthly pass.';

  @override
  String get feeDuration => 'Time parked';

  @override
  String feeHoursValue(String hours) {
    return '$hours h';
  }

  @override
  String get feeBilledHours => 'Billed hours';

  @override
  String feeExtraHours(String hours) {
    return '$hours extra h';
  }

  @override
  String feeNight(String count) {
    return 'Overnight surcharge x$count';
  }

  @override
  String get feeDeposit => 'Deposit deducted';

  @override
  String get sessNotFound => 'This session wasn\'t found in your account.';

  @override
  String get sessPayTitle => 'Pay parking fee';

  @override
  String get sessPayDesc =>
      'Your session is closed as soon as PayOS confirms the payment.';

  @override
  String get sessPaid => 'Parking fee paid';

  @override
  String get sessTitle => 'Parking session';

  @override
  String sessTotal(String duration) {
    return 'Total $duration';
  }

  @override
  String get sessShowAtExit => 'Show this code to staff at the exit gate';

  @override
  String get sessNeedPay => 'Payment needed to exit';

  @override
  String sessNeedPayDetail(String amount, String method) {
    return '$amount by $method.';
  }

  @override
  String get sessPayCash => 'Please pay cash to the staff at the gate.';

  @override
  String get sessEntry => 'Entry time';

  @override
  String get sessEntryGate => 'Entry gate';

  @override
  String get sessSpot => 'Space';

  @override
  String get sessExit => 'Exit time';

  @override
  String get sessExitGate => 'Exit gate';

  @override
  String get sessMode => 'Type';

  @override
  String get sessModeBooked => 'Booked';

  @override
  String get sessModeDirect => 'Walk-in';

  @override
  String get sessPaidAmount => 'Paid';

  @override
  String get sessMethod => 'Method';

  @override
  String get sessReport => 'Report an issue with this session';

  @override
  String get passesTitle => 'Vehicles & passes';

  @override
  String get passesRegister => 'New pass';

  @override
  String get passesEmptyTitle => 'No vehicles yet';

  @override
  String get passesEmptyMessage =>
      'Register a monthly pass for your plate to park without per-visit fees.';

  @override
  String get passesRegisterPass => 'Register a monthly pass';

  @override
  String get passesPlateRequests => 'Plate change requests';

  @override
  String passesPendingRequests(String count) {
    return '$count pending';
  }

  @override
  String get passesTrackRequests => 'Track vehicle changes for your passes';

  @override
  String get passesAll => 'All passes';

  @override
  String passDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String passExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String passFixedSlot(String slot) {
    return 'Reserved space $slot';
  }

  @override
  String get passPayToActivate => 'Pay to activate';

  @override
  String passLastParked(String time) {
    return 'Last parked $time. Get a monthly pass';
  }

  @override
  String get passRenewOrRegister => 'Renew or register again';

  @override
  String get passTitle => 'Monthly pass';

  @override
  String passDaysLeftUntil(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0, expires $date';
  }

  @override
  String get passStart => 'Starts';

  @override
  String get passEnd => 'Ends';

  @override
  String get passFixedSlotLabel => 'Reserved space';

  @override
  String get passPrice => 'Package price';

  @override
  String passPay(String amount) {
    return 'Pay $amount';
  }

  @override
  String get passRenew => 'Renew';

  @override
  String get passChangePlate => 'Change plate';

  @override
  String get passCancel => 'Cancel pass';

  @override
  String get passRenewals => 'Renewal history';

  @override
  String get passPayTitle => 'Pay for monthly pass';

  @override
  String passPayDesc(String package, String plate) {
    return '$package for plate $plate.';
  }

  @override
  String passRegisterPayDesc(String package, String plate) {
    return '$package for plate $plate. The pass activates as soon as payment succeeds.';
  }

  @override
  String get passRenewTitle => 'Renew monthly pass';

  @override
  String passRenewDesc(String package, String plate) {
    return '$package for plate $plate. Time is added from the current expiry date (or from today if already expired).';
  }

  @override
  String get passCancelTitle => 'Cancel monthly pass?';

  @override
  String passCancelMessage(String plate) {
    return 'The pass for plate $plate will stop being valid.';
  }

  @override
  String passCancelMessageSlot(String plate, String slot) {
    return 'The pass for plate $plate will stop being valid and space $slot will be released.';
  }

  @override
  String get passCancelAction => 'Cancel pass';

  @override
  String get passCancelled => 'Pass cancelled';

  @override
  String get passPlateRequested => 'Plate change requested';

  @override
  String get passRenewPick => 'Choose a renewal package';

  @override
  String get passRenewNoneTitle => 'No matching packages';

  @override
  String get passRenewNoneMessage =>
      'No packages are on sale for this vehicle type right now.';

  @override
  String passMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get passFixedSlotTag => 'reserved space';

  @override
  String get regTitle => 'Register monthly pass';

  @override
  String get regPickPackage => 'Please choose a package.';

  @override
  String get regNeedSlot => 'This package requires a reserved space.';

  @override
  String get regEmptyTitle => 'No monthly packages';

  @override
  String get regEmptyMessage => 'No monthly packages are on sale right now.';

  @override
  String get regPlateHelper => 'Type it without dashes or dots.';

  @override
  String get regFixedSlot => 'Reserved space';

  @override
  String get regNoSlot =>
      'No free reserved spaces for this vehicle type right now.';

  @override
  String get regChoosePackage => 'Choose a package';

  @override
  String plateSheetCurrent(String plate) {
    return 'Current plate $plate. Requests need manager approval.';
  }

  @override
  String get plateNew => 'New plate';

  @override
  String get plateReason => 'Reason (optional)';

  @override
  String get plateReasonField => 'Reason';

  @override
  String get plateSend => 'Send request';

  @override
  String get plateEditTitle => 'Edit plate change request';

  @override
  String get plateUpdated => 'Request updated';

  @override
  String get plateWithdrawTitle => 'Withdraw request?';

  @override
  String plateWithdrawMessage(String plate) {
    return 'The request to change to plate $plate will be deleted.';
  }

  @override
  String get plateWithdraw => 'Withdraw';

  @override
  String get plateWithdrawn => 'Request withdrawn';

  @override
  String get plateEmptyTitle => 'No requests';

  @override
  String get plateEmptyMessage =>
      'Open an active pass and choose \"Change plate\" to send a request.';

  @override
  String plateSentAt(String time) {
    return 'Sent $time';
  }

  @override
  String plateReasonValue(String reason) {
    return 'Reason: $reason';
  }

  @override
  String plateRejectedValue(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get incSuggestCollision => 'Collision or scratch';

  @override
  String get incSuggestFee => 'Wrong parking fee';

  @override
  String get incSuggestLost => 'Lost item';

  @override
  String get incSuggestNoSpace => 'Can\'t find a space';

  @override
  String get incPhotoTitle => 'Photo evidence';

  @override
  String get incSent => 'Incident report sent';

  @override
  String get incNewTitle => 'Report incident';

  @override
  String get incType => 'Issue type';

  @override
  String get incTypeField => 'the issue type';

  @override
  String get incDescription => 'Details';

  @override
  String get incDescriptionHint => 'When, where and what happened';

  @override
  String get incDescriptionField => 'the details';

  @override
  String get incSession => 'Related parking session';

  @override
  String get incNoSession => 'No session';

  @override
  String get incSelectedSession => 'Selected session';

  @override
  String get incAddPhoto => 'Add photo';

  @override
  String get incRemovePhoto => 'Remove photo';

  @override
  String get incSubmit => 'Send report';

  @override
  String get incListTitle => 'My reports';

  @override
  String get incReport => 'Report incident';

  @override
  String get incEmptyTitle => 'No reports yet';

  @override
  String get incEmptyMessage =>
      'Had a problem (collision, wrong fee, lost item)? Send a report with photos and staff will handle it.';

  @override
  String get incAssigned => 'You\'re now handling this incident';

  @override
  String get incResolvedToast => 'Marked as resolved';

  @override
  String get incDetailTitle => 'Incident details';

  @override
  String get incImageFailed => 'Couldn\'t load the image';

  @override
  String get incReporter => 'Reported by';

  @override
  String get incLinkedSession => 'Linked session';

  @override
  String get incHandler => 'Handled by';

  @override
  String get incUnassigned => 'Unassigned';

  @override
  String get incResolvedAt => 'Resolved at';

  @override
  String get incResult => 'Resolution';

  @override
  String get incTake => 'Take this';

  @override
  String get incTakeOver => 'Assign to me';

  @override
  String get incMarkResolved => 'Mark as resolved';

  @override
  String get incNotes => 'Resolution notes';

  @override
  String get incNotesHint => 'Checked cameras, contacted the customer...';

  @override
  String get incNotesField => 'resolution notes';

  @override
  String get incConfirmResolved => 'Confirm resolved';

  @override
  String incReporterValue(String name) {
    return 'Reported by $name';
  }

  @override
  String incHandlerValue(String name) {
    return 'Handled by $name';
  }

  @override
  String get accTitle => 'Account';

  @override
  String get accBioReasonEnable => 'Authenticate to turn on biometric app lock';

  @override
  String get accBioEnabled => 'Biometric unlock turned on';

  @override
  String get accBioFailed => 'Couldn\'t verify you, so it wasn\'t turned on';

  @override
  String get accLogoutTitle => 'Sign out?';

  @override
  String get accLogoutMessage =>
      'You\'ll need to sign in again to use the app.';

  @override
  String get accProfileSecurity => 'Profile & security';

  @override
  String get accEditProfile => 'Edit profile';

  @override
  String get accChangePassword => 'Change password';

  @override
  String get accBioTitle => 'Biometric unlock';

  @override
  String get accBioOn =>
      'Ask for fingerprint or Face ID each time the app opens';

  @override
  String get accBioUnavailable =>
      'This device doesn\'t support it or has no fingerprint/face registered';

  @override
  String get accAppearance => 'Appearance';

  @override
  String get accThemeSystem => 'System';

  @override
  String get accThemeLight => 'Light';

  @override
  String get accThemeDark => 'Dark';

  @override
  String get accLanguage => 'Language';

  @override
  String get accAvailability => 'Free spaces by floor';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileTitle => 'Personal details';

  @override
  String get profileEmailHelper =>
      'Used to sign in and receive verification codes.';

  @override
  String get profileSave => 'Save changes';

  @override
  String get pwdChanged => 'Password changed';

  @override
  String get pwdTitle => 'Change password';

  @override
  String get pwdNote =>
      'The new password applies to your next sign-in on every device.';

  @override
  String get pwdSubmit => 'Change password';

  @override
  String get gateEntry => 'Entry gate';

  @override
  String get gateExit => 'Exit gate';

  @override
  String get gateReload => 'Reload gates';

  @override
  String get gateNoneEntry => 'No entry gates are configured.';

  @override
  String get gateNoneExit => 'No exit gates are configured.';

  @override
  String get gatePick => 'Choose a gate';

  @override
  String get ciPlatePhoto => 'Plate photo';

  @override
  String ciRecognizedPct(String pct) {
    return 'Recognized at $pct%. Double-check before confirming.';
  }

  @override
  String get ciRecognized => 'Recognized. Double-check before confirming.';

  @override
  String get ciNotRecognized => 'Couldn\'t read the plate. Please type it.';

  @override
  String get ciQrPhoto => 'Booking QR photo';

  @override
  String get ciNotBookingQr => 'This QR code isn\'t a booking code.';

  @override
  String get ciPickGate => 'Please choose an entry gate.';

  @override
  String get ciPickType => 'Please choose a vehicle type.';

  @override
  String ciSuccess(String type) {
    return '$type: checked in';
  }

  @override
  String get ciTitle => 'Vehicle entry';

  @override
  String get ciScanPlate => 'Photograph and read plate';

  @override
  String get ciBookingCode => 'Booking code';

  @override
  String get ciBookingHint => 'Scan the QR in the customer\'s app';

  @override
  String get ciBookingField => 'the booking code';

  @override
  String get ciScanQr => 'Scan QR code';

  @override
  String get ciBookingWindow =>
      'Check-in is allowed within 30 minutes of the booked time.';

  @override
  String get ciResidentNote =>
      'The system checks for a valid monthly pass by plate.';

  @override
  String get ciSubmit => 'Confirm entry';

  @override
  String ciGuideToSlot(String slot) {
    return 'Direct the vehicle to space $slot';
  }

  @override
  String get ciEntered => 'Vehicle entered';

  @override
  String ciEnteredAt(String type, String time) {
    return '$type, entered at $time';
  }

  @override
  String get ciTicketNote => 'The customer should save this code for exit';

  @override
  String get ciNext => 'Next vehicle';

  @override
  String get coTicketPhoto => 'Ticket QR photo';

  @override
  String get coNotActiveQr => 'This QR code doesn\'t match an active session.';

  @override
  String get coPickGate => 'Please choose an exit gate.';

  @override
  String get coScanFirst => 'Please scan the customer\'s ticket QR.';

  @override
  String get coPayOSReceived => 'PayOS payment received';

  @override
  String get coPaymentCancelled => 'Payment cancelled';

  @override
  String get coCancelTitle => 'Cancel exit request?';

  @override
  String get coCancelMessage => 'The session will return to parked status.';

  @override
  String get coCancelAction => 'Cancel request';

  @override
  String get coCancelled => 'Exit request cancelled';

  @override
  String get coTitle => 'Vehicle exit';

  @override
  String get coByTicket => 'Scan ticket';

  @override
  String get coByPlate => 'By plate';

  @override
  String get coScanPrompt => 'Photograph the customer\'s ticket QR';

  @override
  String get coRescan => 'Tap to scan again';

  @override
  String get coAutoFind => 'The session is found automatically';

  @override
  String get coMethod => 'Payment method';

  @override
  String get coPassFree =>
      'Vehicles with a valid monthly pass exit free automatically.';

  @override
  String get coSubmit => 'Calculate fee and exit';

  @override
  String get coFailedNote =>
      'Payment was cancelled. The session is still active.';

  @override
  String get coDone => 'Done. Let the vehicle exit.';

  @override
  String get coToCollect => 'To collect';

  @override
  String get coNoFee => 'No fee (covered by the monthly pass).';

  @override
  String coScanToPay(String amount) {
    return 'Customer scans to pay $amount';
  }

  @override
  String get coWaitingPayOS => 'Waiting for PayOS';

  @override
  String coCashCollected(String amount) {
    return 'Collected $amount in cash';
  }

  @override
  String get coCancelExit => 'Cancel exit request';

  @override
  String get coNext => 'Next vehicle';

  @override
  String get ssTitle => 'Parking sessions';

  @override
  String get ssSearch => 'Search by plate';

  @override
  String get ssActive => 'Parked';

  @override
  String get ssNoMatchTitle => 'No matching plate';

  @override
  String get ssEmptyTitle => 'No sessions';

  @override
  String get ssNoMatchMessage => 'Check the plate or choose \"All\".';

  @override
  String get ssEmptyMessage => 'Vehicles currently parked will show up here.';

  @override
  String ssCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get ssDetailTitle => 'Session details';

  @override
  String get ssDriver => 'Driver';

  @override
  String get ssPlateOut => 'Plate at exit';

  @override
  String get ssPayment => 'Payment';

  @override
  String get ssImageFailed => 'Couldn\'t load the gate photo';

  @override
  String get siTitle => 'Incidents';

  @override
  String get siOpen => 'To handle';

  @override
  String get siMine => 'Mine';

  @override
  String get siEmptyTitle => 'No incidents';

  @override
  String get siEmptyMessage => 'Nothing in this list.';

  @override
  String get walletTitle => 'PBMS Wallet';

  @override
  String get walletBalance => 'Available balance';

  @override
  String get walletTopUp => 'Top up';

  @override
  String get walletTopUpTitle => 'Top up wallet';

  @override
  String get walletTopUpDesc =>
      'Your balance is credited as soon as PayOS confirms the payment.';

  @override
  String get walletAmount => 'Amount';

  @override
  String walletAmountHint(String min, String max) {
    return 'Between $min and $max';
  }

  @override
  String vAmountRange(String min, String max) {
    return 'Enter a whole amount between $min and $max';
  }

  @override
  String walletTopUpSubmit(String amount) {
    return 'Top up $amount';
  }

  @override
  String get walletHistory => 'Transactions';

  @override
  String get walletFilterTopUps => 'Top-ups';

  @override
  String get walletFilterSpends => 'Spending';

  @override
  String get walletEmptyTitle => 'No transactions yet';

  @override
  String get walletEmptyMessage =>
      'Top up to pay for monthly passes instantly, without a bank transfer each time.';

  @override
  String get walletPendingNote =>
      'Top-ups appear here once PayOS confirms them.';

  @override
  String get walletTxTopUp => 'Top-up via PayOS';

  @override
  String walletTxSpend(String package) {
    return 'Bought $package';
  }

  @override
  String get walletTxSpendGeneric => 'Pass paid with wallet';

  @override
  String walletBalanceAfter(String amount) {
    return 'Balance after: $amount';
  }

  @override
  String get walletToppedUp => 'Wallet topped up';

  @override
  String get payMethodTitle => 'Payment method';

  @override
  String get payMethodWallet => 'PBMS Wallet';

  @override
  String payMethodWalletBalance(String amount) {
    return 'Balance $amount';
  }

  @override
  String payMethodWalletShort(String amount) {
    return 'Not enough balance, $amount short';
  }

  @override
  String get payMethodPayOSHint => 'Bank transfer via VietQR';

  @override
  String get passPaidByWallet => 'Paid with wallet. Your pass is now active.';

  @override
  String get passPayChoose => 'Choose how to pay';

  @override
  String passPayConfirm(String amount) {
    return 'Pay $amount';
  }

  @override
  String get accAvatarChange => 'Change profile photo';

  @override
  String get accAvatarUpdated => 'Profile photo updated';

  @override
  String get accAvatarTooLarge =>
      'The image is larger than 5 MB. Please choose a smaller one.';
}
