import 'package:flutter/material.dart';

/// Biển số xe Việt Nam: nền trắng, viền đen ngoài và viền bạc trong.
/// Xe máy hiển thị 2 dòng ("59-X2" / "123.45"), ô tô 1 dòng ("51A-123.45").
class PbmsPlate extends StatelessWidget {
  final String licensePlate;
  final bool isMotorbike;

  /// Cỡ chữ của dòng số; mọi kích thước khác tỉ lệ theo.
  final double fontSize;

  const PbmsPlate({
    super.key,
    required this.licensePlate,
    required this.isMotorbike,
    this.fontSize = 22,
  });

  static const _ink = Color(0xFF0F172A);
  static const _silver = Color(0xFF94A3B8);

  /// Tách biển thành các dòng hiển thị. Không nhận dạng được thì giữ nguyên chuỗi gốc.
  static List<String> lines(String raw, {required bool isMotorbike}) {
    final compact = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    // Seri ô tô chỉ có chữ ("51A", "51LD"); xe máy thường là chữ + 1 số ("59-X2").
    final letters = RegExp(r'^(\d{2})([A-Z]{1,2})(\d{4,5})$');
    final withDigit = RegExp(r'^(\d{2})([A-Z]{1,2}\d)(\d{4,5})$');
    final match = (isMotorbike ? withDigit : letters).firstMatch(compact) ??
        (isMotorbike ? letters : withDigit).firstMatch(compact);
    if (match == null) return [raw.trim().toUpperCase()];
    final province = match.group(1)!;
    final series = match.group(2)!;
    final digits = match.group(3)!;
    final number = digits.length == 5 ? '${digits.substring(0, 3)}.${digits.substring(3)}' : digits;
    return isMotorbike ? ['$province-$series', number] : ['$province$series-$number'];
  }

  @override
  Widget build(BuildContext context) {
    final rows = lines(licensePlate, isMotorbike: isMotorbike);
    final style = TextStyle(
      fontSize: fontSize,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: fontSize * 0.04,
      color: _ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final radius = fontSize * 0.28;
    return Semantics(
      label: 'Biển số ${rows.join(' ')}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(fontSize * 0.12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _ink, width: 2),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: fontSize * 0.45, vertical: fontSize * 0.14),
          decoration: BoxDecoration(
            border: Border.all(color: _silver),
            borderRadius: BorderRadius.circular(radius * 0.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final line in rows) Text(line, maxLines: 1, style: style)],
          ),
        ),
      ),
    );
  }
}
