import '../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'common.dart';

/// Vé QR để quét tại cổng. Luôn nền trắng để máy quét đọc tốt ở cả chế độ tối.
class TicketQr extends StatelessWidget {
  final String payload;
  final String caption;
  final double size;

  const TicketQr({
    super.key,
    required this.payload,
    required this.caption,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shortCode =
        payload.length > 8 ? payload.substring(0, 8).toUpperCase() : payload;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.surface,
            border: Border.all(color: p.border),
          ),
          child: Semantics(
            label: context.l10n.ticketQrSemantics,
            child: QrImageView(
              data: payload,
              size: size,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square, color: Color(0xFF18181B)),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF18181B),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(caption,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: p.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: AppSpacing.badge,
          onTap: () {
            Clipboard.setData(ClipboardData(text: payload));
            showAppSnack(context, context.l10n.ticketCopied);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.ticketCode(shortCode),
                    style: AppTypography.mono
                        .copyWith(fontSize: 13, color: p.textPrimary)),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 14, color: p.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
