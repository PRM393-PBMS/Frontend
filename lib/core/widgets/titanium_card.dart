import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Thẻ nhận diện nền titanium (phong cách Dark-Tech của nhánh LongMainRes).
///
/// Dùng cho thông tin quan trọng nhất trên màn hình: phiên đang gửi, thẻ xe / vé tháng,
/// kết quả check-in. Nội dung bên trong luôn dùng theme tối để đủ tương phản trên nền kim loại,
/// bất kể ứng dụng đang ở chế độ sáng hay tối.
class TitaniumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool metallic;

  const TitaniumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.metallic = false,
  });

  static final ThemeData _darkTheme = AppTheme.darkTheme;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Theme(
      data: _darkTheme,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: metallic
              ? AppColors.metallicCardGradient
              : AppColors.titaniumCardGradient,
          borderRadius: AppSpacing.surface,
          border: Border.all(color: AppColors.titaniumBorder),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33090D14),
                blurRadius: 24,
                offset: Offset(0, 10)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: onTap == null
              ? content
              : InkWell(
                  borderRadius: AppSpacing.surface,
                  onTap: onTap,
                  child: content),
        ),
      ),
    );
  }
}
