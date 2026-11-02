import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/staff/data/staff_models.dart';
import 'package:prm393_frontend/features/staff/data/pending_scan_store.dart';
import 'package:prm393_frontend/features/staff/data/plate_crop.dart';
import 'package:prm393_frontend/features/staff/presentation/scan_error.dart';
import 'package:prm393_frontend/features/staff/presentation/scan_verdict.dart';
import 'package:prm393_frontend/features/staff/presentation/staff_sheets.dart';

enum _SendState { sending, sent, failed }

/// Một ảnh vừa chụp trên máy: đang gửi, đã gửi (kèm kết quả máy chủ) hoặc lỗi chờ gửi lại.
class _Capture {
  final int key;
  final Uint8List bytes;
  final DateTime capturedAt;
  final String gateId;
  _SendState state = _SendState.sending;
  GateScanModel? result;
  String? error;
  bool saved = false;
  bool deleting = false;
  bool uploading = false;

  _Capture(this.key, this.bytes, this.capturedAt, this.gateId);
}

/// Điện thoại của nhân viên làm máy quét: chọn cổng, đưa biển số vào khung, chụp.
/// Ảnh + giờ chụp gửi lên máy chủ; web staff nhận real-time và xử lý cho vào / ra.
class StaffScannerScreen extends StatefulWidget {
  const StaffScannerScreen({super.key});

  @override
  State<StaffScannerScreen> createState() => _StaffScannerScreenState();
}

