import 'dart:convert';

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
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prm393_frontend/core/config/api_endpoints.dart';
import 'package:prm393_frontend/core/config/app_config.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import 'package:prm393_frontend/core/storage/secure_storage_service.dart';
import 'package:prm393_frontend/features/auth/data/models/user_model.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
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
          final displayName =
              user?.fullName ?? user?.userName ?? 'Nguyễn Thành Long';
          final email = user?.email ?? 'longnguyenthanh07102005@gmail.com';
          final phone = user?.phoneNumber ?? '0987 654 321';
          final role = user?.roleName ?? 'Khách hàng VIP';
          final initial =
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckRequested());
            },
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: context.space(AppSpacing.pagePadding)),
              children: [
                SizedBox(height: context.space(12)),

                // ============================================================
                // HERO PROFILE CARD (Titanium Architectural Pass)
                // ============================================================
                Container(
                  padding: EdgeInsets.all(context.space(20)),
                  decoration: BoxDecoration(
                    gradient: AppColors.titaniumCardGradient,
                    borderRadius: BorderRadius.circular(context.space(16)),
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
                          Icon(Icons.verified_rounded,
                              color: AppColors.secondary,
                              size: context.iconSize(16)),
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
                          borderRadius:
                              BorderRadius.circular(context.space(20)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded,
                                color: Colors.amberAccent, size: 16),
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
                _buildSectionHeader(context,
                    title: 'Thông tin cá nhân',
                    actionLabel: 'Chỉnh sửa', onAction: () {
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
                          _showFeatureNotice(
                              context, 'Quản lý danh sách phương tiện');
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
                          _showFeatureNotice(
                              context, 'Gọi tổng đài hỗ trợ bãi xe');
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
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Text(
            value,
            style: AppTypography.telemetryMono.copyWith(
              fontSize: context.sp(18),
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
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
            child: Icon(icon,
                size: context.iconSize(20), color: AppColors.primary),
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
      trailing:
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
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
        margin: EdgeInsets.fromLTRB(
            16, 0, 16, MediaQuery.paddingOf(context).bottom + 90),
      ),
    );
  }

  bool _profileBusy = false;
  int _avatarVersion = 0;

  void _showProfileMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

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
    } catch (_) {
      debugPrint('Không thể lưu bản sao hồ sơ vào bộ nhớ thiết bị.');
    }
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
        throw const AppException(
          message: 'Ảnh đại diện không được vượt quá 5 MB.',
        );
      }
      final extension = image.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (mimeType == null) {
        throw const AppException(
          message: 'Vui lòng chọn ảnh JPEG, PNG hoặc WebP.',
        );
      }
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty || bytes.length > maxSize) {
        throw const AppException(
          message: 'Ảnh không hợp lệ hoặc vượt quá 5 MB.',
        );
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
      _showProfileMessage('Cập nhật ảnh đại diện thành công.');
    } on AppException catch (error) {
      _showProfileMessage(error.message);
    } catch (_) {
      _showProfileMessage(
        'Không thể cập nhật ảnh. Vui lòng kiểm tra quyền chọn ảnh và thử lại.',
      );
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
      label: 'Đổi ảnh đại diện',
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
                  : const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 14),
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
    final saved = await showResponsiveBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _EditProfileForm(
        currentName: currentName,
        currentPhone: currentPhone,
        onSave: (name, phone) async {
          if (!mounted) {
            throw const AppException(message: 'Màn hình hồ sơ đã đóng.');
          }
          setState(() => _profileBusy = true);
          try {
            final response = await api.put<UserModel>(
              ApiEndpoints.profile,
              data: {'fullName': name, 'phoneNumber': phone},
              fromJsonT: (json) =>
                  UserModel.fromJson(json as Map<String, dynamic>),
            );
            await _publishProfile(_readUpdatedProfile(response));
          } finally {
            if (mounted) setState(() => _profileBusy = false);
          }
        },
      ),
    );
    if (saved == true && mounted) {
      _showProfileMessage('Cập nhật thông tin cá nhân thành công.');
    }
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

class _EditProfileForm extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final Future<void> Function(String name, String phone) onSave;

  const _EditProfileForm({
    required this.currentName,
    required this.currentPhone,
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
    return PopScope(
      canPop: !_saving,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Chỉnh sửa thông tin',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập họ và tên.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập số điện thoại.'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu thay đổi'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed:
                  _saving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
  }
}
