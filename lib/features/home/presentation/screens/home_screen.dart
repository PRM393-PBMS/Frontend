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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'PBMS Parking',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Thông báo',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckRequested());
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                // User Banner Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppSpacing.roundedLg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào,',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                user?.fullName ?? user?.userName ?? 'Khách hàng',
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              user?.roleName ?? 'User',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.roundedMd,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user?.email ?? 'Chưa cập nhật email',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Overview Section
                Text(
                  'Tổng quan bãi xe hôm nay',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Chỗ trống',
                        value: '142',
                        subtitle: 'Tầng B1, B2',
                        color: AppColors.available,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Đang gửi',
                        value: '78',
                        subtitle: 'Xe ô tô, xe máy',
                        color: AppColors.primary,
                        icon: Icons.directions_car_filled_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Actions Grid
                Text(
                  'Tính năng nhanh',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildActionCard(
                      context,
                      title: 'Đặt chỗ trước',
                      subtitle: 'Giữ chỗ trước khi đến',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng Đặt chỗ: Gọi POST /api/reservations')),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Mã QR gửi xe',
                      subtitle: 'Check-in / Check-out',
                      icon: Icons.qr_code_scanner_rounded,
                      color: AppColors.secondary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mã QR: Gọi POST /api/ParkingOperation/upload-and-decode-qr')),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Gói gửi xe tháng',
                      subtitle: 'Đăng ký & gia hạn',
                      icon: Icons.card_membership_rounded,
                      color: AppColors.accent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vé tháng: Gọi GET /api/MonthlySubscription/my')),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Báo cáo sự cố',
                      subtitle: 'Gửi hình ảnh chứng thực',
                      icon: Icons.report_problem_outlined,
                      color: AppColors.warning,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Báo cáo sự cố: Gọi POST /api/IncidentReport')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Active Parking Session Card
                Text(
                  'Phiên gửi xe hiện tại',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ResponsiveCard(
                  padding: EdgeInsets.all(context.space(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.space(10),
                              vertical: context.space(4),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.available.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(context.space(8)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: context.space(8),
                                  height: context.space(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.available,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: context.space(6)),
                                ResponsiveText(
                                  'Đang đỗ xe',
                                  variant: ResponsiveTextVariant.labelMedium,
                                  color: AppColors.available,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                          ResponsiveText(
                            'Vào lúc: Hôm nay 08:30',
                            variant: ResponsiveTextVariant.bodySmall,
                            color: AppColors.textMutedLight,
                          ),
                        ],
                      ),
                      SizedBox(height: context.space(14)),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.space(14),
                              vertical: context.space(8),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(context.space(8)),
                              border: Border.all(color: AppColors.borderLight, width: 1.5),
                            ),
                            child: ResponsiveText(
                              '51G-888.88',
                              variant: ResponsiveTextVariant.titleMedium,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(width: context.space(16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ResponsiveText(
                                  'Vị trí: Tầng B1 - B12',
                                  variant: ResponsiveTextVariant.labelLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                                ResponsiveText(
                                  'Cổng vào: Cổng A1',
                                  variant: ResponsiveTextVariant.bodySmall,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return ResponsiveCard(
      padding: EdgeInsets.all(context.space(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                title,
                variant: ResponsiveTextVariant.bodySmall,
                color: AppColors.textSecondaryLight,
              ),
              Icon(icon, color: color, size: context.iconSize(20)),
            ],
          ),
          SizedBox(height: context.space(8)),
          ResponsiveText(
            value,
            variant: ResponsiveTextVariant.displayMedium,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
          SizedBox(height: context.space(4)),
          ResponsiveText(
            subtitle,
            variant: ResponsiveTextVariant.bodySmall,
            color: AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ResponsiveCard(
      onTap: onTap,
      padding: EdgeInsets.all(context.space(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(context.space(8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.space(10)),
            ),
            child: Icon(icon, color: color, size: context.iconSize(22)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                title,
                variant: ResponsiveTextVariant.labelLarge,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: context.space(2)),
              ResponsiveText(
                subtitle,
                variant: ResponsiveTextVariant.bodySmall,
                color: AppColors.textMutedLight,
                maxLines: 1,
              ),
            ],
          ),
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
