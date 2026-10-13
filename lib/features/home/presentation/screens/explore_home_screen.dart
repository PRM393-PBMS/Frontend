import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/features/home/presentation/models/vehicle_card_model.dart';
import 'package:prm393_frontend/features/map/data/models/mock_parking_lot.dart';

enum _ExploreFilter { all, affordable, available }

class ExploreHomeScreen extends StatefulWidget {
  final String? initialLotId;

  const ExploreHomeScreen({super.key, this.initialLotId});

  @override
  State<ExploreHomeScreen> createState() => _ExploreHomeScreenState();
}

class _ExploreHomeScreenState extends State<ExploreHomeScreen> {
  static const _initialCenter = LatLng(10.7791, 106.7009);
  static const _brand = Color(0xFF087B8C);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceLow = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _green = Color(0xFF059669);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  _ExploreFilter _filter = _ExploreFilter.all;
  String _query = '';
  String _selectedLotId = mockParkingLots.first.id;
  final Set<String> _savedLotIds = {};
  LatLng? _userLocation;
  bool _isLocating = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    final initialLotId = widget.initialLotId;
    if (initialLotId != null &&
        mockParkingLots.any((lot) => lot.id == initialLotId)) {
      _selectedLotId = initialLotId;
    }
  }

  List<MockParkingLot> get _visibleLots {
    final lots = mockParkingLots.where((lot) {
      final matchesQuery =
          lot.name.toLowerCase().contains(_query.trim().toLowerCase());
      final matchesFilter = switch (_filter) {
        _ExploreFilter.all => true,
        _ExploreFilter.affordable => lot.pricePerHour < 40000,
        _ExploreFilter.available => lot.availableSlots >= 10,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    final userLocation = _userLocation;
    if (userLocation != null) {
      lots.sort(
        (first, second) => _distanceFrom(userLocation, first)
            .compareTo(_distanceFrom(userLocation, second)),
      );
    }
    return lots;
  }

  double _distanceFrom(LatLng origin, MockParkingLot lot) {
    return const Distance().as(
      LengthUnit.Meter,
      origin,
      LatLng(lot.latitude, lot.longitude),
    );
  }

  Future<void> _requestUserLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationMessage(
          'Hãy bật dịch vụ vị trí để tìm bãi đỗ quanh bạn.',
          action: SnackBarAction(
            label: 'Cài đặt',
            onPressed: () async => Geolocator.openLocationSettings(),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationMessage('Bạn chưa cấp quyền truy cập vị trí.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Quyền vị trí đang bị tắt. Hãy bật trong cài đặt ứng dụng.',
          action: SnackBarAction(
            label: 'Cài đặt',
            onPressed: () async => Geolocator.openAppSettings(),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = location;
        final nearbyLots = _visibleLots;
        if (nearbyLots.isNotEmpty) _selectedLotId = nearbyLots.first.id;
        _showDetails = false;
      });
      _mapController.move(location, 15.5);
      _showLocationMessage(
        'Đã cập nhật vị trí và sắp xếp bãi gần bạn trước.',
      );
    } catch (_) {
      if (mounted) {
        _showLocationMessage(
          'Không lấy được vị trí. Vui lòng thử lại hoặc kiểm tra cài đặt GPS.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showLocationMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        ),
      );
  }

  MockParkingLot? get _selectedLot {
    for (final lot in _visibleLots) {
      if (lot.id == _selectedLotId) return lot;
    }
    return _visibleLots.isEmpty ? null : _visibleLots.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _selectLot(MockParkingLot lot) {
    setState(() {
      _selectedLotId = lot.id;
      _showDetails = false;
    });
    _mapController.move(LatLng(lot.latitude, lot.longitude), 15.5);
  }

  void _selectFilter(_ExploreFilter filter) {
    setState(() {
      _filter = filter;
      if (!_visibleLots.any((lot) => lot.id == _selectedLotId) &&
          _visibleLots.isNotEmpty) {
        _selectedLotId = _visibleLots.first.id;
      }
    });
  }

  void _showBookingDetails(MockParkingLot lot) {
    showModalBottomSheet<VehicleCardModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VehicleSelectionSheet(parkingLot: lot),
    ).then((vehicle) {
      if (vehicle != null && mounted) _showReservationPreview(lot, vehicle);
    });
  }

  void _showReservationPreview(
    MockParkingLot lot,
    VehicleCardModel vehicle,
  ) {
    context.push(
      RouteNames.bookingConfirmationPath,
      extra: {'parkingLot': lot, 'vehicle': vehicle},
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLot = _selectedLot;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: const Text(
          'Tìm bãi đỗ',
          style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Về khu vực của bạn',
            onPressed: _requestUserLocation,
            icon: _isLocating
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, color: _brand),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sheetHeight =
              (constraints.maxHeight * 0.48).clamp(330.0, 390.0);
          return Stack(
            children: [
              Positioned.fill(child: _buildMap()),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildMapControls(),
              ),
              Positioned(
                right: 14,
                bottom: sheetHeight + bottomInset + 96,
                child: _buildRecenterButton(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 80 + bottomInset,
                child: _buildLotSheet(selectedLot, sheetHeight),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 15.5,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.prm393_frontend',
        ),
        MarkerLayer(
          markers: [
            ..._visibleLots.map(_buildLotMarker),
            if (_userLocation != null) _buildUserLocationMarker(_userLocation!),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _buildUserLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 48,
      height: 48,
      child: Semantics(
        label: 'Vị trí hiện tại của bạn',
        image: true,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0x33087B8C),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _brand,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildLotMarker(MockParkingLot lot) {
    final isSelected = lot.id == _selectedLotId;
    final isLowCapacity = lot.availableSlots <= 5;
    final markerColor = isSelected ? _brand : Colors.white;
    final markerPrice = '${(lot.pricePerHour / 1000).round()}k';

    return Marker(
      point: LatLng(lot.latitude, lot.longitude),
      width: 164,
      height: 58,
      alignment: Alignment.bottomCenter,
      child: Semantics(
        button: true,
        label:
            '${lot.name}, \$${lot.pricePerHour.toStringAsFixed(2)} mỗi giờ, còn ${lot.availableSlots} chỗ',
        child: GestureDetector(
          onTap: () => _selectLot(lot),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: markerColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_parking_rounded,
                      size: 15,
                      color: isSelected ? Colors.white : _brand,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$markerPrice đ/h',
                      style: TextStyle(
                        color: isSelected ? Colors.white : _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isLowCapacity
                            ? AppColors.warning
                            : AppColors.available,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lot.availableSlots} chỗ',
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFD8E2FF) : _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 1),
                transform: Matrix4.rotationZ(0.785398),
                decoration: BoxDecoration(
                  color: markerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: _controlShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 21, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _query = value;
                  if (!_visibleLots.any((lot) => lot.id == _selectedLotId) &&
                      _visibleLots.isNotEmpty) {
                    _selectedLotId = _visibleLots.first.id;
                  }
                });
              },
              style: const TextStyle(fontSize: 13, color: _ink),
              decoration: const InputDecoration(
                hintText: 'Tìm bãi đỗ xe gần bạn...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Xóa nội dung tìm kiếm',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  if (_visibleLots.isNotEmpty) {
                    _selectedLotId = _visibleLots.first.id;
                  }
                });
              },
              icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
            ),
          IconButton(
            tooltip: 'Bộ lọc tìm kiếm',
            onPressed: _showFilterOptions,
            style: IconButton.styleFrom(
              foregroundColor: _muted,
              minimumSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.tune_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: IconButton(
        tooltip: 'Định vị của tôi',
        onPressed: _requestUserLocation,
        icon: _isLocating
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded, color: _brand, size: 22),
      ),
    );
  }

  Widget _buildLotSheet(MockParkingLot? lot, double height) {
    return Container(
      height: height,
      constraints: BoxConstraints(maxHeight: height),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: lot == null
                ? _buildNoResults()
                : SingleChildScrollView(child: _buildLotDetails(lot)),
          ),
          if (lot != null) ...[
            const SizedBox(height: 10),
            _buildActions(lot),
          ],
        ],
      ),
    );
  }

  Widget _buildLotDetails(MockParkingLot lot) {
    final origin = _userLocation ?? _initialCenter;
    final distanceMeters = _distanceFrom(origin, lot).round();
    final walkMinutes = (distanceMeters / 80).ceil().clamp(1, 99);
    final available = lot.availableSlots > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lot.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: _ink),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded,
                          color: _brand, size: 17),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.circle,
                          size: 8, color: available ? _green : Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        available ? 'Còn chỗ' : 'Hết chỗ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: available ? _green : Colors.red),
                      ),
                      const SizedBox(width: 7),
                      const Text('·', style: TextStyle(color: _muted)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          '$distanceMeters m · $walkMinutes phút đi bộ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: _savedLotIds.contains(lot.id)
                    ? 'Bỏ lưu bãi đỗ'
                    : 'Lưu bãi đỗ',
                onPressed: () => setState(() {
                  if (!_savedLotIds.add(lot.id)) _savedLotIds.remove(lot.id);
                }),
                style: IconButton.styleFrom(
                  foregroundColor:
                      _savedLotIds.contains(lot.id) ? _brand : _muted,
                  side: const BorderSide(color: _border),
                ),
                icon: Icon(
                    _savedLotIds.contains(lot.id)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 19),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _detailTile(
                title: 'Chỗ trống hiện tại',
                value: '${lot.availableSlots}',
                suffix: '/ ${lot.totalSlots}',
                badge: available ? 'Chỗ khả dụng' : 'Bãi đã đầy',
                unit: 'chỗ',
                accent: available ? _green : Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailTile(
                title: 'Giá theo giờ',
                value: CurrencyFormatter.format(lot.pricePerHour),
                suffix: '',
                badge: 'Tính phí theo giờ',
                unit: '/ giờ',
                accent: _ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: _border.withValues(alpha: 0.8)),
        InkWell(
          onTap: () => setState(() => _showDetails = !_showDetails),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: _muted),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Thông tin bãi xe',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                AnimatedRotation(
                  turns: _showDetails ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.expand_more_rounded,
                      size: 20, color: _muted),
                ),
              ],
            ),
          ),
        ),
        if (_showDetails)
          Row(
            children: [
              _infoTag(Icons.local_parking_outlined,
                  'Sức chứa ${lot.totalSlots} chỗ'),
              const SizedBox(width: 8),
              _infoTag(Icons.schedule_rounded, 'Tính phí theo giờ'),
            ],
          ),
      ],
    );
  }

  Widget _detailTile({
    required String title,
    required String value,
    required String suffix,
    required String badge,
    required String unit,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceLow,
        border: Border.all(color: _border.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: _muted)),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: accent))),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Flexible(
                    child: Text(suffix,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: _muted))),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(unit, style: const TextStyle(fontSize: 10, color: _muted)),
          const SizedBox(height: 4),
          Text(badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
            color: _surfaceLow, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _muted),
            const SizedBox(width: 5),
            Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _muted))),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(MockParkingLot lot) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: IconButton(
            tooltip: 'Xem vị trí bãi đỗ trên bản đồ',
            onPressed: () =>
                _mapController.move(LatLng(lot.latitude, lot.longitude), 17),
            style: IconButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.directions_rounded, size: 21),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: lot.availableSlots > 0
                  ? () => _showBookingDetails(lot)
                  : null,
              icon: const Icon(Icons.directions_car_rounded, size: 19),
              label: Text(
                'Chọn xe · ${CurrencyFormatter.format(lot.pricePerHour)}/giờ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _border,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return SizedBox(
      height: 130,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: _muted, size: 28),
            const SizedBox(height: 8),
            const Text('Không tìm thấy bãi đỗ phù hợp',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
            TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _filter = _ExploreFilter.all;
                  });
                },
                child: const Text('Xóa bộ lọc')),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE4E2E4),
                          borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 17),
              const Text('Lọc bãi đỗ',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 8),
              _filterOption(context, _ExploreFilter.all, 'Tất cả bãi đỗ',
                  Icons.map_outlined),
              _filterOption(context, _ExploreFilter.affordable,
                  'Dưới 40.000đ / giờ', Icons.sell_outlined),
              _filterOption(context, _ExploreFilter.available,
                  'Còn từ 10 chỗ trở lên', Icons.event_available_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterOption(BuildContext context, _ExploreFilter filter,
      String label, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _brand),
      title: Text(label, style: const TextStyle(fontSize: 14, color: _ink)),
      trailing: _filter == filter
          ? const Icon(Icons.check_rounded, color: _brand)
          : null,
      onTap: () {
        _selectFilter(filter);
        Navigator.pop(context);
      },
    );
  }

  List<BoxShadow> get _controlShadow => [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 16,
            offset: const Offset(0, 4)),
      ];
}

