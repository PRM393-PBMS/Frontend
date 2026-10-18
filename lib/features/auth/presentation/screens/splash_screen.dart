import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/widgets/pbms_logo.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';

/// Màn chờ trong app: trùng với màn chờ native (nền trắng, logo giữa màn hình)
/// để chuyển cảnh liền mạch khi kiểm tra phiên đăng nhập.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PbmsLogo(size: 112),
            SizedBox(height: 20),
            Text('PBMS Parking', style: PbmsText.headline),
            SizedBox(height: 6),
            Text('Tìm bãi, đặt chỗ và gửi xe thông minh', style: PbmsText.caption),
            SizedBox(height: 28),
            SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: PbmsTokens.teal),
            ),
          ],
        ),
      ),
    );
  }
}
