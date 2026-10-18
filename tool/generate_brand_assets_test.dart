// Sinh toàn bộ icon / ảnh khởi động của app từ PbmsLogoPainter, để mọi nền tảng
// dùng đúng một bản logo.
//
// Chạy:  flutter test tool/generate_brand_assets_test.dart
// (Đặt trong tool/ nên không chạy cùng bộ test thường.)
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/widgets/pbms_logo.dart';

/// Nền phía sau logo.
enum _Bg { none, blueSquare, blueRounded }

Future<Uint8List> _render({
  required int px,
  required PbmsLogoVariant variant,
  _Bg bg = _Bg.none,
  double markScale = 1,
  bool opaque = false,
}) async {
  final size = px.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Offset.zero & Size(size, size);
  final blue = Paint()..color = PbmsLogoColors.blue;
  switch (bg) {
    case _Bg.blueSquare:
      canvas.drawRect(rect, blue);
    case _Bg.blueRounded:
      // Biểu tượng bo góc kiểu ứng dụng (22% cạnh), lề 10% như icon macOS / legacy Android.
      final inset = size * 0.1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(inset), Radius.circular((size - 2 * inset) * 0.22)),
        blue,
      );
    case _Bg.none:
      break;
  }
  final markSize = size * markScale;
  final offset = (size - markSize) / 2;
  canvas.save();
  canvas.translate(offset, offset);
  PbmsLogoPainter(variant: variant, simplified: px * markScale <= 40)
      .paint(canvas, Size(markSize, markSize));
  canvas.restore();
  final image = await recorder.endRecording().toImage(px, px);
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  image.dispose();
  return _encodePng(px, px, rgba, opaque: opaque);
}

// ---------------------------------------------------------------- PNG encoder
// Tự mã hoá để xuất được PNG RGB không kênh alpha (iOS từ chối icon có alpha).

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

List<int> _chunk(String type, List<int> data) {
  final typeBytes = type.codeUnits;
  final len = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, _crc([...typeBytes, ...data]));
  return [...len.buffer.asUint8List(), ...typeBytes, ...data, ...crc.buffer.asUint8List()];
}

Uint8List _encodePng(int w, int h, Uint8List rgba, {required bool opaque}) {
  final channels = opaque ? 3 : 4;
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // filter: none
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final a = rgba[i + 3];
      if (opaque) {
        // Ảnh đã có nền đặc; trộn với trắng phòng khi mép khử răng cưa còn alpha.
        for (var c = 0; c < 3; c++) {
          raw.addByte(((rgba[i + c] * a) + 255 * (255 - a)) ~/ 255);
        }
      } else {
        // rawRgba là premultiplied alpha: chuyển về straight alpha cho PNG.
        for (var c = 0; c < 3; c++) {
          raw.addByte(a == 0 ? 0 : (rgba[i + c] * 255 ~/ a).clamp(0, 255));
        }
        raw.addByte(a);
      }
    }
  }
  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, channels == 3 ? 2 : 6) // RGB / RGBA
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ..._chunk('IHDR', ihdr.buffer.asUint8List()),
    ..._chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes())),
    ..._chunk('IEND', const []),
  ]);
}

/// ICO chứa ảnh PNG (Windows Vista trở lên).
Uint8List _encodeIco(List<(int, Uint8List)> images) {
  final header = ByteData(6)
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, images.length, Endian.little);
  final out = BytesBuilder()..add(header.buffer.asUint8List());
  var offset = 6 + 16 * images.length;
  for (final (px, png) in images) {
    final e = ByteData(16)
      ..setUint8(0, px >= 256 ? 0 : px)
      ..setUint8(1, px >= 256 ? 0 : px)
      ..setUint16(4, 1, Endian.little)
      ..setUint16(6, 32, Endian.little)
      ..setUint32(8, png.length, Endian.little)
      ..setUint32(12, offset, Endian.little);
    out.add(e.buffer.asUint8List());
    offset += png.length;
  }
  for (final (_, png) in images) {
    out.add(png);
  }
  return out.takeBytes();
}

