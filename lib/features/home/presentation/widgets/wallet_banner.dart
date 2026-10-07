import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';

class WalletBanner extends StatefulWidget {
  final VoidCallback? onDismiss;

  const WalletBanner({super.key, this.onDismiss});

  @override
  State<WalletBanner> createState() => _WalletBannerState();
}

class _WalletBannerState extends State<WalletBanner> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.space(16)),
      padding: EdgeInsets.symmetric(
        horizontal: context.space(14),
        vertical: context.space(12),
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(context.space(12)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Telemetry Beacon Icon
          Container(
            width: context.space(38),
            height: context.space(38),
            decoration: BoxDecoration(
              color: AppColors.reserved.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(context.space(10)),
              border: Border.all(color: AppColors.reserved.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.reserved,
              size: 20,
            ),
          ),
          SizedBox(width: context.space(12)),

          // Message Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ƯU ĐÃI VÉ THÁNG',
                      style: AppTypography.badgeMono.copyWith(
                        color: AppColors.reserved,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.reserved,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Gia hạn trước ngày 30 để nhận giảm 15% cước gửi xe cư dân PBMS.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: context.sp(11.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: context.space(8)),

          // Dismiss Button
          GestureDetector(
            onTap: () {
              setState(() => _isVisible = false);
              widget.onDismiss?.call();
            },
            child: Container(
              padding: EdgeInsets.all(context.space(6)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.cardDark : Colors.grey.shade200,
              ),
              child: Icon(
                Icons.close_rounded,
                size: context.iconSize(14),
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
