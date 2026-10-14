import '../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/auth/presentation/blocs/auth_event.dart';
import '../../features/auth/presentation/blocs/auth_state.dart';
import '../../features/auth/presentation/widgets/auth_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import 'biometric_service.dart';

/// Khóa ứng dụng bằng sinh trắc học khi mở app và khi quay lại sau thời gian ở nền.
/// Chỉ áp dụng khi người dùng đã đăng nhập và bật tính năng trong Tài khoản.
class AppLockGate extends StatefulWidget {
  final Widget child;

  /// Ở nền ngắn hơn khoảng này (vd. chuyển sang trang PayOS rồi quay lại) thì không khóa.
  static const Duration relockAfter = Duration(seconds: 30);

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _bio = BiometricService.instance;
  bool _locked = false;
  bool _checkedColdStart = false;
  bool _authenticating = false;
  DateTime? _backgroundedAt;
  String? _error;
  IconData _icon = Icons.fingerprint_rounded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _checkedColdStart) return;
      final status = context.read<AuthBloc>().state.status;
      if (status == AuthStatus.authenticated) {
        _checkedColdStart = true;
        _lockIfNeeded();
      } else if (status == AuthStatus.unauthenticated) {
        _checkedColdStart = true;
      }
    });
    _bio.enrolledTypes().then((types) {
      if (mounted &&
          types.contains(BiometricType.face) &&
          !types.contains(BiometricType.fingerprint)) {
        setState(() => _icon = Icons.face_rounded);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _shouldLock() async =>
      context.read<AuthBloc>().state.isAuthenticated &&
      await _bio.isEnabled() &&
      await _bio.isAvailable();

  Future<void> _lockIfNeeded() async {
    if (_locked) return;
    if (await _shouldLock()) {
      if (!mounted) return;
      setState(() {
        _locked = true;
        _error = null;
      });
      _unlock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since != null &&
          DateTime.now().difference(since) >= AppLockGate.relockAfter) {
        _lockIfNeeded();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });
    final ok = await _bio.authenticate(reason: context.l10n.lockReason);
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) {
        _locked = false;
      } else {
        _error = context.l10n.lockFailed;
      }
    });
  }

  void _logout() {
    setState(() => _locked = false);
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, cur) => prev.status != cur.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && !_checkedColdStart) {
          // Phiên được khôi phục khi mở app: yêu cầu sinh trắc học.
          _checkedColdStart = true;
          _lockIfNeeded();
        } else if (state.status == AuthStatus.unauthenticated) {
          _checkedColdStart = true;
          if (_locked) setState(() => _locked = false);
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_locked)
            Positioned.fill(
                child: _LockScreen(
              icon: _icon,
              busy: _authenticating,
              error: _error,
              onUnlock: _unlock,
              onLogout: _logout,
            )),
        ],
      ),
    );
  }
}

class _LockScreen extends StatelessWidget {
  final IconData icon;
  final bool busy;
  final String? error;
  final VoidCallback onUnlock;
  final VoidCallback onLogout;

  const _LockScreen({
    required this.icon,
    required this.busy,
    required this.error,
    required this.onUnlock,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.select((AuthBloc b) => b.state.user);
    return Material(
      color: p.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  const BrandMark(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(context.l10n.lockTitle,
                      style: AppTypography.headline
                          .copyWith(color: p.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.lockMessage(user?.displayName ?? ''),
                    style: AppTypography.body.copyWith(color: p.textSecondary),
                  ),
                  const Spacer(),
                  Center(
                    child: Semantics(
                      button: true,
                      label: context.l10n.lockSemantics,
                      child: InkWell(
                        onTap: busy ? null : onUnlock,
                        borderRadius: BorderRadius.circular(48),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: p.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 48, color: p.accent),
                        ),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(error!,
                        textAlign: TextAlign.center,
                        style:
                            AppTypography.bodySmall.copyWith(color: p.danger)),
                  ],
                  const Spacer(flex: 2),
                  AppButton(
                    label: context.l10n.lockUnlock,
                    icon: icon,
                    loading: busy,
                    onPressed: onUnlock,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                      label: context.l10n.commonLogout,
                      onPressed: busy ? null : onLogout),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
