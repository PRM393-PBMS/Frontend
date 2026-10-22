import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/features/legal/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/storage/preferences_helper.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      title: 'Camera đọc biển số, barie tự mở',
      description:
          'Thêm biển số xe vào tài khoản. Xe có vé tháng hoặc đã đặt chỗ được nhận ra ngay ở cổng.',
      illustration: OnboardingIllustrations.plate,
    ),
    OnboardingSlideData(
      title: 'Biết còn chỗ trước khi đến',
      description: 'Số chỗ trống xe máy và ô tô của từng bãi, cập nhật theo lượt xe ra vào.',
      illustration: OnboardingIllustrations.board,
    ),
    OnboardingSlideData(
      title: 'Trả phí trước, quét mã ra cổng',
      description:
          'Trả bằng ví PBMS hoặc chuyển khoản ngay trên app, rồi đưa mã ở cổng ra. Không cần đợi ở quầy.',
      illustration: OnboardingIllustrations.ticket,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await PreferencesHelper.markOnboardingCompleted();
    if (!mounted) return;
    context.go(RouteNames.loginPath);
  }

  void _onGetStarted() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _TopBar(onSkip: _finishOnboarding),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return OnboardingSlide(
                      data: _slides[index],
                      activeIndex: index,
                      pageCount: _slides.length,
                    );
                  },
                ),
              ),
              _PrimaryButton(
                label: _currentPage == _slides.length - 1 ? 'Bắt đầu' : 'Tiếp tục',
                onPressed: _onGetStarted,
              ),
              const SizedBox(height: 14),
              const LegalLinks(
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSkip;

  const _TopBar({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.textSecondaryLight,
            ),
            child: const Text('Bỏ qua', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
