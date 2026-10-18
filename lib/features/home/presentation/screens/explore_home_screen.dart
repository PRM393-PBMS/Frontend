import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/services/location_service.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';

/// Bản đồ các bãi đỗ với chỗ trống và bảng giá thời gian thực.
class ExploreHomeScreen extends StatefulWidget {
  /// Bãi được chọn sẵn (từ trang chủ).
  final String? initialLotId;

  const ExploreHomeScreen({super.key, this.initialLotId});

  @override
  State<ExploreHomeScreen> createState() => _ExploreHomeScreenState();
}

class _ExploreHomeScreenState extends State<ExploreHomeScreen> {
  static const _surfaceLow = PbmsTokens.surfaceLow;

  final MapController _mapController = MapController();
  final DraggableScrollableController _sheet = DraggableScrollableController();

  /// Chiều cao hiện tại của khung bãi (px), để nút định vị đi theo mép khung.
  final ValueNotifier<double> _sheetPx = ValueNotifier(0);

  /// Các mức của khung (tỉ lệ chiều cao vùng bản đồ), tính trong LayoutBuilder.
  double _minSize = 0.2;
  double _midSize = 0.5;
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _lots = AsyncCubit<List<LotView>>(() => LotView.load(
        lots: _repo.getParkingLots,
        facility: _repo.getAvailability,
        pricing: _repo.getPricingPolicies,
      ));

  late String? _selectedId = widget.initialLotId;
  // Dùng vị trí trang chủ đã lấy (nếu có), không hỏi quyền lại.
  LatLng? _userLocation = LocationService.instance.last;
  bool _isLocating = false;
  bool _showDetails = false;

  @override
  void dispose() {
    _lots.close();
    _mapController.dispose();
    _sheet.dispose();
    _sheetPx.dispose();
    super.dispose();
  }

  LotView? _selected(List<LotView> lots) {
    final chosen = lots.where((l) => l.id == _selectedId).firstOrNull;
    if (chosen != null) return chosen;
    // Chưa chọn: lấy bãi gần vị trí của khách nhất, rồi đến bãi đầu danh sách.
    final near = lots.where((l) => l.distanceFrom(_userLocation) != null).toList()
      ..sort((a, b) => a.distanceFrom(_userLocation)!.compareTo(b.distanceFrom(_userLocation)!));
    return near.firstOrNull ?? lots.firstOrNull;
  }

  LatLng get _initialCenter {
    final lots = _lots.state.data ?? const <LotView>[];
    return _selected(lots)?.point ??
        lots.map((l) => l.point).whereType<LatLng>().firstOrNull ??
        PbmsFacility.location;
  }

  void _selectLot(LotView lot) {
    setState(() {
      _selectedId = lot.id;
      _showDetails = false;
    });
    final p = lot.point;
    if (p != null) _mapController.move(p, 16);
    _snapSheet(_midSize);
  }

