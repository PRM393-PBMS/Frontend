import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/core/localization/app_translations.dart';
import '../models/vehicle_card_model.dart';
import 'vehicle_card_item.dart';

class VehicleCarousel extends StatefulWidget {
  final List<VehicleCardModel> cards;
  final ValueChanged<int>? onCardChanged;
  final int initialIndex;
  final bool isUnlocked;
  final VoidCallback? onTapToUnlock;

  final VoidCallback? onAddVehicle;
  final ValueChanged<VehicleCardModel>? onTapPendingPayment;

  const VehicleCarousel({
    super.key,
    required this.cards,
    this.onCardChanged,
    this.initialIndex = 0,
    this.isUnlocked = false,
    this.onTapToUnlock,
    this.onAddVehicle,
    this.onTapPendingPayment,
  });

  @override
  State<VehicleCarousel> createState() => VehicleCarouselState();
}

class VehicleCarouselState extends State<VehicleCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 0.87, // Hiển thị lấp ló thẻ 2 bên chuẩn Samsung Wallet
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.cards.isEmpty) {
      return Container(
        height: context.space(210),
        margin: EdgeInsets.symmetric(horizontal: context.space(20)),
        padding: EdgeInsets.all(context.space(20)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(context.space(16)),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('empty_vehicles_title'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.sp(15),
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('empty_vehicles_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: context.sp(11.5),
              ),
            ),
            if (widget.onAddVehicle != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: widget.onAddVehicle,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(context.tr('btn_register_now')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF090D14),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final double currentPage = (_pageController.hasClients && _pageController.page != null)
            ? _pageController.page!
            : widget.initialIndex.toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CAROUSEL VIEWPORT
            SizedBox(
              height: context.space(236),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.cards.length,
                onPageChanged: (index) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      widget.onCardChanged?.call(index);
                    }
                  });
                },
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final card = widget.cards[index];
                  final difference = (index - currentPage).abs();
                  final scale = (1.0 - (difference * 0.08)).clamp(0.90, 1.0);
                  final opacity = (1.0 - (difference * 0.18)).clamp(0.72, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: VehicleCardItem(
                        card: card,
                        isCurrent: index == currentPage.round(),
                        isUnlocked: widget.isUnlocked && (index == currentPage.round()),
                        onTapToUnlock: widget.onTapToUnlock,
                        onTapPendingPayment: () => widget.onTapPendingPayment?.call(card),
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
                final isSelected = index == currentPage.round();
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
      },
    );
  }
}
