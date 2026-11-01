import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';

/// Ghim bãi trên Google Maps: viên giá "P 30k · 12 chỗ" có mũi nhọn chỉ xuống,
/// trắng khi thường, teal khi đang chọn. Google Maps không nhận widget làm ghim
/// nên vẽ thẳng lên canvas rồi chuyển thành ảnh.
class LotMarkerIcon {
  LotMarkerIcon._();

  static const _height = 34.0;
  static const _padX = 10.0;
  static const _tip = 7.0;
  static const _shadow = 6.0;

  /// Trả về ảnh PNG và vị trí mũi nhọn (tỉ lệ 0..1) để đặt `anchor` cho ghim.
  static Future<(BitmapDescriptor, Offset)> build({
    required int available,
    int? basePrice,
    required bool selected,
    required double devicePixelRatio,
    String? fontFamily,
  }) async {
    final bg = selected ? PbmsTokens.teal : Colors.white;
    final fg = selected ? Colors.white : PbmsTokens.ink;
    final soft = selected ? const Color(0xFFE4F7F8) : PbmsTokens.muted;

    TextPainter text(String s, Color color, {double size = 12, FontWeight weight = FontWeight.w700, String? family}) =>
        TextPainter(
          text: TextSpan(
            text: s,
            style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: family ?? fontFamily),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

    final icon = text(
      String.fromCharCode(Icons.local_parking_rounded.codePoint),
      selected ? Colors.white : PbmsTokens.teal,
      size: 15,
      weight: FontWeight.w400,
      family: Icons.local_parking_rounded.fontFamily,
    );
    final price = basePrice == null ? null : text('${(basePrice / 1000).round()}k', fg);
    final room = text('$available chỗ', soft, weight: FontWeight.w600);

    final contentW = icon.width + 5 + (price == null ? 0 : price.width + 6) + room.width;
    final pillW = contentW + _padX * 2;
    final width = pillW + _shadow * 2;
    final height = _shadow + _height + _tip + _shadow;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(devicePixelRatio);

    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(_shadow, _shadow, pillW, _height),
      const Radius.circular(_height / 2),
    );
    final cx = width / 2;
    final tipY = _shadow + _height + _tip;
    // Viên giá và mũi nhọn gộp thành một hình liền để không lộ đường nối.
    final shape = Path.combine(
      PathOperation.union,
      Path()..addRRect(pill),
      Path()
        ..moveTo(cx - _tip, _shadow + _height - 2)
        ..lineTo(cx, tipY)
        ..lineTo(cx + _tip, _shadow + _height - 2)
        ..close(),
    );
    canvas.drawShadow(shape, PbmsTokens.ink.withValues(alpha: 0.5), 3, false);
    canvas.drawPath(shape, Paint()..color = bg);
    if (!selected) {
      canvas.drawPath(
        shape,
        Paint()
          ..color = PbmsTokens.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    var x = _shadow + _padX;
    double centerY(TextPainter p) => _shadow + (_height - p.height) / 2;
    icon.paint(canvas, Offset(x, centerY(icon)));
    x += icon.width + 5;
    if (price != null) {
      price.paint(canvas, Offset(x, centerY(price)));
      x += price.width + 6;
    }
    room.paint(canvas, Offset(x, centerY(room)));

    final image = await recorder
        .endRecording()
        .toImage((width * devicePixelRatio).ceil(), (height * devicePixelRatio).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return (
      BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: devicePixelRatio),
      Offset(0.5, tipY / height),
    );
  }
}
