import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/features/home/presentation/models/vehicle_card_model.dart';
import 'package:prm393_frontend/features/map/data/models/mock_parking_lot.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeDashboardScreen extends StatelessWidget {
  final ValueChanged<String?> onOpenMap;

  const HomeDashboardScreen({super.key, required this.onOpenMap});

  static const _teal = Color(0xFF087B8C);
  static const _tealTint = Color(0xFFEFFBFC);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  static const _favoritePlaces = [
    (
      lotId: 'p1',
      name: 'Vincom Đồng Khởi',
      context: 'Công ty',
      icon: Icons.apartment_rounded
    ),
    (
      lotId: 'p2',
      name: 'Chợ Bến Thành',
      context: 'Cà phê',
      icon: Icons.home_rounded
    ),
    (
      lotId: 'p3',
      name: 'Phố đi bộ',
      context: 'Ăn uống',
      icon: Icons.favorite_rounded
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
          padding: EdgeInsets.fromLTRB(20, 12, 20, 112 + bottomInset),
          children: [
            _buildHeader(context),
            const SizedBox(height: 22),
            _buildSearchEntry(),
            const SizedBox(height: 10),
            _buildNearbyButton(availableLots.length),
            const SizedBox(height: 20),
            _buildActivePass(context, vehicle),
            const SizedBox(height: 22),
            _buildFavoritePlaces(),
            const SizedBox(height: 22),
            _buildNearbyLots(availableLots),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpenMap(null),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded, size: 16, color: _teal),
                      SizedBox(width: 5),
                      Text('Bến Nghé, Quận 1',
                          style: TextStyle(fontSize: 12, color: _muted)),
                      Icon(Icons.expand_more_rounded, size: 17, color: _muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$_greeting, Nam',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: _ink),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã xem các thông báo mới nhất.')),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            side: const BorderSide(color: _border),
            minimumSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 21),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 21,
          backgroundColor: _tealTint,
          child: const Text('N',
              style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildSearchEntry() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpenMap(null),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: _tealTint, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.search_rounded, color: _teal, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bạn muốn đỗ xe ở đâu?',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink)),
                    SizedBox(height: 3),
                    Text('Tìm tòa nhà, đường hoặc bãi đỗ xe',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: _muted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mở bộ lọc bãi đỗ',
                onPressed: () => onOpenMap(null),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.tune_rounded, color: _muted, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyButton(int availableCount) {
    return Material(
      color: _teal,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => onOpenMap(null),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.near_me_rounded, size: 20, color: Colors.white),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$availableCount bãi xe gần bạn còn chỗ',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    const Text('Trong khu vực · Xem giá và chỗ trống',
                        style:
                            TextStyle(fontSize: 10, color: Color(0xFFE4F7F8))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePass(BuildContext context, VehicleCardModel vehicle) {
    final activeLot = mockParkingLots.last;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: _teal, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('VÉ ĐỖ ĐANG HOẠT ĐỘNG',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _teal))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: _tealTint, borderRadius: BorderRadius.circular(20)),
                child: Text(vehicle.parkingSlot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _teal)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activeLot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink)),
                    const SizedBox(height: 5),
                    Text('${vehicle.vehicleName} · ${vehicle.licensePlate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _muted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('01h 24m',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _teal)),
                  const SizedBox(height: 3),
                  Text(
                      '${CurrencyFormatter.format(activeLot.pricePerHour)}/giờ',
                      style: const TextStyle(fontSize: 11, color: _muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _showPassDialog(context, vehicle),
              icon: const Icon(Icons.qr_code_2_rounded, size: 19),
              label: const Text('Mã QR ra vào cổng',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                backgroundColor: _tealTint,
                side: const BorderSide(color: Color(0xFF97DFEB)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPassDialog(BuildContext context, VehicleCardModel vehicle) {
    final code = 'PBMS:${vehicle.id}:${vehicle.licensePlate}';
    final parkingDuration = const Duration(hours: 1, minutes: 24);
    final entryTime = DateTime.now().subtract(parkingDuration);
    final localizations = MaterialLocalizations.of(context);
    final entryTimeLabel =
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entryTime))} · '
        '${localizations.formatMediumDate(entryTime)}';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final qrSize =
            (MediaQuery.sizeOf(dialogContext).width - 104).clamp(180.0, 252.0);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 390,
              maxHeight: MediaQuery.sizeOf(dialogContext).height - 48,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mã QR ra vào cổng',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _ink),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng mã QR',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _tealTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_rounded,
                            size: 17, color: _teal),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${vehicle.vehicleName} · ${vehicle.licensePlate}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: QrImageView(
                        data: code,
                        version: QrVersions.auto,
                        size: qrSize,
                        semanticsLabel:
                            'Mã QR ra vào cổng cho xe ${vehicle.licensePlate}',
                        eyeStyle: const QrEyeStyle(color: Colors.black),
                        dataModuleStyle:
                            const QrDataModuleStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        _passDetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Địa điểm',
                          value: mockParkingLots.last.name,
                        ),
                        const Divider(height: 1, color: _border),
                        _passDetailRow(
                          icon: Icons.local_parking_rounded,
                          label: 'Vị trí đỗ',
                          value: vehicle.parkingSlot,
                        ),
                        const Divider(height: 1, color: _border),
                        _passDetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Vào bãi',
                          value: entryTimeLabel,
                        ),
                        const Divider(height: 1, color: _border),
                        _passDetailRow(
                          icon: Icons.timelapse_rounded,
                          label: 'Thời lượng',
                          value: '01 giờ 24 phút',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _passDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritePlaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
                child: Text('Địa điểm thân quen',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink))),
            Text('Đã lưu',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500, color: _teal)),
          ],
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _favoritePlaces.length,
            separatorBuilder: (context, index) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final place = _favoritePlaces[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => onOpenMap(place.lotId),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(13)),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: _tealTint,
                              borderRadius: BorderRadius.circular(9)),
                          child: Icon(place.icon, size: 18, color: _teal),
                        ),
                        const SizedBox(width: 9),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.name,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _ink)),
                            const SizedBox(height: 3),
                            Text(place.context,
                                style: const TextStyle(
                                    fontSize: 10, color: _muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyLots(List<MockParkingLot> lots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
                child: Text('Gợi ý bãi gần nhất',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _tealTint, borderRadius: BorderRadius.circular(20)),
              child: const Text('Còn chỗ',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
            ),
          ],
        ),
        const SizedBox(height: 11),
        for (final lot in lots) ...[
          _ParkingSuggestion(lot: lot, onOpenMap: onOpenMap),
          const SizedBox(height: 11),
        ],
      ],
    );
  }
}

