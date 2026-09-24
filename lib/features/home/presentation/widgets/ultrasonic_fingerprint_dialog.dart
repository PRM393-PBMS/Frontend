import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';

class UltrasonicFingerprintDialog extends StatefulWidget {
  final String vehiclePlate;

  const UltrasonicFingerprintDialog({
    super.key,
    required this.vehiclePlate,
  });

  /// Hàm tĩnh mở quy trình xác thực vân tay siêu âm Samsung S24
  static Future<bool> authenticate(
    BuildContext context, {
    required String vehiclePlate,
  }) async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UltrasonicFingerprintDialog(vehiclePlate: vehiclePlate),
    );

    return result ?? false;
  }

  @override
  State<UltrasonicFingerprintDialog> createState() => _UltrasonicFingerprintDialogState();
}

class _UltrasonicFingerprintDialogState extends State<UltrasonicFingerprintDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanProgressController;
  late Animation<double> _pulseAnimation;

  bool _isHolding = false;
  bool _isSuccess = false;
  String _statusText = 'Chạm và giữ ngón tay trên cảm biến';
  Color _statusColor = const Color(0xFF94A3B8);
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    // Vòng sóng siêu âm lan toả liên tục
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Tiến trình quét khi giữ ngón tay (khoảng 650ms)
    _scanProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scanProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onScanSuccess();
      }
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _pulseController.dispose();
    _scanProgressController.dispose();
    super.dispose();
  }

  void _onFingerDown() {
    if (_isSuccess) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isHolding = true;
      _statusText = 'Đang đọc cấu trúc vân tay siêu âm...';
      _statusColor = const Color(0xFF00E5FF); // Samsung Cyan Glow
    });

    _scanProgressController.forward(from: 0.0);

    // Rung nhịp đều khi đang quét
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_isHolding && !_isSuccess) {
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
      }
    });
  }

  void _onFingerUp() {
    if (_isSuccess) return;
    _hapticTimer?.cancel();
    _scanProgressController.reset();

    setState(() {
      _isHolding = false;
      _statusText = 'Giữ ngón tay lâu hơn một chút để nhận diện';
      _statusColor = const Color(0xFFF59E0B);
    });
  }

  void _onScanSuccess() {
    _hapticTimer?.cancel();
    HapticFeedback.heavyImpact();

    setState(() {
      _isHolding = false;
      _isSuccess = true;
      _statusText = 'Xác thực vân tay thành công!';
      _statusColor = const Color(0xFF10B981); // Emerald Green
    });

    // Tự động đóng modal sau 550ms để người dùng kịp nhìn hiệu ứng thành công
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showPinFallbackSheet() {
    Navigator.pop(context, false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chế độ xác thực mã PIN dự phòng đang sẵn sàng'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.space(24),
        context.space(16),
        context.space(24),
        context.space(24) + bottomPad,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Samsung Deep Obsidian Black
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.space(28)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: context.space(40),
            height: context.space(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: context.space(20)),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_rounded,
                color: const Color(0xFF00E5FF),
                size: context.iconSize(18),
              ),
              SizedBox(width: context.space(8)),
              Text(
                'XÁC THỰC SINH TRẮC HỌC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: context.space(6)),

          Text(
            'Mở khoá thẻ xe ${widget.vehiclePlate}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: context.sp(12),
            ),
          ),
          SizedBox(height: context.space(32)),

          // ===================================================================
          // ULTRASONIC FINGERPRINT SENSOR AREA (Samsung S24 Style)
          // ===================================================================
          GestureDetector(
            onTapDown: (_) => _onFingerDown(),
            onTapUp: (_) => _onFingerUp(),
            onTapCancel: _onFingerUp,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: context.space(140),
              height: context.space(140),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lớp 1: Sóng xung quanh (Pulse Animation)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: context.space(120),
                          height: context.space(120),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isSuccess
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : (_isHolding
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.08)),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Lớp 2: Vòng tiến trình tròn quét vân tay (Circular Progress)
                  AnimatedBuilder(
                    animation: _scanProgressController,
                    builder: (context, child) {
                      return SizedBox(
                        width: context.space(98),
                        height: context.space(98),
                        child: CircularProgressIndicator(
                          value: _isSuccess ? 1.0 : _scanProgressController.value,
                          strokeWidth: 3.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isSuccess
                                ? const Color(0xFF10B981)
                                : const Color(0xFF00E5FF),
                          ),
                        ),
                      );
                    },
                  ),

                  // Lớp 3: Sensor Core Pad (Bề mặt cảm biến phát sáng)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: context.space(84),
                    height: context.space(84),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isSuccess
                            ? [
                                const Color(0xFF10B981).withValues(alpha: 0.8),
                                const Color(0xFF065F46),
                              ]
                            : (_isHolding
                                ? [
                                    const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                    const Color(0xFF0284C7),
                                  ]
                                : [
                                    const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ]),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSuccess
                              ? const Color(0xFF10B981).withValues(alpha: 0.6)
                              : (_isHolding
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.3)),
                          blurRadius: _isHolding || _isSuccess ? 24 : 10,
                          spreadRadius: _isHolding ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.fingerprint_rounded,
                        color: _isSuccess
                            ? Colors.white
                            : (_isHolding ? Colors.white : const Color(0xFF94A3B8)),
                        size: context.iconSize(44),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.space(24)),

          // Status Prompt Text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _statusText,
              key: ValueKey(_statusText),
              style: TextStyle(
                color: _statusColor,
                fontSize: context.sp(12.5),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.space(28)),

          // PIN Fallback & Cancel buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Huỷ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: context.sp(13),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showPinFallbackSheet,
                icon: Icon(
                  Icons.dialpad_rounded,
                  color: const Color(0xFF00E5FF),
                  size: context.iconSize(16),
                ),
                label: Text(
                  'Dùng mã PIN',
                  style: TextStyle(
                    color: const Color(0xFF00E5FF),
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.space(20)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
