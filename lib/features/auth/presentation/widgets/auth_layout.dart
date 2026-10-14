import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Dấu nhận diện PBMS: ô vuông bo góc chứa chữ P.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        'P',
        style: AppTypography.headline.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: size * 0.52,
          height: 1,
        ),
      ),
    );
  }
}

/// Bố cục chung cho các màn xác thực: tiêu đề căn trái, form giới hạn bề rộng.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;
  final bool showBrand;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
    this.showBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xl,
                AppSpacing.page, AppSpacing.xxxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBrand) ...[
                    const Align(
                        alignment: Alignment.centerLeft, child: BrandMark()),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                  Text(title,
                      style: AppTypography.headline
                          .copyWith(color: p.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle,
                      style:
                          AppTypography.body.copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
