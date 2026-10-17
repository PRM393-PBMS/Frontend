import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';

/// Bản đồ bãi đỗ PBMS với chỗ trống và bảng giá thời gian thực.
class ExploreHomeScreen extends StatefulWidget {
  const ExploreHomeScreen({super.key});

  @override
  State<ExploreHomeScreen> createState() => _ExploreHomeScreenState();
}

class _ExploreHomeScreenState extends State<ExploreHomeScreen> {
  static const _surfaceLow = PbmsTokens.surfaceLow;

  final MapController _mapController = MapController();
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _capacity = AsyncCubit<List<VehicleTypeCapacity>>(() async {
    final results = await Future.wait([
      _repo.getAvailability(),
      _repo.getPricingPolicies(),
    ]);
    return VehicleTypeCapacity.summarize(
      results[0] as List<FacilityAvailabilityModel>,
      results[1] as List<PricingPolicyModel>,
    );
  });

  LatLng? _userLocation;
  bool _isLocating = false;
  bool _showDetails = false;

  @override
  void dispose() {
    _capacity.close();
    _mapController.dispose();
    super.dispose();
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
      setState(() => _userLocation = location);
      _mapController.fitCamera(CameraFit.coordinates(
        coordinates: [location, PbmsFacility.location],
        padding: const EdgeInsets.fromLTRB(60, 120, 60, 420),
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
            onPressed: _capacity.load,
            icon: const Icon(Icons.refresh_rounded, color: PbmsTokens.ink),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sheetHeight =
              (constraints.maxHeight * 0.5).clamp(340.0, 420.0);
          return Stack(
            children: [
              Positioned.fill(child: _buildMap()),
              Positioned(
                right: 14,
                bottom: sheetHeight + bottomInset + 14,
                child: _buildRecenterButton(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildLotSheet(sheetHeight + bottomInset, bottomInset),
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
        initialCenter: PbmsFacility.location,
        initialZoom: 16,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.prm393_frontend',
        ),
        BlocBuilder<AsyncCubit<List<VehicleTypeCapacity>>,
            AsyncState<List<VehicleTypeCapacity>>>(
          bloc: _capacity,
          builder: (context, st) => MarkerLayer(
            markers: [
              _buildLotMarker(st.data),
              if (_userLocation != null)
                _buildUserLocationMarker(_userLocation!),
            ],
          ),
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

  Marker _buildLotMarker(List<VehicleTypeCapacity>? items) {
    final available = items?.fold<int>(0, (s, c) => s + c.available);
    final car = items?.where((c) => c.isCar).firstOrNull;
    final price = car?.pricing?.basePrice;

    return Marker(
      point: PbmsFacility.location,
      width: 180,
      height: 58,
      alignment: Alignment.topCenter,
      child: Semantics(
        label: available == null
            ? PbmsFacility.name
            : '${PbmsFacility.name}, còn $available chỗ',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: PbmsTokens.teal,
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
                  const Icon(Icons.local_parking_rounded,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                  if (price != null) ...[
                    Text('${(price / 1000).round()}k',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                  ],
                  Text(available == null ? 'Đang tải' : '$available chỗ',
                      style: const TextStyle(
                          color: Color(0xFFE4F7F8),
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
                color: PbmsTokens.teal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
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

  Widget _buildLotSheet(double height, double bottomInset) {
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + bottomInset),
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
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: PbmsTokens.border,
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PbmsAsync<List<VehicleTypeCapacity>>(
              cubit: _capacity,
              loadingHeight: 220,
              errorTitle: 'Không tải được chỗ trống',
              builder: (items) =>
                  SingleChildScrollView(child: _buildLotDetails(items)),
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<AsyncCubit<List<VehicleTypeCapacity>>,
              AsyncState<List<VehicleTypeCapacity>>>(
            bloc: _capacity,
            builder: (context, st) => _buildActions(st.data),
          ),
        ],
      ),
    );
  }

  Widget _buildLotDetails(List<VehicleTypeCapacity> items) {
    final available = items.fold<int>(0, (s, c) => s + c.available);
    final hasRoom = available > 0;
    final car = items.where((c) => c.isCar).firstOrNull;
    final user = _userLocation;
    final distance = user == null
        ? null
        : const Distance()
            .as(LengthUnit.Meter, user, PbmsFacility.location)
            .round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(PbmsFacility.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PbmsText.title),
            ),
            SizedBox(width: 5),
            Icon(Icons.verified_rounded, color: PbmsTokens.teal, size: 18),
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
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                distance == null
                    ? PbmsFacility.area
                    : '${PbmsFacility.area}, cách bạn ${distance >= 1000 ? '${(distance / 1000).toStringAsFixed(1)} km' : '$distance m'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PbmsText.caption,
              ),
            ),
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
                accent: (car?.available ?? 0) > 0
                    ? PbmsTokens.ok
                    : PbmsTokens.danger,
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
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: PbmsTokens.muted),
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
                  child: const Icon(Icons.expand_more_rounded,
                      size: 20, color: PbmsTokens.muted),
                ),
              ],
            ),
          ),
        ),
        if (_showDetails)
          for (final c in items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                  color: _surfaceLow, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(
                      c.isCar
                          ? Icons.directions_car_rounded
                          : Icons.two_wheeler_rounded,
                      size: 18,
                      color: PbmsTokens.teal),
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
                          color: c.available > 0
                              ? PbmsTokens.ok
                              : PbmsTokens.danger)),
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
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PbmsText.caption),
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
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
        ],
      ),
    );
  }

  Widget _buildActions(List<VehicleTypeCapacity>? items) {
    final car = items?.where((c) => c.isCar).firstOrNull;
    final canBook = car != null;
    return Row(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: IconButton(
            tooltip: 'Xem vị trí bãi đỗ trên bản đồ',
            onPressed: () => _mapController.move(PbmsFacility.location, 17),
            style: IconButton.styleFrom(
              foregroundColor: PbmsTokens.ink,
              side: const BorderSide(color: PbmsTokens.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
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
            onPressed: canBook ? _book : null,
          ),
        ),
      ],
    );
  }
}
