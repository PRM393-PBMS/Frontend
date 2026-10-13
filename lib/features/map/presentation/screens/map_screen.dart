import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import '../../data/models/mock_parking_lot.dart';
import '../widgets/parking_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(10.7769, 106.7009); // HCM City
  String? _selectedLotId;

  void _showParkingDetails(MockParkingLot lot) {
    setState(() {
      _selectedLotId = lot.id;
    });

    // Pan to marker
    _mapController.move(LatLng(lot.latitude, lot.longitude), 16.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParkingBottomSheet(parkingLot: lot),
    ).whenComplete(() {
      setState(() {
        _selectedLotId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm bãi đỗ'),
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 14.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.prm393_frontend',
          ),
          MarkerLayer(
            markers: mockParkingLots.map((lot) {
              final isSelected = lot.id == _selectedLotId;
              return Marker(
                point: LatLng(lot.latitude, lot.longitude),
                width: 48, // Minimum touch target 48x48
                height: 48,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => _showParkingDetails(lot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_parking_rounded,
                        color: isSelected ? Colors.white : AppColors.primary,
                        size: isSelected ? 28 : 24,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(_initialCenter, 14.0);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location_rounded, color: Colors.white),
      ),
    );
  }
}
