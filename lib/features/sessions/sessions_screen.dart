import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_tag.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';
import '../home/widgets/facility_widgets.dart';
import '../shell/shell_scope.dart';
import 'session_detail_sheet.dart';

enum _Filter { all, active, done }

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with ReloadOnDataChange {
  late final _sessions = AsyncCubit(context.read<PbmsRepository>().getMySessions);
  _Filter _filter = _Filter.all;

  @override
  void reloadAll() => _sessions.load();

  @override
  void dispose() {
    _sessions.close();
    super.dispose();
  }

  List<ParkingSessionModel> _apply(List<ParkingSessionModel> items) => switch (_filter) {
        _Filter.all => items,
        _Filter.active => items.where((s) => s.isActive).toList(),
        _Filter.done => items.where((s) => !s.isActive).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _sessions.load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.scrollBottom),
            children: [
              Text('Lượt gửi xe', style: t.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Các lần xe của bạn vào bãi, phí và thanh toán.',
                style: t.bodyMedium?.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              SegmentedButton<_Filter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Filter.all, label: Text('Tất cả')),
                  ButtonSegment(value: _Filter.active, label: Text('Đang gửi')),
                  ButtonSegment(value: _Filter.done, label: Text('Đã ra')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<AsyncCubit<List<ParkingSessionModel>>, AsyncState<List<ParkingSessionModel>>>(
                bloc: _sessions,
                builder: (context, st) => AsyncView(
                  state: st,
                  onRetry: _sessions.load,
                  isEmpty: (d) => _apply(d).isEmpty,
                  empty: EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: _filter == _Filter.active ? 'Không có xe nào trong bãi' : 'Chưa có lượt gửi xe',
                    message: 'Khi xe của bạn qua cổng, lượt gửi sẽ xuất hiện ở đây kèm phí tạm tính.',
                    actionLabel: 'Đặt chỗ trước',
                    onAction: () => ShellScope.maybeOf(context)?.goTab(AppTab.reserve),
                  ),
                  builder: (items) {
                    final list = _apply(items);
                    return Column(
                      children: [
                        for (final s in list) ...[
                          _SessionTile(session: s),
                          const SizedBox(height: AppSpacing.md),
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

class _SessionTile extends StatelessWidget {
  final ParkingSessionModel session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final s = session;
    return AppPanel(
      onTap: () => SessionDetailSheet.show(context, s),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PlateBadge(plate: s.licensePlateIn, fontSize: 14),
                    if (s.slotCode != null)
                      Text('Ô ${s.slotCode}', style: AppTypography.mono(size: 13, color: p.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusTag.of(StatusInfo.session(s.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormatter.formatTime(s.entryTime)} → ${s.exitTime == null ? 'nay' : DateFormatter.formatTime(s.exitTime)}',
                      style: AppTypography.mono(size: 15, weight: FontWeight.w600, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(DateFormatter.formatDay(s.entryTime), style: t.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  s.isActive
                      ? LiveDuration(
                          since: s.entryTime,
                          style: AppTypography.mono(size: 18, weight: FontWeight.w700, color: p.accent),
                        )
                      : Text(
                          DateFormatter.clock(s.parkedDuration),
                          style: AppTypography.mono(size: 18, weight: FontWeight.w700, color: p.text),
                        ),
                  const SizedBox(height: 2),
                  Text(
                    s.isActive
                        ? 'Xem phí tạm tính'
                        : (s.paymentAmount == null ? '—' : CurrencyFormatter.format(s.paymentAmount!)),
                    style: t.bodySmall?.copyWith(color: s.isActive ? p.accent : null),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
