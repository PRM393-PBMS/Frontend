import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'pbms_plate.dart';

/// Mã QR ở cổng, toàn màn hình: nền trắng, sáng tối đa, không tắt màn hình.
/// Nút "Xong" ở nửa dưới cho thao tác một tay; vuốt xuống cũng đóng.
class ExitQrScreen extends StatefulWidget {
  final String title;
  final String payload;

  /// Biển số xe, hiện dạng biển thật phía trên mã.
  final String? plate;
  final bool isMotorbike;

  /// Mã chữ đọc cho nhân viên khi máy quét lỗi.
  final String? code;

  /// Dòng phụ khi không có biển số (ví dụ loại xe của đặt chỗ).
  final String? headline;
  final List<(IconData, String, String)> rows;

  const ExitQrScreen({
    super.key,
    required this.title,
    required this.payload,
    this.plate,
    this.isMotorbike = false,
    this.code,
    this.headline,
    this.rows = const [],
  });

  static Future<void> open(BuildContext context, ExitQrScreen screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => screen));

  @override
  State<ExitQrScreen> createState() => _ExitQrScreenState();
}

class _ExitQrScreenState extends State<ExitQrScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _setGateMode(true);
  }

  @override
  void dispose() {
    _setGateMode(false);
    super.dispose();
  }

  /// Máy quét ở cổng đọc mã nhanh hơn khi màn hình sáng hết cỡ.
  /// Nền tảng không hỗ trợ (web, thử nghiệm) thì bỏ qua.
  Future<void> _setGateMode(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (_) {}
    try {
      on
          ? await ScreenBrightness.instance.setApplicationScreenBrightness(1.0)
          : await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Tối thiểu 300 để máy quét đọc nhanh; màn rất hẹp thì vừa khít bề ngang.
    final qrSize = (size.width - 40).clamp(300.0, 360.0).clamp(0.0, size.width - 24);
    final plate = widget.plate;
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    children: [
                      Text(widget.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const SizedBox(height: 14),
                      if (plate != null && plate.isNotEmpty)
                        PbmsPlate(licensePlate: plate, isMotorbike: widget.isMotorbike, fontSize: 24)
                      else if (widget.headline != null)
                        Text(widget.headline!,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF334155))),
                      const SizedBox(height: 20),
                      QrImageView(
                        data: widget.payload,
                        version: QrVersions.auto,
                        size: qrSize,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                        semanticsLabel: widget.title,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle:
                            const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                      if (widget.code != null) ...[
                        const SizedBox(height: 18),
                        SelectableText(
                          widget.code!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                            color: Color(0xFF0F172A),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      if (widget.rows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        for (final row in widget.rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(row.$1, size: 18, color: const Color(0xFF64748B)),
                                const SizedBox(width: 10),
                                Text(row.$2, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                const Spacer(),
                                Flexible(
                                  child: Text(row.$3,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Xong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
