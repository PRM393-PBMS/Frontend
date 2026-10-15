import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_visuals.dart';

/// Màn chờ trong lúc kiểm tra phiên đăng nhập.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.panel,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 72),
            const SizedBox(height: 20),
            Text('PBMS Parking', style: t.headlineSmall?.copyWith(color: AppColors.panelText)),
            const SizedBox(height: 28),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.cobaltBright,
                backgroundColor: AppColors.panelRaised,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
