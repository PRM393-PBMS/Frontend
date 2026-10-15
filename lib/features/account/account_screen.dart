import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/error/error_text.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/panels.dart';
import '../../data/pbms_repository.dart';
import '../auth/domain/entities/user_entity.dart';
import '../auth/presentation/blocs/auth_bloc.dart';
import '../auth/presentation/blocs/auth_event.dart';
import '../auth/presentation/blocs/auth_state.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  /// Đồng bộ hồ sơ mới nhất từ `GET /api/profile`.
  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final user = await context.read<PbmsRepository>().getProfile();
      if (mounted) context.read<AuthBloc>().add(AuthProfileUpdated(user));
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn cần đăng nhập lại để xem vé và lượt gửi xe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.palette.danger),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _sync,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.scrollBottom),
            children: [
              Text('Tài khoản', style: t.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<AuthBloc, AuthState>(
                buildWhen: (a, b) => a.user != b.user,
                builder: (context, state) {
                  final user = state.user;
                  if (user == null) return const SizedBox.shrink();
                  return _ProfileCard(
                    user: user,
                    syncing: _syncing,
                    onEdit: () => EditProfileSheet.show(context, user),
                  );
                },
              ),
              const SectionHeader(title: 'Giao diện'),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.instance.themeModeNotifier,
                builder: (context, mode, _) => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined, size: 18),
                        label: Text('Theo máy'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.wb_sunny_outlined, size: 18),
                        label: Text('Sáng'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.nights_stay_outlined, size: 18),
                        label: Text('Tối'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => ThemeController.instance.setThemeMode(s.first),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Chế độ tối dịu mắt khi lái xe ban đêm hoặc trong hầm gửi xe.',
                style: t.bodySmall,
              ),
              const SectionHeader(title: 'Hỗ trợ'),
              AppPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_none_rounded),
                      title: const Text('Thông báo'),
                      trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
                      onTap: () => context.push(RouteNames.notificationsPath),
                    ),
                    Divider(height: 1, color: p.line, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.report_gmailerrorred_rounded),
                      title: const Text('Báo cáo sự cố'),
                      subtitle: const Text('Ô bị chiếm, barie lỗi, sai phí'),
                      trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
                      onTap: () => context.push(RouteNames.incidentsPath),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.danger,
                  side: BorderSide(color: p.danger.withValues(alpha: 0.4)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Đăng xuất'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${AppConfig.appTitle} · phiên bản ${AppConfig.appVersion}',
                textAlign: TextAlign.center,
                style: t.labelSmall?.copyWith(color: p.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserEntity user;
  final bool syncing;
  final VoidCallback onEdit;

  const _ProfileCard({required this.user, required this.syncing, required this.onEdit});

  String get _initials {
    final name = (user.fullName?.trim().isNotEmpty ?? false) ? user.fullName!.trim() : user.userName;
    final parts = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: AppSpacing.roundedLg,
                ),
                child: Text(
                  _initials,
                  style: t.titleLarge?.copyWith(color: AppColors.panelText),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName?.trim().isNotEmpty == true ? user.fullName! : user.userName,
                      style: t.titleMedium,
                    ),
                    Text('@${user.userName}', style: t.bodySmall),
                  ],
                ),
              ),
              if (syncing)
                const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(label: 'Email', value: user.email),
          InfoRow(label: 'Điện thoại', value: user.phoneNumber ?? 'Chưa cập nhật', mono: user.phoneNumber != null),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            icon: Icon(Icons.edit_outlined, size: 18, color: p.text),
            label: const Text('Sửa thông tin'),
          ),
        ],
      ),
    );
  }
}

/// `PUT /api/profile`: họ tên, số điện thoại và (tuỳ chọn) mật khẩu mới.
class EditProfileSheet extends StatefulWidget {
  final UserEntity user;

  const EditProfileSheet({super.key, required this.user});

  static Future<void> show(BuildContext context, UserEntity user) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditProfileSheet(user: user),
      );

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName ?? '');
  late final _phone = TextEditingController(text: widget.user.phoneNumber ?? '');
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await context.read<PbmsRepository>().updateProfile(
            fullName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileUpdated(user));
      Navigator.pop(context);
      showSnack(context, 'Đã lưu thông tin tài khoản.');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sửa thông tin', style: t.headlineSmall),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Nhập họ tên' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: AppTypography.mono(size: 15, color: p.text),
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$').hasMatch((v ?? '').trim())
                    ? null
                    : 'Số di động Việt Nam 10 số, ví dụ 0912345678',
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới (không bắt buộc)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
                validator: (v) => (v ?? '').isNotEmpty && v!.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: t.bodyMedium?.copyWith(color: p.danger)),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