class _StaffScannerScreenState extends State<StaffScannerScreen>
    with WidgetsBindingObserver {
  static const _gatePrefKey = 'staff.gate.v1';
  static const _maxCaptures = 8;
  static const _gateSyncEvery = Duration(seconds: 4);

  /// Sau mỗi lần chụp khoá nút một lúc: chạm đúp / chạm liên tục không tạo nhiều lượt quét trùng.
  static const _shotCooldown = Duration(milliseconds: 1500);

  CameraController? _camera;
  String? _cameraError;
  bool _initializing = false;
  bool _shooting = false;
  DateTime _readyAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _cooldownTimer;
  bool _torch = false;
  GateModel? _gate;
  final _captures = <_Capture>[];
  int _nextKey = 0;
  Timer? _gateSync;

  /// Lần web chọn cổng gần nhất đã áp dụng. Web chọn lại thì điện thoại đổi theo;
  /// nhân viên tự chọn trên điện thoại thì giữ tới khi web chọn cổng khác.
  String? _webGateSetAt;
  PendingScanStore? _pending;
  bool _loadingPending = true;
  String? _pendingError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable().catchError((_) {});
    _restoreGate();
    _restorePending();
    _initCamera();
    _startGateSync();
  }

  void _startGateSync() {
    _gateSync?.cancel();
    _gateSync = Timer.periodic(_gateSyncEvery, (_) => _syncGateFromWeb());
  }

  /// Đi theo cổng web staff (cùng tài khoản) đang mở. Lỗi mạng thì bỏ qua, lần sau hỏi lại.
  Future<void> _syncGateFromWeb({bool announce = true}) async {
    try {
      final web = await context.read<PbmsRepository>().getMyGate();
      if (web == null || !mounted || web.setAt == _webGateSetAt) return;
      _webGateSetAt = web.setAt;
      if (web.gate.gateId == _gate?.gateId) return;
      setState(() => _gate = web.gate);
      unawaited(_saveGate(web.gate));
      if (announce) {
        HapticFeedback.selectionClick();
        showPbmsSnack(context,
            'Đổi theo web: ${web.gate.gateName} · ${web.gate.floorName}');
      }
    } catch (_) {}
  }

  Future<void> _saveGate(GateModel gate) async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(_gatePrefKey, jsonEncode(gate.toJson()));
    } catch (_) {}
  }

  Future<void> _restorePending() async {
    try {
      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId == null) throw StateError('Đăng nhập lại để khôi phục ảnh.');
      final prefs = await SharedPreferences.getInstance();
      final pending = PendingScanStore(prefs, userId);
      final items = pending.load();
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _pendingError = null;
        for (final item in items.reversed) {
          final capture = _Capture(
              item.id, item.bytes, item.capturedAt, item.gateId)
            ..state = _SendState.failed
            ..saved = true
            ..error =
                'Ảnh từ lần trước. Kiểm tra lượt quét gần đây trước khi gửi lại.';
          _captures.add(capture);
          if (item.id >= _nextKey) _nextKey = item.id + 1;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _pendingError =
            'Không đọc được ảnh đang lưu. Thử tải lại trước khi chụp.');
      }
    } finally {
      if (mounted) setState(() => _loadingPending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable().catchError((_) {});
    _gateSync?.cancel();
    _cooldownTimer?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nhả camera khi app vào nền, mở lại khi quay về.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final cam = _camera;
      _camera = null;
      _torch = false;
      _gateSync?.cancel();
      if (mounted) setState(() {});
      cam?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_camera == null) _initCamera();
      _syncGateFromWeb();
      _startGateSync();
    }
  }

  Future<void> _initCamera() async {
    if (_initializing) return;
    _initializing = true;
    setState(() => _cameraError = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'Máy không có camera');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        // Ảnh sẽ được cắt còn vùng biển số: chụp nét hơn để phần cắt còn đủ điểm ảnh cho máy đọc chữ.
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = e.code.contains('Denied') ||
              e.code.contains('denied')
          ? 'Chưa cho phép dùng camera. Mở Cài đặt > Ứng dụng > PBMS > Quyền để bật camera.'
          : 'Không mở được camera (${e.description ?? e.code}).');
    } catch (_) {
      if (mounted) {
        setState(() => _cameraError = 'Không mở được camera trên máy này.');
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> _restoreGate() async {
    try {
      final raw =
          (await SharedPreferences.getInstance()).getString(_gatePrefKey);
      if (raw != null && mounted) {
        setState(() => _gate =
            GateModel.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      }
    } catch (_) {
      // Bỏ qua lựa chọn cũ hỏng; nhân viên chọn lại.
    }
    // Web đã chọn cổng thì lấy luôn, khỏi bắt chọn trên điện thoại.
    if (mounted) await _syncGateFromWeb(announce: _gate != null);
    if (mounted && _gate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickGate());
    }
  }

  Future<void> _pickGate() async {
    final picked =
        await showGatePickerSheet(context, selectedId: _gate?.gateId);
    if (picked == null || !mounted) return;
    setState(() => _gate = picked);
    await _saveGate(picked);
  }

  Future<void> _toggleTorch() async {
    final cam = _camera;
    if (cam == null) return;
    try {
      await cam.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      setState(() => _torch = !_torch);
    } catch (_) {
      if (mounted) showPbmsSnack(context, 'Máy không hỗ trợ đèn.', error: true);
    }
  }

  Future<void> _shoot() async {
    final cam = _camera;
    final gate = _gate;
    final pending = _pending;
    if (gate == null) {
      _pickGate();
      return;
    }
    if (cam == null ||
        !cam.value.isInitialized ||
        _shooting ||
        _coolingDown ||
        pending == null) {
      return;
    }
    if (_captures.where((c) => c.saved || c.state != _SendState.sent).length >=
        PendingScanStore.maxCount) {
      showPbmsSnack(
          context, 'Đã có 8 ảnh chưa gửi. Gửi lại hoặc nhấn giữ ảnh cũ để xóa.',
          error: true);
      return;
    }
    // Lấy hình học khung trước khi chờ chụp (context không dùng sau await).
    final screen = MediaQuery.sizeOf(context);
    final ps = cam.value.previewSize;
    // previewSize của camera là chiều ngang; màn hình hiển thị dọc.
    final preview = ps == null ? null : Size(ps.height, ps.width);
    setState(() => _shooting = true);
    try {
      final file = await cam.takePicture();
      final capturedAt = DateTime.now();
      _startCooldown();
      final raw = await file.readAsBytes();
      // Chỉ gửi vùng khung biển số: máy chủ và web đọc chữ chính xác hơn nhiều khi ảnh không lẫn thân xe, nền.
      final bytes = preview == null
          ? raw
          : await compute(
              cropPlatePhoto,
              PlateCropJob(raw, PlateCrop.frameInPreview(screen, preview),
                  preview.width / preview.height),
            );
      final capture = _Capture(_nextKey++, bytes, capturedAt, gate.gateId);
      final pendingBytes = _captures
          .where((c) => c.saved || c.state != _SendState.sent)
          .fold<int>(0, (sum, c) => sum + c.bytes.length);
      if (pendingBytes + capture.bytes.length > PendingScanStore.maxBytes) {
        if (mounted) {
          showPbmsSnack(context,
              'Ảnh vượt dung lượng hàng đợi 8MB. Gửi lại hoặc xóa ảnh cũ rồi chụp lại.',
              error: true);
        }
        return;
      }
      try {
        await pending.put(PendingScan(
            id: capture.key,
            gateId: capture.gateId,
            capturedAt: capture.capturedAt,
            bytes: capture.bytes));
        capture.saved = true;
      } catch (_) {
        capture.state = _SendState.failed;
        capture.error =
            'Không lưu được ảnh trên thiết bị. Giữ màn hình này và thử lại, hoặc nhấn giữ để xóa.';
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _captures.insert(0, capture);
        if (_captures.length > _maxCaptures) {
          final sent = _captures
              .lastIndexWhere((c) => c.state == _SendState.sent && !c.saved);
          if (sent >= 0) _captures.removeAt(sent);
        }
      });
      if (capture.saved) unawaited(_send(capture));
    } on CameraException catch (e) {
      if (mounted) {
        showPbmsSnack(context, 'Chụp không được: ${e.description ?? e.code}',
            error: true);
      }
    } catch (_) {
      if (mounted) {
        showPbmsSnack(
            context, 'Không đọc được ảnh vừa chụp. Vui lòng chụp lại.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _shooting = false);
    }
  }

  bool get _coolingDown => DateTime.now().isBefore(_readyAt);

  void _startCooldown() {
    _readyAt = DateTime.now().add(_shotCooldown);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_shotCooldown, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _send(_Capture capture) async {
    if (!mounted || capture.deleting || capture.uploading) return;
    final repo = context.read<PbmsRepository>();
    final pending = _pending;
    if (pending == null) return;
    capture.uploading = true;
    setState(() {
      capture.state = _SendState.sending;
      capture.error = null;
    });
    try {
      if (!capture.saved) {
        await pending.put(PendingScan(
            id: capture.key,
            gateId: capture.gateId,
            capturedAt: capture.capturedAt,
            bytes: capture.bytes));
      }
      capture.saved = true;
    } catch (_) {
      capture.saved = false;
      capture.uploading = false;
      if (mounted) {
        setState(() {
          capture.state = _SendState.failed;
          capture.error =
              'Không lưu được ảnh trên thiết bị. Giữ màn hình này và thử lại, hoặc nhấn giữ để xóa.';
        });
      }
      return;
    }
    try {
      final result = await repo.sendGateScan(
        gateId: capture.gateId,
        bytes: capture.bytes,
        capturedAt: capture.capturedAt,
      );
      // Giữ kết quả thành công ngay cả khi việc dọn ảnh cục bộ thất bại.
      capture.result = result;
      try {
        await pending.remove(capture.key);
        capture.saved = false;
      } catch (_) {
        capture.error =
            'Web đã nhận ảnh nhưng chưa xóa được bản lưu. Nhấn giữ để xóa, không gửi lại.';
      }
      if (!mounted) return;
      setState(() {
        capture.result = result;
        capture.state = _SendState.sent;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          capture.state = _SendState.failed;
          capture.error = scanErrorText(error);
        });
      }
    } finally {
      capture.uploading = false;
    }
  }

  Future<void> _discard(_Capture capture) async {
    if (capture.state == _SendState.sending || capture.deleting) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Xóa ảnh đang lưu?'),
              content: const Text(
                  'Ảnh sẽ bị xóa khỏi thiết bị và không thể gửi lại từ đây.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Giữ ảnh')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xóa ảnh')),
              ],
            ));
    if (confirmed != true || !mounted || capture.state == _SendState.sending) {
      return;
    }
    setState(() => capture.deleting = true);
    try {
      await _pending!.remove(capture.key);
      if (mounted) setState(() => _captures.remove(capture));
    } catch (_) {
      if (mounted) {
        setState(() => capture.deleting = false);
        showPbmsSnack(context, 'Không xóa được ảnh. Vui lòng thử lại.',
            error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            if (_camera?.value.isInitialized ?? false) const _PlateFrame(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  if (_pendingError != null)
                    TextButton(
                        onPressed: _restorePending,
                        child: Text(_pendingError!,
                            style: const TextStyle(color: Colors.white))),
                  const Spacer(),
                  if (_captures.isNotEmpty) _buildCaptures(),
                  _buildControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final cam = _camera;
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white70, size: 40),
              const SizedBox(height: 12),
              Text(_cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _initCamera,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (cam == null || !cam.value.isInitialized) {
      return const Center(
        child: Text('Đang mở camera…',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
      );
    }
    // Phủ kín màn hình (cắt mép) thay vì chừa viền đen.
    final size = cam.value.previewSize;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size?.height ?? 1,
          height: size?.width ?? 1,
          child: CameraPreview(cam),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final gate = _gate;
    final user = context.read<AuthBloc>().state.user;
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : (user?.email ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _GlassButton(
                onTap: _pickGate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      gate == null
                          ? Icons.sensor_door_outlined
                          : gate.isExit
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        gate == null
                            ? 'Chọn cổng'
                            : '${gate.gateName} · ${gate.floorName}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_more_rounded,
                        color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _GlassButton(
            onTap: () => showStaffMenuSheet(
              context,
              staffName: name,
              onLogout: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
            semanticLabel: 'Tài khoản và lượt quét gần đây',
            child:
                const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptures() {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _captures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _captures[i];
          return _CaptureCard(
            key: ValueKey(c.key),
            bytes: c.bytes,
            capturedAt: c.capturedAt,
            state: c.state,
            result: c.result,
            error: c.error,
            onRetry: c.state == _SendState.failed && !c.deleting
                ? () => _send(c)
                : null,
            onDiscard: c.state != _SendState.sending && !c.deleting
                ? () => _discard(c)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    final ready = (_camera?.value.isInitialized ?? false) &&
        !_loadingPending &&
        _pending != null;
    // Đang chụp / vừa chụp xong: nút mờ đi, chạm không có tác dụng.
    final canShoot = ready && !_shooting && !_coolingDown;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundIcon(
            icon: _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            label: _torch ? 'Tắt đèn' : 'Bật đèn',
            active: _torch,
            onTap: ready ? _toggleTorch : null,
          ),
          Semantics(
            button: true,
            label: 'Chụp biển số và gửi lên web',
            enabled: canShoot,
            child: GestureDetector(
              onTap: canShoot ? _shoot : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 78,
                height: 78,
                padding: EdgeInsets.all(_shooting ? 9 : 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canShoot ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
          _RoundIcon(
            icon: Icons.history_rounded,
            label: 'Lượt quét gần đây',
            onTap: () => showRecentScansSheet(context),
          ),
        ],
      ),
    );
  }
}

/// Khung căn biển số giữa màn hình: phần ngoài khung tối đi, bốn góc sáng.
class _PlateFrame extends StatelessWidget {
  const _PlateFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        // Cùng hình học với phần cắt ảnh trước khi gửi (PlateCrop).
        final rect = PlateCrop.frameOnScreen(Size(c.maxWidth, c.maxHeight));
        return CustomPaint(
          size: Size(c.maxWidth, c.maxHeight),
          painter: _FramePainter(rect),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: rect.bottom + 14,
                child: const Text(
                  'Đưa biển số vào khung rồi bấm chụp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Rect rect;

  const _FramePainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas.drawPath(
      Path.combine(PathOperation.difference,
          Path()..addRect(Offset.zero & size), Path()..addRRect(frame)),
      Paint()..color = const Color(0x8C000000),
    );
    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const r = 18.0;
    for (final (x, y, sx, sy) in [
      (rect.left, rect.top, 1.0, 1.0),
      (rect.right, rect.top, -1.0, 1.0),
      (rect.left, rect.bottom, 1.0, -1.0),
      (rect.right, rect.bottom, -1.0, -1.0),
    ]) {
      final path = Path()
        ..moveTo(x, y + sy * (r + len))
        ..lineTo(x, y + sy * r)
        ..arcToPoint(Offset(x + sx * r, y),
            radius: const Radius.circular(r), clockwise: sx * sy > 0)
        ..lineTo(x + sx * (r + len), y);
      canvas.drawPath(path, corner);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.rect != rect;
}

class _CaptureCard extends StatelessWidget {
  final Uint8List bytes;
  final DateTime capturedAt;
  final _SendState state;
  final GateScanModel? result;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
  final String? error;

  const _CaptureCard({
    super.key,
    required this.bytes,
    required this.capturedAt,
    required this.state,
    required this.result,
    this.onRetry,
    this.onDiscard,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(capturedAt);
    final verdict = result == null ? null : ScanVerdict.of(result!);
    final (String status, Color statusColor) = switch (state) {
      _SendState.sending => ('Đang gửi lên web…', Colors.white70),
      _SendState.sent
          when result?.licensePlate == null &&
              result?.recognitionNote != null =>
        ('${result!.recognitionNote} · $time', const Color(0xFFFCD34D)),
      _SendState.sent => ('Đã gửi · $time', const Color(0xFF6EE7B7)),
      _SendState.failed => ('Chạm để gửi lại', const Color(0xFFFCA5A5)),
    };
    final title = switch (state) {
      _SendState.sending => 'Đang nhận diện…',
      _SendState.sent => result?.licensePlate ?? 'Chưa đọc được',
      _SendState.failed => 'Gửi lỗi',
    };
    return Semantics(
      button: onRetry != null,
      label: [
        result?.licensePlate ?? 'Ảnh chụp lúc $time',
        verdict?.label,
        status,
        error
      ].whereType<String>().join(', '),
      onLongPress: onDiscard,
      child: GestureDetector(
        onTap: onRetry,
        onLongPress: onDiscard,
        child: Container(
          width: 252,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xD90F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(bytes,
                      width: 64,
                      height: 76,
                      fit: BoxFit.cover,
                      gaplessPlayback: true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: state == _SendState.failed
                              ? const Color(0xFFFCA5A5)
                              : Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (verdict != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(verdict.icon,
                                size: 13, color: _onDark(verdict.color)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(verdict.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: _onDark(verdict.color),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(status,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: statusColor, fontSize: 12)),
                      if (error != null) ...[
                        const SizedBox(height: 4),
                        Text(error!,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFFCA5A5), fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Màu trạng thái sáng hơn để đọc được trên nền tối.
  static Color _onDark(Color c) => Color.lerp(c, Colors.white, 0.45)!;
}

class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;

  const _GlassButton(
      {required this.child, required this.onTap, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: const Color(0x99000000),
        shape: const StadiumBorder(side: BorderSide(color: Colors.white24)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _RoundIcon(
      {required this.icon,
      required this.label,
      this.active = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: active ? Colors.white : const Color(0x99000000),
        shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 52,
            child: Icon(icon,
                color: active ? Colors.black : Colors.white,
                size: 24,
                semanticLabel: label),
          ),
        ),
      ),
    );
  }
}
