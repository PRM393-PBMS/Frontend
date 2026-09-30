import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class OnboardingSlideData {
  final String title;
  final String description;
  final String imageUrl;
  final String sensorTag;

  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.sensorTag,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroStage(imageUrl: data.imageUrl, sensorTag: data.sensorTag),
                const SizedBox(height: 22),
                _PageIndicator(count: pageCount, activeIndex: activeIndex),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroStage extends StatelessWidget {
  final String imageUrl;
  final String sensorTag;

  const _HeroStage({required this.imageUrl, required this.sensorTag});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = (constraints.maxWidth / 1.6).clamp(160.0, 260.0);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xCCE2E8F0)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1.6,
            child: SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Semantics(
                    image: true,
                    label: 'Xe điện đỗ tại vị trí đã đặt trước',
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Color(0xFFF1F5F9),
                        child: Center(
                          child: Icon(
                            Icons.local_parking_rounded,
                            size: 42,
                            color: Color(0xFF087B8C),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFF1F5F9),
                        child: Center(
                          child: Icon(
                            Icons.local_parking_rounded,
                            size: 42,
                            color: Color(0xFF087B8C),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _SensorTag(label: sensorTag),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _PageIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF087B8C) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _SensorTag extends StatelessWidget {
  final String label;

  const _SensorTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFBFC).withValues(alpha: 0.94),
        border: Border.all(color: const Color(0xFF97DFEB)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 7, color: Color(0xFF087B8C)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF087B8C),
            ),
          ),
        ],
      ),
    );
  }
}
