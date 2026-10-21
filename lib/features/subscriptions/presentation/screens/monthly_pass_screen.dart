import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/widgets/password_confirm_dialog.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/pay_pending_sheet.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/home/presentation/shell_scope.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/screens/contract_screen.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/pass_sheets.dart';
import 'package:prm393_frontend/features/vehicles/presentation/widgets/vehicle_picker.dart';

class MonthlyPassScreen extends StatefulWidget {
  const MonthlyPassScreen({super.key});

  @override
  State<MonthlyPassScreen> createState() => _MonthlyPassScreenState();
}

class _MonthlyPassScreenState extends State<MonthlyPassScreen>
    with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _passes = AsyncCubit(_repo.getMySubscriptions);
  late final _packages = AsyncCubit(_repo.getSubscriptionPackages);
  late final _changes = AsyncCubit(_repo.getMyVehicleChangeRequests);

  int _activeTab = 0;

  @override
  void reloadAll() {
    _passes.load();
    _packages.load();
    _changes.load();
  }

  void _changed() {
    if (mounted) ShellScope.dataChanged(context);
  }

  @override
  void dispose() {
    _passes.close();
    _packages.close();
    _changes.close();
    super.dispose();
  }

  Future<PaymentCheck> _verifyActive(String? subscriptionId) async {
    if (subscriptionId == null) return PaymentCheck.pending;
    final sub = await _repo.getSubscription(subscriptionId);
    return sub.isActive ? PaymentCheck.paid : PaymentCheck.pending;
  }

  Future<void> _payLink(PaymentLinkModel link, String? subscriptionId) async {
    final paid = await PbmsPaymentSheet.show(
      context,
      title: 'Thanh toán vé tháng',
      link: link,
      verify: () => _verifyActive(subscriptionId),
    );
    _changed();
    if (!mounted) return;
    if (paid) {
      showPbmsSnack(context, 'Vé tháng đã được kích hoạt.');
      setState(() => _activeTab = 0);
    }
  }

  Future<void> _openContract(String subscriptionId) async {
    final activated = await ContractScreen.open(context, subscriptionId);
    _changed();
    if (!mounted) return;
    if (activated == true) {
      showPbmsSnack(context, 'Đã ký hợp đồng và kích hoạt vé tháng.');
      setState(() => _activeTab = 0);
    }
  }

  Future<void> _onRegistered(RegistrationResultModel r) async {
    final subscriptionId = r.subscriptionId;
    if (r.requiresContract && subscriptionId != null) {
      setState(() => _activeTab = 0);
      await _openContract(subscriptionId);
      return;
    }
    if (r.activated) {
      _changed();
      if (!mounted) return;
      showPbmsSnack(context, 'Đã trả bằng ví và kích hoạt vé tháng.');
      setState(() => _activeTab = 0);
      return;
    }
    final link = r.link;
    if (link != null) await _payLink(link, subscriptionId);
  }

  /// Thanh toán (hoặc đổi hình thức thanh toán) một đơn đang chờ.
  Future<void> _pay(MonthlySubscriptionModel sub) async {
    if (sub.needsSignature) {
      await _openContract(sub.subscriptionId);
      return;
    }
    final method = await PayPendingSheet.show(context, sub);
    if (method == null || !mounted) return;
    try {
      final result = await _repo.paySubscription(sub.subscriptionId, method);
      if (!mounted) return;
      if (result.activated) {
        _changed();
        showPbmsSnack(context, 'Đã trả bằng ví và kích hoạt vé tháng.');
        setState(() => _activeTab = 0);
        return;
      }
      final link = result.link;
      if (link != null) await _payLink(link, sub.subscriptionId);
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  /// Đăng ký trùng xe với một đơn đang chờ thanh toán: cho khách chọn trả đơn cũ
  /// hoặc huỷ đơn cũ. Trả true nếu đã huỷ đơn cũ (form đăng ký thử lại).
  Future<bool> _resolvePending(VehicleModel vehicle) async {
    MonthlySubscriptionModel? old;
    try {
      old = (await _repo.getMySubscriptions())
          .where((s) => s.isPendingPayment && s.licensePlate == vehicle.licensePlate)
          .firstOrNull;
    } catch (_) {}
    if (old == null || !mounted) return false;
    final pending = old;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xe đã có đơn chưa thanh toán'),
        content: Text(
          'Xe ${pending.licensePlate} đang có đơn "${pending.packageName}" '
          '(${CurrencyFormatter.format(pending.price)}) chưa thanh toán. '
          'Bạn muốn thanh toán đơn cũ hay huỷ đơn cũ để đăng ký đơn này?',
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 4,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Để sau')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger),
            child: const Text('Huỷ đơn cũ, đăng ký đơn này'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'pay'),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.teal),
            child: const Text('Thanh toán đơn cũ'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'pay') {
      setState(() => _activeTab = 0);
      await _pay(pending);
      return false;
    }
    if (choice != 'cancel') return false;
    final password = await PasswordConfirmDialog.ask(
      context,
      title: 'Huỷ đơn cũ',
      message: 'Nhập mật khẩu để huỷ đơn "${pending.packageName}" của xe ${pending.licensePlate}.',
      confirmLabel: 'Huỷ đơn cũ',
      danger: true,
    );
    if (password == null || !mounted) return false;
    try {
      await _repo.cancelSubscription(pending.subscriptionId, password: password);
      _changed();
      return true;
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
      return false;
    }
  }

  Future<void> _renew(MonthlySubscriptionModel sub) async {
    final packages =
        (_packages.state.data ?? const <SubscriptionPackageModel>[])
            .where((p) => p.vehicleTypeName == sub.vehicleType)
            .toList();
    final result = await RenewPassSheet.show(context, sub, packages);
    if (result == null || !mounted) return;
    if (result.activated) {
      _changed();
      showPbmsSnack(context, 'Đã trừ ví và gia hạn vé tháng.');
      return;
    }
    final link = result.link;
    if (link == null) return;
    final oldEnd = sub.endDate;
    final paid = await PbmsPaymentSheet.show(
      context,
      title: 'Thanh toán gia hạn',
      link: link,
      verify: () async {
        final fresh = await _repo.getSubscription(sub.subscriptionId);
        final extended = fresh.endDate != null &&
            oldEnd != null &&
            fresh.endDate!.isAfter(oldEnd);
        return extended ? PaymentCheck.paid : PaymentCheck.pending;
      },
    );
    _changed();
    if (paid && mounted) showPbmsSnack(context, 'Đã gia hạn vé tháng.');
  }

  Future<void> _cancel(MonthlySubscriptionModel sub) async {
    final password = await PasswordConfirmDialog.ask(
      context,
      title: sub.isPendingPayment ? 'Huỷ đơn vé tháng?' : 'Huỷ vé tháng?',
      message: sub.isPendingPayment
          ? 'Đơn của xe ${sub.licensePlate} sẽ bị huỷ và link thanh toán cũ không dùng được nữa. Nhập mật khẩu để xác nhận.'
          : 'Vé của xe ${sub.licensePlate} sẽ ngừng hiệu lực'
              '${sub.fixedSlot != null ? ' và ô ${sub.fixedSlot} được trả lại' : ''}. Nhập mật khẩu để xác nhận.',
      confirmLabel: 'Huỷ vé',
      danger: true,
    );
    if (password == null) return;
    try {
      await _repo.cancelSubscription(sub.subscriptionId, password: password);
      _changed();
      if (mounted) showPbmsSnack(context, 'Đã huỷ vé tháng.');
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  Future<void> _changePlate(MonthlySubscriptionModel sub) async {
    final sent = await VehicleChangeSheet.show(context, sub);
    if (sent == true) {
      _changed();
      if (mounted) {
        showPbmsSnack(
            context, 'Đã gửi yêu cầu đổi biển số. Quản lý sẽ duyệt sớm.');
      }
    }
  }

  Future<void> _editChange(VehicleChangeRequestModel request) async {
    final saved = await VehicleChangeSheet.edit(context, request);
    if (saved == true) {
      _changed();
      if (mounted) showPbmsSnack(context, 'Đã cập nhật yêu cầu đổi biển số.');
    }
  }

  Future<void> _withdrawChange(VehicleChangeRequestModel request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rút yêu cầu?'),
        content: Text(
            'Yêu cầu đổi sang ${request.newLicensePlate} sẽ bị xoá. Vé vẫn giữ biển số cũ.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger),
            child: const Text('Rút yêu cầu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.withdrawVehicleChangeRequest(request.requestId);
      _changed();
      if (mounted) showPbmsSnack(context, 'Đã rút yêu cầu đổi biển số.');
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: pbmsTabAppBar('Vé tháng'),
      body: RefreshIndicator(
        color: PbmsTokens.teal,
        onRefresh: () async => reloadAll(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 116 + bottomInset),
              children: [
                PbmsSegmentedTabs(
                  tabs: const [
                    (Icons.verified_rounded, 'Vé của tôi'),
                    (Icons.add_circle_outline_rounded, 'Đăng ký mới'),
                  ],
                  selected: _activeTab,
                  onChanged: (i) => setState(() => _activeTab = i),
                ),
                const SizedBox(height: 16),
                if (_activeTab == 0)
                  _buildMyPasses()
                else
                  PbmsAsync<List<SubscriptionPackageModel>>(
                    cubit: _packages,
                    loadingHeight: 360,
                    errorTitle: 'Không tải được gói vé',
                    isEmpty: (d) => d.isEmpty,
                    empty: const PbmsEmptyView(
                      icon: Icons.inventory_2_outlined,
                      title: 'Bãi chưa mở gói vé tháng',
                      message: 'Khi quản lý mở bán gói, bạn có thể đăng ký tại đây.',
                    ),
                    builder: (packages) => _RegistrationForm(
                      packages: packages,
                      onRegistered: _onRegistered,
                      onPendingConflict: _resolvePending,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyPasses() {
    return PbmsAsync<List<MonthlySubscriptionModel>>(
      cubit: _passes,
      loadingHeight: 320,
      errorTitle: 'Không tải được vé tháng',
      isEmpty: (d) => d.isEmpty,
      empty: PbmsEmptyView(
        icon: Icons.card_membership_outlined,
        title: 'Bạn chưa có vé tháng',
        message: 'Vé tháng cho phép ra vào không giới hạn, cổng tự mở theo biển số.',
        action: TextButton.icon(
          onPressed: () => setState(() => _activeTab = 1),
          style: TextButton.styleFrom(
              foregroundColor: PbmsTokens.teal,
              minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          label: const Text('Đăng ký mới'),
        ),
      ),
      builder: (items) {
        int rank(MonthlySubscriptionModel s) =>
            s.isActive ? 0 : (s.isPendingPayment ? 1 : 2);
        final sorted = [...items]..sort((a, b) => rank(a).compareTo(rank(b)));
        final current = sorted.where((s) => rank(s) < 2).toList();
        final past = sorted.where((s) => rank(s) == 2).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final s in current) ...[
              _PassCard(
                pass: s,
                onPay: () => _pay(s),
                onContract: () => _openContract(s.subscriptionId),
                onRenew: () => _renew(s),
                onChangePlate: () => _changePlate(s),
                onHistory: () => RenewalHistorySheet.show(context, s),
                onCancel: () => _cancel(s),
              ),
              const SizedBox(height: 14),
              if (s.isActive) ...[
                _AnprCard(pass: s),
                const SizedBox(height: 14),
              ],
            ],
            BlocBuilder<AsyncCubit<List<VehicleChangeRequestModel>>,
                AsyncState<List<VehicleChangeRequestModel>>>(
              bloc: _changes,
              builder: (context, st) {
                final requests = st.data ?? const [];
                if (requests.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ChangeRequestsCard(
                    requests: requests,
                    onEdit: _editChange,
                    onWithdraw: _withdrawChange,
                  ),
                );
              },
            ),
            if (past.isNotEmpty) ...[
              const PbmsSectionTitle('Vé đã hết hạn hoặc đã huỷ'),
              for (final s in past) ...[
                _PastPassTile(pass: s, onRenew: s.isCancelled ? null : () => _renew(s)),
                const SizedBox(height: 9),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _PassCard extends StatelessWidget {
  final MonthlySubscriptionModel pass;
  final VoidCallback onPay;
  final VoidCallback onContract;
  final VoidCallback onRenew;
  final VoidCallback onChangePlate;
  final VoidCallback onHistory;
  final VoidCallback onCancel;

  const _PassCard({
    required this.pass,
    required this.onPay,
    required this.onContract,
    required this.onRenew,
    required this.onChangePlate,
    required this.onHistory,
    required this.onCancel,
  });

  String _short(DateTime? d) => d == null
      ? '--/--'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = pass;
    final isMotorbike = s.vehicleType.toLowerCase().contains('máy');
    final remaining = 1 - s.elapsedRatio;

    return PbmsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.title),
                    const SizedBox(height: 3),
                    Text(
                        s.allParkings
                            ? 'Mọi bãi PBMS, không cố định vị trí'
                            : s.fixedSlot == null
                                ? '${s.parkingName ?? PbmsFacility.name}, không cố định vị trí'
                                : '${s.parkingName ?? PbmsFacility.name}, ô cố định ${s.fixedSlot}',
                        style: PbmsText.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PbmsStatusPill(StatusInfo.subscription(s.displayStatus)),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: PbmsTokens.surfaceLow,
              border: Border.all(color: PbmsTokens.divider),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: PbmsTokens.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isMotorbike
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded,
                    size: 20,
                    color: PbmsTokens.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Biển kiểm soát', style: PbmsText.caption),
                      Text(s.licensePlate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PbmsText.bodyStrong),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Loại xe', style: PbmsText.caption),
                    Text(s.vehicleType,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PbmsTokens.ink)),
                  ],
                ),
              ],
            ),
          ),
          if (s.isActive) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: PbmsTokens.muted),
                const SizedBox(width: 5),
                const Text('Còn lại ', style: PbmsText.caption),
                Text('${s.daysLeft} ngày',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s.daysLeft <= 5
                            ? PbmsTokens.warn
                            : PbmsTokens.ink)),
                const Spacer(),
                Text('${_short(s.startDate)} - ${_short(s.endDate)}',
                    style: PbmsText.caption),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: remaining,
                minHeight: 7,
                color: s.daysLeft <= 5 ? PbmsTokens.warn : PbmsTokens.teal,
                backgroundColor: PbmsTokens.divider,
                semanticsLabel: 'Thời hạn còn lại',
              ),
            ),
            if (s.daysLeft <= 5) ...[
              const SizedBox(height: 8),
              const Text('Vé sắp hết hạn. Gia hạn để không bị gián đoạn.',
                  style: TextStyle(fontSize: 12, color: PbmsTokens.warn)),
            ],
          ],
          if (s.isPendingPayment) ...[
            const SizedBox(height: 13),
            Text(
                s.needsSignature
                    ? 'Gói dài hạn cần ký hợp đồng điện tử trước khi thanh toán.'
                    : 'Vé chưa có hiệu lực. Thanh toán để kích hoạt ra vào bằng biển số.',
                style: PbmsText.caption),
            const SizedBox(height: 10),
            if (s.needsSignature)
              PbmsPrimaryButton(
                label: 'Xem và ký hợp đồng',
                icon: Icons.draw_rounded,
                onPressed: onContract,
              )
            else
              PbmsPrimaryButton(
                label: 'Thanh toán ${CurrencyFormatter.format(s.price)}',
                icon: Icons.credit_card_rounded,
                onPressed: onPay,
              ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: PbmsTokens.divider),
          Wrap(
            children: [
              if (s.hasContract && !s.needsSignature)
                _action(Icons.description_outlined, 'Hợp đồng', onContract),
              if (s.isActive) ...[
                _action(Icons.autorenew_rounded, 'Gia hạn', onRenew),
                _action(Icons.swap_horiz_rounded, 'Đổi biển số', onChangePlate),
                _action(Icons.history_rounded, 'Lịch sử', onHistory),
              ],
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                    foregroundColor: PbmsTokens.danger,
                    minimumSize: const Size(48, 44)),
                child: const Text('Huỷ vé'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
          foregroundColor: PbmsTokens.teal, minimumSize: const Size(48, 44)),
    );
  }
}

/// Vé tháng mở cổng bằng nhận diện biển số (ANPR), không cần mã QR.
class _AnprCard extends StatelessWidget {
  final MonthlySubscriptionModel pass;

  const _AnprCard({required this.pass});

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.contactless_rounded, size: 20, color: PbmsTokens.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text('Mở cổng tự động', style: PbmsText.section),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: PbmsTokens.ink, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pass.licensePlate,
              style: PbmsText.figure(24).copyWith(letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Camera tại cổng đọc biển số này và mở barie, bạn không cần quét mã.',
            textAlign: TextAlign.center,
            style: PbmsText.caption,
          ),
        ],
      ),
    );
  }
}

class _ChangeRequestsCard extends StatelessWidget {
  final List<VehicleChangeRequestModel> requests;
  final ValueChanged<VehicleChangeRequestModel> onEdit;
  final ValueChanged<VehicleChangeRequestModel> onWithdraw;

  const _ChangeRequestsCard({
    required this.requests,
    required this.onEdit,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yêu cầu đổi biển số', style: PbmsText.section),
          for (final r in requests) ...[
            const Divider(height: 22, color: PbmsTokens.divider),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.oldLicensePlate} sang ${r.newLicensePlate}',
                          style: PbmsText.bodyStrong),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (r.packageName != null) r.packageName!,
                          if (r.createdAt != null)
                            DateFormatter.formatDate(r.createdAt),
                        ].join(', '),
                        style: PbmsText.caption,
                      ),
                      if (r.rejectionReason != null) ...[
                        const SizedBox(height: 4),
                        Text('Lý do từ chối: ${r.rejectionReason}',
                            style: PbmsText.caption
                                .copyWith(color: PbmsTokens.danger)),
                      ],
                    ],
                  ),
                ),
                PbmsStatusPill(StatusInfo.vehicleChange(r.status)),
              ],
            ),
            if (r.status.toLowerCase() == 'pending')
              Row(
                children: [
                  TextButton(
                    onPressed: () => onEdit(r),
                    style: TextButton.styleFrom(
                        foregroundColor: PbmsTokens.teal,
                        minimumSize: const Size(48, 44)),
                    child: const Text('Sửa'),
                  ),
                  TextButton(
                    onPressed: () => onWithdraw(r),
                    style: TextButton.styleFrom(
                        foregroundColor: PbmsTokens.danger,
                        minimumSize: const Size(48, 44)),
                    child: const Text('Rút yêu cầu'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _PastPassTile extends StatelessWidget {
  final MonthlySubscriptionModel pass;
  final VoidCallback? onRenew;

  const _PastPassTile({required this.pass, this.onRenew});

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pass.packageName}, ${pass.licensePlate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PbmsText.bodyStrong),
                const SizedBox(height: 3),
                Text('Hết hạn ${DateFormatter.formatDate(pass.endDate)}',
                    style: PbmsText.caption),
              ],
            ),
          ),
          PbmsStatusPill(StatusInfo.subscription(pass.displayStatus)),
          if (onRenew != null)
            TextButton.icon(
              onPressed: onRenew,
              style: TextButton.styleFrom(
                  foregroundColor: PbmsTokens.teal,
                  minimumSize: const Size(48, 44)),
              icon: const Icon(Icons.autorenew_rounded, size: 18),
              label: const Text('Gia hạn vé'),
            ),
        ],
      ),
    );
  }
}

