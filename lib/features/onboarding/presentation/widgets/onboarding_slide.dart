import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/panels.dart';
import '../../../../core/widgets/plate_badge.dart';

enum OnboardingVisual { capacity, ticket, fee }

class OnboardingSlideData {
  final String title;
  final String description;
  final OnboardingVisual visual;

  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.visual,
  });
}

/// Một trang giới thiệu: minh hoạ bằng chính các thành phần giao diện thật của app.
class OnboardingSlide extends StatelessWidget {
  final OnboardingSlideData data;

  const OnboardingSlide({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: _Visual(kind: data.visual)),
              const SizedBox(height: AppSpacing.xxxl),
              Text(data.title, style: t.displaySmall),
              const SizedBox(height: AppSpacing.md),
              Text(data.description, style: t.bodyLarge?.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Visual extends StatelessWidget {
  final OnboardingVisual kind;

  const _Visual({required this.kind});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final body = switch (kind) {
      OnboardingVisual.capacity => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (floor, free, total) in const [
              ('Tầng B1 · Ô tô', 18, 60),
              ('Tầng B2 · Ô tô', 4, 60),
              ('Tầng 1 · Xe máy', 0, 120),
            ]) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(floor, style: t.titleSmall?.copyWith(color: AppColors.panelText)),
                  ),
                  Text(
                    free == 0 ? 'Hết chỗ' : '$free trống',
                    style: AppTypography.mono(
                      size: 14,
                      weight: FontWeight.w700,
                      color: free == 0
                          ? AppColors.signalBright
                          : free < 10
                              ? AppColors.amberBright
                              : AppColors.emeraldBright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(extensions: const [AppPalette.dark]),
                child: CapacityBar(available: free, total: total, track: AppColors.panelRaised),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      OnboardingVisual.ticket => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PlateBadge(plate: '51K12345', fontSize: 16),
                  const SizedBox(height: 18),
                  Text('Giờ vào', style: t.labelSmall?.copyWith(color: AppColors.panelMuted)),
                  Text('18:30',
                      style: AppTypography.mono(size: 34, weight: FontWeight.w600, color: AppColors.panelText)),
                ],
              ),
            ),
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: AppSpacing.roundedMd),
              child: const Icon(Icons.qr_code_2_rounded, size: 76, color: AppColors.ink),
            ),
          ],
        ),
      OnboardingVisual.fee => Column(
          children: [
            for (final (label, value) in const [
              ('Lượt đầu (2 giờ)', '30.000 ₫'),
              ('1 giờ tiếp theo', '10.000 ₫'),
              ('Đã đặt cọc', '−30.000 ₫'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: t.bodyMedium?.copyWith(color: AppColors.panelMuted))),
                    Text(value, style: AppTypography.mono(size: 14, weight: FontWeight.w600, color: AppColors.panelText)),
                  ],
                ),
              ),
            const Divider(color: AppColors.panelLine),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('Cần trả', style: t.titleSmall?.copyWith(color: AppColors.panelText))),
                Text('10.000 ₫',
                    style: AppTypography.mono(size: 24, weight: FontWeight.w700, color: AppColors.panelText)),
              ],
            ),
          ],
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.panelLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          const SizedBox(height: 12),
          Text(
            'Ví dụ minh hoạ',
            textAlign: TextAlign.end,
            style: t.labelSmall?.copyWith(color: AppColors.panelMuted),
          ),
        ],
      ),
    );
  }
}
