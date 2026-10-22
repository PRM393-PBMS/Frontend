import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';

class OnboardingSlideData {
  final String title;
  final String description;

  /// Hình minh hoạ dựng từ chính các thành phần của app (biển số, bảng chỗ trống, vé).
  final WidgetBuilder illustration;

  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

class OnboardingSlide extends StatelessWidget {
  final OnboardingSlideData data;
  final int activeIndex;
  final int pageCount;

  const OnboardingSlide({
    super.key,
    required this.data,
    required this.activeIndex,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Stage(child: data.illustration(context)),
            const SizedBox(height: 28),
            _PageIndicator(count: pageCount, activeIndex: activeIndex),
            const SizedBox(height: 16),
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung chứa hình minh hoạ, ghi rõ đây là ví dụ.
class _Stage extends StatelessWidget {
  final Widget child;

  const _Stage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 14,
            top: 12,
            child: Text('Ví dụ', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              child: ExcludeSemantics(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _PageIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Trang ${activeIndex + 1} trên $count',
      child: Row(
        children: List.generate(count, (index) {
          final isActive = index == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 6),
            width: isActive ? 24 : 8,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.brand : AppColors.borderLight,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

/// Minh hoạ các slide.
class OnboardingIllustrations {
  OnboardingIllustrations._();

  static Widget plate(BuildContext context) => const FittedBox(
        child: Row(
          children: [
            PbmsPlate(licensePlate: '59X212345', isMotorbike: true, fontSize: 30),
            SizedBox(width: 18),
            Icon(Icons.arrow_forward_rounded, color: AppColors.textMutedLight),
            SizedBox(width: 18),
            Icon(Icons.door_sliding_outlined, size: 44, color: AppColors.brand),
          ],
        ),
      );

  static Widget board(BuildContext context) => const PbmsLedCounter(
        caption: 'Bãi PBMS',
        entries: [
          (label: 'Xe máy', available: 128),
          (label: 'Ô tô', available: 0),
        ],
      );

  static Widget ticket(BuildContext context) => SizedBox(
        width: 260,
        child: PbmsTicketStub(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PbmsPaidStamp(),
              const SizedBox(height: 8),
              Text('K7M2QX', style: PbmsText.display(30).copyWith(letterSpacing: 4)),
            ],
          ),
          stub: const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.brand),
              SizedBox(width: 8),
              Text('Quét ở cổng ra', style: PbmsText.bodyStrong),
            ],
          ),
        ),
      );
}
