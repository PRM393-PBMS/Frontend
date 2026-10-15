import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/error_text.dart';
import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';
import '../shell/shell_scope.dart';
import 'reservation_widgets.dart';

bool _isCar(String vehicleTypeName) {
  final n = vehicleTypeName.toLowerCase();
  return n.contains('ô tô') || n.contains('oto') || n.contains('car');
}

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key});

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _availability = AsyncCubit(() => _repo.getAvailability());
  late final _pricing = AsyncCubit(_repo.getPricingPolicies);
  late final _reservations = AsyncCubit(_repo.getMyReservations);

  DateTime? _time;
  bool _submitting = false;
  String? _formError;

  @override
  void reloadAll() {
    _availability.load();
    _pricing.load();
    _reservations.load();
  }

  /// Báo toàn bộ tab (kể cả tab này) tải lại sau khi đặt/huỷ/đổi giờ.
  void _changedHere() {
    if (!mounted) return;
    ShellScope.dataChanged(context);
  }

  @override
  void dispose() {
    _availability.close();
    _pricing.close();
    _reservations.close();
    super.dispose();
  }

  Future<void> _submit() async {
    final time = _time;
    if (time == null) {
      setState(() => _formError = 'Chọn giờ dự kiến vào bãi.');
      return;
    }
    if (!ReservationWindow.isValid(time)) {
      setState(() => _formError = 'Giờ vào phải trong vòng 5 giờ tới. Chọn lại giờ.');
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final link = await _repo.createReservation(time);
      if (!mounted) return;
      setState(() => _time = null);
      await ReservationActions.payNew(context, link, _changedHere);
    } catch (e) {
      if (mounted) setState(() => _formError = errorText(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              Text('Đặt chỗ ô tô', style: t.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Giữ chỗ trước tối đa 5 giờ. Tiền cọc được trừ vào phí khi bạn ra bãi.',
                style: t.bodyMedium?.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              BlocBuilder<AsyncCubit<List<FacilityAvailabilityModel>>,
                  AsyncState<List<FacilityAvailabilityModel>>>(
                bloc: _availability,
                builder: (context, st) => AsyncView(
                  state: st,
                  onRetry: _availability.load,
                  errorTitle: 'Không tải được tình trạng chỗ',
                  loading: const SkeletonCard(height: 92),
                  builder: (items) => _CarCapacity(
                    items: items.where((i) => _isCar(i.vehicleTypeName)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPanel(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Giờ dự kiến vào bãi', style: t.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    EntryTimePicker(
                      value: _time,
                      onChanged: (v) => setState(() {
                        _time = v;
                        _formError = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(color: p.line),
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<AsyncCubit<List<PricingPolicyModel>>, AsyncState<List<PricingPolicyModel>>>(
                      bloc: _pricing,
                      builder: (context, st) {
                        final car = st.data?.where((x) => _isCar(x.vehicleTypeName)).firstOrNull;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tiền cọc', style: t.labelSmall),
                                  const SizedBox(height: 2),
                                  Text(
                                    car == null
                                        ? 'Bằng giá lượt đầu'
                                        : 'Giá ${car.baseHours} giờ đầu',
                                    style: t.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (st.data == null && st.isLoading)
                              const Skeleton(width: 90, height: 22)
                            else
                              Text(
                                car == null ? '—' : CurrencyFormatter.format(car.basePrice),
                                style: AppTypography.mono(size: 22, weight: FontWeight.w700, color: p.text),
                              ),
                          ],
                        );
                      },
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 18, color: p.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_formError!, style: t.bodyMedium?.copyWith(color: p.danger)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Giữ chỗ và đặt cọc'),
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Đặt chỗ của tôi'),
              BlocBuilder<AsyncCubit<List<ReservationModel>>, AsyncState<List<ReservationModel>>>(
                bloc: _reservations,
                builder: (context, st) => AsyncView(
                  state: st,
                  onRetry: _reservations.load,
                  isEmpty: (d) => d.isEmpty,
                  empty: const EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Chưa có đặt chỗ nào',
                    message: 'Chọn giờ vào ở trên để giữ một chỗ ô tô.',
                  ),
                  builder: (items) {
                    final active = items.where((r) => r.canModify).toList()
                      ..sort((a, b) => a.expectedEntryTime.compareTo(b.expectedEntryTime));
                    final past = items.where((r) => !r.canModify).take(10).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final r in active) ...[
                          ReservationCard(reservation: r, onChanged: _changedHere),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (past.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Text('Đã qua', style: t.titleSmall?.copyWith(color: p.textSecondary)),
                          ),
                          for (final r in past) ...[
                            ReservationCard(reservation: r, onChanged: _changedHere),
                            const SizedBox(height: AppSpacing.sm),
                          ],
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

class _CarCapacity extends StatelessWidget {
  final List<FacilityAvailabilityModel> items;

  const _CarCapacity({required this.items});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final available = items.fold<int>(0, (s, i) => s + i.availableSlots);
    final total = items.fold<int>(0, (s, i) => s + i.totalSlots);
    final tone = CapacityBar.toneFor(context, available, total);
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$available',
                style: AppTypography.mono(size: 34, weight: FontWeight.w700, color: tone, letterSpacing: -1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    total == 0 ? 'Bãi chưa có ô đỗ ô tô' : 'chỗ ô tô trống / $total',
                    style: t.bodyMedium?.copyWith(color: p.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CapacityBar(available: available, total: total),
          if (total > 0 && available == 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bãi đang đầy. Vẫn có thể đặt nếu còn suất giữ chỗ, hệ thống sẽ báo nếu hết.',
              style: t.bodySmall?.copyWith(color: p.warn),
            ),
          ],
        ],
      ),
    );
  }
}