class _ParkingSuggestion extends StatelessWidget {
  final MockParkingLot lot;
  final ValueChanged<String?> onOpenMap;

  const _ParkingSuggestion({required this.lot, required this.onOpenMap});

  static const _teal = Color(0xFF087B8C);
  static const _tealTint = Color(0xFFEFFBFC);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _initialCenter = LatLng(10.7791, 106.7009);

  @override
  Widget build(BuildContext context) {
    final distanceMeters = (const Distance().as(LengthUnit.Meter,
            _initialCenter, LatLng(lot.latitude, lot.longitude)))
        .round();
    final walkMinutes = (distanceMeters / 80).ceil().clamp(1, 99);
    final occupiedPercent =
        ((lot.totalSlots - lot.availableSlots) / lot.totalSlots * 100).round();
    final amenities = switch (lot.id) {
      'p1' => 'Mái che · Sạc EV',
      'p2' => 'Camera 24/7 · Ra vào tự động',
      _ => 'Có mái che · Bảo vệ 24/7',
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: _tealTint, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_parking_rounded,
                    size: 27, color: _teal),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(lot.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _ink))),
                        const SizedBox(width: 5),
                        Text('${CurrencyFormatter.format(lot.pricePerHour)}/h',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _teal)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.directions_walk_rounded,
                            size: 14, color: _teal),
                        const SizedBox(width: 3),
                        Text('${distanceMeters}m · ${walkMinutes}p',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _teal)),
                        const SizedBox(width: 6),
                        const Text('·', style: TextStyle(color: _muted)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(amenities,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10, color: _muted))),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: _teal, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('${lot.availableSlots} chỗ trống',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _teal)),
                        const Spacer(),
                        Text('Đã lấp $occupiedPercent%',
                            style:
                                const TextStyle(fontSize: 10, color: _muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Divider(height: 1, color: _border)),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => onOpenMap(lot.id),
                icon: const Icon(Icons.local_parking_rounded, size: 16),
                label: const Text('Đặt chỗ trước'),
                style: TextButton.styleFrom(
                    foregroundColor: _teal,
                    visualDensity: VisualDensity.compact),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onOpenMap(lot.id),
                icon: const Icon(Icons.navigation_rounded, size: 15),
                label: const Text('Bản đồ'),
                style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