class _RegistrationForm extends StatefulWidget {
  final List<SubscriptionPackageModel> packages;
  final Future<void> Function(RegistrationResultModel result) onRegistered;

  /// Xe đã có đơn chờ thanh toán; trả true nếu đơn cũ đã huỷ để đăng ký lại.
  final Future<bool> Function(VehicleModel vehicle) onPendingConflict;

  const _RegistrationForm({
    required this.packages,
    required this.onRegistered,
    required this.onPendingConflict,
  });

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  VehicleModel? _vehicle;
  bool _payByWallet = false;

  late String _vehicleTypeId = widget.packages.first.vehicleTypeId;
  String? _packageId;
  AsyncCubit<List<ParkingSlotModel>>? _slots;
  String? _slotId;

  /// Bãi áp dụng vé (gói một bãi). Hệ thống chỉ có một bãi thì tự chọn.
  late final _lots = AsyncCubit<List<ParkingLotModel>>(_loadLots);
  String? _parkingId;
  bool _busy = false;
  String? _error;

  List<(String, String)> get _vehicleTypes {
    final seen = <String, String>{};
    for (final p in widget.packages) {
      seen.putIfAbsent(p.vehicleTypeId, () => p.vehicleTypeName);
    }
    return seen.entries.map((e) => (e.key, e.value)).toList();
  }

