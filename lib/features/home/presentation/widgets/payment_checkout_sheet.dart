import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/vehicle_card_model.dart';

enum PaymentMethodOption { vietQr, pbmsWallet, payOsMomo }

class PaymentCheckoutBottomSheet extends StatefulWidget {
  final VehicleCardModel vehicle;
  final ValueChanged<VehicleCardModel> onPaymentSuccess;
  final ValueChanged<VehicleCardModel> onPaymentPending;

  const PaymentCheckoutBottomSheet({
    super.key,
    required this.vehicle,
    required this.onPaymentSuccess,
    required this.onPaymentPending,
  });

  static Future<void> show(
    BuildContext context, {
    required VehicleCardModel vehicle,
    required ValueChanged<VehicleCardModel> onPaymentSuccess,
    required ValueChanged<VehicleCardModel> onPaymentPending,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentCheckoutBottomSheet(
        vehicle: vehicle,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentPending: onPaymentPending,
      ),
    );
  }

  @override
  State<PaymentCheckoutBottomSheet> createState() => _PaymentCheckoutBottomSheetState();
}

class _PaymentCheckoutBottomSheetState extends State<PaymentCheckoutBottomSheet> {
  PaymentMethodOption _selectedMethod = PaymentMethodOption.vietQr;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final v = widget.vehicle;
    final totalAmount = v.price ?? (v.type == VehicleType.car ? 1200000.0 : 120000.0);
    final cleanPlate = v.licensePlate.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final transferContent = 'PBMS VE $cleanPlate';

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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pull bar
            Center(
              child: Container(
                width: 40,
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
                    Icons.account_balance_wallet_rounded,
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
                        'Thanh toán đăng ký vé xe',
                        style: AppTypography.titleLarge.copyWith(fontSize: 17),
                      ),
                      Text(
                        'Kích hoạt thẻ vé điện tử & cấp quyền mở barrier tự động',
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

            // Order Summary Card
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
                children: [
                  _buildSummaryRow(
                    'Biển kiểm soát',
                    v.licensePlate,
                    isHighlight: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Dòng xe & Phân loại',
                    '${v.vehicleName} (${v.type == VehicleType.car ? "Ô tô" : "Xe máy"})',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Gói dịch vụ',
                    '${v.ticketType} (${v.billingMonths} tháng)',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Thời gian hiệu lực',
                    '${v.startDate ?? "Hôm nay"} ➔ ${v.expiryDate}',
                    isDark: isDark,
                  ),
                  if (v.phoneNumber != null && v.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'SĐT khẩn cấp',
                      v.phoneNumber!,
                      isDark: isDark,
                    ),
                  ],
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TỔNG TIỀN THANH TOÁN',
                        style: AppTypography.badgeMono.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(totalAmount),
                        style: AppTypography.telemetryMono.copyWith(
                          fontSize: 18,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.space(18)),

            // Payment Methods Selection
            Text(
              'PHƯƠNG THỨC THANH TOÁN',
              style: AppTypography.badgeMono.copyWith(fontSize: 10.5),
            ),
            SizedBox(height: context.space(10)),

            // 1. Chuyển khoản VietQR
            _buildMethodOption(
              option: PaymentMethodOption.vietQr,
              title: 'Chuyển khoản QR Napas 24/7 (VietQR)',
              subtitle: 'Quét mã từ mọi app ngân hàng, miễn phí giao dịch',
              icon: Icons.qr_code_2_rounded,
              isDark: isDark,
            ),
            SizedBox(height: context.space(8)),

            // 2. Ví điện tử PBMS
            _buildMethodOption(
              option: PaymentMethodOption.pbmsWallet,
              title: 'Ví điện tử PBMS (Trừ số dư)',
              subtitle: 'Số dư khả dụng: 5.250.000 đ • Trừ tiền ngay lập tức',
              icon: Icons.wallet_rounded,
              isDark: isDark,
            ),
            SizedBox(height: context.space(8)),

            // 3. Cổng PayOS / VNPay / MoMo
            _buildMethodOption(
              option: PaymentMethodOption.payOsMomo,
              title: 'Cổng thanh toán PayOS / VNPay / MoMo',
              subtitle: 'Thẻ ATM nội địa, Thẻ quốc tế Visa/Mastercard',
              icon: Icons.payment_rounded,
              isDark: isDark,
            ),
            SizedBox(height: context.space(16)),

            // Dynamic Payment View (If VietQR selected, show QR code box)
            if (_selectedMethod == PaymentMethodOption.vietQr) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: '00020101021238540010A00000072701240006970422011003998877660208QRIBFTTA5303704540${totalAmount.toInt()}5802VN62${transferContent.length.toString().padLeft(2, '0')}${transferContent}6304',
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quét mã QR bằng App Ngân hàng bất kỳ',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildCopyableField('Ngân hàng thụ hưởng', 'MB Bank (Quân Đội)', isDark),
                    _buildCopyableField('Số tài khoản', '0399887766', isDark),
                    _buildCopyableField('Số tiền', CurrencyFormatter.format(totalAmount), isDark),
                    _buildCopyableField('Nội dung CK', transferContent, isDark, isHighlight: true),
                  ],
                ),
              ),
              SizedBox(height: context.space(16)),
            ],

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmPaymentSuccess,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isProcessing ? 'Đang kích hoạt gói...' : 'Xác nhận đã thanh toán',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.available,
                  foregroundColor: const Color(0xFF090D14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: context.space(10)),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _saveAsPendingPayment,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Thanh toán sau (Lưu trạng thái chờ)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false, required bool isDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: isHighlight
              ? AppTypography.licensePlateMono.copyWith(fontSize: 13)
              : AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _buildMethodOption({
    required PaymentMethodOption option,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedMethod == option;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFEFF6FF))
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected && !isDark ? const Color(0xFF0284C7) : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableField(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 11,
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép "$value" vào bộ nhớ tạm'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: isHighlight ? 'monospace' : null,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isHighlight ? AppColors.primary : null,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPaymentSuccess() async {
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    // Giả lập xác nhận thanh toán thành công
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final activatedVehicle = widget.vehicle.copyWith(
      paymentStatus: 'Active',
      isMonthlyActive: true,
    );

    widget.onPaymentSuccess(activatedVehicle);
    Navigator.pop(context);
  }

  void _saveAsPendingPayment() {
    HapticFeedback.mediumImpact();
    final pendingVehicle = widget.vehicle.copyWith(
      paymentStatus: 'PendingPayment',
      isMonthlyActive: false,
    );

    widget.onPaymentPending(pendingVehicle);
    Navigator.pop(context);
  }
}
