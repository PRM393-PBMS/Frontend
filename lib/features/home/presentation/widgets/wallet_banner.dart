import 'package:flutter/material.dart';
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

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.space(16)),
      padding: EdgeInsets.symmetric(
        horizontal: context.space(14),
        vertical: context.space(12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF), // Soft Samsung Blue Tint
        borderRadius: BorderRadius.circular(context.space(18)),
        border: Border.all(
          color: const Color(0xFFDCE6FC),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 3D Leather Wallet Icon
          Container(
            width: context.space(40),
            height: context.space(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.space(12)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: context.space(12)),

          // Message Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gia hạn vé tháng ưu đãi',
                  style: TextStyle(
                    fontSize: context.sp(13),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: context.space(2)),
                Text(
                  'Gia hạn trước 30/09 để nhận ưu đãi giảm 15% phí đỗ xe đô thị...',
                  style: TextStyle(
                    fontSize: context.sp(11),
                    color: const Color(0xFF475569),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: context.space(8)),

          // Close 'X' Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isVisible = false;
              });
              widget.onDismiss?.call();
            },
            child: Container(
              padding: EdgeInsets.all(context.space(5)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD1DCF8),
              ),
              child: Icon(
                Icons.close_rounded,
                size: context.iconSize(14),
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
