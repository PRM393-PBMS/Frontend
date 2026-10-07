import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/services/biometric_service.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/theme/theme_controller.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/home/data/models/facility_availability_model.dart';
import 'package:prm393_frontend/features/home/data/models/monthly_subscription_model.dart';
import 'package:prm393_frontend/features/home/data/models/notification_model.dart';
import 'package:prm393_frontend/features/home/data/models/parking_session_model.dart';
import 'package:prm393_frontend/features/home/data/repositories/parking_repository.dart';
import 'package:prm393_frontend/core/services/vehicle_storage_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/vehicle_card_model.dart';
import '../widgets/add_vehicle_dialog.dart';
import '../widgets/payment_checkout_sheet.dart';
import '../widgets/notifications_bottom_sheet.dart';
import '../widgets/services_popup_sheet.dart';
import '../widgets/ultrasonic_fingerprint_dialog.dart';
import '../widgets/vehicle_card_item.dart';
import '../widgets/vehicle_carousel.dart';
import '../widgets/wallet_banner.dart';
import '../widgets/wallet_quick_dock.dart';

/// Real-Time Driver Cockpit & Smart Vehicle Vault
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Trạng thái mở khoá vân tay
  bool _isCardUnlocked = false;

  // Selected category filter
  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Tất cả',
      'icon': Icons.all_inclusive_rounded,
    },
    {
      'label': 'Ô tô',
      'icon': Icons.directions_car_rounded,
    },
    {
      'label': 'Xe máy',
      'icon': Icons.two_wheeler_rounded,
    },
    {
      'label': 'Vé tháng',
      'icon': Icons.card_membership_rounded,
    },
    {
      'label': 'Vé lượt',
      'icon': Icons.confirmation_number_outlined,
    },
  ];

  // Quick Dock Mode (Thẻ xe vs Danh sách)
  WalletDockMode _dockMode = WalletDockMode.quickAccess;

  // Active vehicle index in carousel
  int _activeCardIndex = 0;

  // Real data state from Backend
  ParkingSessionModel? _activeSession;
  double _activeSessionFee = 25000;
  List<ParkingSessionModel> _recentSessions = [];
  List<FacilityAvailabilityModel> _facilityFloors = [];
  List<NotificationModel> _notifications = [];
  bool _isLoadingBackend = false;

  // Vehicles list (maps from real subscriptions and user-registered vehicles)
  List<VehicleCardModel> _allVehicles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  /// Nối toàn bộ API Backend PBMS: Phiên gửi xe, Gói tháng xe, Sức chứa bãi đỗ, Thông báo
  Future<void> _loadHomeData() async {
    if (!mounted) return;
    setState(() => _isLoadingBackend = true);

    try {
      final repo = context.read<ParkingRepository>();
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;

      final results = await Future.wait([
        repo.getMySessions(),
        repo.getMySubscriptions(),
        repo.getFacilityAvailability(),
        repo.getMyNotifications(),
      ]);

      final sessions = results[0] as List<ParkingSessionModel>;
      final subs = results[1] as List<MonthlySubscriptionModel>;
      final avail = results[2] as List<FacilityAvailabilityModel>;
      final notifs = results[3] as List<NotificationModel>;

      // 1. Tìm phiên gửi xe đang hoạt động (Active)
      ParkingSessionModel? active;
      for (final s in sessions) {
        if (s.isActive) {
          active = s;
          break;
        }
      }

      // 2. Lấy cước tạm tính thời gian thực từ API fee-preview
      double fee = 25000;
      if (active != null) {
        final feeData = await repo.getSessionFeePreview(active.sessionId);
        if (feeData['amount'] != null) {
          fee = (feeData['amount'] as num).toDouble();
        }
      }

      // 3. Lấy danh sách xe đã đăng ký lưu trong Local Storage của tài xế
      final localVehicles = await VehicleStorageService.instance.getVehicles(userId: userId);

      // 4. Danh sách xe: Map từ các gói tháng (MonthlySubscription) của tài xế trên DB
      List<VehicleCardModel> vehicles = [];
      if (subs.isNotEmpty) {
        vehicles.addAll(subs.map((s) => VehicleCardModel.fromSubscription(s)));
      }

      // 5. Kết hợp với xe đã đăng ký lưu trong Local Storage (khử trùng theo biển số)
      for (final lv in localVehicles) {
        final norm = lv.licensePlate.replaceAll(RegExp(r'[^A-Z0-9]'), '');
        final exists = vehicles.any((v) =>
            v.licensePlate.replaceAll(RegExp(r'[^A-Z0-9]'), '') == norm);
        if (!exists) {
          vehicles.add(lv);
        }
      }

      // 6. Nếu có phiên đang đỗ mà xe đó chưa có trong ví, chèn thẻ lượt lên đầu
      if (active != null) {
        final activeNorm = active.licensePlateIn.replaceAll(RegExp(r'[^A-Z0-9]'), '');
        final exists = vehicles.any((v) =>
            v.licensePlate.replaceAll(RegExp(r'[^A-Z0-9]'), '') == activeNorm);
        if (!exists) {
          vehicles.insert(0, VehicleCardModel.fromSession(active));
        }
      }

      // 7. Giữ nguyên danh sách thực tế của tài xế (không tự chèn xe mẫu)
      // Nếu danh sách trống, giao diện sẽ hiển thị thẻ rỗng hướng dẫn đăng ký xe trực quan.

      final recent = sessions.where((s) => !s.isActive).take(5).toList();

      if (mounted) {
        setState(() {
          _activeSession = active;
          _activeSessionFee = fee;
          _recentSessions = recent;
          _facilityFloors = avail;
          _notifications = notifs;
          _allVehicles = vehicles;
          _isLoadingBackend = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBackend = false);
    }
  }

  // Filtered vehicles based on category
  List<VehicleCardModel> get _filteredVehicles {
    switch (_selectedCategoryIndex) {
      case 1:
        return _allVehicles.where((v) => v.type == VehicleType.car).toList();
      case 2:
        return _allVehicles.where((v) => v.type == VehicleType.motorcycle).toList();
      case 3:
        return _allVehicles.where((v) => v.isMonthlyActive).toList();
      case 4:
        return _allVehicles.where((v) => !v.isMonthlyActive).toList();
      default:
        return _allVehicles;
    }
  }

  VehicleCardModel get _currentVehicle {
    if (_filteredVehicles.isEmpty) {
      if (_allVehicles.isNotEmpty) return _allVehicles.first;
      return VehicleCardModel.defaultEmpty;
    }
    final index = _activeCardIndex.clamp(0, _filteredVehicles.length - 1);
    return _filteredVehicles[index];
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildTopCockpitAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;

          if (isWide) {
            // ================================================================
            // DESKTOP / WIDE 2-COLUMN COCKPIT
            // ================================================================
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AuthBloc>().add(AuthCheckRequested());
                await _loadHomeData();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột trái: Cockpit trọng tâm (Live Session + Thẻ xe)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const WalletBanner(),
                          const SizedBox(height: 18),
                          _buildActiveSessionCard(context),
                          const SizedBox(height: 24),
                          _buildCategoryPills(context),
                          const SizedBox(height: 16),
                          if (_dockMode == WalletDockMode.quickAccess) ...[
                            VehicleCarousel(
                              key: ValueKey('${_selectedCategoryIndex}_${_allVehicles.length}'),
                              cards: _filteredVehicles,
                              isUnlocked: _isCardUnlocked,
                              onTapToUnlock: () => _triggerBiometricAuth(),
                              onAddVehicle: () => _showAddVehicleBottomSheet(context),
                              onTapPendingPayment: _openPaymentForVehicle,
                              onCardChanged: (index) {
                                setState(() {
                                  _activeCardIndex = index;
                                  _isCardUnlocked = false;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Center(child: _buildUnlockStatusIndicator(context)),
                          ] else ...[
                            _buildAllCardsVerticalList(context),
                          ],
                          const SizedBox(height: 20),
                          Center(
                            child: WalletQuickDock(
                              currentMode: _dockMode,
                              onModeChanged: (mode) => setState(() => _dockMode = mode),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Cột phải: Live Telemetry Inspector & Sơ đồ tầng
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFacilityInspectorCard(context, margin: EdgeInsets.zero),
                          const SizedBox(height: 20),
                          _buildRecentActivityCard(context, margin: EdgeInsets.zero),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ================================================================
          // MOBILE COCKPIT (SINGLE COLUMN, REAL-TIME SESSION TOP FOCUS)
          // ================================================================
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckRequested());
              await _loadHomeData();
            },
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                SizedBox(height: context.space(8)),

                // 1. BANNER ƯU ĐÃI & THÔNG BÁO HỆ THỐNG
                const WalletBanner(),
                SizedBox(height: context.space(14)),

                // 2. HERO COCKPIT: PHIÊN GỬI XE THỜI GIAN THỰC (ĐƯA LÊN ĐẦU TIÊN)
                _buildActiveSessionCard(context),
                SizedBox(height: context.space(20)),

                // 3. THANH TAB LỌC XE & VÉ
                _buildCategoryPills(context),
                SizedBox(height: context.space(14)),

                // 4. VÍ THẺ PHƯƠNG TIỆN KỸ THUẬT SỐ (DIGITAL PASS CAROUSEL)
                if (_dockMode == WalletDockMode.quickAccess) ...[
                  VehicleCarousel(
                    key: ValueKey('${_selectedCategoryIndex}_${_allVehicles.length}'),
                    cards: _filteredVehicles,
                    isUnlocked: _isCardUnlocked,
                    onTapToUnlock: () => _triggerBiometricAuth(),
                    onAddVehicle: () => _showAddVehicleBottomSheet(context),
                    onTapPendingPayment: _openPaymentForVehicle,
                    onCardChanged: (index) {
                      setState(() {
                        _activeCardIndex = index;
                        _isCardUnlocked = false;
                      });
                    },
                  ),
                  SizedBox(height: context.space(12)),
                  Center(child: _buildUnlockStatusIndicator(context)),
                ] else ...[
                  _buildAllCardsVerticalList(context),
                ],

                SizedBox(height: context.space(20)),

                // 5. CHUYỂN ĐỔI CHẾ ĐỘ XEM VÍ (THẺ XE VS TẤT CẢ)
                Center(
                  child: WalletQuickDock(
                    currentMode: _dockMode,
                    onModeChanged: (mode) => setState(() => _dockMode = mode),
                  ),
                ),

                SizedBox(height: context.space(20)),

                // 6. SỨC CHỨA BÃI ĐỖ XE THỜI GIAN THỰC (REAL-TIME FACILITY CAPACITY)
                _buildFacilityInspectorCard(
                  context,
                  margin: EdgeInsets.symmetric(horizontal: context.space(16)),
                ),

                SizedBox(height: context.space(16)),

                // 7. LỊCH SỬ VÀO / RA GẦN NHẤT
                _buildRecentActivityCard(
                  context,
                  margin: EdgeInsets.symmetric(horizontal: context.space(16)),
                ),

                // Safe padding cho Floating Nav Bar
                SizedBox(height: context.space(88) + bottomPad),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TOP APP BAR: PRECISION COCKPIT HEADER (CHỈ GỒM 2 BIỂU TƯỢNG: 3 CHẤM VÀ THÔNG BÁO)
  // ===========================================================================
  PreferredSizeWidget _buildTopCockpitAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return AppBar(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: _isLoadingBackend
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: isDark ? AppColors.primary : const Color(0xFF0284C7),
              ),
            )
          : null,
      title: Row(
        children: [
          Text(
            'PBMS Cockpit',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: fgColor,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(width: context.space(8)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.available.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.available.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.available,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _activeSession != null ? 'ACTIVE' : 'READY',
                  style: AppTypography.badgeMono.copyWith(
                    color: AppColors.available,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // 1. BIỂU TƯỢNG THÔNG BÁO (NOTIFICATION BELL VỚI BADGE SỐ ĐẾM)
        IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              '$unreadCount',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.error,
            child: Icon(
              unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              size: context.iconSize(22),
              color: unreadCount > 0
                  ? (isDark ? AppColors.primary : const Color(0xFF0284C7))
                  : fgColor,
            ),
          ),
          tooltip: 'Thông báo hệ thống ($unreadCount chưa đọc)',
          onPressed: () {
            HapticFeedback.lightImpact();
            final repo = context.read<ParkingRepository>();
            NotificationsBottomSheet.show(
              context,
              notifications: _notifications,
              repository: repo,
              onNotificationsUpdated: _loadHomeData,
            );
          },
        ),

        // 2. BIỂU TƯỢNG 3 CHẤM (MORE OPTIONS)
        IconButton(
          icon: Icon(Icons.more_horiz_rounded, size: context.iconSize(24)),
          tooltip: 'Tuỳ chọn',
          color: fgColor,
          onPressed: () {
            HapticFeedback.lightImpact();
            _showWalletOptions(context);
          },
        ),
        SizedBox(width: context.space(8)),
      ],
    );
  }

  // ===========================================================================
  // HERO: PHIÊN GỬI XE THỜI GIAN THỰC (REAL-TIME TELEMETRY CARD)
  // ===========================================================================
  Widget _buildActiveSessionCard(BuildContext context) {
    final vehicle = _currentVehicle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveSession = _activeSession != null;

    final hasVehicle = _allVehicles.isNotEmpty;

    final displayPlate = hasActiveSession
        ? _activeSession!.licensePlateIn
        : (hasVehicle ? vehicle.licensePlate : 'CHƯA ĐĂNG KÝ XE');

    final displayDuration = hasActiveSession
        ? _activeSession!.formattedDuration
        : '00h 00m';

    final displayFee = hasActiveSession
        ? (_activeSessionFee == 0 ? 'Gói tháng' : CurrencyFormatter.format(_activeSessionFee))
        : '0 đ';

    final locationTag = hasActiveSession
        ? (_activeSession!.assignedSlotCode != null
            ? 'Ô ${_activeSession!.assignedSlotCode}'
            : (_activeSession!.entryGateName != null
                ? 'CỔNG ${_activeSession!.entryGateName}'
                : 'BÃI ĐỖ PBMS'))
        : (hasVehicle ? vehicle.parkingSlot : 'CỔNG TỰ ĐỘNG');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.space(16)),
      padding: EdgeInsets.all(context.space(16)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(context.space(16)),
        border: Border.all(
          color: hasActiveSession
              ? (isDark ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFF38BDF8))
              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Live Pulse Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasActiveSession ? AppColors.available : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: context.space(8)),
                  Text(
                    hasActiveSession
                        ? 'PHIÊN ĐỖ ĐANG HOẠT ĐỘNG'
                        : (!hasVehicle
                            ? 'CHỜ ĐĂNG KÝ XE'
                            : (_currentVehicle.paymentStatus == 'PendingPayment'
                                ? 'CHỜ THANH TOÁN KÍCH HOẠT'
                                : 'HỆ THỐNG SẴN SÀNG')),
                    style: AppTypography.badgeMono.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontSize: context.sp(11),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : const Color(0xFFBAE6FD),
                  ),
                ),
                child: Text(
                  locationTag,
                  style: AppTypography.badgeMono.copyWith(
                    color: isDark ? AppColors.primary : const Color(0xFF0369A1),
                    fontSize: context.sp(9.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.space(14)),

          // 3-Metric Precision Grid
          Container(
            padding: EdgeInsets.all(context.space(12)),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(context.space(12)),
              border: Border.all(
                color: isDark ? AppColors.borderSubtleDark : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Biển số xe
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'BIỂN SỐ XE',
                          style: AppTypography.badgeMono.copyWith(
                            fontSize: context.sp(9.5),
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        SizedBox(height: context.space(3)),
                        Text(
                          displayPlate,
                          style: AppTypography.licensePlateMono.copyWith(
                            fontSize: context.sp(13.5),
                            height: 1.2,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    width: context.space(16),
                    thickness: 1,
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  ),

                  // Thời gian gửi (JetBrains Mono timer)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'THỜI GIAN',
                          style: AppTypography.badgeMono.copyWith(
                            fontSize: context.sp(9.5),
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        SizedBox(height: context.space(3)),
                        Text(
                          displayDuration,
                          style: AppTypography.telemetryMono.copyWith(
                            fontSize: context.sp(14),
                            height: 1.2,
                            color: isDark ? AppColors.primary : const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    width: context.space(16),
                    thickness: 1,
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  ),

                  // Phí tạm tính
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TẠM TÍNH',
                          style: AppTypography.badgeMono.copyWith(
                            fontSize: context.sp(9.5),
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        SizedBox(height: context.space(3)),
                        Text(
                          displayFee,
                          style: AppTypography.telemetryMono.copyWith(
                            fontSize: context.sp(14),
                            height: 1.2,
                            color: AppColors.available,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.space(14)),

          // Bottom Action Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (hasActiveSession) {
                      _showVehicleLocationModal(context, _activeSession!);
                    } else {
                      _showParkingMapModal(context);
                    }
                  },
                  icon: Icon(
                    hasActiveSession ? Icons.explore_outlined : Icons.map_outlined,
                    size: context.iconSize(16),
                  ),
                  label: Text(hasActiveSession ? 'Định vị xe' : 'Sơ đồ bãi đỗ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                    padding: EdgeInsets.symmetric(vertical: context.space(11)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.space(10))),
                  ),
                ),
              ),
              SizedBox(width: context.space(10)),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    if (hasActiveSession) {
                      _handleCheckoutSession(context, _activeSession!);
                    } else if (!hasVehicle) {
                      _showAddVehicleBottomSheet(context);
                    } else if (_currentVehicle.paymentStatus == 'PendingPayment') {
                      _openPaymentForVehicle(_currentVehicle);
                    } else {
                      if (!_isCardUnlocked) {
                        final ok = await _triggerBiometricAuth();
                        if (ok && context.mounted) {
                          _showVehicleQREntryModal(context, _currentVehicle);
                        }
                      } else {
                        _showVehicleQREntryModal(context, _currentVehicle);
                      }
                    }
                  },
                  icon: Icon(
                    hasActiveSession
                        ? Icons.qr_code_scanner_rounded
                        : (!hasVehicle
                            ? Icons.add_circle_outline_rounded
                            : (_currentVehicle.paymentStatus == 'PendingPayment'
                                ? Icons.payment_rounded
                                : (_isCardUnlocked ? Icons.qr_code_rounded : Icons.fingerprint_rounded))),
                    size: context.iconSize(16),
                  ),
                  label: Text(
                    hasActiveSession
                        ? 'Thanh toán ra'
                        : (!hasVehicle
                            ? 'Đăng ký xe ngay'
                            : (_currentVehicle.paymentStatus == 'PendingPayment'
                                ? 'Thanh toán kích hoạt'
                                : (_isCardUnlocked ? 'Mã QR vào bãi' : 'Mở vé vào bãi'))),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentVehicle.paymentStatus == 'PendingPayment' && !hasActiveSession
                        ? const Color(0xFFF59E0B)
                        : (isDark ? AppColors.primary : const Color(0xFF090D14)),
                    foregroundColor: _currentVehicle.paymentStatus == 'PendingPayment' && !hasActiveSession
                        ? Colors.white
                        : (isDark ? const Color(0xFF090D14) : Colors.white),
                    padding: EdgeInsets.symmetric(vertical: context.space(11)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.space(10))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CATEGORY PILLS (TAB PHÂN LOẠI NHANH NẰM TRÊN THẺ)
  // ===========================================================================
  Widget _buildCategoryPills(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.space(16)),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: context.space(38),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: context.space(8)),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategoryIndex == index;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategoryIndex = index;
                        _activeCardIndex = 0;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.space(14),
                        vertical: context.space(6),
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.primary : const Color(0xFF090D14))
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(context.space(21)),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.primary : const Color(0xFF090D14))
                              : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: context.iconSize(14),
                            color: isSelected
                                ? (isDark ? const Color(0xFF090D14) : Colors.white)
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                          SizedBox(width: context.space(6)),
                          Text(
                            cat['label'] as String,
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: context.sp(11.5),
                              height: 1.15,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF090D14) : Colors.white)
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: context.space(8)),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showAddVehicleBottomSheet(context);
            },
            borderRadius: BorderRadius.circular(context.space(21)),
            child: Container(
              height: context.space(38),
              padding: EdgeInsets.symmetric(horizontal: context.space(12)),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary.withValues(alpha: 0.16) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(context.space(21)),
                border: Border.all(
                  color: isDark ? AppColors.primary.withValues(alpha: 0.45) : const Color(0xFF93C5FD),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: context.iconSize(15),
                    color: isDark ? AppColors.primary : const Color(0xFF0284C7),
                  ),
                  SizedBox(width: context.space(5)),
                  Text(
                    'Đăng ký xe',
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: context.sp(11.5),
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.primary : const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ALL CARDS VERTICAL LIST (KHI CHỌN MODE "TẤT CẢ XE")
  // ===========================================================================
  Widget _buildAllCardsVerticalList(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.space(16)),
      child: Column(
        children: _filteredVehicles.map((card) {
          final isUnlocked = _isCardUnlocked && _currentVehicle.id == card.id;
          return Padding(
            padding: EdgeInsets.only(bottom: context.space(14)),
            child: VehicleCardItem(
              card: card,
              isUnlocked: isUnlocked,
              onTapToUnlock: () => _triggerBiometricAuth(vehicle: card),
              onTapPendingPayment: () => _openPaymentForVehicle(card),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP & MOBILE LIVE FACILITY INSPECTOR (SỨC CHỨA BÃI ĐỖ XE THỜI GIAN THỰC)
  // ===========================================================================
  Widget _buildFacilityInspectorCard(BuildContext context, {EdgeInsetsGeometry? margin}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAll = _facilityFloors.fold<int>(0, (sum, f) => sum + f.totalSlots);
    final availAll = _facilityFloors.fold<int>(0, (sum, f) => sum + f.availableSlots);
    final percentAvail = totalAll > 0 ? ((availAll / totalAll) * 100).round() : 86;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SỨC CHỨA BÃI ĐỖ',
                style: AppTypography.badgeMono.copyWith(color: AppColors.primary),
              ),
              Text(
                '$percentAvail% KHẢ DỤNG',
                style: AppTypography.badgeMono.copyWith(color: AppColors.available),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_facilityFloors.isNotEmpty)
            ..._facilityFloors.map((floor) {
              final occupied = floor.occupiedSlots + floor.assignedSlots;
              final ratio = floor.totalSlots > 0 ? occupied / floor.totalSlots : 0.0;
              final color = ratio > 0.85
                  ? AppColors.error
                  : (ratio > 0.6 ? AppColors.reserved : AppColors.available);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFloorRow(
                  '${floor.floorName.toUpperCase()} (${floor.vehicleTypeName.toUpperCase()})',
                  occupied,
                  floor.totalSlots,
                  color,
                ),
              );
            })
          else ...[
            _buildFloorRow('TẦNG HẦM B1 (Ô TÔ)', 42, 50, AppColors.available),
            const SizedBox(height: 12),
            _buildFloorRow('TẦNG HẦM B2 (XE MÁY)', 88, 120, AppColors.available),
            const SizedBox(height: 12),
            _buildFloorRow('KHU SẠC XE ĐIỆN (EV)', 8, 10, AppColors.reserved),
          ],
        ],
      ),
    );
  }

  Widget _buildFloorRow(String title, int occupied, int total, Color color) {
    final ratio = total > 0 ? (occupied / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            Text(
              '$occupied / $total chỗ',
              style: AppTypography.telemetryMono.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: AppColors.borderDark,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, {EdgeInsetsGeometry? margin}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LỊCH SỬ VÀO / RA GẦN NHẤT',
            style: AppTypography.badgeMono.copyWith(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 14),
          if (_recentSessions.isNotEmpty)
            ..._recentSessions.take(3).map((s) {
              final isExit = s.exitTime != null;
              final title = '${s.licensePlateIn} • ${isExit ? (s.exitGateName != null ? "Ra ${s.exitGateName}" : "Đã checkout") : (s.entryGateName != null ? "Vào ${s.entryGateName}" : "Vào bãi")}';
              final time = '${s.entryTime.hour.toString().padLeft(2, '0')}:${s.entryTime.minute.toString().padLeft(2, '0')} • ${s.entryTime.day.toString().padLeft(2, '0')}/${s.entryTime.month.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActivityItem(
                  title,
                  time,
                  isExit ? Icons.logout_rounded : Icons.login_rounded,
                  isExit ? AppColors.secondary : AppColors.available,
                ),
              );
            })
          else ...[
            _buildActivityItem('VinFast VF 8 • Vào cổng A', '14:22 • Hôm nay', Icons.login_rounded, AppColors.available),
            const Divider(height: 20),
            _buildActivityItem('Honda SH • Ra cổng B', '09:15 • Hôm qua', Icons.logout_rounded, AppColors.secondary),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 12.5)),
              Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MODALS & DIALOGS
  // ===========================================================================
  void _showAddVehicleBottomSheet(BuildContext context) {
    AddVehicleBottomSheet.show(
      context,
      onVehicleRegistered: (newVehicle) async {
        setState(() {
          // Xoá các xe mock nếu danh sách chỉ đang chứa xe mẫu
          if (_allVehicles.isNotEmpty && _allVehicles.any((v) => v.id.startsWith('mock_'))) {
            _allVehicles = _allVehicles.where((v) => !v.id.startsWith('mock_')).toList();
          }
          _allVehicles.insert(0, newVehicle);
          _activeCardIndex = 0;
          _selectedCategoryIndex = 0;
        });

        if (!newVehicle.isPendingPayment) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.available, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đã đăng ký vé lượt cho xe [${newVehicle.licensePlate}] thành công!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.borderDark),
              ),
            ),
          );
        }

        await _loadHomeData();

        // Nếu là vé tháng đang chờ thanh toán, mở checkout sau khi modal đăng ký đóng hoàn toàn
        if (newVehicle.isPendingPayment && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openPaymentForVehicle(newVehicle);
            }
          });
        }
      },
    );
  }

  void _openPaymentForVehicle(VehicleCardModel veh) {
    final userId = context.read<AuthBloc>().state.user?.id;
    final repo = context.read<ParkingRepository>();

    PaymentCheckoutBottomSheet.show(
      context,
      vehicle: veh,
      onPaymentSuccess: (activatedVeh) async {
        setState(() {
          final idx = _allVehicles.indexWhere((v) => v.id == activatedVeh.id);
          if (idx != -1) {
            _allVehicles[idx] = activatedVeh;
          }
        });
        await VehicleStorageService.instance.saveVehicle(activatedVeh, userId: userId);

        try {
          await repo.registerSubscription({
            'licensePlate': activatedVeh.licensePlate.replaceAll(RegExp(r'[^A-Z0-9]'), ''),
            'vehicleTypeId': activatedVeh.type == VehicleType.car ? 'car' : 'motorcycle',
            'durationMonths': activatedVeh.billingMonths,
          });
        } catch (_) {}

        await _loadHomeData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.available, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đã thanh toán kích hoạt thành công xe ${activatedVeh.licensePlate}!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.surfaceDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onPaymentPending: (pendingVeh) async {
        await VehicleStorageService.instance.saveVehicle(pendingVeh, userId: userId);
      },
    );
  }

  void _showWalletOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tuỳ chọn hệ thống PBMS',
                    style: AppTypography.titleLarge.copyWith(fontSize: 17),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),
              // 1. Chuyển đổi theme Sáng / Tối
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFFFBBF24) : const Color(0xFF0F172A)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF0F172A),
                    size: 20,
                  ),
                ),
                title: Text(
                  isDark ? 'Chuyển sang giao diện Sáng' : 'Chuyển sang giao diện Tối',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isDark ? 'Nền sáng sạch sẽ, tối ưu ánh sáng ban ngày' : 'Nền đen OLED sâu, bảo vệ thị lực ban đêm',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) {
                    Navigator.pop(ctx);
                    ThemeController.instance.toggleTheme();
                  },
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ThemeController.instance.toggleTheme();
                },
              ),
              // 2. Thêm phương tiện mới
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text('Thêm phương tiện mới', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Đăng ký thêm xe ô tô / xe máy vào ví điện tử', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddVehicleBottomSheet(context);
                },
              ),
              // 3. Tiện ích & dịch vụ bãi xe
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_car_wash_rounded, color: AppColors.secondary, size: 20),
                ),
                title: Text('Dịch vụ & Tiện ích bãi xe', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Trạm sạc EV, Rửa xe tự động, Bơm lốp kỹ thuật số', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  ServicesPopupSheet.show(context);
                },
              ),
              // 4. Cài đặt NFC chạm nhanh
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.available.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.contactless_rounded, color: AppColors.available, size: 20),
                ),
                title: Text('Cài đặt NFC chạm nhanh', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Bật chạm không cần mở khoá màn hình điện thoại', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng NFC một chạm tại barrier đã được bật sẵn sàng!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              // 5. Bảo mật sinh trắc học
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.maintenance.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: AppColors.maintenance, size: 20),
                ),
                title: Text('Bảo mật sinh trắc học', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Xác thực vân tay trước khi lật vé QR vào/ra bãi', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _triggerBiometricAuth();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVehicleLocationModal(BuildContext context, ParkingSessionModel session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vị trí phương tiện trong bãi', style: AppTypography.titleLarge),
                        Text(
                          'Cảm biến định vị tự động PBMS',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLocationInfoTile(
                'Biển số xe',
                session.licensePlateIn,
                Icons.directions_car_rounded,
                isDark,
              ),
              _buildLocationInfoTile(
                'Vị trí ô đỗ',
                session.assignedSlotCode != null ? 'Ô ${session.assignedSlotCode}' : (session.actualSlotCode ?? 'Đang trong bãi'),
                Icons.local_parking_rounded,
                isDark,
                highlight: true,
              ),
              _buildLocationInfoTile(
                'Cổng vào',
                session.entryGateName ?? 'Cổng kiểm soát chính',
                Icons.login_rounded,
                isDark,
              ),
              _buildLocationInfoTile(
                'Thời điểm vào bãi',
                '${session.entryTime.hour.toString().padLeft(2, '0')}:${session.entryTime.minute.toString().padLeft(2, '0')} • ${session.entryTime.day.toString().padLeft(2, '0')}/${session.entryTime.month.toString().padLeft(2, '0')}/${session.entryTime.year}',
                Icons.access_time_rounded,
                isDark,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showParkingMapModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Sơ đồ & Khả dụng các tầng đỗ', style: AppTypography.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Dữ liệu cảm biến thông minh theo thời gian thực',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 16),
              if (_facilityFloors.isNotEmpty)
                ..._facilityFloors.map((floor) {
                  final occupied = floor.occupiedSlots + floor.assignedSlots;
                  final ratio = floor.totalSlots > 0 ? occupied / floor.totalSlots : 0.0;
                  final color = ratio > 0.85
                      ? AppColors.error
                      : (ratio > 0.6 ? AppColors.reserved : AppColors.available);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildFloorRow(
                      '${floor.floorName.toUpperCase()} (${floor.vehicleTypeName.toUpperCase()})',
                      occupied,
                      floor.totalSlots,
                      color,
                    ),
                  );
                })
              else ...[
                _buildFloorRow('TẦNG HẦM B1 (Ô TÔ)', 42, 50, AppColors.available),
                const SizedBox(height: 12),
                _buildFloorRow('TẦNG HẦM B2 (XE MÁY)', 88, 120, AppColors.available),
                const SizedBox(height: 12),
                _buildFloorRow('KHU SẠC XE ĐIỆN (EV)', 8, 10, AppColors.reserved),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVehicleQREntryModal(BuildContext context, VehicleCardModel vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dynamicPayload = 'PBMS-GATE-IN|${vehicle.licensePlate}|${vehicle.nfcTagId}|${now.millisecondsSinceEpoch ~/ 30000}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thẻ vé điện tử vào bãi', style: AppTypography.titleLarge),
                        Text(
                          'Quét tại Camera Barrier hoặc chạm cảm biến NFC',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Thẻ hiển thị QR Code động
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderSubtleDark : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Text(
                      vehicle.licensePlate,
                      style: AppTypography.licensePlateMono.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.vehicleName} • ${vehicle.ticketType}',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: dynamicPayload,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.nfc_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Mã NFC PBMS: ${vehicle.nfcTagId}',
                          style: AppTypography.badgeMono.copyWith(fontSize: 10.5, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCheckoutSession(BuildContext context, ParkingSessionModel session) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.read<ParkingRepository>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final paymentData = await repo.getCheckoutPayment(session.sessionId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final onlinePayment = paymentData['OnlinePayment'] as Map<String, dynamic>?;
      final payment = paymentData['Payment'] as Map<String, dynamic>?;

      if (onlinePayment != null && onlinePayment['paymentUrl'] != null) {
        final paymentUrl = onlinePayment['paymentUrl'] as String;
        final orderCode = onlinePayment['orderCode']?.toString() ?? '';
        final amount = (payment?['amount'] as num?)?.toDouble() ?? _activeSessionFee;

        _showPayOSCheckoutDialog(
          context,
          session: session,
          paymentUrl: paymentUrl,
          orderCode: orderCode,
          amount: amount,
        );
      } else if (_activeSessionFee == 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.available, size: 24),
                const SizedBox(width: 10),
                const Text('Gói tháng miễn phí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Xe ${session.licensePlateIn} thuộc gói cước tháng đang hoạt động. Cước gửi xe là 0 đ. Barrier cổng ra sẽ tự động nhận diện và mở cửa khi xe tiến ra.',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                const Text('Thanh toán ra bãi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cước phí tạm tính hiện tại: ${CurrencyFormatter.format(_activeSessionFee)}',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.available),
                ),
                const SizedBox(height: 10),
                Text(
                  'Vui lòng di chuyển xe đến cổng kiểm soát ra. Cảm biến OCR sẽ tự động quét biển số xe ${session.licensePlateIn} và kết nối VietQR PayOS trực tiếp tại barrier.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _triggerBiometricAuth();
                },
                child: const Text('Mở thẻ QR vé'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kết nối đến máy chủ thanh toán PBMS'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPayOSCheckoutDialog(
    BuildContext context, {
    required ParkingSessionModel session,
    required String paymentUrl,
    required String orderCode,
    required double amount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.available.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: AppColors.available, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VietQR PayOS Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Xe ${session.licensePlateIn}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: QrImageView(
                data: paymentUrl,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              CurrencyFormatter.format(amount),
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.available,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mã đơn: #$orderCode',
              style: AppTypography.badgeMono.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quét bằng ứng dụng ngân hàng hoặc Mobile Money để mở barrier cổng ra tự động.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _loadHomeData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang cập nhật trạng thái thanh toán từ PayOS...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Đã thanh toán'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoTile(String title, String value, IconData icon, bool isDark, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: highlight ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          const SizedBox(width: 12),
          Text(title, style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockStatusIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isCardUnlocked) {
      return GestureDetector(
        onTap: () => _triggerBiometricAuth(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.space(16),
            vertical: context.space(8),
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(context.space(20)),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint_rounded,
                size: context.iconSize(17),
                color: AppColors.primary,
              ),
              SizedBox(width: context.space(6)),
              Text(
                'Chạm vào thẻ xe để xác thực mở khoá',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space(14),
        vertical: context.space(7),
      ),
      decoration: BoxDecoration(
        color: AppColors.available.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.space(20)),
        border: Border.all(color: AppColors.available.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.available),
          SizedBox(width: context.space(6)),
          Text(
            'Thẻ đã mở khoá • Chạm để lật mã QR',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(width: context.space(8)),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isCardUnlocked = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Khoá lại',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _triggerBiometricAuth({VehicleCardModel? vehicle}) async {
    final target = vehicle ?? _currentVehicle;
    final canAuth = await BiometricService.instance.canAuthenticate();
    bool success = false;

    if (canAuth) {
      success = await BiometricService.instance.authenticateWithDevice(
        reason: 'Xác thực vân tay mở khoá thẻ xe ${target.licensePlate}',
      );
    } else {
      if (!mounted) return false;
      success = await UltrasonicFingerprintDialog.authenticate(
        context,
        vehiclePlate: target.licensePlate,
      );
    }

    if (!mounted) return false;
    if (success) {
      setState(() => _isCardUnlocked = true);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã xác thực mở khoá thẻ ${target.licensePlate}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.borderDark),
          ),
        ),
      );
      return true;
    }
    return false;
  }
}
