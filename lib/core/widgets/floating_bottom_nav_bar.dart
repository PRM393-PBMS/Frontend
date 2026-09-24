import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/responsive_utils.dart';

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
// FLOATING BOTTOM NAV BAR
// ============================================================================

class FloatingBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final List<NavTab> tabs;
  final List<RadialOption> radialOptions;
  final VoidCallback onCenterTap;
  final IconData centerIcon;
  final Color centerColor;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.tabs,
    required this.radialOptions,
    required this.onCenterTap,
    this.centerIcon = Icons.add_rounded,
    this.centerColor = AppColors.primary,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar>
    with TickerProviderStateMixin {
  // ---- Animation Controllers ----
  late final AnimationController _animCtrl;
  late final AnimationController _overlayCtrl;
  late final AnimationController _bounceCtrl;

  late final Animation<double> _menuProg;
  late final Animation<double> _overlayOp;
  late final Animation<double> _bounceAnim;

  // ---- Overlay & State ----
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  final ValueNotifier<int> _highlightedNotifier = ValueNotifier<int>(-1);
  final GlobalKey _centerKey = GlobalKey();
  Offset _centerPos = Offset.zero;
  double _centerR = 28.0;

  // Semicircle geometry constants – Full 180 degrees (Horizontal left to horizontal right)
  static const double kInnerRadius = 52.0;
  static const double kOuterRadius = 182.0;         // Bigger, spacious radius
  static const double kStartAngle = -math.pi;        // Exactly -180 degrees (horizontal left)
  static const double kTotalSweep = math.pi;         // Exactly 180 degrees (full semicircle)
  static const double kGap = 0.046;                 // Equal gap between sectors (~2.6 deg)

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Monotonic curve [0.0 -> 1.0] without negative overshoot
    _menuProg = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _overlayOp = CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeOut);

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.20), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.00), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeOverlayImmediate();
    _animCtrl.dispose();
    _overlayCtrl.dispose();
    _bounceCtrl.dispose();
    _highlightedNotifier.dispose();
    super.dispose();
  }

  void _removeOverlayImmediate() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _computeCenter() {
    final ctx = _centerKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final g = box.localToGlobal(Offset.zero);
        _centerR = box.size.shortestSide / 2;
        _centerPos = g + Offset(_centerR, _centerR);
        return;
      }
    }
    final size = MediaQuery.sizeOf(context);
    _centerPos = Offset(size.width / 2, size.height - 56);
  }

  void _openMenu() {
    HapticFeedback.mediumImpact();
    _computeCenter();
    _highlightedNotifier.value = -1;

    setState(() {
      _isMenuOpen = true;
    });

    _removeOverlayImmediate();
    _overlayEntry = OverlayEntry(
      builder: (context) => _SemicircleRadialOverlay(
        centerPos: _centerPos,
        options: widget.radialOptions,
        highlightedNotifier: _highlightedNotifier,
        anim: _menuProg,
        overlayOpacity: _overlayOp,
        onDismiss: () => _closeMenu(),
        innerRadius: kInnerRadius,
        outerRadius: kOuterRadius,
        startAngle: kStartAngle,
        totalSweep: kTotalSweep,
        gap: kGap,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward(from: 0);
    _overlayCtrl.forward(from: 0);
    _bounceCtrl.forward(from: 0);
  }

  void _closeMenu({RadialOption? executeOption}) {
    if (!_isMenuOpen) return;

    _animCtrl.reverse();
    _overlayCtrl.reverse().then((_) {
      _removeOverlayImmediate();
      if (mounted) {
        setState(() {
          _isMenuOpen = false;
        });
      }
      if (executeOption != null) {
        HapticFeedback.mediumImpact();
        executeOption.onTap();
      }
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isMenuOpen) return;
    _updateHighlight(details.globalPosition);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isMenuOpen) return;
    final idx = _highlightedNotifier.value;
    final opt = (idx >= 0 && idx < widget.radialOptions.length)
        ? widget.radialOptions[idx]
        : null;
    _closeMenu(executeOption: opt);
  }

  void _updateHighlight(Offset gp) {
    final dx = gp.dx - _centerPos.dx;
    final dy = gp.dy - _centerPos.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Dead zone: finger inside the center button
    if (dist < kInnerRadius * 0.90) {
      if (_highlightedNotifier.value != -1) {
        _highlightedNotifier.value = -1;
      }
      return;
    }

    // Too far outside the semicircle
    if (dist > kOuterRadius * 1.35) {
      if (_highlightedNotifier.value != -1) {
        _highlightedNotifier.value = -1;
      }
      return;
    }

    double touchAngle = math.atan2(dy, dx);
    // Allow slight tolerance if finger moves slightly below horizontal baseline
    if (touchAngle > 0) {
      if (touchAngle < 0.40) {
        touchAngle = 0.0;
      } else if (touchAngle > math.pi - 0.40) {
        touchAngle = -math.pi;
      } else {
        if (_highlightedNotifier.value != -1) {
          _highlightedNotifier.value = -1;
        }
        return;
      }
    }

    final count = widget.radialOptions.length;
    final sliceSweep = (kTotalSweep - (count - 1) * kGap) / count;

    int best = -1;
    for (int i = 0; i < count; i++) {
      final sStart = kStartAngle + i * (sliceSweep + kGap) - (i == 0 ? 0.30 : kGap / 2);
      final sEnd = sStart + sliceSweep + (i == count - 1 ? 0.30 : kGap);

      if (touchAngle >= sStart && touchAngle <= sEnd) {
        best = i;
        break;
      }
    }

    if (best != _highlightedNotifier.value) {
      _highlightedNotifier.value = best;
      if (best != -1) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = MediaQuery.paddingOf(context).bottom;
    return _GlassPill(
      tabs: widget.tabs,
      currentIndex: widget.currentIndex,
      onTabChanged: widget.onTabChanged,
      onCenterTap: _isMenuOpen ? null : widget.onCenterTap,
      onCenterLongPressStart: (_) => _openMenu(),
      onCenterLongPressMoveUpdate: _onLongPressMoveUpdate,
      onCenterLongPressEnd: _onLongPressEnd,
      centerKey: _centerKey,
      centerIcon: widget.centerIcon,
      centerColor: widget.centerColor,
      bounceAnim: _bounceAnim,
      isMenuOpen: _isMenuOpen,
      bp: bp,
    );
  }
}

// ============================================================================
// GLASS PILL BAR
// ============================================================================

class _GlassPill extends StatelessWidget {
  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onCenterTap;
  final GestureLongPressStartCallback onCenterLongPressStart;
  final GestureLongPressMoveUpdateCallback onCenterLongPressMoveUpdate;
  final GestureLongPressEndCallback onCenterLongPressEnd;
  final GlobalKey centerKey;
  final IconData centerIcon;
  final Color centerColor;
  final Animation<double> bounceAnim;
  final bool isMenuOpen;
  final double bp;

  const _GlassPill({
    required this.tabs,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onCenterTap,
    required this.onCenterLongPressStart,
    required this.onCenterLongPressMoveUpdate,
    required this.onCenterLongPressEnd,
    required this.centerKey,
    required this.centerIcon,
    required this.centerColor,
    required this.bounceAnim,
    required this.isMenuOpen,
    required this.bp,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.space;
    return Padding(
      padding: EdgeInsets.fromLTRB(sp(16), 0, sp(16), sp(14) + bp),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(sp(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: sp(70),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(sp(32)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.80),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: sp(26),
                  offset: Offset(0, sp(6)),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: sp(40),
                  offset: Offset(0, sp(2)),
                ),
              ],
            ),
            child: Row(
              children: [
                // Tab 0 & 1
                Expanded(child: _NavItem(tab: tabs[0], tabIndex: 0, cur: currentIndex, onTap: onTabChanged)),
                Expanded(child: _NavItem(tab: tabs[1], tabIndex: 1, cur: currentIndex, onTap: onTabChanged)),

                // Center Action Button (Hold to open Semicircle)
                SizedBox(
                  width: sp(72),
                  child: Center(
                    child: GestureDetector(
                      onTap: onCenterTap,
                      onLongPressStart: onCenterLongPressStart,
                      onLongPressMoveUpdate: onCenterLongPressMoveUpdate,
                      onLongPressEnd: onCenterLongPressEnd,
                      child: AnimatedBuilder(
                        animation: bounceAnim,
                        builder: (_, child) => Transform.scale(
                          scale: (bounceAnim.value).clamp(0.5, 2.0),
                          child: child,
                        ),
                        child: Container(
                          key: centerKey,
                          width: sp(56),
                          height: sp(56),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                centerColor,
                                Color.lerp(centerColor, AppColors.accent, 0.40) ?? centerColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: centerColor.withValues(alpha: 0.45),
                                blurRadius: sp(18),
                                offset: Offset(0, sp(6)),
                              ),
                            ],
                          ),
                          child: AnimatedRotation(
                            turns: isMenuOpen ? 0.125 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              isMenuOpen ? Icons.close_rounded : centerIcon,
                              color: Colors.white,
                              size: context.iconSize(28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Tab 2 & 3
                Expanded(child: _NavItem(tab: tabs[2], tabIndex: 3, cur: currentIndex, onTap: onTabChanged)),
                Expanded(child: _NavItem(tab: tabs[3], tabIndex: 4, cur: currentIndex, onTap: onTabChanged)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NAV ITEM
// ============================================================================

class _NavItem extends StatelessWidget {
  final NavTab tab;
  final int tabIndex;
  final int cur;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.tab,
    required this.tabIndex,
    required this.cur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = cur == tabIndex;
    return GestureDetector(
      onTap: () => onTap(tabIndex),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(context.space(5)),
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(context.space(11)),
            ),
            child: Icon(
              active ? tab.activeIcon : tab.icon,
              size: context.iconSize(22),
              color: active ? AppColors.primary : AppColors.textMutedLight,
            ),
          ),
          SizedBox(height: context.space(2)),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: AppTypography.labelMedium.copyWith(
              fontSize: context.sp(10),
              color: active ? AppColors.primary : AppColors.textMutedLight,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(tab.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEMICIRCLE RADIAL OVERLAY – Full 180° Large Pie Semicircle Menu
// ============================================================================

class _SemicircleRadialOverlay extends StatelessWidget {
  final Offset centerPos;
  final List<RadialOption> options;
  final ValueNotifier<int> highlightedNotifier;
  final Animation<double> anim;
  final Animation<double> overlayOpacity;
  final VoidCallback onDismiss;
  final double innerRadius;
  final double outerRadius;
  final double startAngle;
  final double totalSweep;
  final double gap;

  const _SemicircleRadialOverlay({
    required this.centerPos,
    required this.options,
    required this.highlightedNotifier,
    required this.anim,
    required this.overlayOpacity,
    required this.onDismiss,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.totalSweep,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final count = options.length;
    // Exactly equal gaps: total gaps = (count - 1) * gap
    final sliceSweep = (totalSweep - (count - 1) * gap) / count;
    final midRadius = (innerRadius + outerRadius) / 2;

    return Stack(
      children: [
        // 1. Full-screen backdrop blur
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: AnimatedBuilder(
              animation: overlayOpacity,
              builder: (ctx, _) => Container(
                color: Colors.black.withValues(
                  alpha: (0.30 * overlayOpacity.value).clamp(0.0, 0.45),
                ),
              ),
            ),
          ),
        ),

        // 2. Full 180° Semicircle Pie Canvas + Centered Option Content
        AnimatedBuilder(
          animation: anim,
          builder: (ctx, _) {
            final expansion = (anim.value).clamp(0.001, 1.0);

            return ValueListenableBuilder<int>(
              valueListenable: highlightedNotifier,
              builder: (ctx, highlightedIdx, _) {
                return Stack(
                  children: [
                    // Canvas drawing the 4 equal-gapped sectors of the 180° Semicircle
                    CustomPaint(
                      size: MediaQuery.sizeOf(context),
                      painter: _SemicirclePiePainter(
                        center: centerPos,
                        options: options,
                        highlightedIndex: highlightedIdx,
                        innerRadius: innerRadius * expansion,
                        outerRadius: outerRadius * expansion,
                        startAngle: startAngle,
                        sliceSweep: sliceSweep,
                        gap: gap,
                        expansion: expansion,
                      ),
                    ),

                    // Icons & Labels centered in each slice
                    for (int i = 0; i < count; i++)
                      Builder(builder: (ctx) {
                        // Mid-angle of slice i
                        final midAngle = startAngle + i * (sliceSweep + gap) + sliceSweep / 2;
                        final currentMidRadius = midRadius * expansion;
                        final posX = centerPos.dx + math.cos(midAngle) * currentMidRadius;
                        final posY = centerPos.dy + math.sin(midAngle) * currentMidRadius;

                        final isHighlighted = highlightedIdx == i;

                        return Positioned(
                          left: posX,
                          top: posY,
                          child: Transform.translate(
                            offset: const Offset(-41, -30), // center the 82x60 container
                            child: Transform.scale(
                              scale: (expansion * (isHighlighted ? 1.15 : 1.0)).clamp(0.01, 1.5),
                              child: Opacity(
                                opacity: expansion.clamp(0.0, 1.0),
                                child: SizedBox(
                                  width: 82,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        options[i].icon,
                                        size: isHighlighted ? 30 : 26,
                                        color: isHighlighted ? Colors.white : options[i].color,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        options[i].label,
                                        style: AppTypography.labelMedium.copyWith(
                                          fontSize: 11,
                                          color: isHighlighted ? Colors.white : AppColors.textPrimaryLight,
                                          fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// SEMICIRCLE PIE CUSTOM PAINTER – Exact 180° with Equal Gaps
// ============================================================================

class _SemicirclePiePainter extends CustomPainter {
  final Offset center;
  final List<RadialOption> options;
  final int highlightedIndex;
  final double innerRadius;
  final double outerRadius;
  final double startAngle;
  final double sliceSweep;
  final double gap;
  final double expansion;

  _SemicirclePiePainter({
    required this.center,
    required this.options,
    required this.highlightedIndex,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sliceSweep,
    required this.gap,
    required this.expansion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (expansion <= 0.01) return;

    final count = options.length;

    for (int i = 0; i < count; i++) {
      // Each slice starts with an exact equal gap of 'gap' from the previous slice
      final sStart = startAngle + i * (sliceSweep + gap);
      final isHighlighted = highlightedIndex == i;

      // Expand the highlighted sector outward
      final currentOuter = isHighlighted ? outerRadius + 10.0 : outerRadius;
      final currentInner = isHighlighted ? math.max(0.0, innerRadius - 2.0) : innerRadius;

      final path = Path();
      path.arcTo(
        Rect.fromCircle(center: center, radius: currentOuter),
        sStart,
        sliceSweep,
        false,
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: currentInner),
        sStart + sliceSweep,
        -sliceSweep,
        false,
      );
      path.close();

      // 1. Draw glowing drop shadow for highlighted slice
      if (isHighlighted) {
        final shadowPaint = Paint()
          ..color = options[i].color.withValues(alpha: 0.50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
        canvas.drawPath(path, shadowPaint);
      } else {
        final subtleShadow = Paint()
          ..color = Colors.black.withValues(alpha: 0.09)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawPath(path, subtleShadow);
      }

      // 2. Fill the slice (Vibrant option color when active, elegant frosted glass when normal)
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isHighlighted
            ? options[i].color
            : Colors.white.withValues(alpha: 0.94);
      canvas.drawPath(path, fillPaint);

      // 3. Crisp modern stroke border
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 2.2 : 1.4
        ..color = isHighlighted
            ? options[i].color.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.88);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemicirclePiePainter oldDelegate) {
    return oldDelegate.highlightedIndex != highlightedIndex ||
        oldDelegate.expansion != expansion ||
        oldDelegate.center != center;
  }
}