  List<SubscriptionPackageModel> get _plans => widget.packages
      .where((p) => p.vehicleTypeId == _vehicleTypeId)
      .toList()
    ..sort((a, b) => a.durationMonths.compareTo(b.durationMonths));

  SubscriptionPackageModel? get _selected =>
      _plans.where((p) => p.packageId == _packageId).firstOrNull;

  bool get _needsSlot => _selected?.needsFixedSlot ?? false;

  bool get _needsLot {
    final p = _selected;
    return p != null && !p.allParkings;
  }

  Future<List<ParkingLotModel>> _loadLots() async {
    final lots = await _repo.getParkingLots();
    if (lots.length == 1 && _parkingId == null && mounted) {
      setState(() {
        _parkingId = lots.first.id;
        _syncSlots();
      });
    }
    return lots;
  }

  void _selectLot(String id) {
    setState(() {
      _parkingId = id;
      _error = null;
      _syncSlots();
    });
  }

  @override
  void initState() {
    super.initState();
    _packageId = _plans.firstOrNull?.packageId;
    _syncSlots();
  }

  @override
  void dispose() {
    _slots?.close();
    _lots.close();
    super.dispose();
  }

  void _syncSlots() {
    _slots?.close();
    _slots = null;
    _slotId = null;
    if (_needsSlot) {
      // Ô cố định phải thuộc bãi đã chọn.
      final lot = _parkingId;
      _slots = AsyncCubit(() async => (await _repo.getResidentSlots(_vehicleTypeId))
          .where((s) => lot == null || s.parkingId.isEmpty || s.parkingId == lot)
          .toList());
    }
  }

