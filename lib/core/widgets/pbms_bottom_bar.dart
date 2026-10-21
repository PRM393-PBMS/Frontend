import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavTab({required this.icon, required this.activeIcon, required this.label});
}

/// Thanh điều hướng dưới: 4 tab + nút Ví ở giữa nhô lên, có nhãn như các tab khác.
/// Thanh trắng đặc, viền trên mảnh; không kính mờ, không hiệu ứng nảy.
class PbmsBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final List<NavTab> tabs;
  final IconData centerIcon;
  final String centerLabel;
  final VoidCallback onCenterTap;

  const PbmsBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.tabs,
    required this.centerIcon,
    required this.centerLabel,
    required this.onCenterTap,
  }) : assert(tabs.length == 4, 'Thanh dưới cần đúng 4 tab (2 bên nút giữa)');

  static const double barHeight = 64;
  static const double buttonSize = 52;

  /// Phần nút nhô lên trên mép thanh.
  static const double rise = 16;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget tab(int i) => Expanded(
          child: _NavItem(
            tab: tabs[i],
            active: currentIndex == i,
            onTap: () => onTabChanged(i),
          ),
        );

    return SizedBox(
      height: barHeight + rise + bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottom,
            child: Container(
              padding: EdgeInsets.only(bottom: bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  tab(0),
                  tab(1),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: centerLabel,
                      excludeSemantics: true,
                      child: InkResponse(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onCenterTap();
                        },
                        radius: 34,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              centerLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  tab(2),
                  tab(3),
                ],
              ),
            ),
          ),
          // Nút Ví: tròn teal nhô lên, bấm cùng vùng với nhãn bên dưới.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Center(
              child: ExcludeSemantics(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCenterTap();
                  },
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x290F172A), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Icon(centerIcon, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavTab tab;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : AppColors.textSecondaryLight;
    return Semantics(
      selected: active,
      button: true,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? tab.activeIcon : tab.icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
