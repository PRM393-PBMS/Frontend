import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:prm393_frontend/features/map/presentation/lot_marker_icon.dart';

void main() {
  testWidgets('ghim bãi là ảnh PNG, mũi nhọn ở giữa sát đáy ảnh', (tester) async {
    final (icon, anchor) = (await tester.runAsync(() => LotMarkerIcon.build(
          available: 12,
          basePrice: 30000,
          selected: true,
          devicePixelRatio: 3,
        )))!;
    expect(icon, isA<BytesMapBitmap>());
    final bytes = (icon as BytesMapBitmap).byteData;
    // Chữ ký PNG.
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(icon.imagePixelRatio, 3);
    expect(anchor.dx, 0.5);
    expect(anchor.dy, greaterThan(0.8));
    expect(anchor.dy, lessThan(1));
  });

  testWidgets('bãi chưa có giá vẫn vẽ được ghim', (tester) async {
    final result = await tester.runAsync(() => LotMarkerIcon.build(
          available: 0,
          selected: false,
          devicePixelRatio: 2,
        ));
    expect(result, isNotNull);
  });
}