  void _snapSheet(double size) {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(size,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  /// Chạm tay nắm: đang mở thì thu xuống để xem toàn bản đồ, đang thu thì mở ra.
  void _toggleSheet() {
    if (!_sheet.isAttached) return;
    _snapSheet(_sheet.size > _minSize + 0.02 ? _minSize : _midSize);
  }

  Future<void> _requestUserLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationMessage(
          'Hãy bật dịch vụ vị trí để xem khoảng cách tới bãi.',
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
      final lots = _lots.state.data ?? const <LotView>[];
      // Chọn bãi gần nhất có toạ độ.
      final withPoint = lots.where((l) => l.point != null).toList()
        ..sort((a, b) => const Distance()
            .as(LengthUnit.Meter, location, a.point!)
            .compareTo(const Distance().as(LengthUnit.Meter, location, b.point!)));
      setState(() {
        _userLocation = location;
        if (withPoint.isNotEmpty) _selectedId = withPoint.first.id;
      });
      final target = withPoint.firstOrNull?.point;
      _mapController.fitCamera(CameraFit.coordinates(
        coordinates: [location, if (target != null) target],
        padding: EdgeInsets.fromLTRB(60, 120, 60, _sheetPx.value + 40),
        maxZoom: 16,
      ));
    } catch (_) {
      if (mounted) {
        _showLocationMessage(
            'Không lấy được vị trí. Vui lòng thử lại hoặc kiểm tra cài đặt GPS.');
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

  Future<void> _book() async {
    final booked = await context.push<bool>(RouteNames.bookingConfirmationPath);
    if (booked == true && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 4,
        title: const Text('Tìm bãi đỗ',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PbmsTokens.ink)),
        actions: [
          IconButton(
            tooltip: 'Làm mới chỗ trống',
            onPressed: _lots.load,
            icon: const Icon(Icons.refresh_rounded, color: PbmsTokens.ink),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocBuilder<AsyncCubit<List<LotView>>, AsyncState<List<LotView>>>(
        bloc: _lots,
        builder: (context, st) {
          final lots = st.data ?? const <LotView>[];
          final selected = _selected(lots);
          return LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              // Thu nhỏ: chỉ còn tay nắm + nút đặt chỗ, để xem toàn bản đồ.
              _minSize = ((_collapsedHeight + bottomInset) / h).clamp(0.1, 0.4);
              _midSize = (((h * 0.52).clamp(360.0, 450.0) + bottomInset) / h)
                  .clamp(_minSize + 0.05, 0.8);
              const maxSize = 0.9;
              if (_sheetPx.value == 0) _sheetPx.value = _midSize * h;
              return Stack(
                children: [
                  Positioned.fill(child: _buildMap(lots, selected)),
                  ValueListenableBuilder<double>(
                    valueListenable: _sheetPx,
                    builder: (context, px, child) => Positioned(
                      right: 14,
                      bottom: px + 14,
                      // Ẩn khi khung kéo gần kín màn hình.
                      child: AnimatedOpacity(
                        opacity: px > h * 0.75 ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: child,
                      ),
                    ),
                    child: _buildRecenterButton(),
                  ),
                  NotificationListener<DraggableScrollableNotification>(
                    onNotification: (n) {
                      _sheetPx.value = n.extent * h;
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      controller: _sheet,
                      initialChildSize: _midSize,
                      minChildSize: _minSize,
                      maxChildSize: maxSize,
                      snap: true,
                      snapSizes: [_midSize],
                      builder: (context, scroll) =>
                          _buildLotSheet(st, lots, selected, scroll, bottomInset),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMap(List<LotView> lots, LotView? selected) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Nền bản đồ OpenStreetMap France: tile.openstreetmap.org không trả ảnh
        // cho ứng dụng (bản đồ chỉ hiện xám), CARTO thì đòi API key.
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          maxNativeZoom: 19,
          userAgentPackageName: 'com.prm393.parking.prm393_frontend',
        ),
        MarkerLayer(
          markers: [
            for (final l in lots)
              if (l.point != null) _buildLotMarker(l, l.id == selected?.id),
            if (_userLocation != null) _buildUserLocationMarker(_userLocation!),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
            TextSourceAttribution('OpenStreetMap France'),
          ],
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
          decoration: BoxDecoration(
            color: PbmsTokens.teal.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: PbmsTokens.teal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildLotMarker(LotView lot, bool isSelected) {
    final price = lot.car?.pricing?.basePrice;
    final bg = isSelected ? PbmsTokens.teal : Colors.white;
    final fg = isSelected ? Colors.white : PbmsTokens.ink;

    return Marker(
      point: lot.point!,
      width: 180,
      height: 58,
      alignment: Alignment.topCenter,
      child: Semantics(
        button: true,
        label: '${lot.name}, còn ${lot.available} chỗ',
        child: GestureDetector(
          onTap: () => _selectLot(lot),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: PbmsTokens.ink.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_parking_rounded,
                        size: 15, color: isSelected ? Colors.white : PbmsTokens.teal),
                    const SizedBox(width: 5),
                    if (price != null) ...[
                      Text('${(price / 1000).round()}k',
                          style: TextStyle(
                              color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                    ],
                    Text('${lot.available} chỗ',
                        style: TextStyle(
                            color: isSelected ? const Color(0xFFE4F7F8) : PbmsTokens.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 1),
                transform: Matrix4.rotationZ(0.785398),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: PbmsTokens.ink.withValues(alpha: 0.2),
      child: IconButton(
        tooltip: 'Định vị của tôi',
        onPressed: _requestUserLocation,
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: _isLocating
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded,
                color: PbmsTokens.teal, size: 22),
      ),
    );
  }

  /// Chiều cao khung khi thu nhỏ (chưa gồm vùng an toàn dưới):
  /// lề trên + tay nắm + khoảng cách + nút đặt chỗ + lề dưới.
  static const double _collapsedHeight = 8 + 28 + 10 + 50 + 14;

  Widget _buildLotSheet(AsyncState<List<LotView>> st, List<LotView> lots,
      LotView? selected, ScrollController scroll, double bottomInset) {
    final Widget body = selected != null
        ? _buildLotDetails(selected)
        : st.status == AsyncStatus.error
            ? PbmsErrorView(
                title: 'Không tải được bãi đỗ',
                message: st.error ?? '',
                onRetry: _lots.load)
            : st.isLoading
                ? const PbmsLoadingBox(height: 220)
                : const PbmsEmptyView(
                    icon: Icons.local_parking_rounded,
                    title: 'Chưa có bãi đỗ nào',
                  );

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 14 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: PbmsTokens.ink.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: EdgeInsets.zero,
              children: [
                Semantics(
                  button: true,
                  label: 'Thu gọn hoặc mở rộng thông tin bãi',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleSheet,
                    child: SizedBox(
                      height: 28,
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                              color: PbmsTokens.border,
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ),
                if (lots.length > 1) ...[
                  _buildLotStrip(lots, selected),
                  const SizedBox(height: 12),
                ],
                body,
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildActions(selected),
        ],
      ),
    );
  }

  /// Dải chọn bãi: gồm cả bãi chưa có toạ độ trên bản đồ.
  Widget _buildLotStrip(List<LotView> lots, LotView? selected) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: lots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final l = lots[i];
          final isSel = l.id == selected?.id;
          return ChoiceChip(
            label: Text('${l.name} · ${l.available}'),
            avatar: Icon(l.point == null ? Icons.location_off_outlined : Icons.place_outlined,
                size: 16, color: isSel ? PbmsTokens.teal : PbmsTokens.muted),
            selected: isSel,
            selectedColor: PbmsTokens.tealTint,
            showCheckmark: false,
            side: BorderSide(color: isSel ? PbmsTokens.teal : PbmsTokens.border),
            onSelected: (_) => _selectLot(l),
          );
        },
      ),
    );
  }

  Widget _buildLotDetails(LotView lot) {
    final hasRoom = lot.available > 0;
    final car = lot.car;
    final user = _userLocation;
    final point = lot.point;
    final distance = user == null || point == null
        ? null
        : const Distance().as(LengthUnit.Meter, user, point).round();
    final where = [
      if (lot.area != null) lot.area!,
      if (distance != null)
        'cách bạn ${distance >= 1000 ? '${(distance / 1000).toStringAsFixed(1)} km' : '$distance m'}',
      if (point == null) 'chưa có vị trí trên bản đồ',
    ].join(', ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(lot.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PbmsText.title),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.verified_rounded, color: PbmsTokens.teal, size: 18),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              hasRoom ? 'Còn chỗ' : 'Hết chỗ',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasRoom ? PbmsTokens.ok : PbmsTokens.danger),
            ),
            if (where.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(where,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: PbmsText.caption),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _detailTile(
                title: 'Chỗ ô tô trống',
                value: car == null ? '0' : '${car.available}',
                suffix: car == null ? '' : '/ ${car.total}',
                badge: car == null
                    ? 'Bãi chưa có ô ô tô'
                    : (car.available > 0 ? 'Có thể đặt trước' : 'Bãi ô tô đã đầy'),
                accent: (car?.available ?? 0) > 0 ? PbmsTokens.ok : PbmsTokens.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailTile(
                title: 'Giá ô tô',
                value: car?.pricing == null
                    ? 'Chưa có'
                    : CurrencyFormatter.format(car!.pricing!.basePrice),
                suffix: '',
                badge: car?.pricing == null
                    ? 'Liên hệ bãi'
                    : '${car!.pricing!.baseHours} giờ đầu, sau đó ${CurrencyFormatter.format(car.pricing!.extraHourPrice)}/giờ',
                accent: PbmsTokens.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: PbmsTokens.border),
        InkWell(
          onTap: () => setState(() => _showDetails = !_showDetails),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: PbmsTokens.muted),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Chỗ trống và giá theo loại xe',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PbmsTokens.muted))),
                AnimatedRotation(
                  turns: _showDetails ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.expand_more_rounded, size: 20, color: PbmsTokens.muted),
                ),
              ],
            ),
          ),
        ),
        if (_showDetails)
          for (final c in lot.capacities)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                  color: _surfaceLow, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(c.isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                      size: 18, color: PbmsTokens.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.pricing == null
                          ? c.vehicleTypeName
                          : '${c.vehicleTypeName}, ${CurrencyFormatter.format(c.pricing!.basePrice)}/${c.pricing!.baseHours}h',
                      style: PbmsText.caption.copyWith(color: PbmsTokens.ink),
                    ),
                  ),
                  Text('${c.available}/${c.total}',
                      style: PbmsText.figure(13,
                          color: c.available > 0 ? PbmsTokens.ok : PbmsTokens.danger)),
                ],
              ),
            ),
      ],
    );
  }

  Widget _detailTile({
    required String title,
    required String value,
    required String suffix,
    required String badge,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceLow,
        border: Border.all(color: PbmsTokens.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: PbmsText.caption),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PbmsText.figure(19, color: accent))),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(suffix, style: PbmsText.caption),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(badge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
        ],
      ),
    );
  }

  Widget _buildActions(LotView? lot) {
    final car = lot?.car;
    final point = lot?.point;
    return Row(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: IconButton(
            tooltip: 'Xem vị trí bãi đỗ trên bản đồ',
            onPressed: point == null ? null : () => _mapController.move(point, 17),
            style: IconButton.styleFrom(
              foregroundColor: PbmsTokens.ink,
              side: const BorderSide(color: PbmsTokens.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.directions_rounded, size: 21),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: PbmsPrimaryButton(
            label: car?.pricing == null
                ? 'Đặt chỗ ô tô'
                : 'Đặt chỗ, cọc ${CurrencyFormatter.format(car!.pricing!.basePrice)}',
            icon: Icons.directions_car_rounded,
            onPressed: car != null ? _book : null,
          ),
        ),
      ],
    );
  }
}
