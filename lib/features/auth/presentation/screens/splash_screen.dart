import '../../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/auth_layout.dart';

/// Màn khởi động trong lúc kiểm tra phiên đăng nhập. Router tự chuyển khi có kết quả.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              const BrandMark(size: 56),
              const SizedBox(height: AppSpacing.xl),
              Text('PBMS Parking',
                  style: AppTypography.display.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(context.l10n.splashTagline,
                  style: AppTypography.body.copyWith(color: p.textSecondary)),
              const Spacer(flex: 4),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: p.textMuted),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(context.l10n.splashChecking,
                      style:
                          AppTypography.caption.copyWith(color: p.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
