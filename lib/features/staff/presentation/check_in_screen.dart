import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/titanium_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/ticket_qr.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../sessions/data/session_repository.dart';
import 'gate_selector.dart';

/// Nhân viên cổng vào: check-in khách vãng lai, vé tháng hoặc đặt trước.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _reservationCode = TextEditingController();
  late final SessionRepository _repo = context.read<SessionRepository>();

  GateItem? _gate;
  CustomerType _type = CustomerType.guest;
  List<VehicleTypeItem> _vehicleTypes = const [];
  VehicleTypeItem? _vehicleType;
  String? _entryImageUrl;
  String? _plateHint;
  bool _recognizing = false;
  bool _scanning = false;
  bool _submitting = false;
  String? _error;
  ParkingSession? _result;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    context.read<CatalogRepository>().vehicleTypes().then((types) {
      if (mounted) setState(() => _vehicleTypes = types);
    }).catchError((Object e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    });
  }

  @override
  void dispose() {
    _plate.dispose();
    _reservationCode.dispose();
    super.dispose();
  }

  Future<void> _recognize() async {
    final file =
        await ImageCapture.pick(context, title: context.l10n.ciPlatePhoto);
    if (file == null) return;
    setState(() {
      _recognizing = true;
      _plateHint = null;
    });
    try {
      final r = await _repo.recognizePlate(file);
      if (!mounted) return;
      setState(() {
        _entryImageUrl = r.imageUrl;
        if (r.licensePlate != null) {
          _plate.text = r.licensePlate!;
          _plateHint = r.confidence != null
              ? context.l10n
                  .ciRecognizedPct((r.confidence! * 100).toStringAsFixed(0))
              : context.l10n.ciRecognized;
        } else {
          _plateHint = r.message ?? context.l10n.ciNotRecognized;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _plateHint = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  Future<void> _scanReservation() async {
    final file =
        await ImageCapture.pick(context, title: context.l10n.ciQrPhoto);
    if (file == null) return;
    setState(() => _scanning = true);
    try {
      final r = await _repo.decodeQrImage(file);
      if (!mounted) return;
      if (r.reservationId == null) {
        setState(() => _error = context.l10n.ciNotBookingQr);
      } else {
        setState(() {
          _reservationCode.text = r.reservationId!;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _submit() async {
    final gate = _gate;
    if (gate == null) {
      setState(() => _error = context.l10n.ciPickGate);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_type == CustomerType.guest && _vehicleType == null) {
      setState(() => _error = context.l10n.ciPickType);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? reservationId;
      if (_type == CustomerType.reservation) {
        final resolved = await _repo.resolveQrPayload(_reservationCode.text);
        reservationId = resolved.reservationId;
        if (reservationId == null) {
          if (mounted) setState(() => _error = context.l10n.ciNotBookingQr);
          return;
        }
      }
      final session = await _repo.checkIn(
        customerType: _type,
        gateId: gate.id,
        licensePlate: Validators.normalizePlate(_plate.text),
        vehicleTypeId: _type == CustomerType.guest ? _vehicleType!.id : null,
        reservationId: reservationId,
        entryImageUrl: _entryImageUrl,
      );
      if (!mounted) return;
      setState(() {
        _result = session;
        _resultMessage = context.l10n.ciSuccess(_typeLabel(_type));
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _typeLabel(CustomerType type) => switch (type) {
        CustomerType.guest => context.l10n.customerGuestFull,
        CustomerType.resident => context.l10n.customerResidentFull,
        CustomerType.reservation => context.l10n.customerReservationFull,
      };

  void _reset() {
    setState(() {
      _result = null;
      _plate.clear();
      _reservationCode.clear();
      _entryImageUrl = null;
      _plateHint = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ciTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.sm, AppSpacing.page, 120),
        children: [
          ContentWidth(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _result != null
                  ? _CheckInResult(
                      key: ValueKey(_result!.id),
                      session: _result!,
                      message: _resultMessage ?? '',
                      onNext: _reset,
                    )
                  : _buildForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final p = context.palette;
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GateSelector(entry: true, onChanged: (g) => _gate = g),
          const SizedBox(height: AppSpacing.xl),
          SegmentedButton<CustomerType>(
            showSelectedIcon: false,
            segments: [
              for (final t in CustomerType.values)
                ButtonSegment(
                  value: t,
                  label: Text(switch (t) {
                    CustomerType.guest => context.l10n.customerGuest,
                    CustomerType.resident => context.l10n.customerResident,
                    CustomerType.reservation =>
                      context.l10n.customerReservation,
                  }),
                ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: context.l10n.fieldPlate,
            controller: _plate,
            hint: '51H12345',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [PlateInputFormatter()],
            validator: (v) => Validators.plate(context.l10n, v),
            style:
                AppTypography.mono.copyWith(fontSize: 20, color: p.textPrimary),
            suffix: IconButton(
              tooltip: context.l10n.ciScanPlate,
              onPressed: _recognizing ? null : _recognize,
              icon: _recognizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.document_scanner_outlined, color: p.accent),
            ),
          ),
          if (_plateHint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_plateHint!,
                style: AppTypography.caption.copyWith(color: p.textSecondary)),
          ],
          if (_type == CustomerType.guest) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(context.l10n.fieldVehicleType,
                style:
                    AppTypography.labelSmall.copyWith(color: p.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in _vehicleTypes)
                  ChoiceChip(
                    label: Text(t.name),
                    selected: _vehicleType?.id == t.id,
                    onSelected: (_) => setState(() => _vehicleType = t),
                  ),
              ],
            ),
          ],
          if (_type == CustomerType.reservation) ...[
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: context.l10n.ciBookingCode,
              controller: _reservationCode,
              hint: context.l10n.ciBookingHint,
              validator: (v) => Validators.required(
                  context.l10n, v, context.l10n.ciBookingField),
              style: AppTypography.mono
                  .copyWith(fontSize: 13, color: p.textPrimary),
              suffix: IconButton(
                tooltip: context.l10n.ciScanQr,
                onPressed: _scanning ? null : _scanReservation,
                icon: _scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.qr_code_scanner_rounded, color: p.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.ciBookingWindow,
                style: AppTypography.caption.copyWith(color: p.textSecondary)),
          ],
          if (_type == CustomerType.resident) ...[
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.ciResidentNote,
                style: AppTypography.caption.copyWith(color: p.textSecondary)),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            InlineMessage(_error!),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: context.l10n.ciSubmit,
            icon: Icons.login_rounded,
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _CheckInResult extends StatelessWidget {
  final ParkingSession session;
  final String message;
  final VoidCallback onNext;

  const _CheckInResult(
      {super.key,
      required this.session,
      required this.message,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    // Thẻ kết quả nằm trên nền titanium nên dùng bảng màu tối.
    const p = AppPalette.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InlineMessage(message, isError: false),
        const SizedBox(height: AppSpacing.lg),
        TitaniumCard(
          child: Column(
            children: [
              PlateTag(session.licensePlateIn, large: true),
              const SizedBox(height: AppSpacing.md),
              Text(
                session.slotCode != null
                    ? context.l10n.ciGuideToSlot(session.slotCode!)
                    : context.l10n.ciEntered,
                style: AppTypography.title.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  context.l10n.ciEnteredAt(session.vehicleTypeName,
                      DateFormatter.formatTime(session.entryTime)),
                  style:
                      AppTypography.bodySmall.copyWith(color: p.textSecondary)),
              if (session.ticket != null) ...[
                const SizedBox(height: AppSpacing.xl),
                TicketQr(
                  payload: session.ticket!.qrPayload,
                  caption: context.l10n.ciTicketNote,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
            label: context.l10n.ciNext,
            icon: Icons.add_rounded,
            onPressed: onNext),
      ],
    );
  }
}
