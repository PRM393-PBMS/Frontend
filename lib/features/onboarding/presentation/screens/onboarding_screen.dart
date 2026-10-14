import '../../../../core/l10n/locale_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/storage/preferences_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class _Slide {
  final String title;
  final String body;
  final Alignment focus;

  const _Slide(this.title, this.body, this.focus);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _image =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBcBr4h8KuaIDqw9BzmKTLbcNwVrwtrzTKx1bFt0Uud5pCYl4oW0yMF56Xh7yB2Vh820R-WQn9lhywqw4R5JMRlD-4SDv8w2n1y7qj-OfmgaOiPkxOQtmOql0V3iW2L2YjUNc2eIUaTw-dyBPgV5RhH0qtJs05mPNwQhQ3zffXX5bIjBADh1IROW0vpY0WqZo6k0nOvncTYX5fmxmEtPCZqH761Pv__VHs_ULz8wf2Dtcmjwr9t82yd';

  static const _slideCount = 3;

  List<_Slide> _slides(BuildContext context) => [
        _Slide(context.l10n.onb1Title, context.l10n.onb1Body, Alignment.center),
        _Slide(context.l10n.onb2Title, context.l10n.onb2Body,
            Alignment.centerLeft),
        _Slide(context.l10n.onb3Title, context.l10n.onb3Body,
            Alignment.centerRight),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await PreferencesHelper.markOnboardingCompleted();
    if (mounted) context.go(RouteNames.login);
  }

  void _next() {
    if (_page < _slideCount - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = _page == _slideCount - 1;
    final slides = _slides(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: AppButton.text(
                        label: context.l10n.onbSkip, onPressed: _finish),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final s = slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.page),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: AppSpacing.surface,
                                child: CachedNetworkImage(
                                  imageUrl: _image,
                                  fit: BoxFit.cover,
                                  alignment: s.focus,
                                  width: double.infinity,
                                  placeholder: (_, __) =>
                                      ColoredBox(color: p.surfaceMuted),
                                  errorWidget: (_, __, ___) => ColoredBox(
                                    color: p.surfaceMuted,
                                    child: Icon(Icons.local_parking_rounded,
                                        size: 64, color: p.textMuted),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Text(s.title,
                                style: AppTypography.headline
                                    .copyWith(color: p.textPrimary)),
                            const SizedBox(height: AppSpacing.md),
                            Text(s.body,
                                style: AppTypography.body
                                    .copyWith(color: p.textSecondary)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page,
                      AppSpacing.xl, AppSpacing.page, AppSpacing.xl),
                  child: Row(
                    children: [
                      Row(
                        children: List.generate(slides.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.only(right: 6),
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? p.accent : p.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      AppButton(
                        label:
                            last ? context.l10n.onbStart : context.l10n.onbNext,
                        expand: false,
                        onPressed: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
