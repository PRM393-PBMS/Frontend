import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/tile_layout.dart';
import 'lot_iso_painter.dart' show LotColors;

/// Vẽ đúng sơ đồ admin đã vẽ theo kiểu isometric: tầng chồng lên nhau, tầng đang chọn vẽ đủ từng ô
/// (tường, cột cao; ô đỗ màu theo trạng thái thật; lối đi phẳng có mũi tên), đường đi qua các tầng.
class TileIsoPainter extends CustomPainter {
  final TileLot lot;
  final String selectedFloorId;
  final TileGuide? guide;

  /// slotId -> trạng thái thường (available, occupied, assigned...).
  final Map<String, String> slotStatus;
  final double t;

  TileIsoPainter({
    required this.lot,
    required this.selectedFloorId,
    required this.slotStatus,
    this.guide,
    this.t = 0,
  });

  static const _cos = 0.8660254;
  static const _sin = 0.5;
  static const _thick = 0.3;

  late double _scale;
  late Offset _origin;
  late double _levelGap;
  late int _w;
  late int _h;

  Offset _p(double x, double y, int level, [double z = 0]) =>
      _origin + Offset((x - y) * _cos * _scale, ((x + y) * _sin - level * _levelGap - z) * _scale);

  @override
  void paint(Canvas canvas, Size size) {
    final n = lot.floors.length;
    if (n == 0) return;
    _w = lot.floors.map((f) => f.w).reduce(math.max);
    _h = lot.floors.map((f) => f.h).reduce(math.max);
    _levelGap = math.max(2.5, (_w + _h) * 0.18);
    final minX = -_h * _cos, maxX = _w * _cos;
    final minY = -(n - 1) * _levelGap - 2.0, maxY = (_w + _h) * _sin + 0.8;
    _scale = math.min(size.width / (maxX - minX), size.height / (maxY - minY)) * 0.95;
    _origin = Offset(
      (size.width - (maxX - minX) * _scale) / 2 - minX * _scale,
      (size.height - (maxY - minY) * _scale) / 2 - minY * _scale,
    );
    final sel = lot.floors.indexWhere((f) => f.floorId == selectedFloorId);
    for (var i = 0; i < n; i++) {
      final f = lot.floors[i];
      _slab(canvas, i, f, selected: i == sel, faded: sel >= 0 && i > sel);
      if (i == sel) _cells(canvas, f, i);
    }
    _route(canvas);
  }

