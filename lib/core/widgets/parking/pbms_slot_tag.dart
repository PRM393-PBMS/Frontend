import 'package:flutter/material.dart';

/// Mã ô đỗ kiểu sơn trên sàn bãi: chữ trắng đậm trên nền mực.
class PbmsSlotTag extends StatelessWidget {
  final String code;

  const PbmsSlotTag(this.code, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ô đỗ $code',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          code,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
