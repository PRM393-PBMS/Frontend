import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/services/vehicle_storage_service.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/home/data/repositories/parking_repository.dart';
import '../models/vehicle_card_model.dart';

/// Modal đăng ký phương tiện mới vào hệ thống PBMS & Ví kỹ thuật số
class AddVehicleBottomSheet extends StatefulWidget {
  final ValueChanged<VehicleCardModel>? onVehicleRegistered;

  const AddVehicleBottomSheet({
    super.key,
    this.onVehicleRegistered,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<VehicleCardModel>? onVehicleRegistered,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddVehicleBottomSheet(
        onVehicleRegistered: onVehicleRegistered,
      ),
    );
  }

  @override
  State<AddVehicleBottomSheet> createState() => _AddVehicleBottomSheetState();
}

class _AddVehicleBottomSheetState extends State<AddVehicleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _phoneController = TextEditingController();

  VehicleType _selectedType = VehicleType.car;
  int _selectedTicketIndex = 0;
  int _selectedColorIndex = 0;
  bool _isSubmitting = false;

  // Thời gian hiệu lực & chu kỳ thanh toán
  DateTime _startDate = DateTime.now();
  int _billingCycleMonths = 1; // 1, 3, 6 tháng

  final List<String> _ticketTypes = [
    'Vé tháng Cư dân VIP',
    'Vé tháng Tiêu chuẩn',
    'Vé lượt Thông minh',
  ];

  final List<Map<String, dynamic>> _colorThemes = [
    {
      'name': 'Emerald Green',
      'brand': 'EMERALD',
      'gradients': [Color(0xFF033320), Color(0xFF06482F), Color(0xFF0A5E3E)],
      'accent': Color(0xFF84CC16),
    },
    {
      'name': 'Midnight Obsidian',
      'brand': 'OBSIDIAN',
      'gradients': [Color(0xFF111318), Color(0xFF1E222B), Color(0xFF2C323F)],
      'accent': Color(0xFF94A3B8),
    },
    {
      'name': 'Sapphire Azure',
      'brand': 'SAPPHIRE',
      'gradients': [Color(0xFF0A1B3F), Color(0xFF123473), Color(0xFF1A4FA8)],
      'accent': Color(0xFF93C5FD),
    },
    {
      'name': 'Burgundy Velvet',
      'brand': 'BURGUNDY',
      'gradients': [Color(0xFF3B0D1C), Color(0xFF5C142C), Color(0xFF831C3E)],
      'accent': Color(0xFFF472B6),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Tự động điền số điện thoại từ tài khoản đã đăng nhập
    final authState = context.read<AuthBloc>().state;
    if (authState.user?.phoneNumber != null && authState.user!.phoneNumber!.isNotEmpty) {
      _phoneController.text = authState.user!.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isMonthlyTicket => _selectedTicketIndex < 2;

  DateTime get _endDate {
    return DateTime(_startDate.year, _startDate.month + _billingCycleMonths, _startDate.day);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  double _calculatePrice() {
    if (!_isMonthlyTicket) return 0.0;
    final isCar = _selectedType == VehicleType.car;
    final isVip = _selectedTicketIndex == 0;

    double monthlyRate = isCar ? (isVip ? 1800000.0 : 1200000.0) : (isVip ? 180000.0 : 120000.0);

    // Áp dụng giảm giá chu kỳ dài
    if (_billingCycleMonths == 3) {
      return monthlyRate * 3 * 0.95; // Giảm 5%
    } else if (_billingCycleMonths == 6) {
      return monthlyRate * 6 * 0.90; // Giảm 10%
    }
    return monthlyRate * _billingCycleMonths;
  }

  String? _validateLicensePlate(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Vui lòng nhập biển kiểm soát';
    }
    final clean = val.replaceAll(RegExp(r'[\s\.\-]'), '').toUpperCase();
    if (_selectedType == VehicleType.car) {
      // Chuẩn biển ô tô VN: 2 số tỉnh + 1-2 chữ cái + 4-5 số (VD: 30A99999, 51LD12345)
      final carRegex = RegExp(r'^[0-9]{2}[A-Z]{1,2}[0-9]{4,5}$');
      if (!carRegex.hasMatch(clean)) {
        return 'Biển số ô tô không đúng định dạng (VD: 30A-999.99 hoặc 51LD-123.45)';
      }
    } else {
      // Chuẩn biển xe máy VN: 2 số tỉnh + 1 chữ cái + 1 số/chữ cái + 4-5 số (VD: 29B112345)
      final motoRegex = RegExp(r'^[0-9]{2}[A-Z0-9]{2}[0-9]{4,5}$');
      if (!motoRegex.hasMatch(clean)) {
        return 'Biển số xe máy không đúng định dạng (VD: 29B1-123.45 hoặc 59P2-987.65)';
      }
    }
    return null;
  }

  String? _validatePhoneNumber(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại liên hệ khẩn cấp';
    }
    final clean = val.replaceAll(RegExp(r'[\s\.\-]'), '');
    final phoneRegex = RegExp(r'^(03|05|07|08|09)\d{8}$');
    if (!phoneRegex.hasMatch(clean)) {
      return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 03, 05, 07, 08, 09)';
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(now) ? now : _startDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY BẮT ĐẦU HIỆU LỰC GÓI',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: AppTypography.titleMedium)),
          ],
        ),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF090D14),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;
      final repo = context.read<ParkingRepository>();

      final rawPlate = _plateController.text.trim().toUpperCase();
      final cleanPlate = rawPlate.replaceAll(RegExp(r'[\s\.\-]'), '').toUpperCase();
      final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[\s\.\-]'), '');
      final isCar = _selectedType == VehicleType.car;
      final modelName = _modelNameController.text.trim().isNotEmpty
          ? _modelNameController.text.trim()
          : (isCar ? 'Ô tô cá nhân' : 'Xe máy cá nhân');

      final theme = _colorThemes[_selectedColorIndex];
      final ticketType = _ticketTypes[_selectedTicketIndex];
      final isMonthly = _isMonthlyTicket;
      final formattedExpiry = _formatDate(_endDate);
      final formattedStart = _formatDate(_startDate);
      final price = _calculatePrice();

      // =======================================================================
      // 1. DUPLICATE CHECK: KIỂM TRA TRÙNG LẶP BIỂN SỐ XE
      // =======================================================================
      final existingLocal = await VehicleStorageService.instance.getVehicles(userId: userId);
      final isDuplicate = existingLocal.any((v) =>
          v.licensePlate.replaceAll(RegExp(r'[\s\.\-]'), '').toUpperCase() == cleanPlate &&
          (v.paymentStatus == 'Active' || v.isMonthlyActive));

      if (isDuplicate) {
        setState(() => _isSubmitting = false);
        _showErrorDialog(
          title: 'Biển số đã đăng ký',
          message: 'Biển số [$cleanPlate] đã được đăng ký và đang ở trạng thái kích hoạt trên hệ thống. Vui lòng liên hệ BQL/Hỗ trợ nếu có sự nhầm lẫn.',
        );
        return;
      }

      // =======================================================================
      // 2. CAPACITY CHECK: KIỂM TRA SỨC CHỨA CỦA BÃI XE DÀNH CHO Ô TÔ VÉ THÁNG
      // =======================================================================
      if (isCar && isMonthly) {
        try {
          final avail = await repo.getFacilityAvailability();
          int carAvailableSlots = 0;
          for (final f in avail) {
            final type = f.vehicleTypeName.toLowerCase();
            final floor = f.floorName.toLowerCase();
            if (type.contains('car') || type.contains('ô tô') || floor.contains('b1')) {
              carAvailableSlots += f.availableSlots;
            }
          }

          if (avail.isNotEmpty && carAvailableSlots <= 0) {
            setState(() => _isSubmitting = false);
            _showErrorDialog(
              title: 'Hết chỗ đỗ ô tô vé tháng',
              message: 'Hiện bãi xe đã hết chỗ dành cho ô tô vé tháng. Quý khách vui lòng chọn Vé lượt hoặc liên hệ Ban Quản Lý.',
            );
            return;
          }
        } catch (_) {
          // Bỏ qua lỗi mạng nếu đang chạy offline
        }
      }

      final now = DateTime.now();
      final slotCode = isCar
          ? 'Tầng Hầm B1 • Ô C-${(now.millisecond % 50) + 1}'
          : 'Khu vực xe máy B2';

      // =======================================================================
      // 3. TẠO PHƯƠNG TIỆN VỚI TRẠNG THÁI BAN ĐẦU: PENDING_PAYMENT
      // =======================================================================
      final newVehicle = VehicleCardModel(
        id: 'veh_${now.millisecondsSinceEpoch}',
        licensePlate: rawPlate,
        vehicleName: modelName,
        type: _selectedType,
        ticketType: ticketType,
        expiryDate: isMonthly ? formattedExpiry : 'Không thời hạn',
        daysLeft: isMonthly ? (_billingCycleMonths * 30) : 999,
        parkingSlot: slotCode,
        gradientColors: (theme['gradients'] as List<Color>),
        accentColor: theme['accent'] as Color,
        brand: theme['brand'] as String,
        isMonthlyActive: !isMonthly, // Vé lượt kích hoạt ngay, Vé tháng chờ thanh toán
        nfcTagId: 'PBMS-NFC-$cleanPlate',
        phoneNumber: cleanPhone,
        startDate: formattedStart,
        billingMonths: _billingCycleMonths,
        paymentStatus: isMonthly ? 'PendingPayment' : 'Active',
        price: price,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Lưu phương tiện vào bộ nhớ cục bộ (trạng thái Active nếu là vé lượt, PendingPayment nếu là vé tháng)
      await VehicleStorageService.instance.saveVehicle(newVehicle, userId: userId);

      // Đóng form đăng ký trước để tránh xung đột hai BottomSheet lồng nhau
      if (mounted) {
        Navigator.pop(context);
      }

      // Thông báo cho HomeScreen cập nhật danh sách thẻ & kích hoạt quy trình thanh toán nếu cần
      widget.onVehicleRegistered?.call(newVehicle);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorDialog(
          title: 'Lỗi đăng ký',
          message: 'Đã xảy ra sự cố khi đăng ký: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final calculatedPrice = _calculatePrice();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: context.space(16)),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.app_registration_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: context.space(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đăng ký phương tiện PBMS',
                          style: AppTypography.titleLarge.copyWith(fontSize: 17.5),
                        ),
                        Text(
                          'Thêm biển số vào cơ sở dữ liệu nhận diện barrier tự động',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Phân loại xe (Ô tô / Xe máy)
              Text(
                '1. LOẠI PHƯƠNG TIỆN',
                style: AppTypography.badgeMono.copyWith(fontSize: 10.5),
              ),
              SizedBox(height: context.space(8)),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeSelector(
                      label: 'Ô tô',
                      icon: Icons.directions_car_rounded,
                      isSelected: _selectedType == VehicleType.car,
                      onTap: () => setState(() => _selectedType = VehicleType.car),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: context.space(10)),
                  Expanded(
                    child: _buildTypeSelector(
                      label: 'Xe máy',
                      icon: Icons.two_wheeler_rounded,
                      isSelected: _selectedType == VehicleType.motorcycle,
                      onTap: () => setState(() => _selectedType = VehicleType.motorcycle),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.space(16)),

              // 2. Biển số xe & Tên dòng xe
              Text(
                '2. BIỂN KIỂM SOÁT (BIỂN SỐ THỰC TẾ)',
                style: AppTypography.badgeMono.copyWith(fontSize: 10.5),
              ),
              SizedBox(height: context.space(6)),
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                style: AppTypography.licensePlateMono.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: _selectedType == VehicleType.car
                      ? 'VD: 30A - 999.99 hoặc 51LD - 123.45'
                      : 'VD: 29B1 - 888.88 hoặc 59P2 - 123.45',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                ),
                validator: _validateLicensePlate,
              ),
              SizedBox(height: context.space(14)),

              // Dòng xe / Model
              Text(
                'DÒNG XE / THƯƠNG HIỆU',
                style: AppTypography.badgeMono.copyWith(fontSize: 10.5),
              ),
              SizedBox(height: context.space(6)),
              TextFormField(
                controller: _modelNameController,
                decoration: InputDecoration(
                  hintText: _selectedType == VehicleType.car
                      ? 'VD: VinFast VF 8 / Mercedes C300 / Toyota Cross'
                      : 'VD: Honda SH 150i / Vespa GTS / Yamaha NVX',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                ),
              ),
              SizedBox(height: context.space(16)),

              // 3. Số điện thoại liên hệ khẩn cấp (Bắt buộc)
              Row(
                children: [
                  Text(
                    '3. SĐT LIÊN HỆ KHẨN CẤP (BẮT BUỘC)',
                    style: AppTypography.badgeMono.copyWith(fontSize: 10.5),
                  ),
                  const SizedBox(width: 4),
                  const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: context.space(6)),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'VD: 0912345678 (Dùng khi xe gặp sự cố trong bãi)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                  helperText: 'Mặc định từ tài khoản, cho phép điều chỉnh',
                  helperStyle: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                validator: _validatePhoneNumber,
              ),
              SizedBox(height: context.space(16)),

              // 4. Hình thức vé
              Text(
                '4. HÌNH THỨC VÉ',
                style: AppTypography.badgeMono.copyWith(fontSize: 10.5),
              ),
              SizedBox(height: context.space(6)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_ticketTypes.length, (index) {
                  final isSelected = _selectedTicketIndex == index;
                  return ChoiceChip(
                    label: Text(_ticketTypes[index]),
                    selected: isSelected,
                    selectedColor: isDark ? AppColors.primary : const Color(0xFF090D14),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark ? const Color(0xFF090D14) : Colors.white)
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedTicketIndex = index),
                  );
                }),
              ),
              SizedBox(height: context.space(16)),

              // 5. Nếu là Vé tháng: Chọn Ngày bắt đầu & Chu kỳ thanh toán (Bắt buộc)
              if (_isMonthlyTicket) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderSubtleDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THỜI GIAN HIỆU LỰC & CHU KỲ THANH TOÁN',
                        style: AppTypography.badgeMono.copyWith(
                          fontSize: 10.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chọn ngày bắt đầu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ngày bắt đầu hiệu lực:',
                                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(_startDate),
                                style: AppTypography.telemetryMono.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickStartDate,
                            icon: const Icon(Icons.calendar_today_rounded, size: 14),
                            label: const Text('Chọn ngày', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Chu kỳ thanh toán (1, 3, 6 tháng)
                      Text(
                        'Chu kỳ thanh toán:',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildCycleChip(1, '1 Tháng', 'Giá chuẩn', isDark),
                          const SizedBox(width: 8),
                          _buildCycleChip(3, '3 Tháng', 'Giảm 5%', isDark),
                          const SizedBox(width: 8),
                          _buildCycleChip(6, '6 Tháng', 'Giảm 10%', isDark),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Hiển thị ngày kết thúc & tổng chi phí
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hết hạn: ${_formatDate(_endDate)}',
                            style: AppTypography.badgeMono.copyWith(fontSize: 11),
                          ),
                          Text(
                            CurrencyFormatter.format(calculatedPrice),
                            style: AppTypography.telemetryMono.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.space(16)),
              ],

              // 6. Màu sắc hiển thị thẻ ví
              Text(
                'PHONG CÁCH THẺ VÍ KỸ THUẬT SỐ',
                style: AppTypography.badgeMono.copyWith(fontSize: 10.5),
              ),
              SizedBox(height: context.space(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_colorThemes.length, (index) {
                  final theme = _colorThemes[index];
                  final isSelected = _selectedColorIndex == index;
                  final gradients = theme['gradients'] as List<Color>;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      width: 52,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradients,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            )
                          : null,
                    ),
                  );
                }),
              ),
              SizedBox(height: context.space(24)),

              // Nút xác nhận đăng ký phương tiện
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRegistration,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _isMonthlyTicket ? Icons.payment_rounded : Icons.save_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _isSubmitting
                        ? 'Đang kiểm tra hệ thống...'
                        : (_isMonthlyTicket
                            ? 'Xác nhận & Tiến hành thanh toán'
                            : 'Xác nhận đăng ký phương tiện'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.primary : const Color(0xFF090D14),
                    foregroundColor: isDark ? const Color(0xFF090D14) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCycleChip(int months, String label, String discount, bool isDark) {
    final isSelected = _billingCycleMonths == months;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _billingCycleMonths = months),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary : const Color(0xFF090D14))
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.primary : const Color(0xFF090D14))
                  : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (isDark ? const Color(0xFF090D14) : Colors.white)
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                discount,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected
                      ? (isDark ? const Color(0xFF090D14) : Colors.white)
                      : (months > 1 ? AppColors.available : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFEFF6FF))
              : (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.primary : const Color(0xFF0284C7))
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
