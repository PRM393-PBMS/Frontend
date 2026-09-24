import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import '../models/vehicle_card_model.dart';
import 'vehicle_card_item.dart';

class VehicleCarousel extends StatefulWidget {
  final List<VehicleCardModel> cards;
  final ValueChanged<int>? onCardChanged;
  final int initialIndex;
  final bool isUnlocked;
  final VoidCallback? onTapToUnlock;

  const VehicleCarousel({
    super.key,
    required this.cards,
    this.onCardChanged,
    this.initialIndex = 0,
    this.isUnlocked = false,
    this.onTapToUnlock,
  });

  @override
  State<VehicleCarousel> createState() => VehicleCarouselState();
}

class VehicleCarouselState extends State<VehicleCarousel> {
  late PageController _pageController;
  late double _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.toDouble();
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 0.87, // Hiển thị lấp ló thẻ 2 bên chuẩn Samsung Wallet
    )..addListener(() {
        if (mounted) {
          setState(() {
            _currentPage = _pageController.page ?? 0.0;
          });
        }
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void animateToPage(int index) {
    if (index >= 0 && index < widget.cards.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Container(
        height: context.space(210),
        alignment: Alignment.center,
        child: Text(
          'Chưa có phương tiện nào trong mục này',
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: context.sp(14),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CAROUSEL VIEWPORT
        SizedBox(
          height: context.space(224),
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            onPageChanged: (index) {
              widget.onCardChanged?.call(index);
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final card = widget.cards[index];
              final difference = (index - _currentPage).abs();
              final scale = (1.0 - (difference * 0.08)).clamp(0.90, 1.0);
              final opacity = (1.0 - (difference * 0.18)).clamp(0.72, 1.0);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: VehicleCardItem(
                    card: card,
                    isCurrent: index == _currentPage.round(),
                    isUnlocked: widget.isUnlocked && (index == _currentPage.round()),
                    onTapToUnlock: widget.onTapToUnlock,
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: context.space(10)),

        // SUBTLE PAGE INDICATOR (Samsung Wallet Style)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.cards.length, (index) {
            final isSelected = index == _currentPage.round();
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: context.space(3)),
              width: isSelected ? context.space(18) : context.space(6),
              height: context.space(5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondaryLight.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(context.space(3)),
              ),
            );
          }),
        ),
      ],
    );
  }
}
