import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/storage/preferences_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/widgets/auth_visuals.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    OnboardingSlideData(
      title: 'Biết còn chỗ trước khi tới',
      description: 'Số ô trống theo từng tầng cập nhật trực tiếp từ bãi, không phải vòng xe tìm chỗ.',
      visual: OnboardingVisual.capacity,
    ),
    OnboardingSlideData(
      title: 'Giữ chỗ, quét mã qua cổng',
      description: 'Đặt trước tối đa 5 giờ cho ô tô. Tới nơi đưa mã QR vào đầu đọc, barie tự mở.',
      visual: OnboardingVisual.ticket,
    ),
    OnboardingSlideData(
      title: 'Phí rõ ràng từng dòng',
      description: 'Xem phí tạm tính bất cứ lúc nào, tiền cọc tự trừ. Thanh toán qua PayOS hoặc tại cổng.',
      visual: OnboardingVisual.fee,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await PreferencesHelper.markOnboardingCompleted();
    if (mounted) context.go(RouteNames.loginPath);
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  const BrandMark(size: 36),
                  const Spacer(),
                  if (!last) TextButton(onPressed: _finish, child: const Text('Bỏ qua')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => OnboardingSlide(data: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Semantics(
                    label: 'Trang ${_page + 1} trên ${_slides.length}',
                    child: Row(
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _page ? 22 : 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i == _page ? p.accent : p.line,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 52),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    ),
                    child: Text(last ? 'Bắt đầu' : 'Tiếp'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
