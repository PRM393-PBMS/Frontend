import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

/// Cắt ảnh chụp về đúng vùng khung căn biển số trên màn máy quét, để máy chủ và web
/// chỉ phải đọc biển số, không lẫn thân xe, nền, biển hiệu.
class PlateCrop {
  PlateCrop._();

  /// Khung căn trên màn hình: rộng 82%, cao bằng nửa chiều rộng, tâm ở 42% chiều cao.
  static Rect frameOnScreen(Size screen) {
    final w = screen.width * 0.82;
    return Rect.fromCenter(
        center: Offset(screen.width / 2, screen.height * 0.42), width: w, height: w / 2);
  }

  /// Khung trên màn hình quy ra tỉ lệ 0..1 của khung hình camera.
  /// [preview] là cỡ khung hình đã xoay dọc như đang hiển thị; preview phủ kín màn hình (cắt mép).
  static Rect frameInPreview(Size screen, Size preview) {
    final k = math.max(screen.width / preview.width, screen.height / preview.height);
    final dx = (screen.width - preview.width * k) / 2;
    final dy = (screen.height - preview.height * k) / 2;
    final r = frameOnScreen(screen);
    return Rect.fromLTRB(
      ((r.left - dx) / k / preview.width).clamp(0.0, 1.0),
      ((r.top - dy) / k / preview.height).clamp(0.0, 1.0),
      ((r.right - dx) / k / preview.width).clamp(0.0, 1.0),
      ((r.bottom - dy) / k / preview.height).clamp(0.0, 1.0),
    );
  }

  /// Vùng cắt (pixel) trong ảnh chụp cỡ [photoW]×[photoH]. Khung hình preview coi như phần giữa
  /// của ảnh chụp theo tỉ lệ [previewAspect] (rộng/cao). Thêm lề để nhân viên căn lệch một chút
  /// vẫn không mất chữ: ngang 8%, dọc 30% cỡ khung.
  static math.Rectangle<int> cropRect(
    Rect frame,
    double previewAspect,
    int photoW,
    int photoH, {
    double marginX = 0.08,
    double marginY = 0.30,
  }) {
    var vw = photoW.toDouble();
    var vh = photoH.toDouble();
    var ox = 0.0;
    var oy = 0.0;
    if (photoW / photoH > previewAspect) {
      vw = photoH * previewAspect;
      ox = (photoW - vw) / 2;
    } else {
      vh = photoW / previewAspect;
      oy = (photoH - vh) / 2;
    }
    final l = (frame.left - frame.width * marginX).clamp(0.0, 1.0);
    final t = (frame.top - frame.height * marginY).clamp(0.0, 1.0);
    final r = (frame.right + frame.width * marginX).clamp(0.0, 1.0);
    final b = (frame.bottom + frame.height * marginY).clamp(0.0, 1.0);
    final x = (ox + l * vw).round();
    final y = (oy + t * vh).round();
    final w = ((r - l) * vw).round().clamp(1, photoW - x);
    final h = ((b - t) * vh).round().clamp(1, photoH - y);
    return math.Rectangle(x, y, w, h);
  }
}

/// Việc cắt chạy trong isolate riêng (giải mã JPEG nặng): [cropPlatePhoto] nhận job này.
class PlateCropJob {
  final Uint8List bytes;
  final Rect frame;
  final double previewAspect;

  const PlateCropJob(this.bytes, this.frame, this.previewAspect);
}

/// Giải mã, xoay theo EXIF, cắt vùng khung biển số, nén lại JPEG.
/// Không giải mã được hoặc vùng quá nhỏ thì trả ảnh gốc để vẫn gửi được.
Uint8List cropPlatePhoto(PlateCropJob job) {
  try {
    final decoded = img.decodeJpg(job.bytes);
    if (decoded == null) return job.bytes;
    final photo = img.bakeOrientation(decoded);
    final r = PlateCrop.cropRect(job.frame, job.previewAspect, photo.width, photo.height);
    if (r.width < 80 || r.height < 40) return job.bytes;
    final cropped = img.copyCrop(photo, x: r.left, y: r.top, width: r.width, height: r.height);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
  } catch (_) {
    return job.bytes;
  }
}
