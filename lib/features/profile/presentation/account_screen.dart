import '../data/profile_repository.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/utils/error_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/status_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/blocs/auth_bloc.dart';
import '../../auth/presentation/blocs/auth_event.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _bio = BiometricService.instance;
  bool _bioAvailable = false;
  bool _bioEnabled = false;
  bool _bioBusy = false;

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final available = await _bio.isAvailable();
    final enabled = await _bio.isEnabled();
    if (mounted) {
      setState(() {
        _bioAvailable = available;
        _bioEnabled = enabled && available;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _bioBusy = true);
    if (value) {
      final ok =
          await _bio.authenticate(reason: context.l10n.accBioReasonEnable);
      if (ok) {
        await _bio.setEnabled(true);
        if (mounted) showAppSnack(context, context.l10n.accBioEnabled);
      } else if (mounted) {
        showAppSnack(context, context.l10n.accBioFailed, error: true);
      }
      if (mounted) setState(() => _bioEnabled = ok);
    } else {
      await _bio.setEnabled(false);
      if (mounted) setState(() => _bioEnabled = false);
    }
    if (mounted) setState(() => _bioBusy = false);
  }

  bool _avatarBusy = false;

  Future<void> _changeAvatar() async {
    final t = context.l10n;
    final auth = context.read<AuthBloc>();
    final repo = context.read<ProfileRepository>();
    final file = await ImageCapture.pick(context, title: t.accAvatarChange);
    if (file == null || !mounted) return;
    // Backend giới hạn 5MB; kiểm tra trước để báo lỗi ngay.
    if (file.bytes.length > 5 * 1024 * 1024) {
      showAppSnack(context, t.accAvatarTooLarge, error: true);
      return;
    }
    setState(() => _avatarBusy = true);
    try {
      final updated = await repo.uploadAvatar(file);
      auth.add(AuthProfileUpdated(updated));
      if (mounted) showAppSnack(context, t.accAvatarUpdated);
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(e, t), error: true);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmAction(
      context,
      title: context.l10n.accLogoutTitle,
      message: context.l10n.accLogoutMessage,
      confirmLabel: context.l10n.commonLogout,
      destructive: true,
    );
    if (ok && mounted) context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.select((AuthBloc b) => b.state.user);
    final base =
        (user?.isStaff ?? false) ? RouteNames.staffAccount : RouteNames.account;
    final initials = (user?.displayName ?? '?')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .toList();
    final avatar = initials.isEmpty
        ? '?'
        : (initials.length == 1
                ? initials.first
                : '${initials.first}${initials.last}')
            .toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navAccount)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.sm, AppSpacing.page, 120),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _AvatarButton(
                      initials: avatar,
                      url: user?.avatarUrl,
                      busy: _avatarBusy,
                      onTap: _changeAvatar,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? '',
                              style: AppTypography.title
                                  .copyWith(color: p.textPrimary)),
                          const SizedBox(height: 2),
                          Text(StatusLabels.role(context.l10n, user?.roleName),
                              style: AppTypography.caption
                                  .copyWith(color: p.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppSurface(
                  child: Column(
                    children: [
                      KeyValueRow(
                          context.l10n.fieldUserName, user?.userName ?? ''),
                      KeyValueRow(context.l10n.fieldEmail, user?.email ?? ''),
                      KeyValueRow(
                          context.l10n.fieldPhone,
                          (user?.phoneNumber?.isNotEmpty ?? false)
                              ? user!.phoneNumber!
                              : context.l10n.commonNone),
                    ],
                  ),
                ),
                if (user?.isCustomer ?? false) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: ListTile(
                      leading:
                          const Icon(Icons.account_balance_wallet_outlined),
                      title: Text(context.l10n.walletTitle),
                      trailing:
                          Icon(Icons.chevron_right_rounded, color: p.textMuted),
                      onTap: () => context.push(RouteNames.wallet),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(context.l10n.accProfileSecurity),
                AppSurface(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(context.l10n.accEditProfile),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: p.textMuted),
                        onTap: () => context.push('$base/edit'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: Text(context.l10n.pwdTitle),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: p.textMuted),
                        onTap: () => context.push('$base/password'),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint_rounded),
                        title: Text(context.l10n.accBioTitle),
                        subtitle: Text(_bioAvailable
                            ? context.l10n.accBioOn
                            : context.l10n.accBioUnavailable),
                        value: _bioEnabled,
                        onChanged: !_bioAvailable || _bioBusy
                            ? null
                            : _toggleBiometric,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(context.l10n.accAppearance),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.instance.themeModeNotifier,
                  builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(context.l10n.accThemeSystem)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(context.l10n.accThemeLight)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(context.l10n.accThemeDark)),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) =>
                        ThemeController.instance.setThemeMode(s.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(context.l10n.accLanguage),
                ValueListenableBuilder<Locale>(
                  valueListenable: LocaleController.instance.localeNotifier,
                  builder: (context, locale, _) => SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final l in AppLocalizations.supportedLocales)
                        ButtonSegment(
                          value: l.languageCode,
                          label: Text(
                              languageNames[l.languageCode] ?? l.languageCode),
                        ),
                    ],
                    selected: {locale.languageCode},
                    onSelectionChanged: (s) =>
                        LocaleController.instance.setLocale(Locale(s.first)),
                  ),
                ),
                if (user?.isStaff ?? false) ...[
                  const SizedBox(height: AppSpacing.xl),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.local_parking_rounded),
                    title: Text(context.l10n.accAvailability),
                    trailing:
                        Icon(Icons.chevron_right_rounded, color: p.textMuted),
                    onTap: () => context.push(RouteNames.staffAvailability),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                AppButton.secondary(
                    label: context.l10n.commonLogout,
                    icon: Icons.logout_rounded,
                    onPressed: _logout),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(context.l10n.versionLabel(AppConfig.appVersion),
                      style:
                          AppTypography.caption.copyWith(color: p.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh đại diện có thể chạm để đổi. Hiện chữ viết tắt khi chưa có ảnh hoặc ảnh lỗi.
class _AvatarButton extends StatelessWidget {
  final String initials;
  final String? url;
  final bool busy;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.initials,
    required this.url,
    required this.busy,
    required this.onTap,
  });

  /// Backend có thể trả URL đầy đủ hoặc đường dẫn tương đối (uploads/avatars/...).
  static String? resolve(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/${v.replaceAll(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final src = resolve(url);
    final fallback = Center(
      child:
          Text(initials, style: AppTypography.title.copyWith(color: p.accent)),
    );
    return Semantics(
      button: true,
      label: context.l10n.accAvatarChange,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: AppSpacing.surface,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: AppSpacing.surface,
                  child: ColoredBox(
                    color: p.accentSoft,
                    child: src == null
                        ? fallback
                        : CachedNetworkImage(
                            imageUrl: src,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => fallback,
                            errorWidget: (_, __, ___) => fallback,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: p.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border),
                  ),
                  child: busy
                      ? Padding(
                          padding: const EdgeInsets.all(5),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: p.accent),
                        )
                      : Icon(Icons.photo_camera_outlined,
                          size: 14, color: p.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
