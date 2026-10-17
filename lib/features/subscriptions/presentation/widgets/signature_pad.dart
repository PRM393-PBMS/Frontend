import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';

/// Điều khiển bảng ký: biết đã có nét chưa, xoá, xuất PNG nền trắng.
class SignatureController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  List<List<Offset>> get strokes => _strokes;

  /// Đủ nét để coi là một chữ ký (tránh một chấm vô tình).
  bool get hasSignature =>
      _strokes.fold<int>(0, (sum, s) => sum + s.length) >= 12;

  void _start(Offset p) {
    _strokes.add([p]);
    notifyListeners();
  }

  void _extend(Offset p) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(p);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  /// Ảnh PNG nét mực đen trên nền trắng, độ phân giải gấp đôi khung ký.
  Future<Uint8List?> toPng({double scale = 2}) async {
    if (!hasSignature || _size.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    canvas.drawRect(Offset.zero & _size, Paint()..color = Colors.white);
    _SignaturePainter.paintStrokes(canvas, _strokes, const Color(0xFF0F172A));
    final image = await recorder
        .endRecording()
        .toImage((_size.width * scale).round(), (_size.height * scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}

/// Khung ký tay trên màn hình.
class SignaturePad extends StatelessWidget {
  final SignatureController controller;
  final double height;

  const SignaturePad({super.key, required this.controller, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Khung ký tay. Dùng ngón tay ký tên vào đây.',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PbmsTokens.border),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            controller._size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Chặn cuộn trang khi đang ký.
              onVerticalDragStart: (d) => controller._start(d.localPosition),
              onVerticalDragUpdate: (d) => controller._extend(d.localPosition),
              onHorizontalDragStart: (d) => controller._start(d.localPosition),
              onHorizontalDragUpdate: (d) => controller._extend(d.localPosition),
              onTapDown: (d) => controller._start(d.localPosition),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Stack(
                  children: [
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 40,
                      child: Container(height: 1, color: PbmsTokens.border),
                    ),
                    if (controller.strokes.isEmpty)
                      const Center(
                        child: Text('Ký tên của bạn vào đây',
                            style: PbmsText.caption),
                      ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SignaturePainter(controller.strokes),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter(this.strokes);

  static void paintStrokes(Canvas canvas, List<List<Offset>> strokes, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 1.3, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (var i = 1; i < s.length; i++) {
        // Làm mượt bằng trung điểm giữa các điểm chạm.
        final mid = Offset((s[i - 1].dx + s[i].dx) / 2, (s[i - 1].dy + s[i].dy) / 2);
        path.quadraticBezierTo(s[i - 1].dx, s[i - 1].dy, mid.dx, mid.dy);
      }
      path.lineTo(s.last.dx, s.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) =>
      paintStrokes(canvas, strokes, const Color(0xFF0F172A));

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
