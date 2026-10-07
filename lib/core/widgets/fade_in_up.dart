import 'package:flutter/material.dart';

/// Hiệu ứng chuyển động xúc giác tinh tế (Tactile Micro-Transition)
/// Chuẩn impeccable: 180ms - 240ms dứt khoát, độ dời ngắn (12px), loại bỏ độ trễ gây cảm giác lề mề
class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double from;

  const FadeInUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.delay = Duration.zero,
    this.from = 12.0,
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _translateAnimation = Tween<double>(begin: widget.from, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}
