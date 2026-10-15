import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Khối giữ chỗ dạng nhịp thở, theo đúng hình dạng nội dung sắp hiện.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({super.key, this.width, this.height = 14, this.radius = 6});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.palette.skeleton;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, base.withValues(alpha: 0.45),
                Curves.easeInOut.transform(_c.value)),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Thẻ giữ chỗ chung: tiêu đề + 2 dòng phụ.
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vPad = height < 80 ? AppSpacing.md : AppSpacing.lg;
    final room = height - vPad * 2 - 2;
    return Semantics(
      label: 'Đang tải',
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: vPad),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.line),
          borderRadius: AppSpacing.roundedLg,
        ),
        // Số dòng giữ chỗ theo chiều cao thẻ để không bao giờ tràn.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Skeleton(width: 140, height: 16),
            if (room >= 38) ...[
              const SizedBox(height: 10),
              const Flexible(child: Skeleton(width: 220, height: 12)),
            ],
            if (room >= 58) ...[
              const SizedBox(height: 8),
              const Flexible(child: Skeleton(width: 96, height: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({super.key, this.count = 3, this.itemHeight = 96});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          SkeletonCard(height: itemHeight),
        ],
      ],
    );
  }
}
