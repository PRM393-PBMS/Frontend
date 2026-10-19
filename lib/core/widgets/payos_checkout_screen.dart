import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'pbms_ui.dart';

/// Kết quả khi PayOS chuyển hướng về returnUrl / cancelUrl.
class PayosOutcome {
  /// Khách bấm huỷ trên trang PayOS.
  final bool cancelled;
  final String? orderCode;

  /// Trạng thái PayOS gắn trên URL (PAID, CANCELLED...). Chỉ để hiển thị nhanh,
  /// kết quả thật luôn hỏi lại máy chủ (/api/payments/:id/sync).
  final String? status;

  const PayosOutcome({required this.cancelled, this.orderCode, this.status});
}

/// Trang thanh toán PayOS mở trong app (WebView) thay vì đẩy ra trình duyệt.
///
/// - Khi PayOS chuyển sang returnUrl / cancelUrl, app chặn trước khi trang tải,
///   đóng WebView và trả [PayosOutcome]; nơi gọi tự kiểm tra trạng thái với máy chủ.
/// - Link intent:// và scheme riêng của ứng dụng ngân hàng được mở ra ngoài để
///   nút "Mở app ngân hàng" của PayOS hoạt động.
/// - Khách tự đóng màn hình thì trả null.
class PayosCheckoutScreen extends StatefulWidget {
  final Uri url;

  const PayosCheckoutScreen({super.key, required this.url});

  static Future<PayosOutcome?> open(BuildContext context, String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return Future.value(null);
    return Navigator.of(context).push<PayosOutcome>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => PayosCheckoutScreen(url: uri)),
    );
  }

  /// URL là trang kết quả PayOS chuyển về (không phải trang thanh toán của PayOS).
  @visibleForTesting
  static PayosOutcome? outcomeOf(Uri uri) {
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    if (host.endsWith('payos.vn')) return null;
    final path = uri.path.toLowerCase();
    final q = uri.queryParameters;
    final status = q['status']?.toUpperCase();
    final knownPath = path.endsWith('/payment/success') ||
        path.endsWith('/payment/cancel') ||
        path.endsWith('/payment-success') ||
        path.endsWith('/payment-cancel');
    final payosParams = q.containsKey('orderCode') && (q.containsKey('status') || q.containsKey('cancel'));
    if (!knownPath && !payosParams) return null;
    final cancelled = path.contains('cancel') || q['cancel'] == 'true' || status == 'CANCELLED';
    return PayosOutcome(cancelled: cancelled, orderCode: q['orderCode'], status: status);
  }

  /// intent://host/path#Intent;scheme=x;package=y;S.browser_fallback_url=z;end
  /// -> (x://host/path, fallback, package).
  @visibleForTesting
  static ({Uri? target, Uri? fallback, String? package}) parseIntentUrl(String raw) {
    final hash = raw.indexOf('#Intent;');
    if (!raw.startsWith('intent://') || hash < 0) return (target: null, fallback: null, package: null);
    final rest = raw.substring('intent://'.length, hash);
    String? scheme, package, fallback;
    for (final part in raw.substring(hash + '#Intent;'.length).split(';')) {
      final eq = part.indexOf('=');
      if (eq < 0) continue;
      final key = part.substring(0, eq);
      final value = part.substring(eq + 1);
      if (key == 'scheme') scheme = value;
      if (key == 'package') package = value;
      if (key == 'S.browser_fallback_url') fallback = Uri.decodeComponent(value);
    }
    return (
      target: scheme == null ? null : Uri.tryParse('$scheme://$rest'),
      fallback: fallback == null ? null : Uri.tryParse(fallback),
      package: package,
    );
  }

  @override
  State<PayosCheckoutScreen> createState() => _PayosCheckoutScreenState();
}

class _PayosCheckoutScreenState extends State<PayosCheckoutScreen> {
  late final WebViewController _web;
  int _progress = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigation,
        // Dự phòng: một số chuyển hướng phía máy chủ không qua onNavigationRequest.
        onPageStarted: (url) {
          final uri = Uri.tryParse(url);
          final outcome = uri == null ? null : PayosCheckoutScreen.outcomeOf(uri);
          if (outcome != null) _finish(outcome);
        },
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      ))
      ..loadRequest(widget.url);
  }

  FutureOr<NavigationDecision> _onNavigation(NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    final outcome = PayosCheckoutScreen.outcomeOf(uri);
    if (outcome != null) {
      _finish(outcome);
      return NavigationDecision.prevent;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'about' || uri.scheme == 'data') {
      return NavigationDecision.navigate;
    }
    // intent://, momo://, vcb://, market://... : mở ứng dụng bên ngoài.
    await _openExternal(request.url);
    return NavigationDecision.prevent;
  }

  Future<void> _openExternal(String raw) async {
    Future<bool> launch(Uri? u) async {
      if (u == null) return false;
      try {
        return await launchUrl(u, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }

    var opened = false;
    if (raw.startsWith('intent://')) {
      final intent = PayosCheckoutScreen.parseIntentUrl(raw);
      opened = await launch(intent.target) ||
          await launch(intent.fallback) ||
          (intent.package != null &&
              (await launch(Uri.parse('market://details?id=${intent.package}')) ||
                  await launch(Uri.parse('https://play.google.com/store/apps/details?id=${intent.package}'))));
    } else {
      opened = await launch(Uri.tryParse(raw));
    }
    if (!opened && mounted) {
      showPbmsSnack(context, 'Chưa mở được ứng dụng ngân hàng. Hãy quét mã QR hoặc chọn cách khác.', error: true);
    }
  }

  void _finish(PayosOutcome outcome) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _close() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời trang thanh toán?'),
        content: const Text('Nếu đã chuyển khoản xong, app vẫn kiểm tra và ghi nhận thanh toán của bạn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rời trang')),
        ],
      ),
    );
    if (leave == true && mounted) {
      _done = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _web.canGoBack()) {
          await _web.goBack();
        } else {
          await _close();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Đóng trang thanh toán',
            icon: const Icon(Icons.close_rounded),
            onPressed: _close,
          ),
          titleSpacing: 0,
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, size: 16, color: PbmsTokens.ok),
              SizedBox(width: 6),
              Text('Thanh toán PayOS',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: PbmsTokens.ink)),
            ],
          ),
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                    color: PbmsTokens.teal,
                    backgroundColor: PbmsTokens.tealTint,
                  ),
                )
              : null,
        ),
        body: SafeArea(top: false, child: WebViewWidget(controller: _web)),
      ),
    );
  }
}
