import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'plate_badge.dart';

/// Mã QR vé xe (payload do backend cấp). Luôn nền trắng để máy quét ở cổng đọc được.
class TicketQr extends StatelessWidget {
  final String payload;
  final double size;

  const TicketQr({super.key, required this.payload, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.porcelain200),
      ),
      child: QrImageView(
        data: payload,
        version: QrVersions.auto,
        size: size,
        backgroundColor: AppColors.white,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.ink,
        ),
        semanticsLabel: 'Mã QR vé xe',
      ),
    );
  }

  /// Hiện QR toàn màn hình để quét tại cổng.
  static Future<void> present(
    BuildContext context, {
    required String payload,
    required String title,
    String? plate,
    String? caption,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final p = ctx.palette;
        final t = Theme.of(ctx).textTheme;
        final width = MediaQuery.sizeOf(ctx).width;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
              if (plate != null) ...[
                const SizedBox(height: AppSpacing.md),
                PlateBadge(plate: plate, fontSize: 18),
              ],
              const SizedBox(height: AppSpacing.xl),
              TicketQr(payload: payload, size: (width - 96).clamp(180.0, 300.0)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                caption ?? 'Đưa mã này vào đầu đọc tại cổng. Tăng độ sáng màn hình nếu quét chậm.',
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                payload,
                textAlign: TextAlign.center,
                style: AppTypography.mono(size: 11.5, color: p.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}
