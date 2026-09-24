import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';

class EmbeddedUltrasonicSensor extends StatefulWidget {
  final String vehiclePlate;
  final bool isUnlocked;
  final VoidCallback onAuthenticated;
  final VoidCallback? onPinFallback;

  const EmbeddedUltrasonicSensor({
    super.key,
    required this.vehiclePlate,
    required this.isUnlocked,
    required this.onAuthenticated,
    this.onPinFallback,
  });

  @override
  State<EmbeddedUltrasonicSensor> createState() => _EmbeddedUltrasonicSensorState();
}

class _EmbeddedUltrasonicSensorState extends State<EmbeddedUltrasonicSensor>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanProgressController;
  late Animation<double> _pulseAnimation;

  bool _isHolding = false;
  bool _isSuccess = false;
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    _isSuccess = widget.isUnlocked;

    // Vòng sóng siêu âm lan toả liên tục báo hiệu cảm biến đang chờ
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Tiến trình quét khi người dùng ấn giữ ngón tay (~600ms)
    _scanProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scanProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleSuccess();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EmbeddedUltrasonicSensor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked != oldWidget.isUnlocked) {
      setState(() {
        _isSuccess = widget.isUnlocked;
      });
    }
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _pulseController.dispose();
    _scanProgressController.dispose();
    super.dispose();
  }

  void _onFingerDown() {
    if (_isSuccess) {
      // Nếu đã mở khoá, chạm vào sẽ kích hoạt lại hiệu ứng haptic
      HapticFeedback.lightImpact();
      widget.onAuthenticated();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isHolding = true;
    });

    _scanProgressController.forward(from: 0.0);

    // Rung nhịp đều đặn khi ngón tay đang chạm cảm biến
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 110), (timer) {
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
    });
  }

  void _handleSuccess() {
    _hapticTimer?.cancel();
    HapticFeedback.heavyImpact();

    setState(() {
      _isHolding = false;
      _isSuccess = true;
    });

    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSuccess = _isSuccess || widget.isUnlocked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // =====================================================================
        // SENSOR TOUCH PAD (Samsung S24 Ultrasonic Fingerprint)
        // =====================================================================
        GestureDetector(
          onTapDown: (_) => _onFingerDown(),
          onTapUp: (_) => _onFingerUp(),
          onTapCancel: _onFingerUp,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: context.space(88),
            height: context.space(88),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lớp 1: Sóng siêu âm lan toả (Pulse Ring)
                if (!effectiveSuccess)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: context.space(84),
                          height: context.space(84),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isHolding
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Lớp 2: Vòng tiến trình tròn khi đang quét (Circular Progress)
                AnimatedBuilder(
                  animation: _scanProgressController,
                  builder: (context, child) {
                    return SizedBox(
                      width: context.space(78),
                      height: context.space(78),
                      child: CircularProgressIndicator(
                        value: effectiveSuccess ? 1.0 : _scanProgressController.value,
                        strokeWidth: 3.0,
                        backgroundColor: Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFF00E5FF),
                        ),
                      ),
                    );
                  },
                ),

                // Lớp 3: Sensor Core Pad (Vùng tiếp xúc vân tay chính)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: context.space(66),
                  height: context.space(66),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: effectiveSuccess
                          ? [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ]
                          : (_isHolding
                              ? [
                                  const Color(0xFF00E5FF),
                                  const Color(0xFF0284C7),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFF1F5F9),
                                ]),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveSuccess
                            ? const Color(0xFF10B981).withValues(alpha: 0.45)
                            : (_isHolding
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.08)),
                        blurRadius: _isHolding || effectiveSuccess ? 18 : 8,
                        spreadRadius: _isHolding ? 3 : 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      effectiveSuccess
                          ? Icons.check_circle_rounded
                          : Icons.fingerprint_rounded,
                      color: effectiveSuccess
                          ? Colors.white
                          : (_isHolding
                              ? Colors.white
                              : const Color(0xFF0284C7)),
                      size: context.iconSize(34),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: context.space(8)),

        // Status Label & Helper prompt
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            effectiveSuccess
                ? 'ĐÃ XÁC THỰC VÂN TAY • THẺ ĐÃ SẴN SÀNG'
                : (_isHolding
                    ? 'ĐANG QUÉT VÂN TAY SIÊU ÂM...'
                    : 'CHẠM & GIỮ CẢM BIẾN ĐỂ MỞ THẺ'),
            key: ValueKey('${effectiveSuccess}_$_isHolding'),
            style: TextStyle(
              fontSize: context.sp(10.5),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: effectiveSuccess
                  ? const Color(0xFF059669)
                  : (_isHolding
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),

        SizedBox(height: context.space(4)),

        // PIN Fallback subtle link
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onPinFallback?.call();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.space(2)),
            child: Text(
              'Hoặc xác thực bằng mã PIN',
              style: TextStyle(
                fontSize: context.sp(11),
                color: const Color(0xFF94A3B8),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
