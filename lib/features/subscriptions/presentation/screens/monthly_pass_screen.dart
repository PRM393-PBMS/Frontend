import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/features/home/presentation/models/vehicle_card_model.dart';
import 'package:prm393_frontend/features/map/data/models/mock_parking_lot.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MonthlyPassScreen extends StatefulWidget {
  const MonthlyPassScreen({super.key});

  @override
  State<MonthlyPassScreen> createState() => _MonthlyPassScreenState();
}

class _MonthlyPassScreenState extends State<MonthlyPassScreen> {
  static const _green = AppColors.success;
  static const _ink = AppColors.textPrimaryLight;
  static const _muted = AppColors.textSecondaryLight;
  static const _border = AppColors.borderLight;
  static const _monthlyPrice = 1800000;
  static const _quarterlyPrice = 4860000;

  final _qrCardKey = GlobalKey();
  final _plateController = TextEditingController(
    text: VehicleCardModel.mockVehicles.first.licensePlate,
  );

  int _activeTab = 0;
  bool _autoRenew = true;
  VehicleType _vehicleType = VehicleType.car;
  int _selectedPlan = 1;
  String _selectedParkingLotId = mockParkingLots.first.id;

  VehicleCardModel get _activeVehicle =>
      VehicleCardModel.mockVehicles.firstWhere(
        (vehicle) => vehicle.isMonthlyActive,
      );

