import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_spacing.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/features/home/presentation/models/vehicle_card_model.dart';
import 'package:prm393_frontend/features/map/data/models/mock_parking_lot.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Màn hình Home Dashboard theo kiến trúc Dashboard-First
/// Phong cách: Precision Minimalist / Swiss Grid (Apple Wallet Pass, Tabular figures, Hairline borders)
class HomeDashboardScreen extends StatelessWidget {
  final ValueChanged<String?> onOpenMap;

  const HomeDashboardScreen({super.key, required this.onOpenMap});

  static const _favoritePlaces = [
    (
      lotId: 'p1',
      name: 'Vincom Đồng Khởi',
      context: 'Nơi làm việc',
      icon: Icons.apartment_rounded,
    ),
    (
      lotId: 'p2',
      name: 'Chợ Bến Thành',
      context: 'Cà phê & Gặp gỡ',
      icon: Icons.coffee_rounded,
    ),
    (
      lotId: 'p3',
      name: 'Phố đi bộ Nguyễn Huệ',
      context: 'Ăn uống',
      icon: Icons.restaurant_rounded,
    ),
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final vehicle = VehicleCardModel.mockVehicles.first;
    final availableLots =
        mockParkingLots.where((lot) => lot.availableSlots > 0).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 16, 20, 110 + bottomInset),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildActivePass(context, vehicle),
            const SizedBox(height: 20),
            _buildSearchEntry(),
            const SizedBox(height: 12),
            _buildNearbyQuickBar(availableLots.length),
            const SizedBox(height: 24),
            _buildFavoritePlaces(),
            const SizedBox(height: 24),
            _buildNearbyLots(availableLots),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER (Địa điểm & Lời chào thân thiện)
  // ===========================================================================
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: AppSpacing.roundedSm,
                onTap: () => onOpenMap(null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Bến Nghé, Quận 1',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_greeting, Nam',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.displayMedium.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn không có thông báo mới nào.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceLight,
            foregroundColor: AppColors.textPrimaryLight,
            side: const BorderSide(
              color: AppColors.borderLight,
              width: AppSpacing.hairline,
            ),
            minimumSize: const Size(42, 42),
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 20),
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              width: AppSpacing.hairline,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'N',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. ACTIVE DIGITAL PASS (Apple Wallet / Swiss Grid Precision Pass)
  // ===========================================================================
  Widget _buildActivePass(BuildContext context, VehicleCardModel vehicle) {
    final activeLot = mockParkingLots.first;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: AppColors.borderLight,
          width: AppSpacing.hairline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ Header: Trạng thái & Vị trí đỗ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.available,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'VÉ ĐỖ ĐANG HOẠT ĐỘNG',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.available,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: AppSpacing.hairline,
                    ),
                  ),
                  child: Text(
                    vehicle.parkingSlot,
                    style: AppTypography.ticketCode.copyWith(
                      fontSize: 11,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // Thẻ Body: Biển số, Tên xe & Tên bãi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                          Text(
                            activeLot.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.vehicleName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Biển số xe định dạng Monospace Tabular chuẩn
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(
                          color: AppColors.textPrimaryLight.withValues(alpha: 0.15),
                          width: AppSpacing.hairline,
                        ),
                      ),
                      child: Text(
                        vehicle.licensePlate,
                        style: AppTypography.licensePlate.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Telemetry Metrics: Thời gian trôi qua & Mức phí
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THỜI GIAN ĐÃ ĐỖ',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '01:24:18',
                              style: AppTypography.timerMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.borderLight,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MỨC PHÍ HIỆN TẠI',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.format(activeLot.pricePerHour)}/h',
                                style: AppTypography.priceHighlight.copyWith(
                                  fontSize: 14,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Thẻ Footer Button: Mã QR ra vào cổng
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showPassDialog(context, vehicle);
                },
                icon: const Icon(Icons.qr_code_2_rounded, size: 19),
                label: const Text('Mã QR ra vào cổng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedMd,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SEARCH ENTRY (Thanh tìm kiếm chuẩn Swiss Hairline)
  // ===========================================================================
  Widget _buildSearchEntry() {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        borderRadius: AppSpacing.roundedLg,
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenMap(null);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.borderLight,
              width: AppSpacing.hairline,
            ),
            borderRadius: AppSpacing.roundedLg,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn muốn tìm bãi đỗ xe ở đâu?',
                      style: AppTypography.labelLarge.copyWith(fontSize: 13.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Tìm theo địa chỉ, tòa nhà hoặc khu vực',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.tune_rounded,
                color: AppColors.textMutedLight,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. QUICK MAP BAR (Lối tắt mở bản đồ tiện ích)
  // ===========================================================================
  Widget _buildNearbyQuickBar(int count) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenMap(null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.borderLight,
              width: AppSpacing.hairline,
            ),
            borderRadius: AppSpacing.roundedMd,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.available,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count bãi đỗ còn chỗ quanh khu vực của bạn',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                'Xem bản đồ',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. FAVORITE PLACES (Địa điểm thường đến)
  // ===========================================================================
  Widget _buildFavoritePlaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ĐỊA ĐIỂM THƯỜNG ĐẾN',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Quản lý',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _favoritePlaces.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final place = _favoritePlaces[index];
              return InkWell(
                borderRadius: AppSpacing.roundedMd,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onOpenMap(place.lotId);
                },
                child: Container(
                  width: 154,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: AppSpacing.hairline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(place.icon, size: 17, color: AppColors.primary),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            size: 14,
                            color: AppColors.textMutedLight,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge.copyWith(fontSize: 13),
                          ),
                          Text(
                            place.context,
                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. NEARBY LOTS (Danh sách bãi đỗ lân cận)
  // ===========================================================================
  Widget _buildNearbyLots(List<MockParkingLot> lots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BÃI ĐỖ GẦN NHẤT',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            InkWell(
              onTap: () => onOpenMap(null),
              child: Text(
                'Tất cả (${lots.length})',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: lots.map((lot) {
            final isLowSlots = lot.availableSlots <= 5;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color: AppColors.borderLight,
                  width: AppSpacing.hairline,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onOpenMap(lot.id);
                },
                title: Text(
                  lot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLowSlots
                              ? AppColors.reservedLight
                              : AppColors.availableLight,
                          borderRadius: AppSpacing.roundedXs,
                        ),
                        child: Text(
                          'Còn ${lot.availableSlots} chỗ',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10.5,
                            color: isLowSlots
                                ? AppColors.reserved
                                : AppColors.available,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tổng ${lot.totalSlots} ô',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(lot.pricePerHour),
                      style: AppTypography.priceHighlight.copyWith(fontSize: 13.5),
                    ),
                    Text(
                      'mỗi giờ',
                      style: AppTypography.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. QR CODE MODAL DIALOG
  // ===========================================================================
  Future<void> _showPassDialog(BuildContext context, VehicleCardModel vehicle) {
    final code = 'PBMS:${vehicle.id}:${vehicle.licensePlate}';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final qrSize =
            (MediaQuery.sizeOf(dialogContext).width - 120).clamp(180.0, 240.0);

        return Dialog(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã QR Ra Vào Cổng',
                      style: AppTypography.titleMedium.copyWith(fontSize: 17),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: AppSpacing.hairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_car_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vehicle.licensePlate,
                        style: AppTypography.licensePlate.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: AppSpacing.hairline,
                    ),
                  ),
                  child: QrImageView(
                    data: code,
                    version: QrVersions.auto,
                    size: qrSize,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.accent,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Đưa mã vào máy quét tại barie khi vào/ra',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
