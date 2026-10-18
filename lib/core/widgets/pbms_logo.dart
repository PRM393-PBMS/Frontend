import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Biến thể màu của logo (theo bản thiết kế "Logo Variations").
enum PbmsLogoVariant {
  /// Chữ P xanh giao thông, chấm xanh lá, trên nền sáng.
  color,

  /// Chữ P trắng trên nền xanh giao thông.
  reversedOnBlue,

  /// Một màu đen, trên nền sáng.
  mono,

  /// Chữ P trắng trên nền đen.
  reversedOnBlack,
}

/// Màu thương hiệu của logo. Chỉ dùng cho logo, không dùng cho giao diện
/// (giao diện dùng màu teal AppColors.brand).
class PbmsLogoColors {
  PbmsLogoColors._();

  static const blue = Color(0xFF0A47C2);
  static const green = Color(0xFF00A85A);
  static const black = Color(0xFF111318);
}

/// Logo PBMS: chữ P có vạch kẻ đường đứt khúc, hai vạch ô đỗ và chấm xanh.
/// Dưới 40px tự dùng bản rút gọn (bỏ các vạch) như bản thiết kế.
class PbmsLogo extends StatelessWidget {
  final double size;
  final PbmsLogoVariant variant;

  const PbmsLogo({super.key, this.size = 48, this.variant = PbmsLogoVariant.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo PBMS',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: PbmsLogoPainter(variant: variant, simplified: size <= 40)),
      ),
    );
  }
}

/// Vẽ logo trong hệ toạ độ viewBox "40 36 360 360" của SVG gốc.
class PbmsLogoPainter extends CustomPainter {
  final PbmsLogoVariant variant;
  final bool simplified;

  const PbmsLogoPainter({this.variant = PbmsLogoVariant.color, this.simplified = false});

  static const double _viewX = 40, _viewY = 36, _viewSize = 360;

  ({Color letter, Color detail, Color dot}) get _colors => switch (variant) {
        PbmsLogoVariant.color => (
            letter: PbmsLogoColors.blue,
            detail: Colors.white,
            dot: PbmsLogoColors.green,
          ),
        PbmsLogoVariant.reversedOnBlue => (
            letter: Colors.white,
            detail: PbmsLogoColors.blue,
            dot: PbmsLogoColors.green,
          ),
        PbmsLogoVariant.mono => (
            letter: PbmsLogoColors.black,
            detail: Colors.white,
            dot: PbmsLogoColors.black,
          ),
        PbmsLogoVariant.reversedOnBlack => (
            letter: Colors.white,
            detail: PbmsLogoColors.black,
            dot: PbmsLogoColors.green,
          ),
      };

  /// Chữ P (evenodd): thân + vòng, trừ lỗ tròn ở giữa.
  static Path letterPath() {
    return Path()
      ..fillType = PathFillType.evenOdd
      // M96 56H220A124 124 0 0 1 220 304H160V376H96Z
      ..moveTo(96, 56)
      ..lineTo(220, 56)
      ..arcToPoint(const Offset(220, 304), radius: const Radius.circular(124))
      ..lineTo(160, 304)
      ..lineTo(160, 376)
      ..lineTo(96, 376)
      ..close()
      // M160 240V180A60 60 0 1 1 220 240Z
      ..moveTo(160, 240)
      ..lineTo(160, 180)
      ..arcToPoint(const Offset(220, 240), radius: const Radius.circular(60), largeArc: true)
      ..close();
  }

  /// Vạch kẻ đường: M128 296V88H220A92 92 0 0 1 220 272H184
  static Path lanePath() {
    return Path()
      ..moveTo(128, 296)
      ..lineTo(128, 88)
      ..lineTo(220, 88)
      ..arcToPoint(const Offset(220, 272), radius: const Radius.circular(92))
      ..lineTo(184, 272);
  }

  /// Nét đứt "16 12" như stroke-dasharray của SVG.
  static Path dashed(Path source, {double dash = 16, double gap = 12}) {
    final out = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        out.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dash + gap;
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _viewSize;
    canvas.save();
    canvas.translate(
      (size.width - _viewSize * scale) / 2 - _viewX * scale,
      (size.height - _viewSize * scale) / 2 - _viewY * scale,
    );
    canvas.scale(scale);

    final c = _colors;
    canvas.drawPath(letterPath(), Paint()..color = c.letter);
    if (!simplified) {
      canvas.drawPath(
        dashed(lanePath()),
        Paint()
          ..color = c.detail
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
      final bars = Paint()..color = c.detail;
      canvas.drawRect(const Rect.fromLTWH(96, 320, 64, 8), bars);
      canvas.drawRect(const Rect.fromLTWH(96, 344, 64, 8), bars);
    }
    canvas.drawCircle(const Offset(220, 180), simplified ? 24 : 22, Paint()..color = c.dot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PbmsLogoPainter old) =>
      old.variant != variant || old.simplified != simplified;
}