  void _poly(Canvas canvas, List<Offset> pts, Color color) =>
      canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = color);

  void _slab(Canvas canvas, int level, TileFloor f, {required bool selected, required bool faded}) {
    final w = f.w.toDouble(), h = f.h.toDouble();
    final alpha = faded ? 0.18 : (selected ? 1.0 : 0.55);
    _poly(canvas, [_p(0, h, level), _p(w, h, level), _p(w, h, level, -_thick), _p(0, h, level, -_thick)],
        LotColors.slabSide.withValues(alpha: alpha));
    _poly(canvas, [_p(w, 0, level), _p(w, h, level), _p(w, h, level, -_thick), _p(w, 0, level, -_thick)],
        LotColors.slabSide.withValues(alpha: alpha * 0.8));
    final top = [_p(0, 0, level), _p(w, 0, level), _p(w, h, level), _p(0, h, level)];
    _poly(canvas, top, (selected ? Colors.white : LotColors.slab).withValues(alpha: alpha));
    canvas.drawPath(
        Path()..addPolygon(top, true),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 1.6 : 1
          ..color = (selected ? LotColors.route : LotColors.slabSide).withValues(alpha: faded ? 0.35 : 1));
    // Nhãn ở góc sau của sàn: không bị tường/ô phía trước che.
    _text(canvas, f.floorName, _p(0, 0, level) - const Offset(0, 9), selected ? 12 : 11, center: true, bold: selected,
        color: selected ? const Color(0xFF1E293B) : const Color(0xFF64748B));
  }

  Color _slotColor(TileCell c) {
    final s = slotStatus[c.slotId] ?? '';
    if (s == 'available') return LotColors.free;
    if (s == 'occupied') return LotColors.occupied;
    if (s == 'assigned') return LotColors.assigned;
    return LotColors.other;
  }

  void _cells(Canvas canvas, TileFloor f, int level) {
    final cells = [...f.cells]..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final target = guide?.slot;
    Offset? targetTop;
    for (final c in cells) {
      final x = c.x.toDouble(), y = c.y.toDouble();
      switch (c.t) {
        case 'road':
          _flat(canvas, x, y, level, LotColors.aisle);
          if (c.dir != null && _scale > 10) _arrow(canvas, x, y, level, c.dir!);
        case 'walk':
          _flat(canvas, x, y, level, const Color(0xFFBFDBFE));
        case 'moto':
          _flat(canvas, x, y, level, const Color(0xFF6EE7B7));
        case 'ramp':
          _flat(canvas, x, y, level, const Color(0xFFF59E0B));
          _text(canvas, '⇅', _p(x + 0.5, y + 0.5, level), _scale * 0.45, center: true, color: Colors.white);
        case 'stairs':
          _flat(canvas, x, y, level, const Color(0xFFFBBF24));
        case 'gate':
          final gateTop = _box(canvas, x + 0.1, y + 0.1, 0.8, level, 0.25, LotColors.route);
          _text(canvas, c.name ?? '', gateTop - Offset(0, _scale * 0.5), 10, center: true, bold: true);
        case 'wall':
          _box(canvas, x, y, 1, level, 0.45, const Color(0xFF475569));
        case 'pillar':
          _box(canvas, x + 0.3, y + 0.3, 0.4, level, 0.8, const Color(0xFF94A3B8));
        case 'kiosk':
          _box(canvas, x + 0.15, y + 0.15, 0.7, level, 0.55, const Color(0xFF8B5CF6));
        case 'slot':
          final hit = target != null && c.slotId == target.slotId && c.code == target.code;
          final h = hit ? 0.3 * (1.4 + 0.4 * math.sin(t * 2 * math.pi)) : 0.3;
          final slotTop = _box(canvas, x + 0.08, y + 0.08, 0.84, level, h, hit ? LotColors.target : _slotColor(c));
          if (hit) targetTop = slotTop;
          if (_scale >= 22) _text(canvas, c.code ?? '', slotTop, 8, center: true, color: const Color(0xFF0F172A));
      }
    }
    if (targetTop != null) _marker(canvas, targetTop);
  }

  void _flat(Canvas canvas, double x, double y, int level, Color color) {
    _poly(canvas, [_p(x, y, level), _p(x + 1, y, level), _p(x + 1, y + 1, level), _p(x, y + 1, level)], color);
  }

  void _arrow(Canvas canvas, double x, double y, int level, String dir) {
    const v = {'N': (0.0, -1.0), 'E': (1.0, 0.0), 'S': (0.0, 1.0), 'W': (-1.0, 0.0)};
    final (dx, dy) = v[dir]!;
    final a = _p(x + 0.5 - dx * 0.3, y + 0.5 - dy * 0.3, level);
    final b = _p(x + 0.5 + dx * 0.3, y + 0.5 + dy * 0.3, level);
    final paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint);
    final ang = math.atan2(b.dy - a.dy, b.dx - a.dx);
    for (final s in [-0.5, 0.5]) {
      canvas.drawLine(b, b - Offset(math.cos(ang + s) * 5, math.sin(ang + s) * 5), paint);
    }
  }

  /// Khối hộp; trả tâm mặt trên.
  Offset _box(Canvas canvas, double x, double y, double size, int level, double h, Color c) {
    Offset q(double dx, double dy, double z) => _p(x + dx, y + dy, level, z);
    final s = size;
    _poly(canvas, [q(0, s, 0), q(s, s, 0), q(s, s, h), q(0, s, h)], Color.lerp(c, Colors.black, 0.25)!);
    _poly(canvas, [q(s, 0, 0), q(s, s, 0), q(s, s, h), q(s, 0, h)], Color.lerp(c, Colors.black, 0.12)!);
    _poly(canvas, [q(0, 0, h), q(s, 0, h), q(s, s, h), q(0, s, h)], c);
    return q(s / 2, s / 2, h);
  }

  void _marker(Canvas canvas, Offset center) {
    canvas.drawCircle(center, _scale * (0.55 + 0.25 * t), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = LotColors.target.withValues(alpha: 1 - t));
    final pin = center - Offset(0, _scale * 1.1);
    canvas.drawLine(center, pin, Paint()
      ..color = LotColors.target
      ..strokeWidth = 2);
    canvas.drawCircle(pin, _scale * 0.22, Paint()..color = LotColors.target);
  }

  void _route(Canvas canvas) {
    final g = guide;
    if (g == null || g.path.length < 2) return;
    int levelOf(String id) => lot.floors.indexWhere((f) => f.floorId == id);
    final pts = <Offset>[for (final n in g.path) _p(n.x + 0.5, n.y + 0.5, levelOf(n.floorId))];
    final slot = g.slot, floor = g.floor;
    if (slot != null && floor != null) pts.add(_p(slot.x + 0.5, slot.y + 0.5, levelOf(floor.floorId)));
    // Điểm xuất phát (cổng), kể cả khi cổng ở tầng khác tầng đang xem.
    final start = g.path.first;
    final gate = lot.floor(start.floorId)?.at(start.x, start.y);
    canvas.drawCircle(pts.first, 6, Paint()..color = LotColors.route);
    _text(canvas, gate?.name ?? 'Cổng', pts.first - const Offset(0, 14), 10, center: true, bold: true, color: LotColors.route);
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white);
    const dash = 9.0, gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var d = (t * (dash + gap)) % (dash + gap) - gap;
      while (d < metric.length) {
        final start = math.max(0.0, d), end = math.min(metric.length, d + dash);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round
            ..color = LotColors.route);
        }
        d += dash + gap;
      }
    }
  }

  void _text(Canvas canvas, String text, Offset at, double size,
      {bool center = false, bool bold = false, Color color = const Color(0xFF1E293B)}) {
    if (text.isEmpty) return;
    final b = ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1))
      ..pushStyle(ui.TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w600))
      ..addText(text);
    final p = b.build()..layout(const ui.ParagraphConstraints(width: 220));
    canvas.drawParagraph(p, Offset(center ? at.dx - p.longestLine / 2 : at.dx, at.dy - p.height / 2));
  }

  @override
  bool shouldRepaint(TileIsoPainter old) =>
      old.t != t || old.selectedFloorId != selectedFloorId || old.lot != lot || old.guide != guide || old.slotStatus != slotStatus;
}
