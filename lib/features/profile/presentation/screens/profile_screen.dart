import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/widgets/push_toggle_tile.dart';
import 'package:prm393_frontend/core/config/app_config.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/services/app_lock_controller.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_state.dart';
import 'package:prm393_frontend/features/home/presentation/shell_scope.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/notifications_bottom_sheet.dart';
import 'package:prm393_frontend/features/incidents/presentation/screens/incidents_screen.dart';
import 'package:prm393_frontend/features/entry_pass/entry_pass_screen.dart';
import 'package:prm393_frontend/features/legal/legal_screen.dart';
import 'package:prm393_frontend/features/payments/payment_history_screen.dart';
import 'package:prm393_frontend/features/profile/presentation/widgets/change_email_sheet.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/screens/my_contracts_screen.dart';
import 'package:prm393_frontend/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:prm393_frontend/features/profile/presentation/widgets/delete_account_sheet.dart';
import 'package:prm393_frontend/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:prm393_frontend/features/vehicles/presentation/widgets/vehicle_picker.dart';
import 'package:prm393_frontend/features/wallet/presentation/screens/wallet_screen.dart';

/// Số liệu hoạt động của khách hàng, tổng hợp từ lượt gửi, vé tháng, đặt chỗ.
typedef _Stats = ({
  int sessionsThisMonth,
  int activePasses,
  int upcomingReservations,
  List<({VehicleModel vehicle, bool monthly})> vehicles,
});

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final AppLockController _lock = AppLockController.instance;
  late final _stats = AsyncCubit<_Stats>(_loadStats);

  @override
  void reloadAll() => _stats.load();

  @override
  void dispose() {
    _stats.close();
    super.dispose();
  }

  Future<_Stats> _loadStats() async {
    final results = await Future.wait([
      _repo.getMySessions(),
      _repo.getMySubscriptions(),
      _repo.getMyReservations(),
      _repo.getMyVehicles(),
    ]);
    final sessions = results[0] as List<ParkingSessionModel>;
    final passes = results[1] as List<MonthlySubscriptionModel>;
    final reservations = results[2] as List<ReservationModel>;
    final myVehicles = results[3] as List<VehicleModel>;
    final now = DateTime.now();

    // Xe đã đăng ký vào tài khoản; đánh dấu xe đang có vé tháng hiệu lực.
    final monthlyPlates =
        passes.where((p) => p.isActive).map((p) => p.licensePlate).toSet();
    final vehicles = [
      for (final v in myVehicles)
        (vehicle: v, monthly: monthlyPlates.contains(v.licensePlate)),
    ];

    return (
      sessionsThisMonth: sessions
          .where((s) =>
              s.entryTime.year == now.year && s.entryTime.month == now.month)
          .length,
      activePasses: passes.where((p) => p.isActive).length,
      upcomingReservations: reservations.where((r) => r.canModify).length,
      vehicles: vehicles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: pbmsTabAppBar('Cá nhân', actions: [
        PbmsHeaderAction(
          tooltip: 'Thông báo',
          icon: Icons.notifications_none_rounded,
          onPressed: () => NotificationsBottomSheet.show(context,
              onNotificationsUpdated: () {}),
        ),
      ]),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          final fullName = (user?.fullName ?? '').trim();
          final displayName =
              fullName.isNotEmpty ? fullName : (user?.userName ?? 'Khách hàng');
          final initial =
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

          return RefreshIndicator(
            color: PbmsTokens.teal,
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckRequested());
              reloadAll();
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding:
                      EdgeInsets.fromLTRB(16, 12, 16, 116 + bottomPad),
                  children: [
                    _buildProfileSummary(
                      displayName: displayName,
                      email: user?.email ?? '',
                      phone: user?.phoneNumber,
                      initial: initial,
                      avatarUrl: user?.avatarUrl,
                      onEdit: () => _showEditProfileSheet(
                          fullName, user?.phoneNumber ?? ''),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Phương tiện của bạn',
                      icon: Icons.directions_car_rounded,
                      children: [
                        PbmsAsync<_Stats>(
                          cubit: _stats,
                          loadingHeight: 72,
                          builder: (s) => s.vehicles.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Chưa có xe nào. Thêm biển số để đặt chỗ và đăng ký vé tháng.',
                                    style: PbmsText.caption,
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final v in s.vehicles) ...[
                                      _buildVehicleCard(v),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                        ),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _addVehicle,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Thêm biển số xe mới'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PbmsTokens.teal,
                              backgroundColor: PbmsTokens.tealTint,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PbmsSettingsGroup(
                      title: 'Gửi xe',
                      children: [
                        PbmsSettingsRow(
                          icon: Icons.qr_code_2_rounded,
                          title: 'Mã QR gửi xe 1 lần',
                          onTap: () => EntryPassScreen.open(context),
                        ),
                        PbmsSettingsRow(
                          icon: Icons.history_rounded,
                          title: 'Lịch sử gửi xe',
                          onTap: () => ShellScope.maybeOf(context)
                              ?.goTab(AppTab.history),
                        ),
                        PbmsSettingsRow(
                          icon: Icons.report_gmailerrorred_rounded,
                          title: 'Báo cáo sự cố',
                          onTap: () => IncidentsScreen.open(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PbmsSettingsGroup(
                      title: 'Tiền và giấy tờ',
                      children: [
                        PbmsSettingsRow(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Ví PBMS',
                          onTap: () => WalletScreen.open(context),
                        ),
                        PbmsSettingsRow(
                          icon: Icons.receipt_long_outlined,
                          title: 'Lịch sử thanh toán',
                          onTap: () => PaymentHistoryScreen.open(context),
                        ),
                        PbmsSettingsRow(
                          icon: Icons.description_outlined,
                          title: 'Hợp đồng vé tháng',
                          onTap: () => MyContractsScreen.open(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PbmsSettingsGroup(
                      title: 'Tài khoản',
                      children: [
                        PbmsSettingsRow(
                          icon: Icons.password_rounded,
                          title: 'Đổi mật khẩu',
                          onTap: () => ChangePasswordSheet.show(context),
                        ),
                        PbmsSettingsRow(
                          icon: Icons.alternate_email_rounded,
                          title: 'Đổi email',
                          onTap: () => ChangeEmailSheet.show(
                              context, context.read<AuthBloc>().state.user?.email ?? ''),
                        ),
                        _buildBiometricTile(),
                        const PushToggleTile(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Đăng xuất tài khoản'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          foregroundColor: const Color(0xFF991B1B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: () => DeleteAccountSheet.show(context),
                        style: TextButton.styleFrom(
                          foregroundColor: PbmsTokens.danger,
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Xoá tài khoản'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const LegalLinks(prefix: ''),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'PBMS, phiên bản ${AppConfig.appVersion}',
                        style: PbmsText.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSummary({
    required String displayName,
    required String email,
    required String? phone,
    required String initial,
    required String? avatarUrl,
    required VoidCallback onEdit,
  }) {
    return PbmsCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ProfileAvatar(avatarUrl: avatarUrl, initial: initial),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PbmsText.title),
                const SizedBox(height: 4),
                _buildContactLine(Icons.smartphone_rounded,
                    (phone ?? '').isEmpty ? 'Chưa có số điện thoại' : phone!),
                const SizedBox(height: 2),
                if (email.isNotEmpty)
                  _buildContactLine(Icons.email_outlined, email),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chỉnh sửa thông tin',
            onPressed: onEdit,
            style: IconButton.styleFrom(
              backgroundColor: PbmsTokens.tealTint,
              foregroundColor: PbmsTokens.teal,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContactLine(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: PbmsTokens.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PbmsText.caption),
        ),
      ],
    );
  }



  Widget _buildSectionCard({
    required String title,
    IconData? icon,
    required List<Widget> children,
  }) {
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: PbmsTokens.teal),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title, style: PbmsText.section)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildVehicleCard(({VehicleModel vehicle, bool monthly}) item) {
    final v = item.vehicle;
    return Material(
      color: PbmsTokens.surfaceLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editVehicle(v),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: PbmsTokens.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    v.isMotorbike
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded,
                    size: 24,
                    color: PbmsTokens.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.bodyStrong),
                    const SizedBox(height: 2),
                    Text(v.details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.caption),
                  ],
                ),
              ),
              if (item.monthly)
                const PbmsStatusPill(StatusInfo('Vé tháng', PbmsTokens.teal))
              else
                IconButton(
                  tooltip: 'Xoá xe ${v.licensePlate}',
                  onPressed: () => _removeVehicle(v.id, v.licensePlate),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: PbmsTokens.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editVehicle(VehicleModel vehicle) async {
    final updated = await EditVehicleSheet.show(context, vehicle);
    if (updated == null || !mounted) return;
    showPbmsSnack(context, 'Đã lưu thông tin xe ${updated.displayName}.');
    ShellScope.dataChanged(context);
    reloadAll();
  }

  Future<void> _addVehicle() async {
    final added = await AddVehicleSheet.show(context);
    if (added == null || !mounted) return;
    showPbmsSnack(context, 'Đã thêm xe ${added.licensePlate}.');
    ShellScope.dataChanged(context);
    reloadAll();
  }

  Future<void> _removeVehicle(String id, String plate) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá xe?'),
        content: Text('Xe $plate sẽ bị xoá khỏi tài khoản.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger),
            child: const Text('Xoá xe'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.removeVehicle(id);
      if (!mounted) return;
      showPbmsSnack(context, 'Đã xoá xe $plate.');
      reloadAll();
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }


  Widget _buildBiometricTile() {
    return ListenableBuilder(
      listenable: _lock,
      builder: (context, _) {
        final supported = _lock.isSupported;
        final onChanged = !supported
            ? null
            : (bool value) async {
                final ok = await _lock.setEnabled(value);
                if (!context.mounted) return;
                showPbmsSnack(
                  context,
                  ok
                      ? (value ? 'Đã bật khoá sinh trắc học.' : 'Đã tắt khoá sinh trắc học.')
                      : 'Chưa xác thực được, cài đặt giữ nguyên.',
                  error: !ok,
                );
              };
        return PbmsSettingsRow(
          icon: Icons.fingerprint_rounded,
          title: 'Khoá bằng vân tay, khuôn mặt',
          detail: supported ? null : 'Máy chưa hỗ trợ',
          onTap: onChanged == null ? null : () => onChanged(!_lock.isEnabled),
          trailing: Switch.adaptive(
            value: _lock.isEnabled,
            activeTrackColor: PbmsTokens.teal,
            onChanged: onChanged,
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(String currentName, String currentPhone) {
    PbmsSheetFrame.show<void>(
      context,
      (_) => _EditProfileSheet(name: currentName, phone: currentPhone),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
            'Phiên đăng nhập hiện tại trên thiết bị này sẽ kết thúc.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String name;
  final String phone;

  const _EditProfileSheet({required this.name, required this.phone});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await context.read<PbmsRepository>().updateProfile(
            fullName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
          );
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileUpdated(user));
      Navigator.pop(context);
      showPbmsSnack(context, 'Đã cập nhật thông tin.');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Chỉnh sửa thông tin',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Họ và tên', style: PbmsText.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: pbmsInputDecoration(),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'Nhập họ và tên' : null,
              ),
              const SizedBox(height: 14),
              const Text('Số điện thoại', style: PbmsText.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: pbmsInputDecoration(hint: 'Ví dụ: 0901234567'),
                validator: (v) => RegExp(r'^0\d{9}$').hasMatch((v ?? '').trim())
                    ? null
                    : 'Số điện thoại gồm 10 chữ số, bắt đầu bằng 0',
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 18),
        PbmsPrimaryButton(label: 'Lưu thay đổi', busy: _busy, onPressed: _save),
      ],
    );
  }
}
