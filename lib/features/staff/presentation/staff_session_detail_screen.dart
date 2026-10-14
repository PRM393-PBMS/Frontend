import '../../../core/l10n/locale_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../payments/data/payment_models.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/presentation/session_widgets.dart';

class _StaffSessionData extends Equatable {
  final ParkingSession session;
  final FeeBreakdown? fee;
  final Object? feeError;

  const _StaffSessionData(this.session, this.fee, this.feeError);

  @override
  List<Object?> get props => [session, fee, feeError];
}

class StaffSessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const StaffSessionDetailScreen({super.key, required this.sessionId});

  @override
  State<StaffSessionDetailScreen> createState() =>
      _StaffSessionDetailScreenState();
}

class _StaffSessionDetailScreenState extends State<StaffSessionDetailScreen> {
  late final SessionRepository _repo = context.read<SessionRepository>();
  late final DataCubit<_StaffSessionData> _cubit = DataCubit(_load)..load();

  Future<_StaffSessionData> _load() async {
    final session = await _repo.byId(widget.sessionId);
    if (!session.isActive) return _StaffSessionData(session, null, null);
    try {
      return _StaffSessionData(
          session, await _repo.staffFeePreview(session.id), null);
    } catch (e) {
      return _StaffSessionData(session, null, e);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ssDetailTitle)),
      body: LoadStateView<_StaffSessionData>(
        cubit: _cubit,
        builder: (context, d) {
          final s = d.session;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EdgeRow(
                  leading: PlateTag(s.licensePlateIn, large: true),
                  trailing: StatusBadge(
                      StatusLabels.session(context.l10n, s.status))),
              const SizedBox(height: AppSpacing.lg),
              if (d.fee != null)
                AppSurface(child: FeeBreakdownView(fee: d.fee!)),
              if (d.feeError != null)
                InlineMessage(errorText(d.feeError, context.l10n)),
              const SizedBox(height: AppSpacing.md),
              AppSurface(
                child: Column(
                  children: [
                    KeyValueRow(
                        context.l10n.fieldVehicleType, s.vehicleTypeName),
                    KeyValueRow(context.l10n.ssDriver,
                        s.driverFullName ?? context.l10n.customerGuestFull),
                    KeyValueRow(
                        context.l10n.sessMode,
                        s.reservationId != null
                            ? context.l10n.sessModeBooked
                            : context.l10n.sessModeDirect),
                    KeyValueRow(context.l10n.sessEntry,
                        DateFormatter.formatDateTime(s.entryTime)),
                    KeyValueRow(context.l10n.sessEntryGate, s.entryGateName),
                    if (s.slotCode != null)
                      KeyValueRow(context.l10n.sessSpot, s.slotCode!),
                    if (s.exitTime != null)
                      KeyValueRow(context.l10n.sessExit,
                          DateFormatter.formatDateTime(s.exitTime)),
                    if (s.exitGateName != null)
                      KeyValueRow(context.l10n.sessExitGate, s.exitGateName!),
                    if (s.licensePlateOut != null &&
                        s.licensePlateOut != s.licensePlateIn)
                      KeyValueRow(context.l10n.ssPlateOut, s.licensePlateOut!),
                    if (s.paymentAmount != null)
                      KeyValueRow(context.l10n.ssPayment,
                          '${CurrencyFormatter.format(s.paymentAmount!)}, ${StatusLabels.payment(context.l10n, s.paymentStatus).label.toLowerCase()}'),
                  ],
                ),
              ),
              for (final img
                  in [s.entryImageUrl, s.exitImageUrl].whereType<String>()) ...[
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppSpacing.surface,
                  child: CachedNetworkImage(
                    imageUrl: img,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(height: 200, color: p.surfaceMuted),
                    errorWidget: (_, __, ___) => Container(
                      height: 80,
                      color: p.surfaceMuted,
                      alignment: Alignment.center,
                      child: Text(context.l10n.ssImageFailed,
                          style: AppTypography.caption
                              .copyWith(color: p.textMuted)),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
