import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/blocs/auth_bloc.dart';
import '../../incidents/data/incident_repository.dart';
import '../../incidents/presentation/incident_widgets.dart';

enum _Filter { open, mine, all }

class StaffIncidentsScreen extends StatefulWidget {
  const StaffIncidentsScreen({super.key});

  @override
  State<StaffIncidentsScreen> createState() => _StaffIncidentsScreenState();
}

class _StaffIncidentsScreenState extends State<StaffIncidentsScreen> {
  late final DataCubit<List<IncidentReport>> _cubit =
      DataCubit(context.read<IncidentRepository>().all)..load();
  _Filter _filter = _Filter.open;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.select((AuthBloc b) => b.state.user?.id);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.siTitle)),
      body: LoadStateView<List<IncidentReport>>(
        cubit: _cubit,
        header: [
          SegmentedButton<_Filter>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: _Filter.open, label: Text(context.l10n.siOpen)),
              ButtonSegment(
                  value: _Filter.mine, label: Text(context.l10n.siMine)),
              ButtonSegment(
                  value: _Filter.all, label: Text(context.l10n.commonAll)),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        builder: (context, all) {
          final list = all.where((i) {
            switch (_filter) {
              case _Filter.open:
                return i.isOpen || i.isInProgress;
              case _Filter.mine:
                return i.handledByStaffId == myId;
              case _Filter.all:
                return true;
            }
          }).toList();
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.task_alt_rounded,
              title: context.l10n.siEmptyTitle,
              message: context.l10n.siEmptyMessage,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in list) ...[
                IncidentTile(
                  incident: i,
                  showReporter: true,
                  onTap: () async {
                    await context.push(RouteNames.staffIncidentDetail(i.id));
                    if (mounted) _cubit.refresh();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}
