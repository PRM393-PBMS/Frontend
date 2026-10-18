import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/utils/media_url.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';

/// Ảnh đại diện ở trang Cá nhân: chạm để chụp hoặc chọn ảnh mới rồi tải lên.
/// Chưa có ảnh thì hiện chữ cái đầu của tên.
class ProfileAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String initial;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.initial,
    this.radius = 32,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _uploading = false;

  Future<void> _change() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Ảnh đại diện', style: PbmsText.title),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: PbmsTokens.teal),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: PbmsTokens.teal),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final XFile? file;
    try {
      // Thu nhỏ trước khi gửi: máy chủ nhận tối đa 5MB, avatar chỉ cần ảnh nhỏ.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (e) {
      if (mounted) showPbmsSnack(context, 'Không mở được máy ảnh / thư viện ảnh.', error: true);
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final user = await context.read<PbmsRepository>().uploadAvatar(bytes, file.name);
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileUpdated(user));
      showPbmsSnack(context, 'Đã cập nhật ảnh đại diện.');
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(widget.avatarUrl);
    final size = widget.radius * 2;
    final fallback = Center(
      child: Text(widget.initial,
          style: TextStyle(
              fontSize: widget.radius * 0.7,
              color: PbmsTokens.teal,
              fontWeight: FontWeight.w700)),
    );

    return Semantics(
      button: true,
      label: 'Đổi ảnh đại diện',
      child: GestureDetector(
        onTap: _uploading ? null : _change,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: Container(
                  width: size,
                  height: size,
                  color: PbmsTokens.tealTint,
                  child: url == null
                      ? fallback
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => fallback,
                          errorWidget: (_, __, ___) => fallback,
                        ),
                ),
              ),
              if (_uploading)
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: Colors.black38,
                      alignment: Alignment.center,
                      child: const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              // Nút máy ảnh nhỏ ở góc: gợi ý chạm để đổi ảnh.
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: PbmsTokens.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
