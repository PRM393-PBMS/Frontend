import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:prm393_frontend/features/staff/data/plate_crop.dart';

void main() {
  group('cắt ảnh về khung biển số', () {
    test('khung trên màn hình: rộng 82%, cao nửa chiều rộng, tâm 42% chiều cao', () {
      final r = PlateCrop.frameOnScreen(const Size(400, 800));
      expect(r.width, closeTo(328, 0.01));
      expect(r.height, closeTo(164, 0.01));
      expect(r.center, const Offset(200, 336));
    });

    test('preview 9:16 phủ màn 9:19.5: cắt hai bên, khung quy ra tỉ lệ của khung hình', () {
      const screen = Size(360, 780);
      const preview = Size(720, 1280); // đã xoay dọc
      final f = PlateCrop.frameInPreview(screen, preview);
      // Màn hình hẹp hơn preview: preview phóng theo chiều cao, khung chiếm ít hơn 82% bề ngang khung hình.
      expect(f.width, lessThan(0.82));
      expect(f.center.dx, closeTo(0.5, 1e-6));
      expect(f.center.dy, closeTo(0.42, 1e-6));
    });

    test('vùng cắt có lề, nằm trong ảnh; ảnh rộng hơn preview thì bỏ hai bên', () {
      const frame = Rect.fromLTRB(0.1, 0.3, 0.9, 0.5);
      final r = PlateCrop.cropRect(frame, 9 / 16, 1080, 1920);
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.top, greaterThan(0));
      expect(r.left + r.width, lessThanOrEqualTo(1080));
      expect(r.height, lessThan(1920 * 0.4));
      // Ảnh 3:4 rộng hơn preview 9:16: phần preview là dải giữa ảnh.
      final wide = PlateCrop.cropRect(frame, 9 / 16, 1440, 1920);
      expect(wide.left, greaterThan(1440 * 0.1));
    });

    test('cắt ảnh JPEG thật: ra ảnh nhỏ hơn, giữ phần khung', () {
      final photo = img.Image(width: 720, height: 1280);
      img.fill(photo, color: img.ColorRgb8(40, 40, 40));
      // Biển số trắng đúng giữa khung.
      img.fillRect(photo, x1: 160, y1: 480, x2: 560, y2: 600, color: img.ColorRgb8(255, 255, 255));
      final jpeg = Uint8List.fromList(img.encodeJpg(photo));
      final frame = PlateCrop.frameInPreview(const Size(720, 1280), const Size(720, 1280));
      final out = img.decodeJpg(cropPlatePhoto(PlateCropJob(jpeg, frame, 720 / 1280)))!;
      expect(out.width, lessThan(720));
      expect(out.height, lessThan(500));
      // Giữa ảnh cắt là biển trắng.
      final mid = out.getPixel(out.width ~/ 2, out.height ~/ 2);
      expect(mid.r, greaterThan(200));
    });

    test('ảnh hỏng thì gửi nguyên ảnh', () {
      final bad = Uint8List.fromList([1, 2, 3]);
      expect(cropPlatePhoto(PlateCropJob(bad, const Rect.fromLTRB(0, 0, 1, 1), 1)), same(bad));
    });
  });
}
