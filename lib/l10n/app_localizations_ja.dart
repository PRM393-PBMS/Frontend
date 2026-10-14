// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'PBMS Parking';

  @override
  String get commonBack => '戻る';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonAll => 'すべて';

  @override
  String get commonDone => '完了';

  @override
  String get commonEdit => '編集';

  @override
  String get commonYes => 'はい';

  @override
  String get commonNo => 'いいえ';

  @override
  String get commonNone => '未設定';

  @override
  String get commonLoading => '読み込み中';

  @override
  String get commonUnknown => '不明';

  @override
  String get commonLogout => 'ログアウト';

  @override
  String get loadFailedTitle => 'データを読み込めませんでした';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get hidePassword => 'パスワードを隠す';

  @override
  String get imagePickTitle => '写真を選択';

  @override
  String get imageTakePhoto => '写真を撮る';

  @override
  String get imageFromLibrary => 'ライブラリから選択';

  @override
  String get ticketQrSemantics => '駐車券のQRコード';

  @override
  String get ticketCopied => 'チケット番号をコピーしました';

  @override
  String ticketCode(String code) {
    return 'チケット $code';
  }

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String get errorGeneric => 'エラーが発生しました。もう一度お試しください。';

  @override
  String get errorNetwork => 'サーバーに接続できません。通信環境を確認して再試行してください。';

  @override
  String errorStatus(String code) {
    return 'リクエストに失敗しました（$code）。';
  }

  @override
  String get errorSessionExpired => 'セッションの有効期限が切れました。もう一度ログインしてください。';

  @override
  String timeToday(String time) {
    return '今日 $time';
  }

  @override
  String timeTomorrow(String time) {
    return '明日 $time';
  }

  @override
  String timeYesterday(String time) {
    return '昨日 $time';
  }

  @override
  String timeOnDate(String time, String date) {
    return '$date $time';
  }

  @override
  String durationDaysHours(String days, String hours) {
    return '$days日$hours時間';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes分';
  }

  @override
  String get agoJustNow => 'たった今';

  @override
  String agoMinutes(int n) {
    return '$n分前';
  }

  @override
  String agoHours(int n) {
    return '$n時間前';
  }

  @override
  String agoDays(int n) {
    return '$n日前';
  }

  @override
  String dateRange(String from, String to) {
    return '$from 〜 $to';
  }

  @override
  String vRequired(String field) {
    return '$fieldを入力してください';
  }

  @override
  String get vEmailRequired => 'メールアドレスを入力してください';

  @override
  String get vEmailInvalid => 'メールアドレスの形式が正しくありません';

  @override
  String vMaxLength(String field, String max) {
    return '$fieldは$max文字以内で入力してください';
  }

  @override
  String get vPhoneRequired => '電話番号を入力してください';

  @override
  String get vPhoneInvalid => '有効なベトナムの携帯電話番号を入力してください';

  @override
  String get vUserNameRequired => 'ユーザー名を入力してください';

  @override
  String get vFullNameRequired => '氏名を入力してください';

  @override
  String get vPasswordRequired => 'パスワードを入力してください';

  @override
  String get vConfirmRequired => 'パスワードをもう一度入力してください';

  @override
  String get vConfirmMismatch => 'パスワードが一致しません';

  @override
  String get vOtpInvalid => '認証コードは6桁の数字です';

  @override
  String get vPlateRequired => 'ナンバーを入力してください';

  @override
  String get vPlateInvalid => 'ナンバーは英数字4〜15文字です';

  @override
  String get vPlateSame => '新しいナンバーは現在のものと異なる必要があります';

  @override
  String get fieldEmail => 'メールアドレス';

  @override
  String get fieldUserName => 'ユーザー名';

  @override
  String get fieldFullName => '氏名';

  @override
  String get fieldPhone => '電話番号';

  @override
  String get fieldEmailLabel => 'メールアドレス';

  @override
  String get fieldFullNameLabel => '氏名';

  @override
  String get fieldUserNameLabel => 'ユーザー名';

  @override
  String get fieldPassword => 'パスワード';

  @override
  String get fieldPasswordConfirm => 'パスワード（確認）';

  @override
  String get fieldNewPassword => '新しいパスワード';

  @override
  String get fieldNewPasswordConfirm => '新しいパスワード（確認）';

  @override
  String get fieldOtp => '認証コード';

  @override
  String get fieldPlate => 'ナンバープレート';

  @override
  String get fieldVehicleType => '車種';

  @override
  String get stReservationPending => 'デポジット待ち';

  @override
  String get stReservationConfirmed => '確定';

  @override
  String get stReservationModified => '時間変更済み';

  @override
  String get stReservationCheckedIn => '入庫済み';

  @override
  String get stReservationCompleted => '完了';

  @override
  String get stCancelled => 'キャンセル';

  @override
  String get stReservationNoShow => '未来場';

  @override
  String get stSessionActive => '駐車中';

  @override
  String get stSessionCompleted => '出庫済み';

  @override
  String get stSessionException => '例外';

  @override
  String get stPassActive => '有効';

  @override
  String get stPendingPayment => '支払い待ち';

  @override
  String get stPassExpired => '期限切れ';

  @override
  String get stPaid => '支払い済み';

  @override
  String get stIncidentOpen => '新規';

  @override
  String get stIncidentInProgress => '対応中';

  @override
  String get stIncidentResolved => '解決済み';

  @override
  String get stChangePending => '審査中';

  @override
  String get stChangeApproved => '承認済み';

  @override
  String get stChangeRejected => '却下';

  @override
  String get stNoPass => '月極なし';

  @override
  String get payMethodPayOS => 'PayOS振込';

  @override
  String get payMethodCash => '現金';

  @override
  String get payTypeDeposit => '予約デポジット';

  @override
  String get payTypeCheckout => '駐車料金';

  @override
  String get payTypeSubscription => '月極料金';

  @override
  String get payTypeRenewal => '月極の更新';

  @override
  String get roleStaff => 'ゲート係員';

  @override
  String get roleManager => '駐車場マネージャー';

  @override
  String get roleAdmin => '管理者';

  @override
  String get roleCustomer => 'お客様';

  @override
  String get customerGuest => '一般';

  @override
  String get customerResident => '月極';

  @override
  String get customerReservation => '予約';

  @override
  String get customerGuestFull => '一般のお客様';

  @override
  String get customerResidentFull => '月極のお客様';

  @override
  String get customerReservationFull => '予約のお客様';

  @override
  String get navHome => 'ホーム';

  @override
  String get navHistory => '履歴';

  @override
  String get navPasses => '月極';

  @override
  String get navAccount => 'アカウント';

  @override
  String get navCheckIn => '入庫';

  @override
  String get navCheckOut => '出庫';

  @override
  String get navSessions => '駐車記録';

  @override
  String get navIncidents => 'トラブル';

  @override
  String get unsupportedTitle => '対応していない権限です';

  @override
  String unsupportedMessage(String email, String role) {
    return 'アカウント $email の権限は「$role」です。このアプリはお客様とゲート係員向けです。管理画面をご利用ください。';
  }

  @override
  String get notFoundTitle => 'ページが見つかりません';

  @override
  String get notFoundMessage => 'このリンクは存在しないか、変更されています。';

  @override
  String get notFoundAction => 'ホームへ';

  @override
  String get lockReason => 'PBMS Parkingのロックを解除するには認証してください';

  @override
  String get lockFailed => '認証できませんでした。再試行するか、ログアウトしてパスワードでログインしてください。';

  @override
  String get lockTitle => 'アプリはロックされています';

  @override
  String lockMessage(String name) {
    return '$nameさん、こんにちは。続行するには、この端末に登録した指紋または顔を使用してください。';
  }

  @override
  String get lockSemantics => '生体認証でロック解除';

  @override
  String get lockUnlock => 'ロック解除';

  @override
  String get splashTagline => '駐車・予約・月極をひとつのアプリで。';

  @override
  String get splashChecking => 'ログイン状態を確認しています';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get loginSubtitle => '登録済みのメールアドレスで、駐車・予約・月極を管理できます。';

  @override
  String get loginForgot => 'パスワードをお忘れですか？';

  @override
  String get loginSubmit => 'ログイン';

  @override
  String get loginNoAccount => 'アカウントをお持ちでないですか？';

  @override
  String get loginRegister => '新規登録';

  @override
  String get loginFailed => 'ログインできませんでした。入力内容を確認してください。';

  @override
  String get loginRegistered => '登録が完了しました。ログインしてください。';

  @override
  String get loginPasswordReset => 'パスワードを再設定しました。新しいパスワードでログインしてください。';

  @override
  String get registerTitle => 'アカウント作成';

  @override
  String get registerSubtitle => '6桁の認証コードをメールでお送りします。';

  @override
  String get registerSubmit => '認証コードを送信';

  @override
  String get otpSendFailed => '認証コードを送信できませんでした。しばらくしてから再試行してください。';

  @override
  String get otpVerifyFailed => '認証に失敗しました。もう一度お試しください。';

  @override
  String get otpTitleRegister => 'メールアドレスの確認';

  @override
  String get otpTitleReset => 'パスワードの再設定';

  @override
  String otpSubtitle(String email) {
    return '$email に送信した6桁のコードを入力してください。有効期限は10分です。';
  }

  @override
  String get otpSubmitRegister => '登録を完了';

  @override
  String get otpSubmitReset => 'パスワードを再設定';

  @override
  String get otpResend => 'コードを再送信';

  @override
  String get otpEditAndResend => '情報を修正して再送信';

  @override
  String get otpResent => 'メールアドレスが登録済みの場合、再設定コードを送信しました。';

  @override
  String get resetRequestFailed => 'パスワード再設定の申請に失敗しました。';

  @override
  String get resetFailed => 'パスワードを再設定できませんでした。コードを確認してください。';

  @override
  String get forgotTitle => 'パスワードをお忘れの方';

  @override
  String get forgotSubtitle =>
      '登録済みのメールアドレスを入力してください。新しいパスワードを設定するためのコードをお送りします。';

  @override
  String get forgotSubmit => 'コードを送信';

  @override
  String get onbSkip => 'スキップ';

  @override
  String get onbNext => '次へ';

  @override
  String get onbStart => 'はじめる';

  @override
  String get onb1Title => '到着前に空き状況を確認';

  @override
  String get onb1Body => '階・車種ごとの空き台数を駐車場システムから表示します。';

  @override
  String get onb2Title => '車の予約、QRコードで入庫';

  @override
  String get onb2Body => '最大5時間前から予約でき、PayOSでデポジットを支払い、ゲートでチケットを提示します。';

  @override
  String get onb3Title => '月極と料金がひと目でわかる';

  @override
  String get onb3Body => '月極の登録・更新や、駐車中の概算料金をスマホで確認できます。';

  @override
  String get notifTooltip => 'お知らせ';

  @override
  String get notifTitle => 'お知らせ';

  @override
  String get notifMarkAll => 'すべて既読にする';

  @override
  String get notifEmptyTitle => 'お知らせはありません';

  @override
  String get notifEmptyMessage => '予約・月極・トラブルに関するお知らせがここに表示されます。';

  @override
  String get homeMorning => 'おはようございます';

  @override
  String get homeAfternoon => 'こんにちは';

  @override
  String get homeEvening => 'こんばんは';

  @override
  String get homeServices => 'サービス';

  @override
  String get homeBookCar => '車の駐車予約';

  @override
  String get homeBookCarSub => '最大5時間前から確保、PayOSでデポジット';

  @override
  String get homeMyBookings => '予約一覧';

  @override
  String get homeMyBookingsSub => 'チケットの確認・時間変更・キャンセル';

  @override
  String get homeAvailability => '階別の空き状況';

  @override
  String get homeAvailabilitySub => '空き状況と現在の料金';

  @override
  String get homeReport => 'トラブルを報告';

  @override
  String get homeReportSub => '写真付きで報告し、対応状況を確認';

  @override
  String homeParkedFor(String duration) {
    return '駐車時間 $duration';
  }

  @override
  String homeEnteredAt(String time, String gate) {
    return '$time に $gate から入庫';
  }

  @override
  String homeEnteredSlot(String slot) {
    return '、区画 $slot';
  }

  @override
  String get homePayToExit => '出庫するには料金をお支払いください';

  @override
  String get homeViewTicket => 'チケットと概算料金を見る';

  @override
  String get homeFreeNow => '現在の空き';

  @override
  String get homeNoAvailability => '空き状況のデータがありません';

  @override
  String get homeNoSlots => '駐車区画がまだ設定されていません。';

  @override
  String homeOfSpaces(String total) {
    return '/ $total台';
  }

  @override
  String homeTypeFree(String type, String count) {
    return '$type：空き$count台';
  }

  @override
  String get homeByFloor => '階別に見る';

  @override
  String homeBookingAt(String time) {
    return '予約 $time';
  }

  @override
  String get homeFinishDeposit => 'デポジットを支払うと区画が確保されます';

  @override
  String get homeArriveWindow => '予約時刻の前後30分以内にお越しください';

  @override
  String get availTitle => '空き状況';

  @override
  String get availEmptyTitle => '駐車区画のデータがありません';

  @override
  String get availEmptyMessage => '階と区画がまだ設定されていません。後でもう一度ご確認ください。';

  @override
  String get availResidentFloor => '居住者・月極専用階';

  @override
  String availOfFree(String total) {
    return ' / $total台空き';
  }

  @override
  String get availPricing => '駐車料金';

  @override
  String priceFirstHours(String hours) {
    return '最初の$hours時間';
  }

  @override
  String get priceExtraHour => '以降1時間ごと';

  @override
  String get priceNight => '夜間加算（22:00〜06:00）';

  @override
  String get resNewTitle => '車の駐車予約';

  @override
  String get resNewIntro => '予約は車のみ、入庫の最大5時間前まで可能です。予約時刻の前後30分以内に入庫できます。';

  @override
  String get resCarFree => '一般車の空き';

  @override
  String resSpaces(String count) {
    return '$count台';
  }

  @override
  String get resDepositEstimate => 'デポジット（目安）';

  @override
  String get resPerPricing => '料金表による';

  @override
  String get resPrice => '料金';

  @override
  String resPriceValue(String base, String hours, String extra) {
    return '最初の$hours時間 $base、以降1時間 $extra';
  }

  @override
  String get resEntryTime => '入庫時刻';

  @override
  String get resRefreshSlots => '時間枠を更新';

  @override
  String get resPickTime => '入庫時刻を選択してください。';

  @override
  String get resSlotPassed => 'その時刻は過ぎました。もう一度選択してください。';

  @override
  String get resChooseTime => '入庫時刻を選択';

  @override
  String resBookAt(String time) {
    return '$time で予約';
  }

  @override
  String get resNoSlots => '選択できる時間枠がありません。';

  @override
  String get resDepositTitle => '予約デポジット';

  @override
  String resDepositDesc(String time) {
    return '$time に車の区画を確保します。デポジットは出庫時の駐車料金から差し引かれます。';
  }

  @override
  String resDepositDescShort(String time) {
    return '$time に車の区画を確保します。';
  }

  @override
  String get resListTitle => '予約一覧';

  @override
  String get resNew => '新規予約';

  @override
  String get resEmptyTitle => '予約はまだありません';

  @override
  String get resEmptyMessage => '最大5時間前から車の区画を予約し、QRコードで入庫できます。';

  @override
  String get resUpcoming => '今後の予約';

  @override
  String get resPast => '過去の予約';

  @override
  String resTileMeta(String type, String ago) {
    return '$type・$agoに予約';
  }

  @override
  String get resDetailTitle => '予約の詳細';

  @override
  String get resConfirmed => '予約が確定しました';

  @override
  String get resCancelTitle => '予約をキャンセルしますか？';

  @override
  String get resCancelPending => '未払いの予約がキャンセルされます。';

  @override
  String get resCancelPaid => '支払い済みの予約がキャンセルされ、元に戻せません。';

  @override
  String get resCancelAction => '予約をキャンセル';

  @override
  String get resCancelled => '予約をキャンセルしました';

  @override
  String resRescheduled(String time) {
    return '$time に変更しました';
  }

  @override
  String resEntryWindow(String from, String to) {
    return '$from〜$to に入庫';
  }

  @override
  String get resShowAtEntry => '入口ゲートで係員にこのコードを提示してください';

  @override
  String get resBookedAt => '予約日';

  @override
  String get resReschedule => '時間変更';

  @override
  String get resRescheduleUsed => '使用済み';

  @override
  String get resRescheduleLeft => '残り1回';

  @override
  String get resPendingNote =>
      'デポジットの支払い後に区画が確保されます。予約時刻から30分を過ぎると自動的にキャンセルされます。';

  @override
  String get resPayDeposit => 'デポジットを支払う';

  @override
  String get resChangeTime => '入庫時刻を変更';

  @override
  String get resChangeRule => '時間変更は予約時刻の15分前まで可能です。';

  @override
  String get resNewTime => '新しい入庫時刻を選択';

  @override
  String get resOneChange => '時間変更は1回のみ可能です。';

  @override
  String get resConfirmChange => '変更を確定';

  @override
  String get payInvalidLink => '支払いリンクが無効です。';

  @override
  String get payCantOpen => 'この端末で支払いページを開けませんでした。';

  @override
  String get payNotYet => 'まだ入金を確認できません。PayOSのページで支払いを完了してから再確認してください。';

  @override
  String get paySuccessTitle => 'お支払いが完了しました';

  @override
  String get paySuccessMessage => 'お支払いを確認しました。';

  @override
  String get payFailedTitle => 'お支払いに失敗しました';

  @override
  String get payFailedMessage => '取引はキャンセルされたか失敗しました。支払いリンクを作り直せます。';

  @override
  String get payAmount => '金額';

  @override
  String get payOrderCode => '注文番号';

  @override
  String get payWaiting => 'PayOSの確認待ちです。画面は自動で更新されます。';

  @override
  String get payHint => 'PayOSのページでVietQRを使い、銀行アプリで支払います。';

  @override
  String get payReopen => '支払いページを再表示';

  @override
  String get payWithPayOS => 'PayOSで支払う';

  @override
  String get payCheckStatus => '状況を確認';

  @override
  String get payLater => '後で支払う';

  @override
  String get paySuccessShort => 'お支払いが完了しました';

  @override
  String get histTitle => '駐車履歴';

  @override
  String get histEmptyTitle => '駐車記録はまだありません';

  @override
  String get histEmptyMessage => 'アカウントに紐づく駐車（月極・予約）は入庫後にここに表示されます。';

  @override
  String get histActive => '駐車中';

  @override
  String get histDone => '完了';

  @override
  String sessTileActive(String time, String duration) {
    return '$time 入庫・駐車 $duration';
  }

  @override
  String sessSlot(String slot) {
    return '区画 $slot';
  }

  @override
  String get feeRunning => '概算料金';

  @override
  String get feeFree => '無料';

  @override
  String get feeCovered => 'このナンバーの月極に含まれています。';

  @override
  String get feeDuration => '駐車時間';

  @override
  String feeHoursValue(String hours) {
    return '$hours時間';
  }

  @override
  String get feeBilledHours => '課金時間';

  @override
  String feeExtraHours(String hours) {
    return '追加$hours時間';
  }

  @override
  String feeNight(String count) {
    return '夜間加算 ×$count';
  }

  @override
  String get feeDeposit => 'デポジット控除';

  @override
  String get sessNotFound => 'この駐車記録はアカウントに見つかりません。';

  @override
  String get sessPayTitle => '駐車料金の支払い';

  @override
  String get sessPayDesc => 'PayOSで支払いが確認されると駐車が完了します。';

  @override
  String get sessPaid => '駐車料金を支払いました';

  @override
  String get sessTitle => '駐車記録';

  @override
  String sessTotal(String duration) {
    return '合計 $duration';
  }

  @override
  String get sessShowAtExit => '出口ゲートで係員にこのコードを提示してください';

  @override
  String get sessNeedPay => '出庫には支払いが必要です';

  @override
  String sessNeedPayDetail(String amount, String method) {
    return '$amount（$method）';
  }

  @override
  String get sessPayCash => 'ゲートで係員に現金でお支払いください。';

  @override
  String get sessEntry => '入庫時刻';

  @override
  String get sessEntryGate => '入口ゲート';

  @override
  String get sessSpot => '区画';

  @override
  String get sessExit => '出庫時刻';

  @override
  String get sessExitGate => '出口ゲート';

  @override
  String get sessMode => '利用形態';

  @override
  String get sessModeBooked => '予約';

  @override
  String get sessModeDirect => '直接入庫';

  @override
  String get sessPaidAmount => '支払額';

  @override
  String get sessMethod => '支払方法';

  @override
  String get sessReport => 'この駐車についてトラブルを報告';

  @override
  String get passesTitle => '車両と月極';

  @override
  String get passesRegister => '月極を申込';

  @override
  String get passesEmptyTitle => '車両はまだありません';

  @override
  String get passesEmptyMessage => 'ナンバーを月極登録すると、利用ごとの支払いが不要になります。';

  @override
  String get passesRegisterPass => '月極を申し込む';

  @override
  String get passesPlateRequests => 'ナンバー変更申請';

  @override
  String passesPendingRequests(String count) {
    return '$count件が審査中';
  }

  @override
  String get passesTrackRequests => '月極の車両変更申請を確認';

  @override
  String get passesAll => 'すべての月極';

  @override
  String passDaysLeft(int days) {
    return '残り$days日';
  }

  @override
  String passExpiresOn(String date) {
    return '$date まで';
  }

  @override
  String passFixedSlot(String slot) {
    return '固定区画 $slot';
  }

  @override
  String get passPayToActivate => '支払うと有効になります';

  @override
  String passLastParked(String time) {
    return '最終利用 $time。月極を申し込む';
  }

  @override
  String get passRenewOrRegister => '更新または再申込';

  @override
  String get passTitle => '月極';

  @override
  String passDaysLeftUntil(int days, String date) {
    return '残り$days日・$date まで';
  }

  @override
  String get passStart => '開始日';

  @override
  String get passEnd => '終了日';

  @override
  String get passFixedSlotLabel => '固定区画';

  @override
  String get passPrice => 'プラン料金';

  @override
  String passPay(String amount) {
    return '$amount を支払う';
  }

  @override
  String get passRenew => '更新';

  @override
  String get passChangePlate => 'ナンバー変更';

  @override
  String get passCancel => '月極を解約';

  @override
  String get passRenewals => '更新履歴';

  @override
  String get passPayTitle => '月極の支払い';

  @override
  String passPayDesc(String package, String plate) {
    return 'ナンバー $plate の $package';
  }

  @override
  String passRegisterPayDesc(String package, String plate) {
    return 'ナンバー $plate の $package。支払いが完了すると直ちに有効になります。';
  }

  @override
  String get passRenewTitle => '月極の更新';

  @override
  String passRenewDesc(String package, String plate) {
    return 'ナンバー $plate の $package。期間は現在の有効期限から延長されます（期限切れの場合は本日から）。';
  }

  @override
  String get passCancelTitle => '月極を解約しますか？';

  @override
  String passCancelMessage(String plate) {
    return 'ナンバー $plate の月極が無効になります。';
  }

  @override
  String passCancelMessageSlot(String plate, String slot) {
    return 'ナンバー $plate の月極が無効になり、区画 $slot が解放されます。';
  }

  @override
  String get passCancelAction => '解約する';

  @override
  String get passCancelled => '月極を解約しました';

  @override
  String get passPlateRequested => 'ナンバー変更を申請しました';

  @override
  String get passRenewPick => '更新プランを選択';

  @override
  String get passRenewNoneTitle => '該当するプランがありません';

  @override
  String get passRenewNoneMessage => 'この車種で販売中のプランは現在ありません。';

  @override
  String passMonths(int months) {
    return '$monthsか月';
  }

  @override
  String get passFixedSlotTag => '固定区画';

  @override
  String get regTitle => '月極の申込';

  @override
  String get regPickPackage => 'プランを選択してください。';

  @override
  String get regNeedSlot => 'このプランでは固定区画の選択が必要です。';

  @override
  String get regEmptyTitle => '月極プランがありません';

  @override
  String get regEmptyMessage => '現在販売中の月極プランはありません。';

  @override
  String get regPlateHelper => 'ハイフンやドットは不要です。';

  @override
  String get regFixedSlot => '固定区画';

  @override
  String get regNoSlot => 'この車種の固定区画に現在空きがありません。';

  @override
  String get regChoosePackage => 'プランを選択';

  @override
  String plateSheetCurrent(String plate) {
    return '現在のナンバー $plate。申請は管理者の承認が必要です。';
  }

  @override
  String get plateNew => '新しいナンバー';

  @override
  String get plateReason => '理由（任意）';

  @override
  String get plateReasonField => '理由';

  @override
  String get plateSend => '申請する';

  @override
  String get plateEditTitle => 'ナンバー変更申請を編集';

  @override
  String get plateUpdated => '申請を更新しました';

  @override
  String get plateWithdrawTitle => '申請を取り下げますか？';

  @override
  String plateWithdrawMessage(String plate) {
    return 'ナンバー $plate への変更申請が削除されます。';
  }

  @override
  String get plateWithdraw => '取り下げる';

  @override
  String get plateWithdrawn => '申請を取り下げました';

  @override
  String get plateEmptyTitle => '申請はありません';

  @override
  String get plateEmptyMessage => '有効な月極を開き「ナンバー変更」から申請してください。';

  @override
  String plateSentAt(String time) {
    return '$time に申請';
  }

  @override
  String plateReasonValue(String reason) {
    return '理由：$reason';
  }

  @override
  String plateRejectedValue(String reason) {
    return '却下理由：$reason';
  }

  @override
  String get incSuggestCollision => '接触・傷';

  @override
  String get incSuggestFee => '料金の誤り';

  @override
  String get incSuggestLost => '紛失物';

  @override
  String get incSuggestNoSpace => '区画が見つからない';

  @override
  String get incPhotoTitle => '証拠写真';

  @override
  String get incSent => 'トラブル報告を送信しました';

  @override
  String get incNewTitle => 'トラブル報告';

  @override
  String get incType => '種類';

  @override
  String get incTypeField => '種類';

  @override
  String get incDescription => '詳細';

  @override
  String get incDescriptionHint => 'いつ・どこで・何が起きたか';

  @override
  String get incDescriptionField => '詳細';

  @override
  String get incSession => '関連する駐車記録';

  @override
  String get incNoSession => '紐づけない';

  @override
  String get incSelectedSession => '選択した駐車記録';

  @override
  String get incAddPhoto => '写真を追加';

  @override
  String get incRemovePhoto => '写真を削除';

  @override
  String get incSubmit => '報告を送信';

  @override
  String get incListTitle => '報告したトラブル';

  @override
  String get incReport => 'トラブル報告';

  @override
  String get incEmptyTitle => '報告はまだありません';

  @override
  String get incEmptyMessage => '接触・料金の誤り・紛失などがあれば、写真付きで報告してください。係員が対応します。';

  @override
  String get incAssigned => 'このトラブルの担当になりました';

  @override
  String get incResolvedToast => '解決済みにしました';

  @override
  String get incDetailTitle => 'トラブルの詳細';

  @override
  String get incImageFailed => '画像を読み込めませんでした';

  @override
  String get incReporter => '報告者';

  @override
  String get incLinkedSession => '駐車記録の紐づけ';

  @override
  String get incHandler => '担当者';

  @override
  String get incUnassigned => '未割り当て';

  @override
  String get incResolvedAt => '解決日時';

  @override
  String get incResult => '対応結果';

  @override
  String get incTake => '担当する';

  @override
  String get incTakeOver => '自分に割り当てる';

  @override
  String get incMarkResolved => '解決済みにする';

  @override
  String get incNotes => '対応メモ';

  @override
  String get incNotesHint => 'カメラを確認、お客様に連絡済み…';

  @override
  String get incNotesField => '対応メモ';

  @override
  String get incConfirmResolved => '解決を確定';

  @override
  String incReporterValue(String name) {
    return '報告者：$name';
  }

  @override
  String incHandlerValue(String name) {
    return '担当：$name';
  }

  @override
  String get accTitle => 'アカウント';

  @override
  String get accBioReasonEnable => '生体認証によるアプリロックを有効にするには認証してください';

  @override
  String get accBioEnabled => '生体認証によるロック解除を有効にしました';

  @override
  String get accBioFailed => '認証できなかったため有効にしませんでした';

  @override
  String get accLogoutTitle => 'ログアウトしますか？';

  @override
  String get accLogoutMessage => 'アプリを使うには再度ログインが必要です。';

  @override
  String get accProfileSecurity => 'プロフィールとセキュリティ';

  @override
  String get accEditProfile => 'プロフィールを編集';

  @override
  String get accChangePassword => 'パスワードを変更';

  @override
  String get accBioTitle => '生体認証でロック解除';

  @override
  String get accBioOn => 'アプリを開くたびに指紋またはFace IDを要求します';

  @override
  String get accBioUnavailable => 'この端末は非対応か、指紋・顔が登録されていません';

  @override
  String get accAppearance => '表示';

  @override
  String get accThemeSystem => '端末に合わせる';

  @override
  String get accThemeLight => 'ライト';

  @override
  String get accThemeDark => 'ダーク';

  @override
  String get accLanguage => '言語';

  @override
  String get accAvailability => '階別の空き状況';

  @override
  String get profileUpdated => 'プロフィールを更新しました';

  @override
  String get profileTitle => '個人情報';

  @override
  String get profileEmailHelper => 'ログインと認証コードの受信に使用します。';

  @override
  String get profileSave => '変更を保存';

  @override
  String get pwdChanged => 'パスワードを変更しました';

  @override
  String get pwdTitle => 'パスワードを変更';

  @override
  String get pwdNote => '新しいパスワードは、すべての端末で次回のログインから有効になります。';

  @override
  String get pwdSubmit => 'パスワードを変更';

  @override
  String get gateEntry => '入口ゲート';

  @override
  String get gateExit => '出口ゲート';

  @override
  String get gateReload => 'ゲート一覧を再読み込み';

  @override
  String get gateNoneEntry => '入口ゲートが設定されていません。';

  @override
  String get gateNoneExit => '出口ゲートが設定されていません。';

  @override
  String get gatePick => 'ゲートを選択';

  @override
  String get ciPlatePhoto => 'ナンバーの写真';

  @override
  String ciRecognizedPct(String pct) {
    return '認識率 $pct%。確定前に確認してください。';
  }

  @override
  String get ciRecognized => '認識しました。確定前に確認してください。';

  @override
  String get ciNotRecognized => 'ナンバーを認識できませんでした。手入力してください。';

  @override
  String get ciQrPhoto => '予約QRの写真';

  @override
  String get ciNotBookingQr => 'このQRコードは予約コードではありません。';

  @override
  String get ciPickGate => '入口ゲートを選択してください。';

  @override
  String get ciPickType => '車種を選択してください。';

  @override
  String ciSuccess(String type) {
    return '$type：入庫しました';
  }

  @override
  String get ciTitle => '入庫';

  @override
  String get ciScanPlate => 'ナンバーを撮影して認識';

  @override
  String get ciBookingCode => '予約コード';

  @override
  String get ciBookingHint => 'お客様のアプリのQRを読み取る';

  @override
  String get ciBookingField => '予約コード';

  @override
  String get ciScanQr => 'QRコードを読み取る';

  @override
  String get ciBookingWindow => '入庫は予約時刻の前後30分以内に限ります。';

  @override
  String get ciResidentNote => 'ナンバーで有効な月極を自動確認します。';

  @override
  String get ciSubmit => '入庫を確定';

  @override
  String ciGuideToSlot(String slot) {
    return '区画 $slot へ誘導してください';
  }

  @override
  String get ciEntered => '入庫しました';

  @override
  String ciEnteredAt(String type, String time) {
    return '$type・$time 入庫';
  }

  @override
  String get ciTicketNote => 'お客様には出庫時に使うこのコードを保存していただいてください';

  @override
  String get ciNext => '次の車両';

  @override
  String get coTicketPhoto => 'チケットQRの写真';

  @override
  String get coNotActiveQr => 'このQRコードに該当する駐車中の記録がありません。';

  @override
  String get coPickGate => '出口ゲートを選択してください。';

  @override
  String get coScanFirst => 'お客様のチケットQRを読み取ってください。';

  @override
  String get coPayOSReceived => 'PayOSの入金を確認しました';

  @override
  String get coPaymentCancelled => '支払いはキャンセルされました';

  @override
  String get coCancelTitle => '出庫リクエストを取り消しますか？';

  @override
  String get coCancelMessage => '駐車記録は駐車中の状態に戻ります。';

  @override
  String get coCancelAction => '取り消す';

  @override
  String get coCancelled => '出庫リクエストを取り消しました';

  @override
  String get coTitle => '出庫';

  @override
  String get coByTicket => 'チケットを読み取る';

  @override
  String get coByPlate => 'ナンバーで検索';

  @override
  String get coScanPrompt => 'お客様のチケットのQRを撮影';

  @override
  String get coRescan => 'タップして再読み取り';

  @override
  String get coAutoFind => '駐車記録を自動で検索します';

  @override
  String get coMethod => '支払方法';

  @override
  String get coPassFree => '有効な月極の車両は自動的に無料になります。';

  @override
  String get coSubmit => '料金を計算して出庫';

  @override
  String get coFailedNote => '支払いはキャンセルされました。駐車記録は継続中です。';

  @override
  String get coDone => '完了しました。出庫させてください。';

  @override
  String get coToCollect => '請求額';

  @override
  String get coNoFee => '料金はかかりません（月極に含まれます）。';

  @override
  String coScanToPay(String amount) {
    return 'お客様がコードを読み取り $amount を支払います';
  }

  @override
  String get coWaitingPayOS => 'PayOSの確認待ち';

  @override
  String coCashCollected(String amount) {
    return '現金 $amount を受領';
  }

  @override
  String get coCancelExit => '出庫リクエストを取り消す';

  @override
  String get coNext => '次の車両';

  @override
  String get ssTitle => '駐車記録';

  @override
  String get ssSearch => 'ナンバーで検索';

  @override
  String get ssActive => '駐車中';

  @override
  String get ssNoMatchTitle => '該当するナンバーがありません';

  @override
  String get ssEmptyTitle => '駐車記録はありません';

  @override
  String get ssNoMatchMessage => 'ナンバーを確認するか「すべて」を選択してください。';

  @override
  String get ssEmptyMessage => '駐車中の車両がここに表示されます。';

  @override
  String ssCount(int count) {
    return '$count件';
  }

  @override
  String get ssDetailTitle => '駐車記録の詳細';

  @override
  String get ssDriver => 'ドライバー';

  @override
  String get ssPlateOut => '出庫時のナンバー';

  @override
  String get ssPayment => '支払い';

  @override
  String get ssImageFailed => 'ゲート写真を読み込めませんでした';

  @override
  String get siTitle => 'トラブル';

  @override
  String get siOpen => '要対応';

  @override
  String get siMine => '担当分';

  @override
  String get siEmptyTitle => 'トラブルはありません';

  @override
  String get siEmptyMessage => 'この一覧に報告はありません。';

  @override
  String get walletTitle => 'PBMSウォレット';

  @override
  String get walletBalance => '利用可能残高';

  @override
  String get walletTopUp => 'チャージ';

  @override
  String get walletTopUpTitle => 'ウォレットにチャージ';

  @override
  String get walletTopUpDesc => 'PayOSで支払いが確認されると残高に反映されます。';

  @override
  String get walletAmount => 'チャージ金額';

  @override
  String walletAmountHint(String min, String max) {
    return '$min〜$max';
  }

  @override
  String vAmountRange(String min, String max) {
    return '$min〜$maxの整数で入力してください';
  }

  @override
  String walletTopUpSubmit(String amount) {
    return '$amountをチャージ';
  }

  @override
  String get walletHistory => '取引履歴';

  @override
  String get walletFilterTopUps => 'チャージ';

  @override
  String get walletFilterSpends => '支出';

  @override
  String get walletEmptyTitle => '取引はまだありません';

  @override
  String get walletEmptyMessage => 'チャージしておくと、毎回振込せずに月極をすぐ支払えます。';

  @override
  String get walletPendingNote => 'チャージはPayOSの確認後に表示されます。';

  @override
  String get walletTxTopUp => 'PayOSでチャージ';

  @override
  String walletTxSpend(String package) {
    return '$packageを購入';
  }

  @override
  String get walletTxSpendGeneric => 'ウォレットで月極を支払い';

  @override
  String walletBalanceAfter(String amount) {
    return '取引後残高：$amount';
  }

  @override
  String get walletToppedUp => 'チャージしました';

  @override
  String get payMethodTitle => '支払方法';

  @override
  String get payMethodWallet => 'PBMSウォレット';

  @override
  String payMethodWalletBalance(String amount) {
    return '残高 $amount';
  }

  @override
  String payMethodWalletShort(String amount) {
    return '残高不足（あと$amount）';
  }

  @override
  String get payMethodPayOSHint => 'VietQRで振込';

  @override
  String get passPaidByWallet => 'ウォレットで支払いました。月極が有効になりました。';

  @override
  String get passPayChoose => '支払方法を選択';

  @override
  String passPayConfirm(String amount) {
    return '$amountを支払う';
  }

  @override
  String get accAvatarChange => 'プロフィール写真を変更';

  @override
  String get accAvatarUpdated => 'プロフィール写真を更新しました';

  @override
  String get accAvatarTooLarge => '画像が5MBを超えています。小さい画像を選んでください。';
}
