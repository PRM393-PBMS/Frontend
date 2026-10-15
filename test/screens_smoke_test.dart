import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/storage/secure_storage_service.dart';
import 'package:prm393_frontend/core/theme/app_theme.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:prm393_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/home/home_screen.dart';
import 'package:prm393_frontend/features/pass/monthly_pass_screen.dart';
import 'package:prm393_frontend/features/reserve/reserve_screen.dart';
import 'package:prm393_frontend/features/sessions/sessions_screen.dart';

class _FakeRepo extends PbmsRepository {
  _FakeRepo() : super(apiClient: ApiClient(storageService: SecureStorageService()));

  final now = DateTime.now();

  @override
  Future<List<ParkingSessionModel>> getMySessions() async => [
        ParkingSessionModel(
          sessionId: 's1',
          licensePlateIn: '51K12345',
          entryTime: now.subtract(const Duration(hours: 2, minutes: 7)),
          entryGateName: 'Cổng vào A',
          actualSlotCode: 'B2-C07',
          status: 'Active',
          ticket: const TicketModel(qrPayload: 's1'),
        ),
        ParkingSessionModel(
          sessionId: 's2',
          licensePlateIn: '51K12345',
          entryTime: now.subtract(const Duration(days: 1, hours: 4)),
          exitTime: now.subtract(const Duration(days: 1, hours: 1)),
          status: 'Completed',
          paymentAmount: 20000,
          paymentStatus: 'Success',
        ),
      ];

  @override
  Future<List<ReservationModel>> getMyReservations() async => [
        ReservationModel(
          reservationId: 'r1',
          vehicleTypeName: 'Ô tô',
          expectedEntryTime: now.add(const Duration(hours: 2)),
          status: 'Confirmed',
          ticket: const TicketModel(qrPayload: 'r1'),
        ),
        ReservationModel(
          reservationId: 'r2',
          vehicleTypeName: 'Ô tô',
          expectedEntryTime: now.add(const Duration(hours: 4)),
          status: 'Pending',
        ),
      ];

  @override
  Future<List<FacilityAvailabilityModel>> getAvailability({String? vehicleTypeId}) async => const [
        FacilityAvailabilityModel(
          floorId: 'f1',
          floorName: 'Tầng B1',
          vehicleTypeId: 'm',
          vehicleTypeName: 'Xe máy',
          totalSlots: 50,
          availableSlots: 0,
          occupiedSlots: 50,
          assignedSlots: 0,
        ),
        FacilityAvailabilityModel(
          floorId: 'f2',
          floorName: 'Tầng B2',
          vehicleTypeId: 'c',
          vehicleTypeName: 'Ô tô',
          totalSlots: 30,
          availableSlots: 4,
          occupiedSlots: 26,
          assignedSlots: 0,
        ),
      ];

  @override
  Future<List<PricingPolicyModel>> getPricingPolicies() async => const [
        PricingPolicyModel(
          policyId: 'p1',
          vehicleTypeId: 'c',
          vehicleTypeName: 'Ô tô',
          basePrice: 10000,
          baseHours: 1,
          extraHourPrice: 5000,
          nightSurcharge: 3000,
          status: 'Active',
        ),
      ];

  @override
  Future<List<MonthlySubscriptionModel>> getMySubscriptions() async => [
        MonthlySubscriptionModel(
          subscriptionId: 'sub1',
          licensePlate: '30A99999',
          vehicleType: 'Ô tô',
          packageName: 'Gói tháng ô tô có ô cố định dài tên',
          startDate: now.subtract(const Duration(days: 27)),
          endDate: now.add(const Duration(days: 3)),
          price: 1500000,
          status: 'Active',
          fixedSlot: 'B2-A01',
        ),
        const MonthlySubscriptionModel(
          subscriptionId: 'sub2',
          licensePlate: '59X312345',
          vehicleType: 'Xe máy',
          packageName: 'Gói tháng xe máy',
          price: 300000,
          status: 'PendingPayment',
        ),
      ];

  @override
  Future<List<SubscriptionPackageModel>> getSubscriptionPackages() async => const [
        SubscriptionPackageModel(
          packageId: 'k1',
          packageName: 'Gói tháng ô tô',
          vehicleTypeId: 'c',
          vehicleTypeName: 'Ô tô',
          durationMonths: 3,
          price: 4200000,
          requireFixedSlot: true,
          status: 'Active',
        ),
      ];

  @override
  Future<List<VehicleChangeRequestModel>> getMyVehicleChangeRequests() async => const [
        VehicleChangeRequestModel(
          requestId: 'v1',
          subscriptionId: 'sub1',
          oldLicensePlate: '30A99999',
          newLicensePlate: '30A88888',
          status: 'Pending',
        ),
      ];

  @override
  Future<NotificationPage> getNotifications() async =>
      const NotificationPage(items: [], unreadCount: 3);
}

class _FakeAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    AppTypography.useGoogleFonts = false;
    await initializeDateFormatting('vi');
  });

  final screens = <String, Widget>{
    'home': const HomeScreen(),
    'reserve': const ReserveScreen(),
    'sessions': const SessionsScreen(),
    'pass': const MonthlyPassScreen(),
  };

  for (final dark in [false, true]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} hiển thị không tràn ở 360dp (${dark ? 'tối' : 'sáng'})', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 780 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final auth = AuthBloc(authRepository: _FakeAuth());
        auth.add(const AuthProfileUpdated(UserEntity(
          id: 'u1',
          userName: 'khoatran',
          email: 'khoa@example.com',
          fullName: 'Trần Minh Khoa',
          roleName: 'User',
        )));

        await tester.pumpWidget(
          RepositoryProvider<PbmsRepository>.value(
            value: _FakeRepo(),
            child: BlocProvider<AuthBloc>.value(
              value: auth,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                locale: const Locale('vi'),
                supportedLocales: const [Locale('vi')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: entry.value,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Lỗi bố cục (tràn RenderFlex…) sẽ được flutter_test báo là test thất bại.
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await auth.close();
      });
    }
  }
}
