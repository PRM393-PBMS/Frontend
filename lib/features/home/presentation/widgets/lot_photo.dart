import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/utils/media_url.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';

/// Ảnh bãi đỗ: ảnh quản lý tải lên máy chủ; chưa có hoặc tải lỗi thì dùng
/// một ảnh bãi đỗ có sẵn trong app, gán cố định theo mã bãi.
class LotPhoto extends StatelessWidget {
  final LotView lot;

  const LotPhoto({super.key, required this.lot});

  static const _fallbacks = [
    'assets/images/promo/reserve.jpg',
    'assets/images/promo/prepay.jpg',
    'assets/images/promo/monthly.jpg',
    'assets/images/promo/wallet.jpg',
  ];

  static String fallbackFor(String lotId) =>
      _fallbacks[lotId.codeUnits.fold<int>(0, (s, c) => s + c) % _fallbacks.length];

  @override
  Widget build(BuildContext context) {
    final asset = Image.asset(fallbackFor(lot.id), fit: BoxFit.cover, excludeFromSemantics: true);
    final src = resolveMediaUrl(lot.imageUrl);
    if (src == null) return asset;
    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      placeholder: (_, __) => asset,
      errorWidget: (_, __, ___) => asset,
    );
  }
}
