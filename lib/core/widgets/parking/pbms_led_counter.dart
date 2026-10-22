import 'package:flutter/material.dart';

/// Một ô trên bảng LED: loại xe và số chỗ trống.
typedef PbmsLedEntry = ({String label, int available});

/// Bảng LED chỗ trống như ở cổng bãi: nền tối, số lớn chữ số đều độ rộng.
/// Hết chỗ thì hiện "HẾT" màu đỏ nhạt.
class PbmsLedCounter extends StatelessWidget {
  final List<PbmsLedEntry> entries;

  /// Dòng nhỏ phía trên, ví dụ tên bãi hoặc số bãi.
  final String? caption;
  final VoidCallback? onTap;

  const PbmsLedCounter({super.key, required this.entries, this.caption, this.onTap});

  static const panel = Color(0xFF0B1220);
  static const lit = Color(0xFF7FE3EE);
  static const full = Color(0xFFFCA5A5);
  static const dim = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final semantics = entries
        .map((e) => '${e.label} ${e.available > 0 ? 'còn ${e.available} chỗ' : 'hết chỗ'}')
        .join(', ');
    return Semantics(
      button: onTap != null,
      label: '${caption == null ? '' : '$caption. '}$semantics',
      excludeSemantics: true,
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(caption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dim)),
                      ),
                      if (onTap != null) const Icon(Icons.map_outlined, size: 18, color: dim),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: const Color(0xFF1E293B),
                        ),
                      Expanded(child: _Cell(entry: entries[i])),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final PbmsLedEntry entry;

  const _Cell({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasRoom = entry.available > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PbmsLedCounter.dim)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            hasRoom ? '${entry.available}' : 'HẾT',
            style: TextStyle(
              fontSize: 44,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: hasRoom ? PbmsLedCounter.lit : PbmsLedCounter.full,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(hasRoom ? 'chỗ trống' : 'đã đầy',
            style: const TextStyle(fontSize: 12, color: PbmsLedCounter.dim)),
      ],
    );
  }
}
