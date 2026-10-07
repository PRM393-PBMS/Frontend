import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class RadialOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const RadialOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// ============================================================================
// PRECISION MINIMALIST BOTTOM NAV BAR (SWISS DOCKED / FLOATING CAPSULE)
// ============================================================================

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final List<NavTab> tabs;
  final List<RadialOption> radialOptions;
  final VoidCallback onCenterTap;
  final IconData centerIcon;
  final Color centerColor;
  final bool showCenterButton;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.tabs,
    this.radialOptions = const [],
    required this.onCenterTap,
    this.centerIcon = Icons.add_rounded,
    this.centerColor = AppColors.primary,
    this.showCenterButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.borderLight,
                width: AppSpacing.hairline,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTabChanged(index);
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primarySubtle
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isSelected ? tab.activeIcon : tab.icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab.label,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
