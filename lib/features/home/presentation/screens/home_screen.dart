import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/services/biometric_service.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';

import '../models/vehicle_card_model.dart';
import '../widgets/services_popup_sheet.dart';
import '../widgets/ultrasonic_fingerprint_dialog.dart';
import '../widgets/vehicle_card_item.dart';
import '../widgets/vehicle_carousel.dart';
import '../widgets/wallet_banner.dart';
import '../widgets/wallet_quick_dock.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Trạng thái mở khoá vân tay (mặc định thẻ bị khoá, ẩn biển số và không lật được)
  bool _isCardUnlocked = false;

  // Selected category filter
  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Tất cả',
      'icon': Icons.all_inclusive_rounded,
      'bg': Color(0xFFE0EAFF),
      'color': Color(0xFF2563EB),
    },
    {
      'label': 'Ô tô',
      'icon': Icons.directions_car_rounded,
      'bg': Color(0xFFE0F2FE),
      'color': Color(0xFF0284C7),
    },
    {
      'label': 'Xe máy',
      'icon': Icons.two_wheeler_rounded,
      'bg': Color(0xFFDCFCE7),
      'color': Color(0xFF16A34A),
    },
    {
      'label': 'Vé tháng',
      'icon': Icons.card_membership_rounded,
      'bg': Color(0xFFFFEDD5),
      'color': Color(0xFFEA580C),
    },
    {
      'label': 'Vé lượt',
      'icon': Icons.confirmation_number_outlined,
      'bg': Color(0xFFF3E8FF),
      'color': Color(0xFF9333EA),
    },
  ];

  // Quick Dock Mode (Thẻ xe vs Tất cả)
  WalletDockMode _dockMode = WalletDockMode.quickAccess;

  // Active vehicle index in carousel
  int _activeCardIndex = 0;

  // All mock vehicles
  final List<VehicleCardModel> _allVehicles = VehicleCardModel.mockVehicles;

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
    if (_filteredVehicles.isEmpty) return _allVehicles.first;
    final index = _activeCardIndex.clamp(0, _filteredVehicles.length - 1);
    return _filteredVehicles[index];
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F8), // Exact Samsung One UI background
      appBar: _buildTopWalletAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AuthBloc>().add(AuthCheckRequested());
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            SizedBox(height: context.space(8)),

            // ================================================================
            // 1. NOTIFICATION BANNER (Soft Tint / Slate - Bo góc 16px)
            // ================================================================
            const WalletBanner(),
            SizedBox(height: context.space(14)),

            // ================================================================
            // 2. QUICK CATEGORY PILLS (Hàng chip phân loại nằm ngay trên thẻ)
            // ================================================================
            _buildCategoryPills(context),
            SizedBox(height: context.space(14)),

            // ================================================================
            // 3. MAIN INTERACTION: VEHICLE CAROUSEL (3D FLIP CARDS)
            // ================================================================
            if (_dockMode == WalletDockMode.quickAccess) ...[
              VehicleCarousel(
                key: ValueKey(_selectedCategoryIndex),
                cards: _filteredVehicles,
                isUnlocked: _isCardUnlocked,
                onTapToUnlock: () => _triggerBiometricAuth(),
                onCardChanged: (index) {
                  setState(() {
                    _activeCardIndex = index;
                    _isCardUnlocked = false; // Luôn khoá thẻ khi đổi xe
                  });
                },
              ),
              SizedBox(height: context.space(12)),

              // Trạng thái mở khoá vân tay
              Center(
                child: _buildUnlockStatusIndicator(context),
              ),
            ] else ...[
              // CHẾ ĐỘ "TẤT CẢ XE" (VERTICAL STACK LIST)
              _buildAllCardsVerticalList(context),
            ],

            SizedBox(height: context.space(20)),

            // ================================================================
            // 4. ACTIVE PARKING SESSION STATUS (Phiên đỗ xe thời gian thực)
            // ================================================================
            _buildActiveSessionCard(context),
            SizedBox(height: context.space(20)),

            // ================================================================
            // 5. WALLET QUICK DOCK (Capsule chuyển đổi Thẻ xe vs Tất cả)
            // ================================================================
            Center(
              child: WalletQuickDock(
                currentMode: _dockMode,
                onModeChanged: (mode) {
                  setState(() {
                    _dockMode = mode;
                  });
                },
              ),
            ),

            // Khoảng trống an toàn đảm bảo không bị Floating Bottom Bar che
            SizedBox(height: context.space(84) + bottomPad + 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP APP BAR (SAMSUNG WALLET STYLE)
  // ===========================================================================
  PreferredSizeWidget _buildTopWalletAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF4F5F8), // Exact Samsung One UI background
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Text(
            'PBMS Wallet',
            style: TextStyle(
              fontSize: context.sp(22),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF000000),
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(width: context.space(6)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.space(6),
              vertical: context.space(2),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1273EB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.space(6)),
            ),
            child: Text(
              'PASS',
              style: TextStyle(
                fontSize: context.sp(9),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1273EB),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // (+) Thêm xe mới / Đăng ký vé
        IconButton(
          icon: Icon(Icons.add_rounded, size: context.iconSize(26)),
          tooltip: 'Thêm thẻ xe',
          color: const Color(0xFF000000),
          onPressed: () => _showAddVehicleBottomSheet(context),
        ),

        // Dịch vụ bãi xe (Megaphone / Announcement icon tương tự Samsung Wallet)
        IconButton(
          icon: Icon(Icons.campaign_outlined, size: context.iconSize(24)),
          tooltip: 'Dịch vụ bãi xe',
          color: const Color(0xFF000000),
          onPressed: () => ServicesPopupSheet.show(context),
        ),

        // Menu 3 chấm (More Options)
        IconButton(
          icon: Icon(Icons.more_vert_rounded, size: context.iconSize(22)),
          tooltip: 'Tuỳ chọn',
          color: const Color(0xFF000000),
          onPressed: () => _showWalletOptions(context),
        ),
        SizedBox(width: context.space(4)),
      ],
    );
  }

  // ===========================================================================
  // CATEGORY PILLS (TAB PHÂN LOẠI NHANH NẰM TRÊN THẺ)
  // ===========================================================================
  Widget _buildCategoryPills(BuildContext context) {
    return SizedBox(
      height: context.space(38),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: context.space(16)),
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
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: context.space(12),
                vertical: context.space(6),
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF000000) : Colors.white,
                borderRadius: BorderRadius.circular(context.space(20)),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF000000)
                      : const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : (cat['bg'] as Color),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: context.iconSize(14),
                      color: isSelected ? Colors.white : (cat['color'] as Color),
                    ),
                  ),
                  SizedBox(width: context.space(6)),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: context.sp(12),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // ACTIVE PARKING SESSION CARD (THÔNG TIN PHIÊN ĐỖ THỰC TẾ)
  // ===========================================================================
  Widget _buildActiveSessionCard(BuildContext context) {
    final vehicle = _currentVehicle;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.space(16)),
      padding: EdgeInsets.all(context.space(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.space(20)),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), // Live pulse dot
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: context.space(8)),
                  Text(
                    'PHIÊN GỬI XE ĐANG DIỄN RA',
                    style: TextStyle(
                      fontSize: context.sp(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.space(8),
                  vertical: context.space(3),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(context.space(6)),
                ),
                child: Text(
                  'Đang tính giờ',
                  style: TextStyle(
                    fontSize: context.sp(10),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.space(12)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biển số đỗ:',
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: context.space(2)),
                    Text(
                      vehicle.licensePlate,
                      style: TextStyle(
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
              SizedBox(width: context.space(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời gian gửi:',
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: context.space(2)),
                    Text(
                      '02h 35m',
                      style: TextStyle(
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
              SizedBox(width: context.space(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạm tính:',
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: context.space(2)),
                    Text(
                      CurrencyFormatter.format(25000),
                      style: TextStyle(
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.space(14)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang định vị xe tại Tầng Hầm B2 - Cột F12'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.near_me_outlined, size: context.iconSize(16)),
                  label: const Text('Tìm vị trí xe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: EdgeInsets.symmetric(vertical: context.space(10)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.space(12)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.space(10)),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mã QR Checkout đã kích hoạt trên màn hình'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.qr_code_scanner_rounded, size: context.iconSize(16)),
                  label: const Text('Thanh toán ra'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000000),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: context.space(10)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.space(12)),
                    ),
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
  // ADD VEHICLE BOTTOM SHEET (+)
  // ===========================================================================
  void _showAddVehicleBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thêm thẻ phương tiện mới',
                style: TextStyle(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Đăng ký biển số xe mới vào ví để vào/ra bãi tự động qua mã QR hoặc NFC',
                style: TextStyle(
                  fontSize: context.sp(12),
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Biển kiểm soát (VD: 29A - 999.99)',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Tên xe / Model (VD: Honda Civic)',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Yêu cầu thêm xe đã được gửi lên hệ thống'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000000),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Thêm vào ví', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // WALLET OPTIONS MENU (:)
  // ===========================================================================
  void _showWalletOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.contactless_rounded, color: Color(0xFF1273EB)),
                title: const Text('Cài đặt NFC quẹt nhanh'),
                subtitle: const Text('Bật chạm không cần mở khoá màn hình'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.security_rounded, color: Color(0xFF059669)),
                title: const Text('Bảo mật sinh trắc học'),
                subtitle: const Text('Xác thực vân tay trước khi lật thẻ QR'),
                onTap: () {
                  Navigator.pop(ctx);
                  _triggerBiometricAuth();
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
                title: const Text('Hướng dẫn sử dụng ví PBMS'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TRẠNG THÁI MỞ KHOÁ VÂN TAY (STATUS INDICATOR)
  // ===========================================================================
  Widget _buildUnlockStatusIndicator(BuildContext context) {
    if (!_isCardUnlocked) {
      return GestureDetector(
        onTap: () => _triggerBiometricAuth(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.space(16),
            vertical: context.space(8),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.space(20)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                color: const Color(0xFF1273EB),
              ),
              SizedBox(width: context.space(6)),
              Text(
                'Chạm vào thẻ xe để quét vân tay',
                style: TextStyle(
                  fontSize: context.sp(12),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
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
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(context.space(20)),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF5E93F7)),
          SizedBox(width: context.space(6)),
          Text(
            'Thẻ đã mở khoá • Chạm để lật mã QR',
            style: TextStyle(
              fontSize: context.sp(12),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF000000),
            ),
          ),
          SizedBox(width: context.space(8)),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isCardUnlocked = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF52563),
                borderRadius: BorderRadius.circular(10),
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

  // ===========================================================================
  // XÁC THỰC VÂN TAY (BIOMETRIC FINGERPRINT AUTH)
  // ===========================================================================
  Future<void> _triggerBiometricAuth({VehicleCardModel? vehicle}) async {
    final target = vehicle ?? _currentVehicle;
    final canAuth = await BiometricService.instance.canAuthenticate();
    bool success = false;

    if (canAuth) {
      success = await BiometricService.instance.authenticateWithDevice(
        reason: 'Quét vân tay trên điện thoại để mở khoá thẻ xe ${target.licensePlate} và kích hoạt NFC',
      );
    } else {
      if (!mounted) return;
      // Fallback dialog nếu demo trên Web hoặc máy không có cảm biến vân tay
      success = await UltrasonicFingerprintDialog.authenticate(
        context,
        vehiclePlate: target.licensePlate,
      );
    }

    if (!mounted) return;
    if (success) {
      setState(() {
        _isCardUnlocked = true;
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1273EB).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đã xác thực vân tay • Thẻ ${target.licensePlate}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE3E1E2), // Samsung One UI Matte Dark Toast
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: 8,
          duration: const Duration(milliseconds: 2200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      );
    }
  }

}