class _VehicleSelectionSheet extends StatefulWidget {
  final MockParkingLot parkingLot;

  const _VehicleSelectionSheet({required this.parkingLot});

  @override
  State<_VehicleSelectionSheet> createState() => _VehicleSelectionSheetState();
}

class _VehicleSelectionSheetState extends State<_VehicleSelectionSheet> {
  static const _brand = Color(0xFF087B8C);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    final vehicles = VehicleCardModel.mockVehicles;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chọn xe của bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.parkingLot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 14),
              for (final vehicle in vehicles) ...[
                _vehicleOption(vehicle),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _selectedVehicleId == null
                      ? null
                      : () {
                          final vehicle = vehicles.firstWhere(
                            (item) => item.id == _selectedVehicleId,
                          );
                          Navigator.pop(context, vehicle);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleOption(VehicleCardModel vehicle) {
    final isSelected = _selectedVehicleId == vehicle.id;
    return Material(
      color: isSelected ? const Color(0xFFEFFBFC) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => setState(() => _selectedVehicleId = vehicle.id),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? _brand : _border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: vehicle.gradientColors.first,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  vehicle.type == VehicleType.car
                      ? Icons.directions_car_rounded
                      : Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.vehicleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.licensePlate} · ${vehicle.type == VehicleType.car ? 'Ô tô' : 'Xe máy'}',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? _brand : _muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
