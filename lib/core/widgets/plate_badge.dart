import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Biển số xe hiển thị như biển trắng chữ đen của Việt Nam.
/// "51K12345" → "51K-123.45".
class PlateBadge extends StatelessWidget {
  final String plate;
  final double fontSize;

  const PlateBadge({super.key, required this.plate, this.fontSize = 15});

  static String format(String raw) {
    final s = raw.replaceAll(RegExp(r'[\s\-.]'), '').toUpperCase();
    // Ưu tiên dạng 5 số (51K-123.45), sau đó dạng 4 số (30A-1234).
    final m = RegExp(r'^(\d{2}[A-Z]{1,2}\d?)(\d{5})$').firstMatch(s) ??
        RegExp(r'^(\d{2}[A-Z]{1,2}\d?)(\d{4})$').firstMatch(s);
    if (m == null) return s;
    final series = m.group(1)!;
    final number = m.group(2)!;
    final tail = number.length == 5
        ? '${number.substring(0, 3)}.${number.substring(3)}'
        : number;
    return '$series-$tail';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = format(plate);
    return Semantics(
      label: 'Biển số $text',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.55,
          vertical: fontSize * 0.28,
        ),
        decoration: BoxDecoration(
          color: p.plateBg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.ink, width: 1.4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text.isEmpty ? '—' : text,
            maxLines: 1,
            style: AppTypography.plate(size: fontSize, color: p.plateText),
          ),
        ),
      ),
    );
  }
}
