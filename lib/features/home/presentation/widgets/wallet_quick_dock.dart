import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';

enum WalletDockMode { quickAccess, allCards }

class WalletQuickDock extends StatelessWidget {
  final WalletDockMode currentMode;
  final ValueChanged<WalletDockMode> onModeChanged;

  const WalletQuickDock({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.space(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.space(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDockButton(
            context,
            mode: WalletDockMode.quickAccess,
            icon: Icons.credit_card_rounded,
            label: 'Thẻ xe',
          ),
          _buildDockButton(
            context,
            mode: WalletDockMode.allCards,
            icon: Icons.grid_view_rounded,
            label: 'Tất cả xe',
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton(
    BuildContext context, {
    required WalletDockMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onModeChanged(mode);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: context.space(24),
          vertical: context.space(10),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDFE2E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.space(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.iconSize(20),
              color: isSelected ? const Color(0xFF000000) : const Color(0xFF6B7280),
            ),
            SizedBox(height: context.space(2)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.sp(11),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF000000) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