  int get _selectedPrice =>
      _selectedPlan == 1 ? _monthlyPrice : _quarterlyPrice;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
        ),
      );
  }

  Future<void> _scrollToQr() async {
    final targetContext = _qrCardKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    }
    if (mounted) {
      _showMessage('Mã QR này là dữ liệu mẫu, chưa dùng tại barrier.');
    }
  }

  void _selectVehicleType(VehicleType type) {
    setState(() {
      _vehicleType = type;
      final vehicle = VehicleCardModel.mockVehicles.firstWhere(
        (item) => item.type == type,
      );
      _plateController.text = vehicle.licensePlate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 31,
              height: 31,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Quản lý vé tháng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => _showMessage('Bạn đã xem các thông báo mới nhất.'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Trợ giúp',
            onPressed: () =>
                _showMessage('Kênh hỗ trợ vé tháng đang được cập nhật.'),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 116 + bottomInset),
              children: [
                _buildTabs(),
                const SizedBox(height: 16),
                if (_activeTab == 0) ...[
                  _buildActivePass(),
                  const SizedBox(height: 14),
                  _buildQrCard(),
                  const SizedBox(height: 14),
                  _buildPassInfo(),
                  const SizedBox(height: 14),
                  _buildActiveAction(),
                ] else
                  _buildRegistrationForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PassTab(
              label: 'Vé của tôi',
              icon: Icons.verified_rounded,
              selected: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
          ),
          Expanded(
            child: _PassTab(
              label: 'Đăng ký mới',
              icon: Icons.add_circle_outline_rounded,
              selected: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePass() {
    final vehicle = _activeVehicle;
    final expiryDate = _parseExpiryDate(vehicle.expiryDate);
    final remainingDays =
        expiryDate.difference(DateTime.now()).inDays.clamp(0, 999);
    final periodStart = DateTime(expiryDate.year, expiryDate.month, 1);
    final progress = (remainingDays / 60).clamp(0.0, 1.0);

    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VÉ GỬI XE CỐ ĐỊNH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.ticketType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle.parkingSlot,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _PassStatusBadge(),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              border: Border.all(color: const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    vehicle.type == VehicleType.car
                        ? Icons.directions_car_rounded
                        : Icons.two_wheeler_rounded,
                    size: 20,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Biển kiểm soát',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textMutedLight)),
                      Text(
                        vehicle.licensePlate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Dòng xe',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textMutedLight)),
                      Text(
                        vehicle.vehicleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 15, color: AppColors.textMutedLight),
              const SizedBox(width: 5),
              const Text('Thời hạn còn lại: ',
                  style: TextStyle(fontSize: 11, color: _muted)),
              Text('$remainingDays ngày',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
              const Spacer(),
              Text(
                '${_formatShortDate(periodStart)} - ${_formatShortDate(expiryDate)}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 7,
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: const ColoredBox(color: AppColors.success),
              ),
            ),
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.autorenew_rounded,
                  size: 18, color: AppColors.textSecondaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tự động gia hạn',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight)),
                    Text(
                      '${CurrencyFormatter.format(_monthlyPrice)} / tháng · Gia hạn ${_formatShortDate(expiryDate.add(const Duration(days: 1)))}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMutedLight),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _autoRenew,
                onChanged: (value) {
                  setState(() => _autoRenew = value);
                  _showMessage(value
                      ? 'Đã bật tự động gia hạn (bản xem trước).'
                      : 'Đã tắt tự động gia hạn.');
                },
                activeTrackColor: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    final vehicle = _activeVehicle;

    return _SurfaceCard(
      key: _qrCardKey,
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.contactless_rounded, size: 19, color: _green),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'MỞ CỔNG TỰ ĐỘNG',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimaryLight),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('MÃ MẪU',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          const Text(
            'Mã QR minh họa cho vé tháng',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(17),
            ),
            child: QrImageView(
              data: vehicle.nfcTagId,
              version: QrVersions.auto,
              size: 176,
              eyeStyle: const QrEyeStyle(color: AppColors.textPrimaryLight),
              dataModuleStyle:
                  const QrDataModuleStyle(color: AppColors.textPrimaryLight),
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9)),
            child: Text(
              vehicle.nfcTagId,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimaryLight),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showMessage('Chia sẻ vé chưa được kết nối.'),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Chia sẻ vé'),
                  style: _utilityButtonStyle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showMessage('Nhật ký vào/ra chưa được kết nối.'),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Lịch sử vào ra'),
                  style: _utilityButtonStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassInfo() {
    final vehicle = _activeVehicle;
    return _SurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_parking_rounded,
                  size: 18, color: AppColors.textMutedLight),
              const SizedBox(width: 7),
              const Expanded(
                  child: Text('Thông tin vé',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink))),
              TextButton(
                onPressed: () =>
                    _showMessage('Bản đồ vé tháng chưa được kết nối.'),
                child: const Text('Xem vị trí',
                    style: TextStyle(fontSize: 11, color: AppColors.success)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(vehicle.parkingSlot,
                style: const TextStyle(fontSize: 11, color: _muted)),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              const Expanded(
                  child: Text('Gói vé',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondaryLight))),
              Text(vehicle.ticketType,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: _ink)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                  child: Text('Mã phương tiện',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondaryLight))),
              Text(vehicle.id,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: _ink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAction() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _scrollToQr,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
            label: const Text('Quét mã mở barrier',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dữ liệu vé mẫu, chưa dùng để ra vào bãi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.textMutedLight),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Đăng ký vé tháng mới',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 4),
          const Text('Chọn bãi, phương tiện và kỳ hạn vé',
              style: TextStyle(fontSize: 11, color: _muted)),
          const SizedBox(height: 17),
          const _FieldLabel('Điểm đỗ'),
          DropdownButtonFormField<String>(
            initialValue: _selectedParkingLotId,
            isExpanded: true,
            decoration: _formDecoration(),
            items: mockParkingLots
                .map((lot) => DropdownMenuItem(
                      value: lot.id,
                      child: Text(lot.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) => setState(() =>
                _selectedParkingLotId = value ?? mockParkingLots.first.id),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Loại phương tiện'),
          SegmentedButton<VehicleType>(
            segments: const [
              ButtonSegment(
                  value: VehicleType.car,
                  label: Text('Ô tô'),
                  icon: Icon(Icons.directions_car_rounded)),
              ButtonSegment(
                  value: VehicleType.motorcycle,
                  label: Text('Xe máy'),
                  icon: Icon(Icons.two_wheeler_rounded)),
            ],
            selected: {_vehicleType},
            onSelectionChanged: (selection) =>
                _selectVehicleType(selection.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? AppColors.success
                      : AppColors.textSecondaryLight),
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Colors.white),
              side: WidgetStateProperty.resolveWith((states) => BorderSide(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.success
                      : AppColors.borderLight)),
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Biển kiểm soát'),
          Semantics(
            label: 'Biển kiểm soát',
            child: TextField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 .-]'))
              ],
              decoration: _formDecoration(hint: 'Ví dụ: 51H - 999.88'),
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Kỳ hạn cước'),
          _PlanOption(
            selected: _selectedPlan == 1,
            title: '1 tháng',
            subtitle: 'Linh hoạt theo tháng',
            price: CurrencyFormatter.format(_monthlyPrice),
            onTap: () => setState(() => _selectedPlan = 1),
          ),
          const SizedBox(height: 8),
          _PlanOption(
            selected: _selectedPlan == 3,
            title: '3 tháng',
            subtitle: 'Giá tham khảo, có thể tiết kiệm',
            price: CurrencyFormatter.format(_quarterlyPrice),
            onTap: () => setState(() => _selectedPlan = 3),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(11)),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Tổng tiền tham khảo',
                        style: TextStyle(fontSize: 11, color: _muted))),
                Text(CurrencyFormatter.format(_selectedPrice),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 49,
            child: FilledButton.icon(
              onPressed: () => _showMessage(
                  'Đăng ký và thanh toán vé tháng chưa được kết nối.'),
              icon: const Icon(Icons.credit_card_rounded, size: 19),
              label: const Text('Thanh toán & kích hoạt',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseExpiryDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return DateTime.now().add(const Duration(days: 30));
    return DateTime(
      int.tryParse(parts[2]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? DateTime.now().month,
      int.tryParse(parts[0]) ?? DateTime.now().day,
    );
  }

  String _formatShortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  static InputDecoration _formDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _green, width: 1.5)),
    );
  }

  static const _utilityButtonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
    foregroundColor: WidgetStatePropertyAll(AppColors.textSecondaryLight),
    backgroundColor: WidgetStatePropertyAll(Colors.white),
    side: WidgetStatePropertyAll(BorderSide(color: AppColors.borderLight)),
    textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(11)))),
  );
}

class _PassTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PassTab(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: selected ? Colors.white : Colors.transparent,
          foregroundColor: selected
              ? AppColors.textPrimaryLight
              : AppColors.textSecondaryLight,
          elevation: selected ? 1 : 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PassStatusBadge extends StatelessWidget {
  const _PassStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: AppColors.success),
          SizedBox(width: 5),
          Text('Kích hoạt',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success)),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x070F172A), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: child,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight)),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  const _PlanOption(
      {required this.selected,
      required this.title,
      required this.subtitle,
      required this.price,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final outline = selected ? AppColors.success : AppColors.borderLight;
    return Material(
      color: selected
          ? AppColors.success.withValues(alpha: 0.06)
          : AppColors.bgLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
              border: Border.all(color: outline),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 19,
                  color:
                      selected ? AppColors.success : AppColors.textMutedLight),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(price,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight)),
            ],
          ),
        ),
      ),
    );
  }
}
