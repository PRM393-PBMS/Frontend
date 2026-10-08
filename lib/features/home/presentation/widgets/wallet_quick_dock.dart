import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/core/localization/app_translations.dart';

enum WalletDockMode { quickAccess, allCards }

class WalletQuickDock extends StatelessWidget {
  final WalletDockMode currentMode;
  final ValueChanged<WalletDockMode> onModeChanged;

  const WalletQuickDock({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(context.space(4)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(context.space(24)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDockButton(
            context,
            mode: WalletDockMode.quickAccess,
            icon: Icons.credit_card_rounded,
            label: context.tr('dock_cards'),
          ),
          _buildDockButton(
            context,
            mode: WalletDockMode.allCards,
            icon: Icons.layers_outlined,
            label: context.tr('dock_list'),
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton(
    BuildContext context, {
    required WalletDockMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onModeChanged(mode);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: context.space(20),
          vertical: context.space(8),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cardDark : const Color(0xFFF1F5F9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(context.space(20)),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1))
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.iconSize(16),
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            SizedBox(width: context.space(6)),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                fontSize: context.sp(11.5),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
