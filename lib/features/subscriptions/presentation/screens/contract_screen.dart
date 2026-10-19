import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/services/biometric_service.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/signature_pad.dart';

/// Hợp đồng vé tháng 3/6/9/12 tháng: đọc, ký điện tử, thanh toán; xem lại và kiểm tra niêm phong.
class ContractScreen extends StatefulWidget {
  final String subscriptionId;

  const ContractScreen({super.key, required this.subscriptionId});

  /// Trả `true` nếu đã ký và thanh toán thành công (vé được kích hoạt).
  static Future<bool?> open(BuildContext context, String subscriptionId) =>
      Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ContractScreen(subscriptionId: subscriptionId)),
      );

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _contract = AsyncCubit(() => _repo.getContractForSubscription(widget.subscriptionId));

  final _signature = SignatureController();
  late final _name = TextEditingController(
    text: (context.read<AuthBloc>().state.user?.fullName ?? '').trim(),
  );
  bool _agreed = false;
  bool _payByWallet = false;
  bool _busy = false;
  String? _error;
  String? _paymentError;
  ContractVerificationModel? _verification;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _signature.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contract.close();
    _signature.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<PaymentCheck> _isActive() async {
    final sub = await _repo.getSubscription(widget.subscriptionId);
    return sub.isActive ? PaymentCheck.paid : PaymentCheck.pending;
  }

  Future<void> _pay(PaymentLinkModel link) async {
    final paid = await PbmsPaymentSheet.show(
      context,
      title: 'Thanh toán vé tháng',
      link: link,
      verify: _isActive,
      recreate: () async => (await _repo.paySubscription(widget.subscriptionId, 'PayOS')).link,
    );
    if (paid && mounted) Navigator.pop(context, true);
  }

  Future<void> _payAgain() async {
    setState(() {
      _busy = true;
      _paymentError = null;
    });
    try {
      final link = await _repo.repaySubscription(widget.subscriptionId);
      if (mounted) await _pay(link);
    } catch (e) {
      if (mounted) setState(() => _paymentError = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sign(ContractModel c) async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Nhập họ tên người ký.');
      return;
    }
    if (!_agreed) {
      setState(() => _error = 'Bạn cần đồng ý với các điều khoản.');
      return;
    }
    if (!_signature.hasSignature) {
      setState(() => _error = 'Ký tên vào khung bên dưới.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Xác nhận chính chủ bằng sinh trắc học / mã khoá máy trước khi ký.
      final auth = await BiometricService.instance.authenticate(
        reason: 'Xác thực để ký hợp đồng ${c.contractNumber}',
      );
      if (auth != BiometricResult.success && auth != BiometricResult.unavailable) {
        if (mounted) setState(() => _error = 'Chưa xác thực được, hợp đồng chưa được ký.');
        return;
      }
      final png = await _signature.toPng();
      if (png == null) {
        if (mounted) setState(() => _error = 'Không đọc được chữ ký, hãy ký lại.');
        return;
      }
      final result = await _repo.signContract(
        contractId: c.id,
        signerName: name,
        contentHash: c.contentHash,
        signaturePng: png,
        paymentMethod: _payByWallet ? 'Wallet' : 'PayOS',
      );
      if (!mounted) return;
      _contract.patch((_) => result.contract);
      if (_payByWallet && result.paymentError == null) {
        // Trả bằng ví: gói được kích hoạt ngay sau khi ký.
        Navigator.pop(context, true);
        return;
      }
      final link = result.payment;
      if (link != null && link.hasUrl) {
        await _pay(link);
      } else {
        setState(() => _paymentError = result.paymentError ??
            'Đã ký hợp đồng nhưng chưa tạo được thanh toán. Thử lại bên dưới.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(ContractModel c) async {
    setState(() => _verifying = true);
    try {
      final v = await _repo.verifyContract(c.id);
      if (mounted) setState(() => _verification = v);
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Hợp đồng vé tháng',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 32 + bottomInset),
            children: [
              PbmsAsync<ContractModel>(
                cubit: _contract,
                loadingHeight: 480,
                errorTitle: 'Không tải được hợp đồng',
                builder: (c) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Số ${c.contractNumber}', style: PbmsText.bodyStrong),
                        ),
                        PbmsStatusPill(c.isSigned
                            ? const StatusInfo('Đã ký', PbmsTokens.ok)
                            : const StatusInfo('Chờ ký', PbmsTokens.warn)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PbmsCard(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: _ContractText(content: c.content),
                    ),
                    const SizedBox(height: 18),
                    if (c.isSigned) ..._signedSection(c) else ..._signSection(c),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _signSection(ContractModel c) => [
        const Text('Ký hợp đồng', style: PbmsText.section),
        const SizedBox(height: 4),
        const Text(
          'Sau khi ký, bạn được chuyển sang PayOS để thanh toán. Vé chỉ kích hoạt khi thanh toán thành công.',
          style: PbmsText.caption,
        ),
        const SizedBox(height: 14),
        const Text('Họ tên người ký', style: PbmsText.label),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: pbmsInputDecoration(hint: 'Đúng họ tên trên hợp đồng'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: Text('Chữ ký', style: PbmsText.label)),
            TextButton.icon(
              onPressed: _signature.strokes.isEmpty ? null : _signature.clear,
              style: TextButton.styleFrom(
                  foregroundColor: PbmsTokens.muted, minimumSize: const Size(48, 40)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Ký lại'),
            ),
          ],
        ),
        SignaturePad(controller: _signature),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _agreed,
          onChanged: (v) => setState(() {
            _agreed = v ?? false;
            _error = null;
          }),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: PbmsTokens.teal,
          title: const Text(
            'Tôi đã đọc, hiểu và đồng ý toàn bộ điều khoản của hợp đồng này.',
            style: PbmsText.body,
          ),
        ),
        const SizedBox(height: 6),
        const Text('Thanh toán', style: PbmsText.label),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('PayOS'), icon: Icon(Icons.credit_card_rounded)),
            ButtonSegment(
                value: true, label: Text('Ví PBMS'), icon: Icon(Icons.account_balance_wallet_rounded)),
          ],
          selected: {_payByWallet},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _payByWallet = s.first),
          style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 14),
        PbmsPrimaryButton(
          label: 'Ký và thanh toán',
          icon: Icons.draw_rounded,
          busy: _busy,
          onPressed: () => _sign(c),
        ),
      ];

  List<Widget> _signedSection(ContractModel c) {
    final bytes = _decodeDataUrl(c.signatureImageDataUrl);
    final v = _verification;
    return [
      const Text('Chữ ký', style: PbmsText.section),
      const SizedBox(height: 8),
      PbmsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bytes != null)
              Center(
                child: Image.memory(bytes,
                    height: 110, semanticLabel: 'Chữ ký của ${c.signerName ?? 'khách hàng'}'),
              ),
            const SizedBox(height: 6),
            PbmsDetailRow(label: 'Người ký', value: c.signerName ?? 'Không rõ'),
            PbmsDetailRow(label: 'Thời điểm ký', value: DateFormatter.formatDateTime(c.signedAt)),
            PbmsDetailRow(label: 'Mã khoá niêm phong', value: c.sealKeyId ?? 'Không rõ'),
          ],
        ),
      ),
      if (_paymentError != null) ...[
        const SizedBox(height: 12),
        Text(_paymentError!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        const SizedBox(height: 8),
        PbmsPrimaryButton(
          label: 'Thanh toán',
          icon: Icons.credit_card_rounded,
          busy: _busy,
          onPressed: _payAgain,
        ),
      ],
      const SizedBox(height: 14),
      SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _verifying ? null : () => _verify(c),
          icon: _verifying
              ? const SizedBox.square(
                  dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.verified_user_outlined, size: 19),
          label: const Text('Kiểm tra niêm phong'),
          style: OutlinedButton.styleFrom(
            foregroundColor: PbmsTokens.teal,
            backgroundColor: PbmsTokens.tealTint,
            side: const BorderSide(color: PbmsTokens.tealLine),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      ),
      if (v != null) ...[
        const SizedBox(height: 12),
        PbmsCard(
          color: v.valid ? PbmsTokens.tealTint : const Color(0xFFFEF2F2),
          borderColor: v.valid ? PbmsTokens.tealLine : const Color(0xFFFECACA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(v.valid ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                      color: v.valid ? PbmsTokens.ok : PbmsTokens.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v.valid ? 'Hợp đồng nguyên vẹn, niêm phong hợp lệ' : 'Hợp đồng không hợp lệ',
                      style: PbmsText.bodyStrong,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _check('Nội dung không bị sửa', v.contentIntact),
              _check('Chữ ký tay khớp bản đã ký', v.signatureIntact),
              _check('Chữ ký số của bãi hợp lệ', v.sealValid),
              if (!v.keyMatches)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Khoá niêm phong hiện tại của máy chủ khác khoá đã dùng khi ký.',
                    style: PbmsText.caption,
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _check(String label, bool ok) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18, color: ok ? PbmsTokens.ok : PbmsTokens.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: PbmsText.body)),
          ],
        ),
      );

  static Uint8List? _decodeDataUrl(String? dataUrl) {
    if (dataUrl == null) return null;
    final i = dataUrl.indexOf(',');
    try {
      return base64Decode(i >= 0 ? dataUrl.substring(i + 1) : dataUrl);
    } catch (_) {
      return null;
    }
  }
}

/// Hiển thị văn bản hợp đồng: quốc hiệu và tiêu đề căn giữa, tên điều in đậm.
class _ContractText extends StatelessWidget {
  final String content;

  const _ContractText({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++) _line(i, lines[i]),
        ],
      ),
    );
  }

  Widget _line(int index, String line) {
    if (line.isEmpty) return const SizedBox(height: 10);
    if (index < 2) {
      return Text(line,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              fontWeight: index == 0 ? FontWeight.w700 : FontWeight.w600,
              color: PbmsTokens.ink));
    }
    if (line.startsWith('HỢP ĐỒNG')) {
      return Text(line,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: PbmsTokens.ink));
    }
    if (line.startsWith('Số: ') || line.startsWith('Lập ngày')) {
      return Text(line, textAlign: TextAlign.center, style: PbmsText.caption);
    }
    if (line.startsWith('ĐIỀU ') || line.startsWith('BÊN ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(line, style: PbmsText.bodyStrong),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(line, style: PbmsText.body),
    );
  }
}
