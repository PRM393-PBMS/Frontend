import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../data/session_repository.dart';
import 'session_widgets.dart';

/// Tab Lịch sử: các lượt gửi xe của tài xế.
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  late final DataCubit<List<ParkingSession>> _cubit =
      DataCubit(context.read<SessionRepository>().mine)..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _open(ParkingSession s) async {
    await context.push(RouteNames.sessionDetail(s.id), extra: s);
    if (mounted) _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.histTitle)),
      body: LoadStateView<List<ParkingSession>>(
        cubit: _cubit,
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: context.l10n.histEmptyTitle,
          message: context.l10n.histEmptyMessage,
        ),
        builder: (context, list) {
          final active = list.where((s) => s.isActive).toList();
          final done = list.where((s) => !s.isActive).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (active.isNotEmpty) ...[
                SectionHeader(context.l10n.histActive),
                for (final s in active) ...[
                  SessionTile(session: s, onTap: () => _open(s)),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              if (done.isNotEmpty) ...[
                SectionHeader(context.l10n.histDone),
                for (final s in done) ...[
                  SessionTile(session: s, onTap: () => _open(s)),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
