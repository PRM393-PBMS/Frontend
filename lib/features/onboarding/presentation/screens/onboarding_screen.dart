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

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBcBr4h8KuaIDqw9BzmKTLbcNwVrwtrzTKx1bFt0Uud5pCYl4oW0yMF56Xh7yB2Vh820R-WQn9lhywqw4R5JMRlD-4SDv8w2n1y7qj-OfmgaOiPkxOQtmOql0V3iW2L2YjUNc2eIUaTw-dyBPgV5RhH0qtJs05mPNwQhQ3zffXX5bIjBADh1IROW0vpY0WqZo6k0nOvncTYX5fmxmEtPCZqH761Pv__VHs_ULz8wf2Dtcmjwr9t82yd';

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      title: 'Đỗ xe thông minh, trọn vẹn thảnh thơi',
      description:
          'Tìm và đặt trước vị trí đỗ xe còn trống theo thời gian thực. Dẫn đường chuẩn xác, thanh toán tiện lợi cùng ưu đãi mỗi ngày.',
      imageUrl: _heroImage,
      sensorTag: 'Vị trí #402 • Đã giữ chỗ',
    ),
    OnboardingSlideData(
      title: 'Đến đúng chỗ, không mất thời gian',
      description:
          'Xem chỗ trống được cập nhật liên tục và đi theo chỉ dẫn đến bãi đỗ đã chọn.',
      imageUrl: _heroImage,
      sensorTag: 'Bãi xe cập nhật trực tiếp',
    ),
    OnboardingSlideData(
      title: 'Thanh toán gọn nhẹ, ưu đãi mỗi ngày',
      description:
          'Sử dụng mã QR để ra vào thuận tiện, theo dõi chi phí và nhận ưu đãi dành riêng cho hội viên.',
      imageUrl: _heroImage,
      sensorTag: 'Mã QR • Ưu đãi hội viên',
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
      backgroundColor: const Color(0xFFF7FAFC),
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
                label: _currentPage == _slides.length - 1
                    ? 'Bắt đầu ngay'
                    : _currentPage == 0
                        ? 'Bắt đầu ngay'
                        : 'Tiếp tục',
                onPressed: _onGetStarted,
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  text: 'Tiếp tục đồng nghĩa với việc bạn đồng ý với ',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  children: [
                    TextSpan(
                      text: 'Điều khoản dịch vụ',
                      style: const TextStyle(
                        color: Color(0xFF087B8C),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
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
              foregroundColor: const Color(0xFF64748B),
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
          backgroundColor: const Color(0xFF087B8C),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x1A0F172A),
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