Future<void> _write(String path, Future<Uint8List> bytes) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(await bytes);
}

void main() {
  test('sinh icon và ảnh khởi động từ logo', () async {
    await TestWidgetsFlutterBinding.ensureInitialized().runAsync(() async {
      const res = 'android/app/src/main/res';
      const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};

      for (final MapEntry(key: d, value: f) in densities.entries) {
        // Icon cũ (Android < 8): ô bo góc xanh, chữ P trắng.
        await _write('$res/mipmap-$d/ic_launcher.png',
            _render(px: (48 * f).round(), variant: PbmsLogoVariant.reversedOnBlue, bg: _Bg.blueRounded, markScale: 0.66));
        // Adaptive icon (Android 8+): lớp trước 108dp, logo nằm trong vùng an toàn 66dp.
        await _write('$res/mipmap-$d/ic_launcher_foreground.png',
            _render(px: (108 * f).round(), variant: PbmsLogoVariant.reversedOnBlue, markScale: 0.56));
        // Màn hình chờ: logo màu trên nền trắng.
        await _write('$res/mipmap-$d/launch_image.png',
            _render(px: (112 * f).round(), variant: PbmsLogoVariant.color));
      }

      // iOS: icon vuông kín nền (hệ thống tự bo), không kênh alpha.
      const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      const iosIcons = {
        'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40, 'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29, 'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80, 'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120, 'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76, 'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167, 'Icon-App-1024x1024@1x.png': 1024,
      };
      for (final MapEntry(key: name, value: px) in iosIcons.entries) {
        await _write('$iosDir/$name',
            _render(px: px, variant: PbmsLogoVariant.reversedOnBlue, bg: _Bg.blueSquare, markScale: 0.7, opaque: true));
      }
      const launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
      for (final (name, scale) in [('LaunchImage.png', 1), ('LaunchImage@2x.png', 2), ('LaunchImage@3x.png', 3)]) {
        await _write('$launch/$name', _render(px: 112 * scale, variant: PbmsLogoVariant.color));
      }

      // Web: favicon bản rút gọn, icon PWA kín nền, maskable trong vùng an toàn 80%.
      await _write('web/favicon.png', _render(px: 32, variant: PbmsLogoVariant.color));
      for (final px in [192, 512]) {
        await _write('web/icons/Icon-$px.png',
            _render(px: px, variant: PbmsLogoVariant.reversedOnBlue, bg: _Bg.blueSquare, markScale: 0.7, opaque: true));
        await _write('web/icons/Icon-maskable-$px.png',
            _render(px: px, variant: PbmsLogoVariant.reversedOnBlue, bg: _Bg.blueSquare, markScale: 0.56, opaque: true));
      }

      // macOS: ô bo góc có lề trong suốt như icon macOS.
      for (final px in [16, 32, 64, 128, 256, 512, 1024]) {
        await _write('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$px.png',
            _render(px: px, variant: PbmsLogoVariant.reversedOnBlue, bg: _Bg.blueRounded, markScale: 0.62));
      }

      // Windows: file .ico nhiều kích thước.
      final ico = <(int, Uint8List)>[];
      for (final px in [16, 32, 48, 256]) {
        ico.add((px, await _render(px: px, variant: PbmsLogoVariant.reversedOnBlue, bg: _Bg.blueRounded, markScale: 0.62)));
      }
      await File('windows/runner/resources/app_icon.ico').writeAsBytes(_encodeIco(ico));

      // Ảnh xem trước để đối chiếu với bản thiết kế.
      await _write('build/brand_preview/color_512.png', _render(px: 512, variant: PbmsLogoVariant.color));
      await _write('build/brand_preview/reversed_512.png',
          _render(px: 512, variant: PbmsLogoVariant.reversedOnBlue, bg: _Bg.blueSquare, opaque: true));
      await _write('build/brand_preview/simplified_32.png', _render(px: 32, variant: PbmsLogoVariant.color));
    });
  });
}
