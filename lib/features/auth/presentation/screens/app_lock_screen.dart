import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/services/app_lock_controller.dart';
import 'package:prm393_frontend/core/services/biometric_service.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';

/// Lớp phủ che nội dung khi ứng dụng bị khoá, tự mở hộp thoại sinh trắc học.
class AppLockScreen extends StatefulWidget {
  final AppLockController controller;

  const AppLockScreen({super.key, required this.controller});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    setState(() => _message = null);
    final result = await widget.controller.unlock();
    if (!mounted) return;
    setState(() {
      _message = switch (result) {
        BiometricResult.success || BiometricResult.unavailable => null,
        BiometricResult.canceled => 'Bạn đã huỷ xác thực.',
        BiometricResult.lockedOut =>
          'Sai quá nhiều lần. Mở khoá màn hình điện thoại rồi thử lại.',
        BiometricResult.failed => 'Không xác thực được. Thử lại.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.controller.isAuthenticating;
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: PbmsTokens.tealTint,
                      border: Border.all(color: PbmsTokens.tealLine),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fingerprint_rounded,
                        size: 40, color: PbmsTokens.teal),
                  ),
                  const SizedBox(height: 18),
                  const Text('PBMS đã khoá',
                      textAlign: TextAlign.center, style: PbmsText.headline),
                  const SizedBox(height: 6),
                  const Text(
                    'Bạn rời ứng dụng hơn 1 phút. Xác thực bằng vân tay, khuôn mặt hoặc mã khoá máy để tiếp tục.',
                    textAlign: TextAlign.center,
                    style: PbmsText.caption,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(_message!,
                        textAlign: TextAlign.center,
                        style: PbmsText.caption
                            .copyWith(color: PbmsTokens.danger)),
                  ],
                  const Spacer(flex: 2),
                  PbmsPrimaryButton(
                    label: 'Mở khoá',
                    icon: Icons.fingerprint_rounded,
                    busy: busy,
                    onPressed: _unlock,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () =>
                            context.read<AuthBloc>().add(AuthLogoutRequested()),
                    style: TextButton.styleFrom(
                        foregroundColor: PbmsTokens.muted,
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('Đăng xuất và đăng nhập lại'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
