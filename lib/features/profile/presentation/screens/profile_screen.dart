import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_spacing.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/theme/responsive_components.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cài đặt hệ thống đang hoàn thiện'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          final displayName = user?.fullName ?? user?.userName ?? 'Nguyễn Thành Long';
          final email = user?.email ?? 'longnguyenthanh07102005@gmail.com';
          final phone = user?.phoneNumber ?? '0987 654 321';
          final role = user?.roleName ?? 'Khách hàng VIP';
          final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckRequested());
            },
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: context.space(AppSpacing.pagePadding)),
              children: [
                SizedBox(height: context.space(12)),

                // ============================================================
                // HERO PROFILE CARD (Modern Web Gradient)
                // ============================================================
                Container(
                  padding: EdgeInsets.all(context.space(20)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(context.space(24)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with Initial & Camera badge
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: context.space(84),
                            height: context.space(84),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: AppTypography.displayLarge.copyWith(
                                  fontSize: context.sp(36),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.space(12)),

                      // User Full Name
                      ResponsiveText(
                        displayName,
                        variant: ResponsiveTextVariant.titleLarge,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.space(4)),

                      // Email with verified check
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.secondary, size: context.iconSize(16)),
                          SizedBox(width: context.space(6)),
                          Flexible(
                            child: ResponsiveText(
                              email,
                              variant: ResponsiveTextVariant.bodySmall,
                              color: Colors.white.withValues(alpha: 0.88),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.space(14)),

                      // Role Tag Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.space(14),
                          vertical: context.space(6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(context.space(20)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 16),
                            SizedBox(width: context.space(6)),
                            Text(
                              role,
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.space(20)),

                // ============================================================
                // MINI STATS ROW
                // ============================================================
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        context,
                        icon: Icons.directions_car_rounded,
                        color: AppColors.primary,
                        value: '02',
                        label: 'Phương tiện',
                      ),
                    ),
                    SizedBox(width: context.space(12)),
                    Expanded(
                      child: _buildMiniStat(
                        context,
                        icon: Icons.card_membership_rounded,
                        color: AppColors.accent,
                        value: '01',
                        label: 'Vé tháng',
                      ),
                    ),
                    SizedBox(width: context.space(12)),
                    Expanded(
                      child: _buildMiniStat(
                        context,
                        icon: Icons.local_parking_rounded,
                        color: AppColors.available,
                        value: '24',
                        label: 'Lượt đỗ',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.space(24)),

                // ============================================================
                // SECTION 1: THÔNG TIN TÀI KHOẢN (Personal Information)
                // ============================================================
                _buildSectionHeader(context, title: 'Thông tin cá nhân', actionLabel: 'Chỉnh sửa', onAction: () {
                  _showEditProfileSheet(context, displayName, phone);
                }),
                SizedBox(height: context.space(10)),
                ResponsiveCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.space(16),
                    vertical: context.space(8),
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        context,
                        icon: Icons.badge_outlined,
                        label: 'Họ và tên',
                        value: displayName,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        context,
                        icon: Icons.phone_android_rounded,
                        label: 'Số điện thoại',
                        value: phone,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        context,
                        icon: Icons.alternate_email_rounded,
                        label: 'Tên tài khoản',
                        value: '@${user?.userName ?? 'thanhlong'}',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.space(24)),

                // ============================================================
                // SECTION 2: PHƯƠNG TIỆN & DỊCH VỤ (Vehicles & Subscriptions)
                // ============================================================
                _buildSectionHeader(context, title: 'Dịch vụ của tôi'),
                SizedBox(height: context.space(10)),
                ResponsiveCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.space(16),
                    vertical: context.space(8),
                  ),
                  child: Column(
                    children: [
                      _buildActionTile(
                        context,
                        icon: Icons.two_wheeler_rounded,
                        color: AppColors.primary,
                        title: 'Phương tiện đã đăng ký',
                        subtitle: '29A-888.99 (Honda SH), 30E-123.45',
                        onTap: () {
                          _showFeatureNotice(context, 'Quản lý danh sách phương tiện');
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        icon: Icons.card_membership_rounded,
                        color: AppColors.accent,
                        title: 'Gói vé tháng đang dùng',
                        subtitle: 'Gói Resident Car VIP • Còn 22 ngày',
                        onTap: () {
                          _showFeatureNotice(context, 'Chi tiết gói vé tháng');
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        icon: Icons.swap_horiz_rounded,
                        color: AppColors.secondary,
                        title: 'Yêu cầu đổi phương tiện',
                        subtitle: 'Xem lịch sử và gửi yêu cầu đổi xe mới',
                        onTap: () {
                          _showFeatureNotice(context, 'Yêu cầu đổi xe');
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.space(24)),

                // ============================================================
                // SECTION 3: CÀI ĐẶT & BẢO MẬT (Settings & Security)
                // ============================================================
                _buildSectionHeader(context, title: 'Cài đặt & Tiện ích'),
                SizedBox(height: context.space(10)),
                ResponsiveCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.space(16),
                    vertical: context.space(6),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        context,
                        icon: Icons.notifications_active_outlined,
                        title: 'Thông báo đẩy',
                        subtitle: 'Nhận tin nhắn khi xe vào / ra bãi đỗ',
                        value: _pushNotifications,
                        onChanged: (val) {
                          setState(() => _pushNotifications = val);
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        context,
                        icon: Icons.dark_mode_outlined,
                        title: 'Chế độ tối (Dark Mode)',
                        subtitle: 'Tối ưu mắt khi đỗ xe vào ban đêm',
                        value: _darkMode,
                        onChanged: (val) {
                          setState(() => _darkMode = val);
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        icon: Icons.lock_outline_rounded,
                        color: AppColors.warning,
                        title: 'Đổi mật khẩu',
                        subtitle: 'Bảo vệ tài khoản an toàn',
                        onTap: () {
                          _showFeatureNotice(context, 'Đổi mật khẩu tài khoản');
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        icon: Icons.translate_rounded,
                        color: AppColors.info,
                        title: 'Ngôn ngữ',
                        subtitle: 'Tiếng Việt (Mặc định)',
                        onTap: () {
                          _showFeatureNotice(context, 'Chuyển đổi ngôn ngữ');
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.space(24)),

                // ============================================================
                // SECTION 4: HỖ TRỢ & THÔNG TIN ỨNG DỤNG
                // ============================================================
                _buildSectionHeader(context, title: 'Hỗ trợ'),
                SizedBox(height: context.space(10)),
                ResponsiveCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.space(16),
                    vertical: context.space(8),
                  ),
                  child: Column(
                    children: [
                      _buildActionTile(
                        context,
                        icon: Icons.headset_mic_outlined,
                        color: AppColors.available,
                        title: 'Liên hệ quản lý bãi đỗ',
                        subtitle: 'Hotline trực ban: 1900 6868 (24/7)',
                        onTap: () {
                          _showFeatureNotice(context, 'Gọi tổng đài hỗ trợ bãi xe');
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        context,
                        icon: Icons.policy_outlined,
                        color: Colors.grey.shade600,
                        title: 'Quy định bãi đỗ & Điều khoản',
                        subtitle: 'Chính sách gửi xe và bảo hiểm phương tiện',
                        onTap: () {
                          _showFeatureNotice(context, 'Chính sách bãi xe');
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.space(28)),

                // ============================================================
                // DANGER ZONE: LOGOUT BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  height: context.space(52),
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    label: Text(
                      'Đăng xuất tài khoản',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(15),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      elevation: 4,
                      shadowColor: AppColors.error.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.space(16)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.space(16)),

                // App Version Footer
                Center(
                  child: Text(
                    'PBMS Smart Parking • Phiên bản 1.0.0 (Release 2026)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedLight,
                      fontSize: context.sp(11),
                    ),
                  ),
                ),

                // ============================================================
                // KHOẢNG TRỐNG AN TOÀN ĐỘNG (Tránh thanh Nav Bar che nội dung)
                // ============================================================
                SizedBox(
                  height: context.space(84) + bottomPad + 24,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Helper Widgets ----

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return ResponsiveCard(
      padding: EdgeInsets.all(context.space(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: context.iconSize(20)),
          ),
          SizedBox(height: context.space(8)),
          ResponsiveText(
            value,
            variant: ResponsiveTextVariant.titleLarge,
            fontWeight: FontWeight.w800,
          ),
          SizedBox(height: context.space(2)),
          ResponsiveText(
            label,
            variant: ResponsiveTextVariant.bodySmall,
            color: AppColors.textMutedLight,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ResponsiveText(
          title,
          variant: ResponsiveTextVariant.titleMedium,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: context.space(8)),
            ),
            child: Text(
              actionLabel,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.space(10)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: context.iconSize(20), color: AppColors.primary),
          ),
          SizedBox(width: context.space(14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: context.sp(11.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: context.iconSize(20), color: color),
      ),
      title: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textMutedLight,
          fontSize: context.sp(11.5),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: context.iconSize(20), color: AppColors.primary),
      ),
      title: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textMutedLight,
          fontSize: context.sp(11.5),
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  void _showFeatureNotice(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng: $featureName'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 90),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, String currentName, String currentPhone) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);

    showResponsiveBottomSheet(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveText(
            'Chỉnh sửa thông tin',
            variant: ResponsiveTextVariant.titleLarge,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sheetContext.space(16)),
          ResponsiveTextField(
            controller: nameCtrl,
            label: 'Họ và tên',
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: sheetContext.space(12)),
          ResponsiveTextField(
            controller: phoneCtrl,
            label: 'Số điện thoại',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: sheetContext.space(20)),
          ResponsiveButton(
            label: 'Lưu thay đổi',
            onPressed: () {
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thông tin đã được cập nhật thành công!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          SizedBox(height: sheetContext.space(10)),
          ResponsiveButton(
            label: 'Hủy',
            type: ResponsiveButtonType.outlined,
            backgroundColor: Colors.grey.shade400,
            foregroundColor: AppColors.textPrimaryLight,
            onPressed: () => Navigator.pop(sheetContext),
          ),
          SizedBox(height: sheetContext.space(10)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showResponsiveBottomSheet(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveText(
            'Xác nhận đăng xuất',
            variant: ResponsiveTextVariant.titleLarge,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sheetContext.space(12)),
          ResponsiveText(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng PBMS không? Phiên đăng nhập hiện tại sẽ kết thúc.',
            variant: ResponsiveTextVariant.bodyMedium,
            color: AppColors.textSecondaryLight,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sheetContext.space(24)),
          ResponsiveButton(
            label: 'Đăng xuất',
            backgroundColor: AppColors.error,
            onPressed: () {
              Navigator.pop(sheetContext);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
          SizedBox(height: sheetContext.space(10)),
          ResponsiveButton(
            label: 'Hủy',
            type: ResponsiveButtonType.outlined,
            backgroundColor: Colors.grey.shade400,
            foregroundColor: AppColors.textPrimaryLight,
            onPressed: () => Navigator.pop(sheetContext),
          ),
          SizedBox(height: sheetContext.space(10)),
        ],
      ),
    );
  }
}