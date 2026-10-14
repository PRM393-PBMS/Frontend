import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/presentation/session_widgets.dart';

class StaffSessionsScreen extends StatefulWidget {
  const StaffSessionsScreen({super.key});

  @override
  State<StaffSessionsScreen> createState() => _StaffSessionsScreenState();
}

class _StaffSessionsScreenState extends State<StaffSessionsScreen> {
  late final DataCubit<List<ParkingSession>> _cubit =
      DataCubit(context.read<SessionRepository>().all)..load();
  bool _activeOnly = true;
  String _query = '';

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ssTitle)),
      body: LoadStateView<List<ParkingSession>>(
        cubit: _cubit,
        header: [
          TextField(
            decoration: InputDecoration(
              hintText: context.l10n.ssSearch,
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) =>
                setState(() => _query = Validators.normalizePlate(v)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ChoiceChip(
                label: Text(context.l10n.ssActive),
                selected: _activeOnly,
                onSelected: (_) => setState(() => _activeOnly = true),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: Text(context.l10n.commonAll),
                selected: !_activeOnly,
                onSelected: (_) => setState(() => _activeOnly = false),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        builder: (context, all) {
          final list = all
              .where((s) => !_activeOnly || s.isActive)
              .where((s) => _query.isEmpty || s.licensePlateIn.contains(_query))
              .toList();
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.local_parking_outlined,
              title: _query.isNotEmpty
                  ? context.l10n.ssNoMatchTitle
                  : context.l10n.ssEmptyTitle,
              message: _query.isNotEmpty
                  ? context.l10n.ssNoMatchMessage
                  : context.l10n.ssEmptyMessage,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(context.l10n.ssCount(list.length)),
              for (final s in list) ...[
                SessionTile(
                  session: s,
                  showDriver: true,
                  onTap: () async {
                    await context.push(RouteNames.staffSessionDetail(s.id));
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
