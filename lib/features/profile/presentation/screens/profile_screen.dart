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
import 'package:prm393_frontend/features/home/presentation/models/vehicle_card_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _profilePrimary = Color(0xFF00616E);
  static const _profilePrimaryContainer = Color(0xFF087B8C);
  static const _profileSecondary = Color(0xFF136873);
  static const _profileSecondaryContainer = Color(0xFFA3EBF7);
  static const _profileSurface = Color(0xFFF9F9FF);
  static const _profileSurfaceLow = Color(0xFFF0F3FF);
  static const _profileOutline = Color(0xFFBEC8CB);
  static const _profileOnSurface = Color(0xFF111C2D);
  static const _profileOnSurfaceVariant = Color(0xFF3E484B);
  static const _profileErrorContainer = Color(0xFFFFDAD6);
  static const _profileOnErrorContainer = Color(0xFF93000A);

  bool _parkingNotifications = true;
  bool _monthlyPassAutoRenew = false;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _profileSurface,
      appBar: AppBar(
        backgroundColor: _profileSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cá Nhân',
          style: AppTypography.titleMedium.copyWith(
            color: _profileOnSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _showFeatureNotice(context, 'Thông báo'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => _showFeatureNotice(context, 'Cài đặt hệ thống'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _profilePrimary,
              child: const Icon(Icons.person_rounded,
                  size: 19, color: Colors.white),
            ),
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
          final vehicle = VehicleCardModel.mockVehicles.first;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckRequested());
            },
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                context.space(AppSpacing.pagePadding),
                context.space(12),
                context.space(AppSpacing.pagePadding),
                context.space(84) + bottomPad + 24,
              ),
              children: [
                _buildProfileSummary(
                  context,
                  displayName: displayName,
                  email: email,
                  phone: phone,
                  role: role,
                  initial: initial,
                  onEdit: () => _showEditProfileSheet(context, displayName, phone),
                ),
                SizedBox(height: context.space(12)),
                _buildStats(context),
                SizedBox(height: context.space(16)),
                _buildSectionCard(
                  context,
                  title: 'Phương tiện đã liên kết (ANPR)',
                  icon: Icons.directions_car_rounded,
                  trailing: '1 phương tiện',
                  children: [
                    _buildVehicleCard(context, vehicle),
                    SizedBox(height: context.space(8)),
                    SizedBox(
                      height: context.space(48),
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showFeatureNotice(context, 'Thêm biển số xe mới'),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Thêm biển số xe mới'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _profilePrimaryContainer,
                          backgroundColor: _profileSurfaceLow,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.space(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.space(12)),
                _buildSectionCard(
                  context,
                  title: 'Ví & Phương thức thanh toán',
                  children: [
                    _buildActionTile(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      color: _profilePrimary,
                      title: 'Ví điện tử & Thẻ thanh toán',
                      subtitle: 'MoMo • Visa ending **** 4288',
                      onTap: () => _showFeatureNotice(context, 'Ví và thẻ thanh toán'),
                    ),
                    const Divider(height: 1),
                    _buildActionTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      color: _profilePrimary,
                      title: 'Lịch sử đỗ xe & Hóa đơn VAT',
                      subtitle: 'Xuất hóa đơn điện tử qua email',
                      onTap: () => _showFeatureNotice(context, 'Lịch sử đỗ xe và hóa đơn'),
                    ),
                  ],
                ),
                SizedBox(height: context.space(12)),
                _buildSectionCard(
                  context,
                  title: 'Cài đặt & Tiện ích',
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: 'Cảnh báo sắp hết giờ',
                      subtitle: 'Báo trước 15 phút khi sắp hết giờ đỗ',
                      value: _parkingNotifications,
                      onChanged: (value) =>
                          setState(() => _parkingNotifications = value),
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      context,
                      icon: Icons.autorenew_rounded,
                      title: 'Gia hạn vé tháng tự động',
                      subtitle: 'Tự động thanh toán vào ngày 28 hàng tháng',
                      value: _monthlyPassAutoRenew,
                      onChanged: (value) =>
                          setState(() => _monthlyPassAutoRenew = value),
                    ),
                    const Divider(height: 1),
                    _buildActionTile(
                      context,
                      icon: Icons.fingerprint_rounded,
                      color: _profilePrimary,
                      title: 'Bảo mật & Sinh trắc học',
                      subtitle: 'Face ID / Mã PIN xác thực thanh toán',
                      trailingLabel: 'Bật',
                      onTap: () => _showFeatureNotice(context, 'Bảo mật và sinh trắc học'),
                    ),
                    const Divider(height: 1),
                    _buildActionTile(
                      context,
                      icon: Icons.support_agent_rounded,
                      color: _profilePrimary,
                      title: 'Trung tâm trợ giúp & Cứu hộ bãi xe',
                      subtitle: 'Hotline miễn phí 1900 6868 (24/7)',
                      onTap: () => _showFeatureNotice(context, 'Trung tâm trợ giúp'),
                    ),
                  ],
                ),
                SizedBox(height: context.space(16)),
                SizedBox(
                  height: context.space(48),
                  child: FilledButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng xuất tài khoản'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _profileErrorContainer,
                      foregroundColor: _profileOnErrorContainer,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.space(12)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.space(8)),
                Center(
                  child: Column(
                    children: [
                      ResponsiveText(
                        'PBMS Smart Parking • Phiên bản 1.0.0 (Release 2026)',
                        variant: ResponsiveTextVariant.labelMedium,
                        color: _profileOnSurfaceVariant,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.space(2)),
                      ResponsiveText(
                        'Hệ thống bãi đỗ thông minh ANPR AI',
                        variant: ResponsiveTextVariant.labelMedium,
                        color: _profileOutline,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Profile UI ----

  Widget _buildProfileSummary(
    BuildContext context, {
    required String displayName,
    required String email,
    required String phone,
    required String role,
    required String initial,
    required VoidCallback onEdit,
  }) {
    return ResponsiveCard(
      padding: EdgeInsets.all(context.space(16)),
      borderRadius: BorderRadius.circular(context.space(12)),
      backgroundColor: Colors.white,
      borderColor: _profileSurfaceLow,
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: context.space(32),
                backgroundColor: _profileSurfaceLow,
                child: Text(
                  initial,
                  style: AppTypography.titleLarge.copyWith(
                    color: _profilePrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: context.space(44),
                height: context.space(44),
                child: IconButton(
                  tooltip: 'Thay đổi ảnh đại diện hoặc thông tin',
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: _profilePrimaryContainer,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  icon: Icon(Icons.camera_alt_rounded,
                      size: context.iconSize(15)),
                ),
              ),
            ],
          ),
          SizedBox(width: context.space(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveText(
                        displayName,
                        variant: ResponsiveTextVariant.titleMedium,
                        color: _profileOnSurface,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: context.space(4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.space(6),
                        vertical: context.space(2),
                      ),
                      decoration: BoxDecoration(
                        color: _profileSecondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: context.iconSize(13),
                              color: _profileSecondary),
                          SizedBox(width: context.space(2)),
                          ResponsiveText(
                            'Đã xác minh',
                            variant: ResponsiveTextVariant.labelMedium,
                            color: _profileSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.space(2)),
                ResponsiveText(
                  '$role • Ô tô chính chủ',
                  variant: ResponsiveTextVariant.labelMedium,
                  color: _profilePrimary,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                ),
                SizedBox(height: context.space(4)),
                _buildContactLine(
                  context,
                  icon: Icons.smartphone_rounded,
                  value: phone,
                ),
                SizedBox(height: context.space(2)),
                _buildContactLine(
                  context,
                  icon: Icons.email_outlined,
                  value: email,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactLine(
    BuildContext context, {
    required IconData icon,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: context.iconSize(14), color: _profileOnSurfaceVariant),
        SizedBox(width: context.space(4)),
        Expanded(
          child: ResponsiveText(
            value,
            variant: ResponsiveTextVariant.bodySmall,
            color: _profileOnSurfaceVariant,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.all(context.space(8)),
      borderRadius: BorderRadius.circular(context.space(12)),
      backgroundColor: Colors.white,
      borderColor: _profileSurfaceLow,
      child: Row(
        children: [
          _buildStat(context,
              value: '24', label: 'Lượt đỗ tháng', valueColor: _profilePrimaryContainer),
          SizedBox(width: context.space(4)),
          _buildStat(context,
              value: '01',
              label: 'Vé tháng hiệu lực',
              valueColor: _profileSecondary,
              highlighted: true),
          SizedBox(width: context.space(4)),
          _buildStat(context,
              value: '320',
              label: 'Điểm Eco-Park',
              valueColor: _profilePrimaryContainer,
              icon: Icons.eco_rounded),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String value,
    required String label,
    required Color valueColor,
    IconData? icon,
    bool highlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.space(4),
          vertical: context.space(10),
        ),
        decoration: BoxDecoration(
          color: highlighted ? _profileSurfaceLow : Colors.transparent,
          borderRadius: BorderRadius.circular(context.space(8)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveText(
                  value,
                  variant: ResponsiveTextVariant.titleLarge,
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
                if (icon != null) ...[
                  SizedBox(width: context.space(2)),
                  Icon(icon, size: context.iconSize(16), color: _profilePrimary),
                ],
              ],
            ),
            SizedBox(height: context.space(2)),
            ResponsiveText(
              label,
              variant: ResponsiveTextVariant.labelMedium,
              color: _profileOnSurfaceVariant,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    IconData? icon,
    String? trailing,
    required List<Widget> children,
  }) {
    return ResponsiveCard(
      padding: EdgeInsets.all(context.space(16)),
      borderRadius: BorderRadius.circular(context.space(12)),
      backgroundColor: Colors.white,
      borderColor: _profileSurfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: context.iconSize(20), color: _profilePrimaryContainer),
                SizedBox(width: context.space(8)),
              ],
              Expanded(
                child: ResponsiveText(
                  title,
                  variant: ResponsiveTextVariant.titleSmall,
                  color: _profileOnSurface,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: context.space(8)),
                ResponsiveText(
                  trailing,
                  variant: ResponsiveTextVariant.labelMedium,
                  color: _profilePrimary,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                ),
              ],
            ],
          ),
          SizedBox(height: context.space(8)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleCardModel vehicle) {
    return Container(
      padding: EdgeInsets.all(context.space(12)),
      decoration: BoxDecoration(
        color: _profileSecondaryContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(context.space(12)),
      ),
      child: Row(
        children: [
          Container(
            width: context.space(48),
            height: context.space(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.space(12)),
            ),
            child: Icon(Icons.directions_car_rounded,
                size: context.iconSize(26), color: _profilePrimaryContainer),
          ),
          SizedBox(width: context.space(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveText(
                        vehicle.vehicleName,
                        variant: ResponsiveTextVariant.titleSmall,
                        color: _profileOnSurface,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: context.space(4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.space(4),
                        vertical: context.space(2),
                      ),
                      decoration: BoxDecoration(
                        color: _profilePrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(context.space(4)),
                      ),
                      child: const ResponsiveText(
                        'Mặc định',
                        variant: ResponsiveTextVariant.labelMedium,
                        color: _profilePrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.space(4)),
                ResponsiveText(
                  vehicle.licensePlate,
                  variant: ResponsiveTextVariant.labelLarge,
                  color: _profileOnSurface,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
                SizedBox(height: context.space(2)),
                Row(
                  children: [
                    Icon(Icons.sensor_door_outlined,
                        size: context.iconSize(13), color: _profileSecondary),
                    SizedBox(width: context.space(2)),
                    const ResponsiveText(
                      'Auto barrier',
                      variant: ResponsiveTextVariant.labelMedium,
                      color: _profileSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.space(4)),
          IconButton(
            tooltip: 'Tùy chọn xe ${vehicle.vehicleName}',
            onPressed: () => _showFeatureNotice(context, 'Tùy chọn phương tiện'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.more_vert_rounded,
                color: _profileOnSurfaceVariant),
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
    String? trailingLabel,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: context.space(40),
        height: context.space(40),
        decoration: BoxDecoration(
          color: _profileSurfaceLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: context.iconSize(20), color: color),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: _profileOnSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          color: _profileOnSurfaceVariant,
          fontSize: context.sp(11.5),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingLabel != null) ...[
            Text(
              trailingLabel,
              style: AppTypography.labelMedium.copyWith(
                color: _profilePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: context.space(4)),
          ],
          Icon(Icons.chevron_right_rounded,
              color: _profileOutline, size: context.iconSize(20)),
        ],
      ),
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
        width: context.space(40),
        height: context.space(40),
        decoration: BoxDecoration(
          color: _profileSurfaceLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: context.iconSize(20), color: _profilePrimaryContainer),
      ),
      title: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: _profileOnSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: _profileOnSurfaceVariant,
          fontSize: context.sp(11.5),
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: _profilePrimary,
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
            backgroundColor: AppColors.borderLight,
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
            backgroundColor: AppColors.borderLight,
            foregroundColor: AppColors.textPrimaryLight,
            onPressed: () => Navigator.pop(sheetContext),
          ),
          SizedBox(height: sheetContext.space(10)),
        ],
      ),
    );
  }
}