import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/history/presentation/widgets/session_detail_sheet.dart';
import 'package:prm393_frontend/features/home/presentation/shell_scope.dart';
import 'package:prm393_frontend/features/incidents/presentation/screens/incidents_screen.dart';
import 'package:prm393_frontend/features/reservations/presentation/widgets/reservation_actions.dart';

/// Tab "Lịch sử": lượt gửi xe và đặt chỗ của khách hàng.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _sessions = AsyncCubit(_repo.getMySessions);
  late final _reservations = AsyncCubit(_repo.getMyReservations);
  int _tab = 0;

  @override
  void reloadAll() {
    _sessions.load();
    _reservations.load();
  }

  @override
  void dispose() {
    _sessions.close();
    _reservations.close();
    super.dispose();
  }

  void _changed() {
    if (mounted) ShellScope.dataChanged(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: pbmsTabAppBar('Lịch sử', actions: [
        PbmsHeaderAction(
          tooltip: 'Báo cáo sự cố',
          onPressed: () => IncidentsScreen.open(context),
          icon: Icons.report_gmailerrorred_rounded,
        ),
      ]),
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
                    (Icons.receipt_long_rounded, 'Lượt gửi xe'),
                    (Icons.event_available_rounded, 'Đặt chỗ'),
                  ],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 16),
                if (_tab == 0) _buildSessions() else _buildReservations(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessions() {
    return PbmsAsync<List<ParkingSessionModel>>(
      cubit: _sessions,
      loadingHeight: 240,
      errorTitle: 'Không tải được lượt gửi xe',
      isEmpty: (d) => d.isEmpty,
      empty: const PbmsEmptyView(
        icon: Icons.receipt_long_outlined,
        title: 'Chưa có lượt gửi xe',
      ),
      builder: (items) {
        final total = items
            .where((s) => !s.isActive)
            .fold<double>(0, (sum, s) => sum + (s.paymentAmount ?? 0));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 11, left: 2),
              child: Text(
                '${items.length} lượt gửi, đã thanh toán ${CurrencyFormatter.format(total)}',
                style: PbmsText.caption,
              ),
            ),
            for (final s in items) ...[
              _SessionTile(
                session: s,
                onTap: () => SessionDetailSheet.show(context, s),
              ),
              const SizedBox(height: 9),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PbmsPrimaryButton(
          label: 'Đặt chỗ mới',
          icon: Icons.add_rounded,
          onPressed: () async {
            await context.push(RouteNames.mapPath);
            reloadAll();
          },
        ),
        const SizedBox(height: 16),
        PbmsAsync<List<ReservationModel>>(
          cubit: _reservations,
          loadingHeight: 200,
          errorTitle: 'Không tải được đặt chỗ',
          isEmpty: (d) => d.isEmpty,
          empty: const PbmsEmptyView(
            icon: Icons.event_busy_outlined,
            title: 'Chưa có đặt chỗ nào',
          ),
          builder: (items) {
            final active = items.where((r) => r.canModify).toList()
              ..sort(
                  (a, b) => a.expectedEntryTime.compareTo(b.expectedEntryTime));
            final past = items.where((r) => !r.canModify).take(20).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (active.isNotEmpty) ...[
                  const PbmsSectionTitle('Sắp tới'),
                  for (final r in active) ...[
                    ReservationCard(reservation: r, onChanged: _changed),
                    const SizedBox(height: 9),
                  ],
                  const SizedBox(height: 10),
                ],
                if (past.isNotEmpty) ...[
                  const PbmsSectionTitle('Đã qua'),
                  for (final r in past) ...[
                    ReservationCard(reservation: r, onChanged: _changed),
                    const SizedBox(height: 9),
                  ],
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ParkingSessionModel session;
  final VoidCallback onTap;

  const _SessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = session;
    return Material(
      color: s.isActive ? PbmsTokens.tealTint : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(
                color: s.isActive ? PbmsTokens.tealLine : PbmsTokens.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: s.isActive ? Colors.white : PbmsTokens.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  (s.vehicleTypeName ?? '').toLowerCase().contains('máy')
                      ? Icons.two_wheeler_rounded
                      : Icons.directions_car_rounded,
                  size: 22,
                  color: PbmsTokens.teal,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.licensePlateIn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.bodyStrong),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormatter.formatDayTime(s.entryTime)}, ${DateFormatter.humanDuration(s.parkedDuration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PbmsText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PbmsStatusPill(StatusInfo.session(s.status)),
                  const SizedBox(height: 5),
                  Text(
                    s.isActive
                        ? 'Xem phí'
                        : (s.paymentAmount == null
                            ? 'Chưa có phí'
                            : CurrencyFormatter.format(s.paymentAmount!)),
                    style: PbmsText.figure(13,
                        color: s.isActive ? PbmsTokens.teal : PbmsTokens.ink),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
