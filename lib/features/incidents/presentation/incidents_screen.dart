import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../data/incident_repository.dart';
import 'incident_widgets.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  late final DataCubit<List<IncidentReport>> _cubit =
      DataCubit(context.read<IncidentRepository>().mine)..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.incListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(RouteNames.newIncident),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.incReport),
      ),
      body: LoadStateView<List<IncidentReport>>(
        cubit: _cubit,
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(
          icon: Icons.report_outlined,
          title: context.l10n.incEmptyTitle,
          message: context.l10n.incEmptyMessage,
          actionLabel: context.l10n.incReport,
          onAction: () => _open(RouteNames.newIncident),
        ),
        builder: (context, list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final i in list) ...[
              IncidentTile(
                  incident: i,
                  onTap: () => _open(RouteNames.incidentDetail(i.id))),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}
