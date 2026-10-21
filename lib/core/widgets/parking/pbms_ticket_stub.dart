import 'package:flutter/material.dart';

/// Cuống vé gửi xe: thân vé ở trên, cuống ở dưới, ngăn bằng đường xé đứt đoạn
/// với hai vết khuyết tròn ở hai mép. Giấy trắng ngà, đổ bóng nhẹ.
class PbmsTicketStub extends StatelessWidget {
  final Widget body;
  final Widget stub;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const PbmsTicketStub({
    super.key,
    required this.body,
    required this.stub,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
  });

  static const paper = Color(0xFFF9F9F6);
  static const perforation = Color(0xFFCBD5E1);
  static const double notch = 11;
  static const double radius = 14;

  static const _shadows = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 14, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  Widget _half({required bool top, required Widget child}) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: paper,
        shadows: _shadows,
        shape: _TicketEdge(notchAtBottom: top),
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: _TicketEdge(notchAtBottom: top),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _half(top: true, child: body),
        _half(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Đường xé nằm ngay mép trên của cuống, giữa hai vết khuyết.
              Transform.translate(
                offset: Offset(0, -padding.resolve(TextDirection.ltr).top),
                child: const SizedBox(height: 1, child: CustomPaint(painter: _DashPainter())),
              ),
              stub,
            ],
          ),
        ),
      ],
    );
  }
}

/// Hình chữ nhật bo góc, khuyết một phần tư vòng tròn ở hai góc giáp đường xé.
class _TicketEdge extends ShapeBorder {
  final bool notchAtBottom;

  const _TicketEdge({required this.notchAtBottom});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const r = PbmsTicketStub.radius;
    const n = PbmsTicketStub.notch;
    final path = Path();
    if (notchAtBottom) {
      path
        ..moveTo(rect.left, rect.top + r)
        ..arcToPoint(Offset(rect.left + r, rect.top), radius: const Radius.circular(r))
        ..lineTo(rect.right - r, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + r), radius: const Radius.circular(r))
        ..lineTo(rect.right, rect.bottom - n)
        ..arcToPoint(Offset(rect.right - n, rect.bottom), radius: const Radius.circular(n), clockwise: false)
        ..lineTo(rect.left + n, rect.bottom)
        ..arcToPoint(Offset(rect.left, rect.bottom - n), radius: const Radius.circular(n), clockwise: false)
        ..close();
    } else {
      path
        ..moveTo(rect.left, rect.top + n)
        ..arcToPoint(Offset(rect.left + n, rect.top), radius: const Radius.circular(n), clockwise: false)
        ..lineTo(rect.right - n, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + n), radius: const Radius.circular(n), clockwise: false)
        ..lineTo(rect.right, rect.bottom - r)
        ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: const Radius.circular(r))
        ..lineTo(rect.left + r, rect.bottom)
        ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: const Radius.circular(r))
        ..close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PbmsTicketStub.perforation
      ..strokeWidth = 1.2;
    const dash = 6.0;
    const gap = 5.0;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
