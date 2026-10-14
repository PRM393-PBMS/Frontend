import '../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../network/api_client.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Chọn ảnh từ camera hoặc thư viện, trả về bytes để upload (chạy cả mobile và web).
class ImageCapture {
  ImageCapture._();

  static final ImagePicker _picker = ImagePicker();

  static Future<UploadFile?> pick(BuildContext context, {String? title}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title ?? ctx.l10n.imagePickTitle,
                      style: AppTypography.titleSmall),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(ctx.l10n.imageTakePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(ctx.l10n.imageFromLibrary),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return null;
    return fromSource(source);
  }

  static Future<UploadFile?> fromSource(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty ? file.name : 'image.jpg';
      final lower = name.toLowerCase();
      final mime = file.mimeType ??
          (lower.endsWith('.png')
              ? 'image/png'
              : lower.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');
      return UploadFile(bytes: bytes, fileName: name, mimeType: mime);
    } catch (e) {
      debugPrint('ImageCapture error: $e');
      return null;
    }
  }
}
