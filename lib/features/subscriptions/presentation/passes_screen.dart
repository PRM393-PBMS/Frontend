import '../../../core/utils/settle.dart';
import '../../../core/l10n/locale_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/titanium_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../sessions/data/session_repository.dart';
import '../data/subscription_repository.dart';

/// Xe của tài xế, suy ra từ backend: biển số trong vé tháng và trong lịch sử gửi xe.
class MyVehicle extends Equatable {
  final String plate;
  final String? vehicleType;
  final MonthlyPass? pass;
  final DateTime? lastParked;

  const MyVehicle(
      {required this.plate, this.vehicleType, this.pass, this.lastParked});

  @override
  List<Object?> get props => [plate, vehicleType, pass, lastParked];
}

class PassesData extends Equatable {
  final List<MyVehicle> vehicles;
  final List<MonthlyPass> passes;
  final int pendingPlateRequests;

  const PassesData(
      {required this.vehicles,
      required this.passes,
      required this.pendingPlateRequests});

  @override
  List<Object?> get props => [vehicles, passes, pendingPlateRequests];
}

class PassesScreen extends StatefulWidget {
  const PassesScreen({super.key});

  @override
  State<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen> {
  late final DataCubit<PassesData> _cubit = DataCubit(_load)..load();

  Future<PassesData> _load() async {
    final subs = context.read<SubscriptionRepository>();
    final passesF = settle(subs.mine());
    final sessionsF = settle(context.read<SessionRepository>().mine());
    final requestsF = settle(subs.myChangeRequests());
    final passes = (await passesF).require;
    // Lịch sử gửi xe và yêu cầu đổi biển số chỉ bổ sung thông tin: lỗi thì bỏ qua.
    final sessions = (await sessionsF).value ?? const <ParkingSession>[];
    final requests = (await requestsF).value ?? const <VehicleChangeRequest>[];

    // Mỗi biển số lấy vé tháng "tốt nhất": đang hiệu lực > chờ thanh toán > gần nhất.
    int rank(MonthlyPass p) =>
        p.isValidNow ? 0 : (p.isPendingPayment ? 1 : (p.isActive ? 2 : 3));
    final byPlate = <String, MyVehicle>{};
    for (final pass in passes) {
      final cur = byPlate[pass.licensePlate]?.pass;
      if (cur == null || rank(pass) < rank(cur)) {
        byPlate[pass.licensePlate] = MyVehicle(
            plate: pass.licensePlate,
            vehicleType: pass.vehicleType,
            pass: pass);
      }
    }
    for (final s in sessions) {
      final existing = byPlate[s.licensePlateIn];
      final last = existing?.lastParked;
      if (existing == null) {
        byPlate[s.licensePlateIn] = MyVehicle(
            plate: s.licensePlateIn,
            vehicleType: s.vehicleTypeName,
            lastParked: s.entryTime);
      } else if (last == null || (s.entryTime?.isAfter(last) ?? false)) {
        byPlate[s.licensePlateIn] = MyVehicle(
          plate: existing.plate,
          vehicleType: existing.vehicleType ?? s.vehicleTypeName,
          pass: existing.pass,
          lastParked: s.entryTime,
        );
      }
    }
    final vehicles = byPlate.values.toList()
      ..sort((a, b) {
        final ra = a.pass == null ? 9 : rank(a.pass!);
        final rb = b.pass == null ? 9 : rank(b.pass!);
        return ra != rb ? ra.compareTo(rb) : a.plate.compareTo(b.plate);
      });
    return PassesData(
      vehicles: vehicles,
      passes: passes,
      pendingPlateRequests: requests.where((r) => r.isPending).length,
    );
  }

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
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.passesTitle),
        actions: [
          TextButton.icon(
            onPressed: () => _open(RouteNames.registerPass),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(context.l10n.passesRegister),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: LoadStateView<PassesData>(
        cubit: _cubit,
        isEmpty: (d) => d.vehicles.isEmpty,
        empty: EmptyState(
          icon: Icons.directions_car_outlined,
          title: context.l10n.passesEmptyTitle,
          message: context.l10n.passesEmptyMessage,
          actionLabel: context.l10n.passesRegisterPass,
          onAction: () => _open(RouteNames.registerPass),
        ),
        builder: (context, d) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final v in d.vehicles) ...[
              _VehicleCard(
                vehicle: v,
                onTap: v.pass != null
                    ? () => _open(RouteNames.passDetail(v.pass!.id))
                    : () => _open(
                        '${RouteNames.registerPass}?plate=${Uri.encodeComponent(v.plate)}'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.swap_horiz_rounded, color: p.textSecondary),
              title: Text(context.l10n.passesPlateRequests),
              subtitle: Text(d.pendingPlateRequests > 0
                  ? context.l10n
                      .passesPendingRequests('${d.pendingPlateRequests}')
                  : context.l10n.passesTrackRequests),
              trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
              onTap: () => _open(RouteNames.plateRequests),
            ),
            if (d.passes.length >
                d.vehicles.where((v) => v.pass != null).length) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(context.l10n.passesAll),
              for (final pass in d.passes) ...[
                _PassRow(
                    pass: pass,
                    onTap: () => _open(RouteNames.passDetail(pass.id))),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final MyVehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Nội dung nằm trên nền titanium nên luôn dùng bảng màu tối.
    const p = AppPalette.dark;
    final pass = vehicle.pass;
    return TitaniumCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EdgeRow(
            leading: PlateTag(vehicle.plate, large: true),
            trailing: pass != null
                ? StatusBadge(
                    StatusLabels.subscription(context.l10n, pass.status))
                : StatusBadge(
                    StatusInfo(context.l10n.stNoPass, StatusTone.neutral)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            [vehicle.vehicleType, pass?.packageName]
                .whereType<String>()
                .join(', '),
            style: AppTypography.bodySmall.copyWith(color: p.textSecondary),
          ),
          if (pass != null && pass.isValidNow) ...[
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pass.progress,
                minHeight: 6,
                backgroundColor: p.surfaceMuted,
                color: pass.daysLeft <= 5 ? p.warning : p.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text(context.l10n.passDaysLeft(pass.daysLeft),
                    style: AppTypography.label.copyWith(
                        color: pass.daysLeft <= 5 ? p.warning : p.textPrimary)),
                Text(
                    context.l10n
                        .passExpiresOn(DateFormatter.formatDate(pass.endDate)),
                    style:
                        AppTypography.caption.copyWith(color: p.textSecondary)),
              ],
            ),
            if (pass.fixedSlot != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(context.l10n.passFixedSlot(pass.fixedSlot!),
                  style:
                      AppTypography.caption.copyWith(color: p.textSecondary)),
            ],
          ] else if (pass != null && pass.isPendingPayment) ...[
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.passPayToActivate,
                style: AppTypography.label.copyWith(color: p.accent)),
          ] else if (pass == null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              vehicle.lastParked != null
                  ? context.l10n.passLastParked(DateFormatter.formatRelativeDay(
                      context.l10n, vehicle.lastParked))
                  : context.l10n.passesRegisterPass,
              style: AppTypography.label.copyWith(color: p.accent),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.passRenewOrRegister,
                style: AppTypography.label.copyWith(color: p.accent)),
          ],
        ],
      ),
    );
  }
}

class _PassRow extends StatelessWidget {
  final MonthlyPass pass;
  final VoidCallback onTap;

  const _PassRow({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pass.licensePlate}, ${pass.packageName ?? ''}',
                    style: AppTypography.label.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(
                    context.l10n.dateRange(
                        DateFormatter.formatDate(pass.startDate),
                        DateFormatter.formatDate(pass.endDate)),
                    style:
                        AppTypography.caption.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          StatusBadge(StatusLabels.subscription(context.l10n, pass.status)),
        ],
      ),
    );
  }
}