  void _selectVehicleType(String id) {
    setState(() {
      _vehicleTypeId = id;
      _packageId = _plans.firstOrNull?.packageId;
      _error = null;
      _syncSlots();
    });
  }

  void _selectPlan(String id) {
    setState(() {
      _packageId = id;
      _error = null;
      _syncSlots();
    });
  }

  Future<void> _submit() async {
    final pkg = _selected;
    if (pkg == null) return;
    final vehicle = _vehicle;
    if (vehicle == null) {
      setState(() => _error = 'Chọn xe đăng ký vé.');
      return;
    }
    if (_needsLot && _parkingId == null) {
      setState(() => _error = 'Chọn bãi đỗ áp dụng vé.');
      return;
    }
    if (_needsSlot && _slotId == null) {
      setState(() => _error = 'Chọn một ô đỗ cố định.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    Future<RegistrationResultModel> register() => _repo.registerSubscription(
          packageId: pkg.packageId,
          vehicleId: vehicle.id,
          fixedSlotId: _needsSlot ? _slotId : null,
          parkingId: _needsLot ? _parkingId : null,
          // Gói có hợp đồng: chọn cách trả ở bước ký.
          paymentMethod: _payByWallet && pkg.durationMonths < 3 ? 'Wallet' : 'PayOS',
        );
    try {
      RegistrationResultModel result;
      try {
        result = await register();
      } on ConflictException catch (e) {
        // Xe đang có đơn chờ thanh toán: khách chọn trả đơn cũ hoặc huỷ để đăng ký lại.
        if (!mounted) return;
        setState(() => _busy = false);
        final cancelledOld = await widget.onPendingConflict(vehicle);
        if (!cancelledOld) {
          if (mounted) setState(() => _error = e.message);
          return;
        }
        if (!mounted) return;
        setState(() => _busy = true);
        result = await register();
      }
      if (!mounted) return;
      await widget.onRegistered(result);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _vehicleTypes;
    final selected = _selected;

    return PbmsCard(
      padding: const EdgeInsets.all(16),
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Đăng ký vé tháng mới', style: PbmsText.title),
            const SizedBox(height: 4),
            const Text('Chọn phương tiện và kỳ hạn vé', style: PbmsText.caption),
            const SizedBox(height: 17),
            const Text('Bãi áp dụng vé', style: PbmsText.label),
            const SizedBox(height: 6),
            if (_needsLot)
              ParkingLotPicker(lots: _lots, selectedId: _parkingId, onSelected: _selectLot)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: PbmsTokens.surfaceLow,
                  border: Border.all(color: PbmsTokens.border),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.public_rounded, size: 18, color: PbmsTokens.teal),
                    SizedBox(width: 8),
                    Text('Mọi bãi PBMS', style: PbmsText.body),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const Text('Loại phương tiện', style: PbmsText.label),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: [
                for (final t in types)
                  ButtonSegment(
                    value: t.$1,
                    label: Text(t.$2),
                    icon: Icon(t.$2.toLowerCase().contains('máy')
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded),
                  ),
              ],
              selected: {_vehicleTypeId},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _selectVehicleType(s.first),
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                foregroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? PbmsTokens.teal
                        : PbmsTokens.muted),
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? PbmsTokens.tealTint
                        : Colors.white),
                side: WidgetStateProperty.resolveWith((states) => BorderSide(
                    color: states.contains(WidgetState.selected)
                        ? PbmsTokens.teal
                        : PbmsTokens.border)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Xe đăng ký vé', style: PbmsText.label),
            const SizedBox(height: 6),
            VehiclePicker(
              selectedId: _vehicle?.id,
              filter: (v) => v.vehicleTypeId == _vehicleTypeId,
              preferredTypeId: _vehicleTypeId,
              emptyMessage: 'Chưa có xe loại này trong tài khoản. Thêm xe để đăng ký vé.',
              onChanged: (v) => setState(() {
                _vehicle = v;
                _error = null;
              }),
            ),
            const SizedBox(height: 14),
            const Text('Kỳ hạn cước', style: PbmsText.label),
            const SizedBox(height: 6),
            for (final p in _plans) ...[
              PlanOption(
                selected: _packageId == p.packageId,
                title: p.packageName,
                subtitle: [
                  '${p.durationMonths} tháng',
                  if (p.allParkings) 'đỗ ở mọi bãi',
                  if (p.needsFixedSlot) 'ô cố định',
                  if (p.durationMonths >= 3) 'kèm hợp đồng điện tử',
                  if (p.description != null) p.description!,
                ].join(', '),
                price: CurrencyFormatter.format(p.price),
                onTap: () => _selectPlan(p.packageId),
              ),
              const SizedBox(height: 8),
            ],
            if (_needsSlot && _slots != null) ...[
              const SizedBox(height: 6),
              const Text('Ô đỗ cố định tại tầng cư dân', style: PbmsText.label),
              const SizedBox(height: 6),
              FixedSlotPicker(
                slots: _slots!,
                selectedId: _slotId,
                onSelected: (id) => setState(() {
                  _slotId = id;
                  _error = null;
                }),
              ),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                  color: PbmsTokens.surfaceLow,
                  borderRadius: BorderRadius.circular(11)),
              child: Row(
                children: [
                  const Expanded(
                      child: Text('Tổng tiền', style: PbmsText.caption)),
                  Text(
                      selected == null
                          ? 'Chọn gói'
                          : CurrencyFormatter.format(selected.price),
                      style: PbmsText.figure(16)),
                ],
              ),
            ),
            if ((selected?.durationMonths ?? 0) < 3) ...[
              const SizedBox(height: 14),
              const Text('Thanh toán', style: PbmsText.label),
              const SizedBox(height: 6),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      label: Text('PayOS'),
                      icon: Icon(Icons.credit_card_rounded)),
                  ButtonSegment(
                      value: true,
                      label: Text('Ví PBMS'),
                      icon: Icon(Icons.account_balance_wallet_rounded)),
                ],
                selected: {_payByWallet},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _payByWallet = s.first),
                style: ButtonStyle(
                  minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                  foregroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? PbmsTokens.teal : PbmsTokens.muted),
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? PbmsTokens.tealTint : Colors.white),
                  side: WidgetStateProperty.resolveWith((states) => BorderSide(
                      color: states.contains(WidgetState.selected)
                          ? PbmsTokens.teal
                          : PbmsTokens.border)),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
            ],
            const SizedBox(height: 12),
            PbmsPrimaryButton(
              label: (selected?.durationMonths ?? 0) >= 3
                  ? 'Tiếp tục ký hợp đồng'
                  : (_payByWallet ? 'Trả bằng ví & kích hoạt' : 'Thanh toán & kích hoạt'),
              icon: (selected?.durationMonths ?? 0) >= 3
                  ? Icons.draw_rounded
                  : Icons.credit_card_rounded,
              busy: _busy,
              onPressed: selected == null ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
