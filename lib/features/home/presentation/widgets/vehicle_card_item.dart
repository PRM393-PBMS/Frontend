import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import '../models/vehicle_card_model.dart';

class VehicleCardItem extends StatefulWidget {
  final VehicleCardModel card;
  final bool isCurrent;
  final bool isUnlocked;
  final VoidCallback? onTapToUnlock;

  const VehicleCardItem({
    super.key,
    required this.card,
    this.isCurrent = true,
    this.isUnlocked = false,
    this.onTapToUnlock,
  });

  @override
  State<VehicleCardItem> createState() => _VehicleCardItemState();
}

class _VehicleCardItemState extends State<VehicleCardItem>
    with TickerProviderStateMixin {
  // Flip Animation Controller
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // NFC Ripple Animation Controller
  late AnimationController _rippleController;

  // Dynamic QR Code Refresh (TOTP Simulation)
  Timer? _totpTimer;
  int _countdownSeconds = 30;
  static const int _maxCountdown = 30;
  int _totpEpoch = 1;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _startTotpTimer();

    if (widget.isUnlocked) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant VehicleCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked != oldWidget.isUnlocked) {
      if (widget.isUnlocked) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  void _startTotpTimer() {
    _totpTimer?.cancel();
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
        } else {
          _countdownSeconds = _maxCountdown;
          _totpEpoch++;
        }
      });
    });
  }

  @override
  void dispose() {
    _totpTimer?.cancel();
    _flipController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _toggleCardFlip() {
    HapticFeedback.mediumImpact();
    // LOGIC: Nếu thẻ chưa mở khoá -> KHÔNG THỂ LẬT ĐƯỢC -> Kích hoạt quét vân tay!
    if (!widget.isUnlocked) {
      widget.onTapToUnlock?.call();
      return;
    }

    // Khi đã mở khoá: Lật mặt trước / mặt sau bình thường
    if (_flipController.status == AnimationStatus.completed ||
        _flipController.value > 0.5) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  /// Hiển thị biển số: Nếu chưa mở khoá thì ẩn chỉ hiện 2 số cuối (VD: •••• ••88)
  String get _displayLicensePlate {
    if (widget.isUnlocked) {
      return widget.card.licensePlate;
    }
    final raw = widget.card.licensePlate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (raw.length <= 2) return '•• $raw';
    final last2 = raw.substring(raw.length - 2);
    return '•••• ••$last2';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCardFlip,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * math.pi;
          final isUnder = angle > (math.pi / 2);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // Perspective 3D
              ..rotateY(angle),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: context.space(6),
                vertical: context.space(4),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.space(22)),
                boxShadow: [
                  BoxShadow(
                    color: widget.card.gradientColors.first.withValues(alpha: 0.35),
                    blurRadius: context.space(24),
                    spreadRadius: -2,
                    offset: Offset(0, context.space(10)),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: context.space(8),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.space(22)),
                child: isUnder
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _buildBackView(context),
                      )
                    : _buildFrontView(context),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MẶT TRƯỚC THẺ (FRONT VIEW - DIGITAL WALLET CARD)
  // ===========================================================================
  Widget _buildFrontView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.card.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background Tech Netting / Glow Circles Pattern (Phong cách Samsung Wallet)
          Positioned.fill(
            child: CustomPaint(
              painter: _CardMeshPainter(accentColor: widget.card.accentColor),
            ),
          ),

          // Main Card Content
          Padding(
            padding: EdgeInsets.all(context.space(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Brand & EMV Chip & NFC Waves
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Tag / Logo
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.space(8),
                            vertical: context.space(4),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(context.space(6)),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.card.brand,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(11),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(width: context.space(8)),
                        Icon(
                          widget.card.type == VehicleType.car
                              ? Icons.directions_car_rounded
                              : Icons.two_wheeler_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: context.iconSize(18),
                        ),
                      ],
                    ),

                    // EMV Gold Chip & Contactless NFC Waves
                    Row(
                      children: [
                        // Simulated EMV Chip
                        Container(
                          width: context.space(32),
                          height: context.space(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.space(4)),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFDF7A), Color(0xFFC99824)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: const Color(0xFF8C660B), width: 0.6),
                          ),
                          child: CustomPaint(
                            painter: _ChipLinesPainter(),
                          ),
                        ),
                        SizedBox(width: context.space(10)),
                        // Contactless NFC Wave Icon
                        RotatedBox(
                          quarterTurns: 1,
                          child: Icon(
                            Icons.wifi_rounded,
                            color: Colors.white.withValues(alpha: 0.95),
                            size: context.iconSize(20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Center: License Plate (Khi khoá: Ẩn chỉ hiện 2 số cuối • Khi mở: Hiện đầy đủ)
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.space(16),
                      vertical: context.space(7),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(context.space(12)),
                      border: Border.all(
                        color: widget.isUnlocked
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.isUnlocked) ...[
                          Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: context.iconSize(16),
                          ),
                          SizedBox(width: context.space(8)),
                        ],
                        Text(
                          _displayLicensePlate,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: context.sp(21),
                            fontWeight: FontWeight.w900,
                            letterSpacing: widget.isUnlocked ? 2.0 : 3.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(1, 2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Row: Vehicle Name, Ticket Badge & Action Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Vehicle Name & Ticket Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.card.vehicleName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(13.5),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: context.space(3)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.space(8),
                              vertical: context.space(2.5),
                            ),
                            decoration: BoxDecoration(
                              color: widget.card.accentColor.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(context.space(6)),
                              border: Border.all(
                                color: widget.card.accentColor.withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.card.ticketType,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.sp(9.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Tap prompt badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.space(10),
                        vertical: context.space(5.5),
                      ),
                      decoration: BoxDecoration(
                        color: widget.isUnlocked
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(context.space(20)),
                        border: Border.all(
                          color: widget.isUnlocked
                              ? const Color(0xFF10B981).withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isUnlocked
                                ? Icons.qr_code_2_rounded
                                : Icons.fingerprint_rounded,
                            color: Colors.white,
                            size: context.iconSize(14),
                          ),
                          SizedBox(width: context.space(5)),
                          Text(
                            widget.isUnlocked ? 'Lật xem QR' : 'Chạm để quét vân tay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(10),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MẶT SAU THẺ (BACK VIEW - DYNAMIC QR CODE & NFC RADAR)
  // ===========================================================================
  Widget _buildBackView(BuildContext context) {
    final dynamicPayload =
        'PBMS-SECURE-${widget.card.id}-${widget.card.licensePlate}-T$_totpEpoch';
    final progress = _countdownSeconds / _maxCountdown;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // NFC Concentric Radar Ripple Animation
          Positioned(
            right: -context.space(30),
            top: -context.space(30),
            child: AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(context.space(160), context.space(160)),
                  painter: _NfcRadarPainter(
                    animationProgress: _rippleController.value,
                    color: widget.card.accentColor,
                  ),
                );
              },
            ),
          ),

          // Content Layout
          Padding(
            padding: EdgeInsets.all(context.space(12)),
            child: Row(
              children: [
                // CỘT TRÁI: DYNAMIC QR CODE & PROGRESS COUNTDOWN
                Container(
                  padding: EdgeInsets.all(context.space(6)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.space(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: dynamicPayload,
                        version: QrVersions.auto,
                        size: context.space(86),
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: context.space(4)),
                      // Dynamic TOTP Countdown bar
                      SizedBox(
                        width: context.space(86),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 3.0,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress > 0.3
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            SizedBox(height: context.space(2)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đổi sau',
                                  style: TextStyle(
                                    fontSize: context.sp(7.5),
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  '${_countdownSeconds}s',
                                  style: TextStyle(
                                    fontSize: context.sp(7.5),
                                    color: progress > 0.3
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: context.space(12)),

                // CỘT PHẢI: TRẠNG THÁI NFC & THÔNG TIN BÃI ĐỖ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // NFC Radar Status Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.card.accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.contactless_rounded,
                              color: widget.card.accentColor,
                              size: context.iconSize(14),
                            ),
                          ),
                          SizedBox(width: context.space(6)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NFC SẴN SÀNG',
                                  style: TextStyle(
                                    color: widget.card.accentColor,
                                    fontSize: context.sp(9.5),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'Chạm lưng máy vào trụ Barrier',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: context.sp(8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Thông tin vị trí đỗ & Hạn vé
                      Container(
                        padding: EdgeInsets.all(context.space(7)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(context.space(8)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBackInfoRow(
                              context,
                              icon: Icons.local_parking_rounded,
                              label: 'Vị trí:',
                              value: widget.card.parkingSlot,
                            ),
                            SizedBox(height: context.space(3)),
                            _buildBackInfoRow(
                              context,
                              icon: Icons.timer_outlined,
                              label: 'Hạn vé:',
                              value: widget.card.isMonthlyActive
                                  ? '${widget.card.expiryDate} (${widget.card.daysLeft} ngày)'
                                  : widget.card.expiryDate,
                            ),
                          ],
                        ),
                      ),

                      // Nút lật lại
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.space(8),
                            vertical: context.space(3.5),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(context.space(16)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: context.iconSize(11),
                              ),
                              SizedBox(width: context.space(3)),
                              Text(
                                'Lật lại thẻ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.sp(9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: context.iconSize(11)),
        SizedBox(width: context.space(4)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: context.sp(8.5),
          ),
        ),
        SizedBox(width: context.space(3)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: context.sp(9),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS: NET MESH & EMV CHIP & NFC RADAR
// =============================================================================
class _CardMeshPainter extends CustomPainter {
  final Color accentColor;
  _CardMeshPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.45, size.height * 0.18),
      Offset(size.width * 0.75, size.height * 0.35),
      Offset(size.width * 0.35, size.height * 0.55),
      Offset(size.width * 0.60, size.height * 0.70),
      Offset(size.width * 0.85, size.height * 0.80),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    path.lineTo(points[1].dx, points[1].dy);
    path.lineTo(points[3].dx, points[3].dy);
    path.lineTo(points[4].dx, points[4].dy);
    path.lineTo(points[2].dx, points[2].dy);
    path.moveTo(points[3].dx, points[3].dy);
    path.lineTo(points[0].dx, points[0].dy);
    path.moveTo(points[4].dx, points[4].dy);
    path.lineTo(points[5].dx, points[5].dy);

    canvas.drawPath(path, paint);

    for (final p in points) {
      canvas.drawCircle(p, 3.0, dotPaint);
      canvas.drawCircle(p, 1.2, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF6B4E04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), p);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.5), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.5), Offset(size.width, size.height * 0.5), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NfcRadarPainter extends CustomPainter {
  final double animationProgress;
  final Color color;

  _NfcRadarPainter({required this.animationProgress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final currentProgress = (animationProgress + (i * 0.33)) % 1.0;
      final radius = currentProgress * maxRadius;
      final opacity = (1.0 - currentProgress).clamp(0.0, 1.0) * 0.5;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NfcRadarPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress;
}
