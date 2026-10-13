class MockParkingLot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final int availableSlots;
  final int totalSlots;

  const MockParkingLot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.availableSlots,
    required this.totalSlots,
  });
}

// Sample mock data simulating backend response
final List<MockParkingLot> mockParkingLots = [
  const MockParkingLot(
    id: 'p1',
    name: 'Bãi đỗ trung tâm Sài Gòn',
    latitude: 10.7769, // Approximate location in HCM City center
    longitude: 106.7009,
    pricePerHour: 45000,
    availableSlots: 15,
    totalSlots: 100,
  ),
  const MockParkingLot(
    id: 'p2',
    name: 'Bãi đỗ ven sông Sài Gòn',
    latitude: 10.7735,
    longitude: 106.7050,
    pricePerHour: 30000,
    availableSlots: 42,
    totalSlots: 200,
  ),
  const MockParkingLot(
    id: 'p3',
    name: 'Bãi đỗ đường Nguyễn Huệ',
    latitude: 10.7800,
    longitude: 106.6980,
    pricePerHour: 50000,
    availableSlots: 3,
    totalSlots: 50,
  ),
];
