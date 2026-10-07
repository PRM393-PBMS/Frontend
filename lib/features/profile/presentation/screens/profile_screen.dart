import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'package:prm393_frontend/core/config/api_endpoints.dart';
import 'package:prm393_frontend/core/config/app_config.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/localization/app_language.dart';
import 'package:prm393_frontend/core/localization/app_translations.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import 'package:prm393_frontend/core/services/vehicle_storage_service.dart';
import 'package:prm393_frontend/core/storage/secure_storage_service.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_spacing.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/theme/theme_controller.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/features/auth/data/models/user_model.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_state.dart';
import 'package:prm393_frontend/features/home/data/repositories/parking_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _biometricEnabled = true;
  bool _profileBusy = false;
  int _avatarVersion = 0;

  // Real stats state
  int _registeredVehiclesCount = 0;
  int _activePassesCount = 0;
  int _parkingTripsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;

    // 1. Tải số lượng xe thực tế từ storage/backend
    try {
      final vehicles = await VehicleStorageService.instance.getVehicles(userId: userId);
      if (mounted) {
        setState(() {
          _registeredVehiclesCount = vehicles.where((v) => !v.id.startsWith('mock_')).length;
          _activePassesCount = vehicles.where((v) => v.isMonthlyActive).length;
        });
      }
    } catch (_) {}

    // 2. Tải số lượt đỗ thực tế từ ParkingRepository
    try {
      if (!mounted) return;
      final repo = context.read<ParkingRepository>();
      final sessions = await repo.getMySessions();
      if (mounted) {
        setState(() {
          _parkingTripsCount = sessions.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: Text(
          context.tr('profile_title'),
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.translate_rounded,
              color: isDark ? AppColors.primary : const Color(0xFF0284C7),
            ),
            tooltip: context.tr('item_language'),
            onPressed: () => _showLanguageSelectorModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('settings_tooltip'),
            onPressed: () => _showLanguageSelectorModal(context),
          ),
          SizedBox(width: context.space(8)),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          final displayName = user?.fullName ?? user?.userName ?? 'Nguyễn Thành Long';
          final email = user?.email ?? 'driver@pbms.smartparking.vn';
          final phone = user?.phoneNumber ?? '0987 654 321';
          final role = user?.roleName == 'admin'
              ? 'Administrator'
              : (user?.roleName == 'staff'
                  ? 'Operator PBMS'
                  : context.tr('role_customer_vip'));
          final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckRequested());
              await _loadProfileStats();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.symmetric(horizontal: context.space(AppSpacing.pagePadding)),
              children: [
                SizedBox(height: context.space(10)),

                // ============================================================
                // HERO PROFILE CARD (Titanium Architectural Aesthetic)
                // ============================================================
                Container(
                  padding: EdgeInsets.all(context.space(20)),
                  decoration: BoxDecoration(
                    gradient: AppColors.titaniumCardGradient,
                    borderRadius: BorderRadius.circular(context.space(18)),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileAvatar(user?.avatarUrl, initial),
                      SizedBox(height: context.space(12)),

                      // User Full Name
                      Text(
                        displayName,
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.sp(20),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.space(4)),

                      // Email with verified check
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              email,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: context.sp(12),
                              ),
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
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(context.space(20)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Colors.amberAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              role,
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.space(18)),

                // ============================================================
                // MINI STATS ROW (Real Data Count)
                // ============================================================
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        context,
                        icon: Icons.directions_car_rounded,
                        color: AppColors.primary,
                        value: _registeredVehiclesCount.toString().padLeft(2, '0'),
                        label: context.tr('stat_vehicles'),
                      ),
                    ),
                    SizedBox(width: context.space(10)),
                    Expanded(
                      child: _buildMiniStat(
                        context,
                        icon: Icons.card_membership_rounded,
                        color: AppColors.accent,
                        value: _activePassesCount.toString().padLeft(2, '0'),
                        label: context.tr('stat_passes'),
                      ),
                    ),
                    SizedBox(width: context.space(10)),
                    Expanded(
                      child: _buildMiniStat(
                        context,
                        icon: Icons.local_parking_rounded,
                        color: AppColors.available,
                        value: _parkingTripsCount.toString().padLeft(2, '0'),
                        label: context.tr('stat_parkings'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.space(22)),

                // ============================================================
                // SECTION 1: THÔNG TIN CÁ NHÂN (Personal Information)
                // ============================================================
                _buildSectionHeader(
                  context,
                  title: context.tr('sec_personal_info'),
                  actionLabel: context.tr('btn_edit'),
                  onAction: () => _showEditProfileSheet(context, displayName, phone),
                ),
                SizedBox(height: context.space(10)),
                _buildCardWrapper(
                  context,
                  isDark: isDark,
                  children: [
                    _buildInfoTile(
                      context,
                      icon: Icons.badge_outlined,
                      label: context.tr('lbl_full_name'),
                      value: displayName,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      context,
                      icon: Icons.phone_android_rounded,
                      label: context.tr('lbl_phone'),
                      value: phone,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      context,
                      icon: Icons.alternate_email_rounded,
                      label: context.tr('lbl_username'),
                      value: '@${user?.userName ?? 'driver'}',
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      context,
                      icon: Icons.email_outlined,
                      label: context.tr('lbl_email'),
                      value: email,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: context.space(22)),

                // ============================================================
                // SECTION 2: DỊCH VỤ & PHƯƠNG TIỆN (Services & Vehicles)
                // ============================================================
                _buildSectionHeader(context, title: context.tr('sec_services')),
                SizedBox(height: context.space(10)),
                _buildCardWrapper(
                  context,
                  isDark: isDark,
                  children: [
                    _buildActionTile(
                      context,
                      icon: Icons.two_wheeler_rounded,
                      color: AppColors.primary,
                      title: context.tr('item_registered_vehicles'),
                      subtitle: '$_registeredVehiclesCount ${context.tr('stat_vehicles').toLowerCase()} PBMS',
                      isDark: isDark,
                      onTap: () => _showFeatureNotice(context, context.tr('item_registered_vehicles')),
                    ),
                    _buildDivider(isDark),
                    _buildActionTile(
                      context,
                      icon: Icons.card_membership_rounded,
                      color: AppColors.accent,
                      title: context.tr('item_active_passes'),
                      subtitle: '$_activePassesCount ${context.tr('stat_passes').toLowerCase()} PBMS Active',
                      isDark: isDark,
                      onTap: () => _showFeatureNotice(context, context.tr('item_active_passes')),
                    ),
                    _buildDivider(isDark),
                    _buildActionTile(
                      context,
                      icon: Icons.swap_horiz_rounded,
                      color: AppColors.secondary,
                      title: context.tr('item_swap_vehicle'),
                      subtitle: context.tr('item_swap_vehicle_desc'),
                      isDark: isDark,
                      onTap: () => _showFeatureNotice(context, context.tr('item_swap_vehicle')),
                    ),
                    _buildDivider(isDark),
                    _buildActionTile(
                      context,
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.available,
                      title: context.tr('item_parking_history'),
                      subtitle: context.tr('item_parking_history_desc'),
                      isDark: isDark,
                      onTap: () => _showFeatureNotice(context, context.tr('item_parking_history')),
                    ),
                  ],
                ),
                SizedBox(height: context.space(22)),

                // ============================================================
                // SECTION 3: CÀI ĐẶT & TIỆN ÍCH (Settings & Language)
                // ============================================================
                _buildSectionHeader(context, title: context.tr('sec_settings')),
                SizedBox(height: context.space(10)),
                _buildCardWrapper(
                  context,
                  isDark: isDark,
                  children: [
                    // Cài đặt ngôn ngữ (Language Selector Tile)
                    _buildActionTile(
                      context,
                      icon: Icons.translate_rounded,
                      color: const Color(0xFF0284C7),
                      title: context.tr('item_language'),
                      subtitle: '${LanguageController.instance.currentLanguage.flag} ${LanguageController.instance.currentLanguage.name} (${LanguageController.instance.currentLanguage.englishName})',
                      isDark: isDark,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primary.withValues(alpha: 0.16) : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFBAE6FD),
                          ),
                        ),
                        child: Text(
                          LanguageController.instance.currentLanguage.code.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark ? AppColors.primary : const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      onTap: () => _showLanguageSelectorModal(context),
                    ),
                    _buildDivider(isDark),

                    // Chế độ tối (Dark Mode Switch)
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.instance.themeModeNotifier,
                      builder: (ctx, mode, _) {
                        final isDarkActive = mode == ThemeMode.dark;
                        return _buildSwitchTile(
                          context,
                          icon: Icons.dark_mode_outlined,
                          title: context.tr('item_dark_mode'),
                          subtitle: context.tr('item_dark_mode_desc'),
                          value: isDarkActive,
                          isDark: isDark,
                          onChanged: (_) {
                            ThemeController.instance.toggleTheme();
                          },
                        );
                      },
                    ),
                    _buildDivider(isDark),

                    // Thông báo thời gian thực (Push Notifications)
                    _buildSwitchTile(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: context.tr('item_push_notifications'),
                      subtitle: context.tr('item_push_notifications_desc'),
                      value: _pushNotifications,
                      isDark: isDark,
                      onChanged: (val) {
                        setState(() => _pushNotifications = val);
                      },
                    ),
                    _buildDivider(isDark),

                    // Sinh trắc học (Biometrics)
                    _buildSwitchTile(
                      context,
                      icon: Icons.fingerprint_rounded,
                      title: context.tr('item_biometric'),
                      subtitle: context.tr('item_biometric_desc'),
                      value: _biometricEnabled,
                      isDark: isDark,
                      onChanged: (val) {
                        setState(() => _biometricEnabled = val);
                      },
                    ),
                    _buildDivider(isDark),

                    // Đổi mật khẩu
                    _buildActionTile(
                      context,
                      icon: Icons.lock_outline_rounded,
                      color: AppColors.warning,
                      title: context.tr('item_change_password'),
                      subtitle: context.tr('item_change_password_desc'),
                      isDark: isDark,
                      onTap: () => _showFeatureNotice(context, context.tr('item_change_password')),
                    ),
                  ],
                ),
                SizedBox(height: context.space(22)),

                // ============================================================
                // SECTION 4: HỖ TRỢ & CHÍNH SÁCH (Support & Legal)
                // ============================================================
                _buildSectionHeader(context, title: context.tr('sec_support')),
                SizedBox(height: context.space(10)),
                _buildCardWrapper(
                  context,
                  isDark: isDark,
                  children: [
                    _buildActionTile(
                      context,
                      icon: Icons.headset_mic_outlined,
                      color: AppColors.available,
                      title: context.tr('item_hotline'),
                      subtitle: context.tr('item_hotline_desc'),
                      isDark: isDark,
                      onTap: () => _showFeatureNotice(context, context.tr('item_hotline')),
                    ),
                    _buildDivider(isDark),
                    _buildActionTile(
                      context,
                      icon: Icons.policy_outlined,
                      color: Colors.grey.shade600,
                      title: context.tr('item_rules'),
                      subtitle: context.tr('item_rules_desc'),
                      isDark: isDark,
                      onTap: () => _showFeatureNotice(context, context.tr('item_rules')),
                    ),
                  ],
                ),
                SizedBox(height: context.space(28)),

                // ============================================================
                // DANGER ZONE: LOGOUT BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  height: context.space(50),
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    label: Text(
                      context.tr('btn_logout'),
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(14.5),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      elevation: 3,
                      shadowColor: AppColors.error.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.space(14)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.space(16)),

                // App Version Footer
                Center(
                  child: Text(
                    context.tr('app_version'),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: context.sp(11),
                    ),
                  ),
                ),

                // Spacing for floating navigation bar
                SizedBox(height: context.space(84) + bottomPad + 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // LANGUAGE SELECTOR MODAL (Tiếng Việt, English, 日本語)
  // ===========================================================================
  void _showLanguageSelectorModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = LanguageController.instance.currentLanguage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.translate_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('modal_lang_title'),
                          style: AppTypography.titleLarge.copyWith(fontSize: 17),
                        ),
                        Text(
                          context.tr('modal_lang_desc'),
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Danh sách 3 ngôn ngữ
              ...AppLanguage.values.map((lang) {
                final isSelected = lang == currentLang;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      await LanguageController.instance.setLanguage(lang);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Text(lang.flag, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${context.tr('lang_switched_notice')}${lang.name} (${lang.englishName})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFEFF6FF))
                            : (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.primary : const Color(0xFF38BDF8))
                              : (isDark ? AppColors.borderSubtleDark : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      lang.name,
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isSelected
                                            ? (isDark ? AppColors.primary : const Color(0xFF0369A1))
                                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ${lang.englishName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang.desc,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: isDark ? AppColors.primary : const Color(0xFF0284C7),
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildCardWrapper(
    BuildContext context, {
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(context.space(16)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.space(16),
        vertical: context.space(4),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderSubtleDark : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.space(12), horizontal: context.space(8)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(context.space(14)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: context.iconSize(18)),
          ),
          SizedBox(height: context.space(6)),
          Text(
            value,
            style: AppTypography.telemetryMono.copyWith(
              fontSize: context.sp(17),
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: context.space(2)),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: context.sp(10.5),
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.badgeMono.copyWith(
            fontSize: context.sp(11),
            color: isDark ? AppColors.primary : const Color(0xFF0369A1),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                actionLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
    required bool isDark,
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
            child: Icon(icon, size: context.iconSize(18), color: AppColors.primary),
          ),
          SizedBox(width: context.space(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontSize: context.sp(11),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: context.sp(13.5),
                  ),
                ),
              ],
            ),
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
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailing,
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
        child: Icon(icon, size: context.iconSize(19), color: color),
      ),
      title: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontSize: context.sp(13.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          fontSize: context.sp(11),
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textMutedDark : Colors.grey.shade400,
            size: 20,
          ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
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
        child: Icon(icon, size: context.iconSize(19), color: AppColors.primary),
      ),
      title: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontSize: context.sp(13.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          fontSize: context.sp(11),
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
        content: Text('$featureName • PBMS Smart Feature'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 90),
      ),
    );
  }

  void _showProfileMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ===========================================================================
  // AVATAR & PROFILE UPDATE API FLOW
  // ===========================================================================
  UserModel _readUpdatedProfile(ApiResponse<UserModel> response) {
    final user = response.result;
    if (!response.isOk || user == null || user.id.isEmpty) {
      throw AppException(
        message: response.message ?? 'Máy chủ chưa trả về hồ sơ hợp lệ.',
      );
    }
    return user;
  }

  Future<void> _publishProfile(UserModel user) async {
    if (!mounted) return;
    final bloc = context.read<AuthBloc>();
    final storage = context.read<SecureStorageService>();
    if (!bloc.state.isAuthenticated || bloc.state.user?.id != user.id) {
      throw const AppException(message: 'Phiên đăng nhập đã thay đổi.');
    }
    bloc.add(AuthProfileUpdated(user));
    try {
      await storage.saveUserData(jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_profileBusy) return;
    final api = context.read<ApiClient>();
    setState(() => _profileBusy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;
      const maxSize = 5 * 1024 * 1024;
      if (await image.length() > maxSize) {
        throw AppException(message: AppTranslations.tr('avatar_error_size'));
      }
      final extension = image.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (mimeType == null) {
        throw AppException(message: AppTranslations.tr('avatar_error_format'));
      }
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty || bytes.length > maxSize) {
        throw AppException(message: AppTranslations.tr('avatar_error_size'));
      }
      if (!mounted) return;
      final response = await api.post<UserModel>(
        ApiEndpoints.profileAvatar,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: image.name,
            contentType: MediaType.parse(mimeType),
          ),
        }),
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        fromJsonT: (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
      await _publishProfile(_readUpdatedProfile(response));
      if (!mounted) return;
      setState(() => _avatarVersion = DateTime.now().millisecondsSinceEpoch);
      _showProfileMessage(context.tr('avatar_success'));
    } on AppException catch (error) {
      _showProfileMessage(error.message);
    } catch (_) {
      _showProfileMessage('Không thể cập nhật ảnh đại diện. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _profileBusy = false);
    }
  }

  Widget _buildProfileAvatar(String? avatarUrl, String initial) {
    String? imageUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      final uri = Uri.parse(AppConfig.baseUrl).resolve(avatarUrl.trim());
      imageUrl = _avatarVersion == 0
          ? uri.toString()
          : uri.replace(queryParameters: {
              ...uri.queryParameters,
              'v': '$_avatarVersion',
            }).toString();
    }
    Widget fallback() => Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: context.sp(36),
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        );
    return Semantics(
      button: true,
      label: context.tr('change_avatar_tooltip'),
      child: InkWell(
        onTap: _profileBusy ? null : _pickAndUploadAvatar,
        borderRadius: BorderRadius.circular(60),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: context.space(84),
              height: context.space(84),
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: imageUrl == null
                    ? fallback()
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => fallback(),
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
              child: _profileBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    String currentName,
    String currentPhone,
  ) async {
    if (_profileBusy) return;
    final api = context.read<ApiClient>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileForm(
        currentName: currentName,
        currentPhone: currentPhone,
        isDark: isDark,
        onSave: (name, phone) async {
          if (!mounted) throw const AppException(message: 'Màn hình hồ sơ đã đóng.');
          setState(() => _profileBusy = true);
          try {
            final response = await api.put<UserModel>(
              ApiEndpoints.profile,
              data: {'fullName': name, 'phoneNumber': phone},
              fromJsonT: (json) => UserModel.fromJson(json as Map<String, dynamic>),
            );
            await _publishProfile(_readUpdatedProfile(response));
          } finally {
            if (mounted) setState(() => _profileBusy = false);
          }
        },
      ),
    );
    if (saved == true && mounted) {
      _showProfileMessage(AppTranslations.tr('msg_profile_saved'));
    }
  }

  // ===========================================================================
  // LOGOUT DIALOG
  // ===========================================================================
  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('dialog_logout_title'),
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('dialog_logout_msg'),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  context.tr('btn_confirm_logout'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                  foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.tr('btn_cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EDIT PROFILE FORM MODAL
// =============================================================================
class _EditProfileForm extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final bool isDark;
  final Future<void> Function(String name, String phone) onSave;

  const _EditProfileForm({
    required this.currentName,
    required this.currentPhone,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is AppException
            ? error.message
            : 'Không thể lưu hồ sơ. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 20,
        bottom: bottomInset + 22,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: widget.isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: PopScope(
        canPop: !_saving,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('edit_sheet_title'),
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('edit_sheet_desc'),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: context.tr('lbl_full_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr('validate_name_req')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.tr('lbl_phone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr('validate_phone_req')
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDark ? AppColors.primary : const Color(0xFF090D14),
                    foregroundColor: widget.isDark ? const Color(0xFF090D14) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          context.tr('btn_save_changes'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                    foregroundColor: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(context.tr('btn_cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
