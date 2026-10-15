import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/error_text.dart';
import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/payment_sheet.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_tag.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';
import '../shell/shell_scope.dart';
import 'pass_sheets.dart';

class MonthlyPassScreen extends StatefulWidget {
  const MonthlyPassScreen({super.key});

  @override
  State<MonthlyPassScreen> createState() => _MonthlyPassScreenState();
}

class _MonthlyPassScreenState extends State<MonthlyPassScreen> with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _passes = AsyncCubit(_repo.getMySubscriptions);
  late final _packages = AsyncCubit(_repo.getSubscriptionPackages);
  late final _changes = AsyncCubit(_repo.getMyVehicleChangeRequests);

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

  Future<void> _pay(MonthlySubscriptionModel sub) async {
    try {
      final link = await _repo.repaySubscription(sub.subscriptionId);
      if (!mounted) return;
      final paid = await PaymentSheet.show(
        context,
        title: 'Thanh toán vé tháng',
        link: link,
        verify: () => _verifyActive(sub.subscriptionId),
      );
      _changed();
      if (paid && mounted) showSnack(context, 'Vé tháng đã được kích hoạt.');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    }
  }

  Future<void> _register(SubscriptionPackageModel pkg) async {
    final link = await RegisterPassSheet.show(context, pkg);
    if (link == null || !mounted) return;
    final paid = await PaymentSheet.show(
      context,
      title: 'Thanh toán vé tháng',
      link: link,
      verify: () => _verifyActive(link.subscriptionId),
    );
    _changed();
    if (paid && mounted) showSnack(context, 'Vé tháng đã được kích hoạt.');
  }

  Future<void> _renew(MonthlySubscriptionModel sub) async {
    final packages = (_packages.state.data ?? const <SubscriptionPackageModel>[])
        .where((p) => p.vehicleTypeName == sub.vehicleType)
        .toList();
    final link = await RenewPassSheet.show(context, sub, packages);
    if (link == null || !mounted) return;
    final oldEnd = sub.endDate;
    final paid = await PaymentSheet.show(
      context,
      title: 'Thanh toán gia hạn',
      link: link,
      verify: () async {
        final fresh = await _repo.getSubscription(sub.subscriptionId);
        final extended = fresh.endDate != null && oldEnd != null && fresh.endDate!.isAfter(oldEnd);
        return extended ? PaymentCheck.paid : PaymentCheck.pending;
      },
    );
    _changed();
    if (paid && mounted) showSnack(context, 'Đã gia hạn vé tháng.');
  }

  Future<void> _cancel(MonthlySubscriptionModel sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ vé tháng?'),
        content: Text(
          'Vé của xe ${PlateBadge.format(sub.licensePlate)} sẽ ngừng hiệu lực'
          '${sub.fixedSlot != null ? ' và ô ${sub.fixedSlot} được trả lại' : ''}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ vé')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.palette.danger),
            child: const Text('Huỷ vé'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.cancelSubscription(sub.subscriptionId);
      _changed();
      if (mounted) showSnack(context, 'Đã huỷ vé tháng.');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    }
  }

  Future<void> _changePlate(MonthlySubscriptionModel sub) async {
    final sent = await VehicleChangeSheet.show(context, sub);
    if (sent == true) {
      _changed();
      if (mounted) showSnack(context, 'Đã gửi yêu cầu đổi biển số. Quản lý sẽ duyệt sớm.');
    }
  }

  Future<void> _editChange(VehicleChangeRequestModel request) async {
    final saved = await VehicleChangeSheet.edit(context, request);
    if (saved == true) {
      _changed();
      if (mounted) showSnack(context, 'Đã cập nhật yêu cầu đổi biển số.');
    }
  }

  Future<void> _withdrawChange(VehicleChangeRequestModel request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rút yêu cầu?'),
        content: Text(
          'Yêu cầu đổi sang ${PlateBadge.format(request.newLicensePlate)} sẽ bị xoá. Vé vẫn giữ biển số cũ.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.palette.danger),
            child: const Text('Rút yêu cầu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.withdrawVehicleChangeRequest(request.requestId);
      _changed();
      if (mounted) showSnack(context, 'Đã rút yêu cầu đổi biển số.');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => reloadAll(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.scrollBottom),
            children: [
              Text('Vé tháng', style: t.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Ra vào không giới hạn, nhận diện biển số tự động tại cổng.',
                style: t.bodyMedium?.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              BlocBuilder<AsyncCubit<List<MonthlySubscriptionModel>>,
                  AsyncState<List<MonthlySubscriptionModel>>>(
                bloc: _passes,
                builder: (context, st) => AsyncView(
                  state: st,
                  onRetry: _passes.load,
                  loading: const SkeletonCard(height: 190),
                  isEmpty: (d) => d.where((s) => !s.isCancelled).isEmpty,
                  empty: const EmptyState(
                    icon: Icons.badge_outlined,
                    title: 'Bạn chưa có vé tháng',
                    message: 'Chọn một gói bên dưới, nhập biển số và thanh toán qua PayOS để kích hoạt.',
                  ),
                  builder: (items) {
                    final visible = items.where((s) => !s.isCancelled).toList()
                      ..sort((a, b) => (a.isActive ? 0 : 1).compareTo(b.isActive ? 0 : 1));
                    return Column(
                      children: [
                        for (final s in visible) ...[
                          _PassCard(
                            pass: s,
                            onPay: () => _pay(s),
                            onRenew: () => _renew(s),
                            onChangePlate: () => _changePlate(s),
                            onHistory: () => RenewalHistorySheet.show(context, s),
                            onCancel: () => _cancel(s),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                ),
              ),
              BlocBuilder<AsyncCubit<List<VehicleChangeRequestModel>>,
                  AsyncState<List<VehicleChangeRequestModel>>>(
                bloc: _changes,
                builder: (context, st) {
                  final items = st.data ?? const <VehicleChangeRequestModel>[];
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Yêu cầu đổi biển số'),
                      AppPanel(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) Divider(height: 1, color: p.line),
                              _ChangeRequestRow(
                                item: items[i],
                                onEdit: () => _editChange(items[i]),
                                onWithdraw: () => _withdrawChange(items[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SectionHeader(title: 'Gói đang bán'),
              BlocBuilder<AsyncCubit<List<SubscriptionPackageModel>>,
                  AsyncState<List<SubscriptionPackageModel>>>(
                bloc: _packages,
                builder: (context, st) => AsyncView(
                  state: st,
                  onRetry: _packages.load,
                  loading: const SkeletonList(count: 3, itemHeight: 84),
                  isEmpty: (d) => d.isEmpty,
                  empty: const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Chưa mở bán gói tháng',
                    message: 'Bãi xe chưa có gói thuê bao nào đang áp dụng.',
                  ),
                  builder: (items) {
                    final sorted = [...items]
                      ..sort((a, b) {
                        final byType = (a.isMotorbike ? 1 : 0).compareTo(b.isMotorbike ? 1 : 0);
                        return byType != 0 ? byType : a.durationMonths.compareTo(b.durationMonths);
                      });
                    return Column(
                      children: [
                        for (final pkg in sorted) ...[
                          _PackageTile(pkg: pkg, onTap: () => _register(pkg)),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PassAction { history, cancel }

class _PassCard extends StatelessWidget {
  final MonthlySubscriptionModel pass;
  final VoidCallback onPay;
  final VoidCallback onRenew;
  final VoidCallback onChangePlate;
  final VoidCallback onHistory;
  final VoidCallback onCancel;

  const _PassCard({
    required this.pass,
    required this.onPay,
    required this.onRenew,
    required this.onChangePlate,
    required this.onHistory,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final s = pass;
    final info = StatusInfo.subscription(s.status);
    final soon = s.isActive && s.daysLeft <= 5;

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PlateBadge(plate: s.licensePlate, fontSize: 17),
                    StatusTag.of(info),
                  ],
                ),
              ),
              PopupMenuButton<_PassAction>(
                tooltip: 'Tuỳ chọn khác',
                icon: Icon(Icons.more_vert_rounded, color: p.textSecondary),
                onSelected: (a) => a == _PassAction.history ? onHistory() : onCancel(),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: _PassAction.history, child: Text('Lịch sử gia hạn')),
                  PopupMenuItem(
                    value: _PassAction.cancel,
                    child: Text('Huỷ vé tháng', style: TextStyle(color: p.danger)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.packageName, style: t.titleMedium),
                Text(
                  [s.vehicleType, if (s.fixedSlot != null) 'Ô cố định ${s.fixedSlot}']
                      .where((x) => x.isNotEmpty)
                      .join(' · '),
                  style: t.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (s.isActive) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.daysLeft}',
                        style: AppTypography.mono(
                          size: 30,
                          weight: FontWeight.w700,
                          color: soon ? p.warn : p.text,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('ngày còn lại', style: t.bodySmall),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'đến ${DateFormatter.formatDate(s.endDate)}',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.mono(size: 12, color: p.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 1 - s.elapsedRatio,
                      minHeight: 5,
                      color: soon ? p.warn : p.ok,
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.isPendingPayment
                              ? 'Hoàn tất thanh toán để kích hoạt vé.'
                              : 'Hết hiệu lực ngày ${DateFormatter.formatDate(s.endDate)}.',
                          style: t.bodyMedium?.copyWith(color: p.textSecondary),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(s.price),
                        style: AppTypography.mono(size: 16, weight: FontWeight.w700, color: p.text),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            children: [
              if (s.isPendingPayment)
                TextButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Thanh toán'),
                ),
              if (!s.isPendingPayment)
                TextButton.icon(
                  onPressed: onRenew,
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: const Text('Gia hạn'),
                ),
              if (s.isActive)
                TextButton.icon(
                  onPressed: onChangePlate,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Đổi biển số'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeRequestRow extends StatelessWidget {
  final VehicleChangeRequestModel item;
  final VoidCallback onEdit;
  final VoidCallback onWithdraw;

  const _ChangeRequestRow({required this.item, required this.onEdit, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlateBadge(plate: item.oldLicensePlate, fontSize: 12),
              Icon(Icons.arrow_forward_rounded, size: 16, color: p.textMuted),
              PlateBadge(plate: item.newLicensePlate, fontSize: 12),
              StatusTag.of(StatusInfo.vehicleChange(item.status)),
            ],
          ),
          if (item.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text('Lý do từ chối: ${item.rejectionReason}', style: t.bodySmall?.copyWith(color: p.danger)),
          ] else if (item.createdAt != null) ...[
            const SizedBox(height: 6),
            Text('Gửi ${DateFormatter.relative(item.createdAt!)}', style: t.bodySmall),
          ],
          if (item.status.toLowerCase() == 'pending')
            Wrap(
              spacing: 4,
              children: [
                TextButton(onPressed: onEdit, child: const Text('Sửa')),
                TextButton(
                  onPressed: onWithdraw,
                  style: TextButton.styleFrom(foregroundColor: p.danger),
                  child: const Text('Rút yêu cầu'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final SubscriptionPackageModel pkg;
  final VoidCallback onTap;

  const _PackageTile({required this.pkg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final perMonth = pkg.durationMonths > 1 ? pkg.price / pkg.durationMonths : null;
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.surfaceRaised, borderRadius: AppSpacing.roundedMd),
            child: Icon(
              pkg.isMotorbike ? Icons.two_wheeler_rounded : Icons.directions_car_filled_rounded,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkg.packageName, style: t.titleSmall),
                const SizedBox(height: 2),
                Text(
                  [
                    '${pkg.durationMonths} tháng',
                    pkg.vehicleTypeName,
                    if (pkg.requireFixedSlot && !pkg.isMotorbike) 'chọn ô cố định',
                  ].join(' · '),
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(pkg.price),
                style: AppTypography.mono(size: 15, weight: FontWeight.w700, color: p.text),
              ),
              if (perMonth != null)
                Text('${CurrencyFormatter.format(perMonth)}/th', style: t.labelSmall),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}
