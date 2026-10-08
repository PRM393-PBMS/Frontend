import 'package:flutter/widgets.dart';
import 'app_language.dart';

/// Từ điển dịch thuật toàn diện cho hệ thống PBMS Smart Parking
/// Hỗ trợ 3 ngôn ngữ: Tiếng Việt (vi), English (en), 日本語 (ja)
class AppTranslations {
  AppTranslations._();

  static const Map<String, Map<AppLanguage, String>> _localizedValues = {
    // =========================================================================
    // PROFILE HEADER & HERO
    // =========================================================================
    'profile_title': {
      AppLanguage.vi: 'Hồ sơ cá nhân',
      AppLanguage.en: 'Personal Profile',
      AppLanguage.ja: 'プロフィール',
    },
    'settings_tooltip': {
      AppLanguage.vi: 'Cài đặt hệ thống',
      AppLanguage.en: 'System Settings',
      AppLanguage.ja: 'システム設定',
    },
    'change_avatar_tooltip': {
      AppLanguage.vi: 'Đổi ảnh đại diện',
      AppLanguage.en: 'Change Avatar',
      AppLanguage.ja: 'アバターを変更',
    },
    'avatar_uploading': {
      AppLanguage.vi: 'Đang tải ảnh lên...',
      AppLanguage.en: 'Uploading avatar...',
      AppLanguage.ja: 'アバター画像をアップロード中...',
    },
    'avatar_success': {
      AppLanguage.vi: 'Cập nhật ảnh đại diện thành công.',
      AppLanguage.en: 'Avatar updated successfully.',
      AppLanguage.ja: 'アバターが正常に更新されました。',
    },
    'avatar_error_size': {
      AppLanguage.vi: 'Ảnh đại diện không được vượt quá 5 MB.',
      AppLanguage.en: 'Avatar must not exceed 5 MB.',
      AppLanguage.ja: 'アバター画像は5MB以下にしてください。',
    },
    'avatar_error_format': {
      AppLanguage.vi: 'Vui lòng chọn ảnh JPEG, PNG hoặc WebP.',
      AppLanguage.en: 'Please select a JPEG, PNG, or WebP image.',
      AppLanguage.ja: 'JPEG、PNG、またはWebP画像を選択してください。',
    },
    'role_customer_vip': {
      AppLanguage.vi: 'Khách hàng VIP PBMS',
      AppLanguage.en: 'VIP Customer Pass',
      AppLanguage.ja: 'PBMS VIP 会員',
    },
    'role_resident': {
      AppLanguage.vi: 'Cư dân thông minh',
      AppLanguage.en: 'Resident Driver',
      AppLanguage.ja: 'レジデンス利用者',
    },
    'verified_member': {
      AppLanguage.vi: 'Tài khoản đã xác minh danh tính',
      AppLanguage.en: 'Identity Verified Account',
      AppLanguage.ja: '本人認証済みアカウント',
    },

    // =========================================================================
    // MINI STATS
    // =========================================================================
    'stat_vehicles': {
      AppLanguage.vi: 'Phương tiện',
      AppLanguage.en: 'Vehicles',
      AppLanguage.ja: '登録車両',
    },
    'stat_passes': {
      AppLanguage.vi: 'Vé tháng',
      AppLanguage.en: 'Passes',
      AppLanguage.ja: '定期券',
    },
    'stat_parkings': {
      AppLanguage.vi: 'Lượt đỗ xe',
      AppLanguage.en: 'Parking Trips',
      AppLanguage.ja: '駐車履歴',
    },

    // =========================================================================
    // SECTION 1: PERSONAL INFORMATION
    // =========================================================================
    'sec_personal_info': {
      AppLanguage.vi: 'Thông tin cá nhân',
      AppLanguage.en: 'Personal Information',
      AppLanguage.ja: '個人情報',
    },
    'btn_edit': {
      AppLanguage.vi: 'Chỉnh sửa',
      AppLanguage.en: 'Edit',
      AppLanguage.ja: '編集',
    },
    'lbl_full_name': {
      AppLanguage.vi: 'Họ và tên',
      AppLanguage.en: 'Full Name',
      AppLanguage.ja: '氏名',
    },
    'lbl_phone': {
      AppLanguage.vi: 'Số điện thoại',
      AppLanguage.en: 'Phone Number',
      AppLanguage.ja: '電話番号',
    },
    'lbl_username': {
      AppLanguage.vi: 'Tên tài khoản',
      AppLanguage.en: 'Username',
      AppLanguage.ja: 'ユーザー名',
    },
    'lbl_email': {
      AppLanguage.vi: 'Email xác thực',
      AppLanguage.en: 'Verified Email',
      AppLanguage.ja: '認証済みメール',
    },

    // =========================================================================
    // SECTION 2: SERVICES & VEHICLES
    // =========================================================================
    'sec_services': {
      AppLanguage.vi: 'Dịch vụ & Phương tiện của tôi',
      AppLanguage.en: 'My Services & Vehicles',
      AppLanguage.ja: '利用サービス・車両管理',
    },
    'item_registered_vehicles': {
      AppLanguage.vi: 'Phương tiện đã đăng ký',
      AppLanguage.en: 'Registered Vehicles',
      AppLanguage.ja: '登録済み車両一覧',
    },
    'item_active_passes': {
      AppLanguage.vi: 'Gói vé tháng đang kích hoạt',
      AppLanguage.en: 'Active Monthly Subscriptions',
      AppLanguage.ja: '有効な月極・定期利用契約',
    },
    'item_swap_vehicle': {
      AppLanguage.vi: 'Yêu cầu đổi biển số xe',
      AppLanguage.en: 'Change Vehicle Plate Request',
      AppLanguage.ja: 'ナンバープレート変更申請',
    },
    'item_swap_vehicle_desc': {
      AppLanguage.vi: 'Cập nhật biển số mới hoặc chuyển nhượng ô đỗ',
      AppLanguage.en: 'Update new plate or transfer parking slot',
      AppLanguage.ja: '車両変更または駐車枠の移行手続き',
    },
    'item_parking_history': {
      AppLanguage.vi: 'Lịch sử đỗ & Cuống vé điện tử',
      AppLanguage.en: 'Parking & Electronic Receipt History',
      AppLanguage.ja: '入出庫・電子レシート履歴',
    },
    'item_parking_history_desc': {
      AppLanguage.vi: 'Tra cứu hoá đơn VAT và lịch trình ra vào bãi',
      AppLanguage.en: 'Review e-invoices and gate entry/exit logs',
      AppLanguage.ja: '電子領収書およびゲート通過記録の確認',
    },

    // =========================================================================
    // SECTION 3: SETTINGS & UTILITIES
    // =========================================================================
    'sec_settings': {
      AppLanguage.vi: 'Cài đặt & Tiện ích ứng dụng',
      AppLanguage.en: 'Settings & Utilities',
      AppLanguage.ja: '設定とユーティリティ',
    },
    'item_push_notifications': {
      AppLanguage.vi: 'Thông báo thời gian thực',
      AppLanguage.en: 'Real-Time Notifications',
      AppLanguage.ja: 'リアルタイム通知',
    },
    'item_push_notifications_desc': {
      AppLanguage.vi: 'Nhận thông báo khi xe quét qua cổng barrier',
      AppLanguage.en: 'Receive alert when vehicle passes gate barrier',
      AppLanguage.ja: '車両がゲートを通過した際に通知を受信',
    },
    'item_dark_mode': {
      AppLanguage.vi: 'Chế độ nền tối (Dark Mode)',
      AppLanguage.en: 'Dark Mode Experience',
      AppLanguage.ja: 'ダークモード表示',
    },
    'item_dark_mode_desc': {
      AppLanguage.vi: 'Giảm chói và tối ưu góc nhìn ban đêm',
      AppLanguage.en: 'High-contrast cockpit view for night parking',
      AppLanguage.ja: '夜間の視認性を高め目の負担を軽減',
    },
    'item_change_password': {
      AppLanguage.vi: 'Đổi mật khẩu bảo mật',
      AppLanguage.en: 'Security Password',
      AppLanguage.ja: 'パスワード変更',
    },
    'item_change_password_desc': {
      AppLanguage.vi: 'Cập nhật mã khoá bảo vệ tài khoản',
      AppLanguage.en: 'Update account authorization credentials',
      AppLanguage.ja: 'アカウント認証情報の更新',
    },
    'item_language': {
      AppLanguage.vi: 'Ngôn ngữ hiển thị',
      AppLanguage.en: 'Application Language',
      AppLanguage.ja: '言語設定 (Language)',
    },
    'item_language_sub': {
      AppLanguage.vi: 'Tiếng Việt (Mặc định)',
      AppLanguage.en: 'English (Selected)',
      AppLanguage.ja: '日本語 (選択中)',
    },
    'item_biometric': {
      AppLanguage.vi: 'Xác thực sinh trắc học (Biometrics)',
      AppLanguage.en: 'Biometric Security Access',
      AppLanguage.ja: '生体認証セキュリティ',
    },
    'item_biometric_desc': {
      AppLanguage.vi: 'Dùng vân tay hoặc Face ID để mở thẻ ví',
      AppLanguage.en: 'Unlock vehicle pass via Fingerprint or Face ID',
      AppLanguage.ja: '指紋または顔認証でチケットロックを解除',
    },

    // =========================================================================
    // SECTION 4: SUPPORT & POLICIES
    // =========================================================================
    'sec_support': {
      AppLanguage.vi: 'Trợ giúp & Chính sách bãi đỗ',
      AppLanguage.en: 'Support & Parking Policies',
      AppLanguage.ja: 'サポート・規約',
    },
    'item_hotline': {
      AppLanguage.vi: 'Trung tâm trực ban bãi đỗ 24/7',
      AppLanguage.en: '24/7 Parking Operations Center',
      AppLanguage.ja: '24時間駐車場管理センター',
    },
    'item_hotline_desc': {
      AppLanguage.vi: 'Hotline sự cố: 1900 6868 (Bấm nhánh 1)',
      AppLanguage.en: 'Emergency Hotline: 1900 6868 (Ext 1)',
      AppLanguage.ja: '緊急対応ホットライン: 1900 6868 (内線1)',
    },
    'item_rules': {
      AppLanguage.vi: 'Quy chế bãi đỗ & Bảo hiểm rủi ro',
      AppLanguage.en: 'Parking Regulations & Insurance',
      AppLanguage.ja: '利用規約と車両保険規定',
    },
    'item_rules_desc': {
      AppLanguage.vi: 'Điều khoản trách nhiệm và hướng dẫn cứu hộ',
      AppLanguage.en: 'Liability terms and emergency recovery guide',
      AppLanguage.ja: '責任範囲および緊急時レッカー対応案内',
    },

    // =========================================================================
    // DANGER ZONE & LOGOUT
    // =========================================================================
    'btn_logout': {
      AppLanguage.vi: 'Đăng xuất tài khoản',
      AppLanguage.en: 'Sign Out Account',
      AppLanguage.ja: 'ログアウト',
    },
    'dialog_logout_title': {
      AppLanguage.vi: 'Xác nhận đăng xuất',
      AppLanguage.en: 'Confirm Sign Out',
      AppLanguage.ja: 'ログアウトの確認',
    },
    'dialog_logout_msg': {
      AppLanguage.vi: 'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống PBMS Smart Parking?',
      AppLanguage.en: 'Are you sure you want to sign out from PBMS Smart Parking system?',
      AppLanguage.ja: 'PBMSスマートパーキングからログアウトしてもよろしいですか？',
    },
    'btn_cancel': {
      AppLanguage.vi: 'Huỷ bỏ',
      AppLanguage.en: 'Cancel',
      AppLanguage.ja: 'キャンセル',
    },
    'btn_confirm_logout': {
      AppLanguage.vi: 'Đăng xuất ngay',
      AppLanguage.en: 'Sign Out Now',
      AppLanguage.ja: 'ログアウトする',
    },
    'app_version': {
      AppLanguage.vi: 'PBMS Smart Parking • Phiên bản 1.0.0 (Release 2026)',
      AppLanguage.en: 'PBMS Smart Parking • Version 1.0.0 (Release 2026)',
      AppLanguage.ja: 'PBMSスマートパーキング • バージョン 1.0.0 (2026年版)',
    },

    // =========================================================================
    // EDIT PROFILE SHEET
    // =========================================================================
    'edit_sheet_title': {
      AppLanguage.vi: 'Chỉnh sửa thông tin tài khoản',
      AppLanguage.en: 'Edit Account Profile',
      AppLanguage.ja: 'アカウント情報の編集',
    },
    'edit_sheet_desc': {
      AppLanguage.vi: 'Thông tin hiển thị trên biên lai điện tử PBMS',
      AppLanguage.en: 'Details displayed on PBMS electronic receipts',
      AppLanguage.ja: 'PBMS電子レシートに記載される情報',
    },
    'validate_name_req': {
      AppLanguage.vi: 'Vui lòng nhập họ và tên.',
      AppLanguage.en: 'Please enter your full name.',
      AppLanguage.ja: '氏名を入力してください。',
    },
    'validate_phone_req': {
      AppLanguage.vi: 'Vui lòng nhập số điện thoại liên lạc.',
      AppLanguage.en: 'Please enter your phone number.',
      AppLanguage.ja: '電話番号を入力してください。',
    },
    'btn_save_changes': {
      AppLanguage.vi: 'Lưu thay đổi',
      AppLanguage.en: 'Save Changes',
      AppLanguage.ja: '変更を保存',
    },
    'msg_profile_saved': {
      AppLanguage.vi: 'Cập nhật thông tin cá nhân thành công.',
      AppLanguage.en: 'Profile information updated successfully.',
      AppLanguage.ja: 'プロフィールが正常に更新されました。',
    },

    // =========================================================================
    // LANGUAGE SELECTOR MODAL
    // =========================================================================
    'modal_lang_title': {
      AppLanguage.vi: 'Chọn ngôn ngữ hệ thống',
      AppLanguage.en: 'Select System Language',
      AppLanguage.ja: 'システム言語の選択',
    },
    'modal_lang_desc': {
      AppLanguage.vi: 'Thay đổi toàn bộ giao diện và từ ngữ trong ứng dụng',
      AppLanguage.en: 'Instantly apply language to entire application interface',
      AppLanguage.ja: 'アプリケーション全体の表示言語を即座に切り替えます',
    },
    // =========================================================================
    // NAVIGATION & GENERAL
    // =========================================================================
    'nav_home': {
      AppLanguage.vi: 'Trang chủ',
      AppLanguage.en: 'Home',
      AppLanguage.ja: 'ホーム',
    },
    'nav_history': {
      AppLanguage.vi: 'Lịch sử',
      AppLanguage.en: 'History',
      AppLanguage.ja: '履歴',
    },
    'nav_services': {
      AppLanguage.vi: 'Dịch vụ',
      AppLanguage.en: 'Services',
      AppLanguage.ja: 'サービス',
    },
    'nav_profile': {
      AppLanguage.vi: 'Hồ sơ',
      AppLanguage.en: 'Profile',
      AppLanguage.ja: 'プロフィール',
    },
    'lang_switched_notice': {
      AppLanguage.vi: 'Đã đổi ngôn ngữ sang: ',
      AppLanguage.en: 'Language switched to: ',
      AppLanguage.ja: '言語を切り替えました: ',
    },

    // =========================================================================
    // HOME SCREEN & COCKPIT TELEMETRY
    // =========================================================================
    'home_cockpit_title': {
      AppLanguage.vi: 'PBMS Cockpit',
      AppLanguage.en: 'PBMS Cockpit',
      AppLanguage.ja: 'PBMS コックピット',
    },
    'home_active': {
      AppLanguage.vi: 'HOẠT ĐỘNG',
      AppLanguage.en: 'ACTIVE',
      AppLanguage.ja: '利用中',
    },
    'home_ready': {
      AppLanguage.vi: 'SẴN SÀNG',
      AppLanguage.en: 'READY',
      AppLanguage.ja: '待機中',
    },
    'session_active_status': {
      AppLanguage.vi: 'PHIÊN ĐỖ ĐANG HOẠT ĐỘNG',
      AppLanguage.en: 'ACTIVE PARKING SESSION',
      AppLanguage.ja: '利用中の駐車セッション',
    },
    'session_awaiting_veh': {
      AppLanguage.vi: 'CHỜ ĐĂNG KÝ XE',
      AppLanguage.en: 'AWAITING VEHICLE',
      AppLanguage.ja: '車両登録待ち',
    },
    'session_pending_payment': {
      AppLanguage.vi: 'CHỜ THANH TOÁN KÍCH HOẠT',
      AppLanguage.en: 'AWAITING PAYMENT ACTIVATION',
      AppLanguage.ja: '利用料金決済待ち',
    },
    'session_system_ready': {
      AppLanguage.vi: 'HỆ THỐNG SẴN SÀNG',
      AppLanguage.en: 'SYSTEM READY',
      AppLanguage.ja: 'システム準備完了',
    },
    'metric_license_plate': {
      AppLanguage.vi: 'BIỂN SỐ XE',
      AppLanguage.en: 'LICENSE PLATE',
      AppLanguage.ja: '車両ナンバー',
    },
    'metric_duration': {
      AppLanguage.vi: 'THỜI GIAN',
      AppLanguage.en: 'DURATION',
      AppLanguage.ja: '駐車時間',
    },
    'metric_estimated_fee': {
      AppLanguage.vi: 'TẠM TÍNH',
      AppLanguage.en: 'EST. FEE',
      AppLanguage.ja: '概算料金',
    },
    'btn_locate_car': {
      AppLanguage.vi: 'Định vị xe',
      AppLanguage.en: 'Locate Car',
      AppLanguage.ja: '車両位置',
    },
    'btn_parking_map': {
      AppLanguage.vi: 'Sơ đồ bãi đỗ',
      AppLanguage.en: 'Floor Map',
      AppLanguage.ja: '駐車場マップ',
    },
    'btn_pay_exit': {
      AppLanguage.vi: 'Thanh toán ra',
      AppLanguage.en: 'Pay & Exit',
      AppLanguage.ja: '精算・出庫',
    },
    'btn_register_vehicle_now': {
      AppLanguage.vi: 'Đăng ký xe ngay',
      AppLanguage.en: 'Register Vehicle',
      AppLanguage.ja: '車両を登録',
    },
    'btn_pay_activate': {
      AppLanguage.vi: 'Thanh toán kích hoạt',
      AppLanguage.en: 'Pay to Activate',
      AppLanguage.ja: '決済して有効化',
    },
    'btn_qr_entry': {
      AppLanguage.vi: 'Mã QR vào bãi',
      AppLanguage.en: 'Entry QR Pass',
      AppLanguage.ja: '入庫QRコード',
    },
    'btn_unlock_pass': {
      AppLanguage.vi: 'Mở vé vào bãi',
      AppLanguage.en: 'Unlock Pass',
      AppLanguage.ja: 'チケット解除',
    },
    'filter_all': {
      AppLanguage.vi: 'Tất cả',
      AppLanguage.en: 'All',
      AppLanguage.ja: 'すべて',
    },
    'filter_cars': {
      AppLanguage.vi: 'Ô tô',
      AppLanguage.en: 'Cars',
      AppLanguage.ja: '普通車',
    },
    'filter_bikes': {
      AppLanguage.vi: 'Xe máy',
      AppLanguage.en: 'Bikes',
      AppLanguage.ja: '二輪車',
    },
    'filter_monthly': {
      AppLanguage.vi: 'Vé tháng',
      AppLanguage.en: 'Monthly Pass',
      AppLanguage.ja: '定期券',
    },
    'filter_daily': {
      AppLanguage.vi: 'Vé lượt',
      AppLanguage.en: 'Single Entry',
      AppLanguage.ja: '一般利用',
    },
    'indicator_tap_to_unlock': {
      AppLanguage.vi: 'Chạm vào thẻ xe để xác thực mở khoá',
      AppLanguage.en: 'Tap vehicle pass to authenticate & unlock',
      AppLanguage.ja: 'カードをタップして認証解除',
    },
    'indicator_unlocked': {
      AppLanguage.vi: 'Thẻ đã mở khoá • Chạm để lật mã QR',
      AppLanguage.en: 'Pass Unlocked • Tap to flip QR',
      AppLanguage.ja: '認証完了 • タップしてQRコード表示',
    },
    'btn_lock': {
      AppLanguage.vi: 'Khoá lại',
      AppLanguage.en: 'Lock',
      AppLanguage.ja: 'ロック',
    },
    'lang_selector_banner_title': {
      AppLanguage.vi: 'GIAO DIỆN NGÔN NGỮ (LANGUAGE INTERFACE)',
      AppLanguage.en: 'LANGUAGE INTERFACE (NGÔN NGỮ HỆ THỐNG)',
      AppLanguage.ja: 'システム表示言語 (LANGUAGE INTERFACE)',
    },
    'facility_capacity_title': {
      AppLanguage.vi: 'SỨC CHỨA BÃI ĐỖ',
      AppLanguage.en: 'PARKING CAPACITY',
      AppLanguage.ja: '駐車場空き状況',
    },
    'available_percent': {
      AppLanguage.vi: 'KHẢ DỤNG',
      AppLanguage.en: 'AVAILABLE',
      AppLanguage.ja: '空車',
    },
    'recent_activity_title': {
      AppLanguage.vi: 'LỊCH SỬ VÀO / RA GẦN NHẤT',
      AppLanguage.en: 'RECENT ENTRY & EXIT LOGS',
      AppLanguage.ja: '最近の入出庫履歴',
    },
    'empty_vehicles_title': {
      AppLanguage.vi: 'Chưa có phương tiện nào',
      AppLanguage.en: 'No Vehicles Registered',
      AppLanguage.ja: '登録車両がありません',
    },
    'empty_vehicles_desc': {
      AppLanguage.vi: 'Đăng ký biển số xe để kích hoạt thẻ vé thông minh và nhận diện barrier tự động.',
      AppLanguage.en: 'Register your license plate to activate smart pass and barrier recognition.',
      AppLanguage.ja: 'ナンバープレートを登録してスマートパスと自動ゲートを有効化します。',
    },
    'btn_register_now': {
      AppLanguage.vi: 'Đăng ký phương tiện ngay',
      AppLanguage.en: 'Register Vehicle Now',
      AppLanguage.ja: '今すぐ車両を登録',
    },
    'register_vehicle_pill': {
      AppLanguage.vi: 'Đăng ký xe',
      AppLanguage.en: 'Add Vehicle',
      AppLanguage.ja: '車両登録',
    },
    'card_pending_payment': {
      AppLanguage.vi: 'CHỜ THANH TOÁN',
      AppLanguage.en: 'PENDING PAYMENT',
      AppLanguage.ja: '決済待ち',
    },
    'card_tap_to_unlock': {
      AppLanguage.vi: 'CHẠM ĐỂ MỞ',
      AppLanguage.en: 'TAP TO UNLOCK',
      AppLanguage.ja: 'タップして解除',
    },
    'card_unlocked': {
      AppLanguage.vi: 'ĐÃ MỞ KHOÁ',
      AppLanguage.en: 'UNLOCKED',
      AppLanguage.ja: '認証済み',
    },
    'card_tap_to_pay': {
      AppLanguage.vi: 'Chạm để thanh toán',
      AppLanguage.en: 'Tap to Pay',
      AppLanguage.ja: 'タップして決済',
    },
    'desktop_sidebar_cockpit': {
      AppLanguage.vi: 'Trang chủ Cockpit',
      AppLanguage.en: 'Cockpit Dashboard',
      AppLanguage.ja: 'コックピット',
    },
    'desktop_sidebar_history': {
      AppLanguage.vi: 'Lịch sử giao dịch',
      AppLanguage.en: 'Transaction History',
      AppLanguage.ja: '利用履歴',
    },
    'desktop_sidebar_services': {
      AppLanguage.vi: 'Dịch vụ bãi xe',
      AppLanguage.en: 'Parking Services',
      AppLanguage.ja: 'パーキングサービス',
    },
    'desktop_sidebar_profile': {
      AppLanguage.vi: 'Hồ sơ & Xe cá nhân',
      AppLanguage.en: 'Profile & Vehicles',
      AppLanguage.ja: 'プロフィール・車両',
    },
    'desktop_reserve_slot': {
      AppLanguage.vi: 'Đặt chỗ gửi xe',
      AppLanguage.en: 'Reserve Slot',
      AppLanguage.ja: '駐車枠予約',
    },
    'desktop_scan_qr': {
      AppLanguage.vi: 'Quét mã ra / vào',
      AppLanguage.en: 'Scan Entry / Exit',
      AppLanguage.ja: 'QRコードスキャン',
    },
    'floor_b1_cars': {
      AppLanguage.vi: 'TẦNG HẦM B1 (Ô TÔ)',
      AppLanguage.en: 'BASEMENT B1 (CARS)',
      AppLanguage.ja: '地下1階 B1 (普通車)',
    },
    'floor_b2_bikes': {
      AppLanguage.vi: 'TẦNG HẦM B2 (XE MÁY)',
      AppLanguage.en: 'BASEMENT B2 (BIKES)',
      AppLanguage.ja: '地下2階 B2 (二輪車)',
    },
    'floor_ev_charging': {
      AppLanguage.vi: 'KHU SẠC XE ĐIỆN (EV)',
      AppLanguage.en: 'EV CHARGING HUB',
      AppLanguage.ja: 'EV充電ステーション',
    },
    'slots_count_unit': {
      AppLanguage.vi: 'chỗ',
      AppLanguage.en: 'slots',
      AppLanguage.ja: '台',
    },
    'dock_cards': {
      AppLanguage.vi: 'Thẻ đỗ xe',
      AppLanguage.en: 'Pass Cards',
      AppLanguage.ja: '駐車カード',
    },
    'dock_list': {
      AppLanguage.vi: 'Danh sách xe',
      AppLanguage.en: 'Vehicle List',
      AppLanguage.ja: '車両一覧',
    },
    'card_flip_qr': {
      AppLanguage.vi: 'Lật xem QR',
      AppLanguage.en: 'Flip to view QR',
      AppLanguage.ja: 'QRコード表示',
    },
    'card_tap_fingerprint': {
      AppLanguage.vi: 'Chạm để quét vân tay',
      AppLanguage.en: 'Tap to scan fingerprint',
      AppLanguage.ja: '指紋認証で解除',
    },
  };

  /// Lấy chuỗi bản dịch theo key và ngôn ngữ hiện tại
  static String tr(String key) {
    final currentLang = LanguageController.instance.currentLanguage;
    final entry = _localizedValues[key];
    if (entry == null) return key;
    return entry[currentLang] ?? entry[AppLanguage.vi] ?? key;
  }
}

/// Extension tiện lợi trên BuildContext để gọi `context.tr('key')`
extension LocalizationContextExtension on BuildContext {
  String tr(String key) => AppTranslations.tr(key);
}
