import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavTab({required this.icon, required this.activeIcon, required this.label});
}

/// Thanh điều hướng dưới: 4 tab + nút tròn lớn ở giữa (Ví của tôi) nhô lên khỏi
/// thanh, có vòng hở cùng màu nền trang bao quanh. Nhấn: nảy nhẹ rồi gọi [onCenterTap].
class PbmsBottomBar extends StatefulWidget {
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

  static const double barHeight = 68;
  static const double buttonSize = 62;

  /// Phần nút nhô lên trên mép thanh.
  static const double rise = 22;

  /// Độ dày vòng hở quanh nút.
  static const double gap = 5;

  @override
  State<PbmsBottomBar> createState() => _PbmsBottomBarState();
}

class _PbmsBottomBarState extends State<PbmsBottomBar> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  // Co lại khi chạm, bật lên quá cỡ một chút, rồi về cỡ thường.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88).chain(CurveTween(curve: Curves.easeOut)), weight: 18),
    TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.12).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 34),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.97).chain(CurveTween(curve: Curves.easeInOut)), weight: 24),
    TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 24),
  ]).animate(_bounce);

  // Nút nhích lên vài điểm ảnh lúc bật.
  late final Animation<double> _lift = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 2.0), weight: 18),
    TweenSequenceItem(tween: Tween(begin: 2.0, end: -6.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 34),
    TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 48),
  ]).animate(_bounce);

  bool _busy = false;

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _tapCenter() async {
    if (_busy) return;
    _busy = true;
    HapticFeedback.lightImpact();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduceMotion) {
      // Mở trang ngay sau đỉnh nảy để chuyển cảnh liền mạch.
      _bounce.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 210));
    }
    if (mounted) widget.onCenterTap();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    const total = PbmsBottomBar.buttonSize + 2 * PbmsBottomBar.gap;
    final tabs = widget.tabs;

    Widget tab(int i) => Expanded(
          child: _NavItem(
            tab: tabs[i],
            active: widget.currentIndex == i,
            onTap: () => widget.onTabChanged(i),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: SizedBox(
        height: PbmsBottomBar.barHeight + PbmsBottomBar.rise,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Thanh kính mờ.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: PbmsBottomBar.barHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        tab(0),
                        tab(1),
                        const SizedBox(width: total + 4),
                        tab(2),
                        tab(3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Nút Ví ở giữa, nhô lên, vòng hở cùng màu nền trang.
            Positioned(
              bottom: PbmsBottomBar.barHeight + PbmsBottomBar.rise - total,
              child: Semantics(
                button: true,
                label: widget.centerLabel,
                child: GestureDetector(
                  onTap: _tapCenter,
                  child: AnimatedBuilder(
                    animation: _bounce,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _lift.value),
                      child: Transform.scale(scale: _scale.value, child: child),
                    ),
                    child: Container(
                      width: total,
                      height: total,
                      padding: const EdgeInsets.all(PbmsBottomBar.gap),
                      decoration: const BoxDecoration(
                        color: AppColors.bgLight,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x290F172A),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(widget.centerIcon, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.brandTint : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(active ? tab.activeIcon : tab.icon, size: 22, color: color),
            ),
            const SizedBox(height: 3),
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
