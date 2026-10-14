import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';

/// Chọn cổng vào/ra cho ca làm việc; nhớ lựa chọn gần nhất trên thiết bị.
class GateSelector extends StatefulWidget {
  final bool entry;
  final ValueChanged<GateItem?> onChanged;

  const GateSelector({super.key, required this.entry, required this.onChanged});

  @override
  State<GateSelector> createState() => _GateSelectorState();
}

class _GateSelectorState extends State<GateSelector> {
  List<GateItem>? _gates;
  GateItem? _selected;
  Object? _error;

  String get _key =>
      widget.entry ? 'pbms_staff_entry_gate' : 'pbms_staff_exit_gate';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final all = await context.read<CatalogRepository>().gates();
      final gates =
          all.where((g) => widget.entry ? g.isEntry : g.isExit).toList();
      String? saved;
      try {
        saved = (await SharedPreferences.getInstance()).getString(_key);
      } catch (_) {}
      GateItem? pick;
      for (final g in gates) {
        if (g.id == saved) pick = g;
      }
      pick ??= gates.length == 1 ? gates.first : null;
      if (!mounted) return;
      setState(() {
        _gates = gates;
        _selected = pick;
      });
      widget.onChanged(pick);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _select(GateItem? g) async {
    setState(() => _selected = g);
    widget.onChanged(g);
    if (g != null) {
      try {
        await (await SharedPreferences.getInstance()).setString(_key, g.id);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = widget.entry ? context.l10n.gateEntry : context.l10n.gateExit;
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineMessage(errorText(_error, context.l10n)),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(label: context.l10n.gateReload, onPressed: _load),
        ],
      );
    }
    final gates = _gates;
    if (gates == null) {
      return const SkeletonBox(
          height: 52, radius: BorderRadius.all(Radius.circular(12)));
    }
    if (gates.isEmpty) {
      return InlineMessage(widget.entry
          ? context.l10n.gateNoneEntry
          : context.l10n.gateNoneExit);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall.copyWith(color: p.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selected?.id,
          isExpanded: true,
          hint: Text(context.l10n.gatePick),
          items: [
            for (final g in gates)
              DropdownMenuItem(
                  value: g.id, child: Text('${g.name}, ${g.floorName}')),
          ],
          onChanged: (id) =>
              _select(gates.where((g) => g.id == id).firstOrNull),
        ),
      ],
    );
  }
}
