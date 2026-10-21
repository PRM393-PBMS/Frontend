import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_state.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/auth/domain/entities/user_entity.dart';

MonthlySubscriptionModel _pass(String status, DateTime end) =>
    MonthlySubscriptionModel.fromJson({
      'subscriptionId': 's1',
      'status': status,
      'startDate': end.subtract(const Duration(days: 30)).toIso8601String(),
      'endDate': end.toIso8601String(),
    });

ReservationModel _reservation(String status, DateTime entry) =>
    ReservationModel.fromJson({
      'reservationId': 'r1',
      'status': status,
      'expectedEntryTime': entry.toIso8601String(),
      'licensePlate': '51A-123.45',
      'depositAmount': 20000,
    });

UserEntity _user(String role) =>
    UserEntity(id: 'u', userName: 'u', email: 'u@x.vn', roleName: role);

class _FakeAuthRepository implements AuthRepository {
  final UserEntity user;
  int logouts = 0;

  _FakeAuthRepository(this.user);

  @override
  Future<UserEntity> login({required String email, required String password}) async => user;

  @override
  Future<UserEntity?> getCurrentUser() async => user;

  @override
  Future<void> logout() async => logouts++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();

  test('vé Active đã quá endDate là hết hạn, không còn hiệu lực', () {
    final pass = _pass('Active', now.subtract(const Duration(hours: 1)));
    expect(pass.isExpired, isTrue);
    expect(pass.isActive, isFalse);
    expect(StatusInfo.subscription(pass.displayStatus).label, 'Đã hết hạn');
  });

  test('vé Active còn hạn vẫn hiệu lực', () {
    final pass = _pass('Active', now.add(const Duration(days: 3)));
    expect(pass.isActive, isTrue);
    expect(pass.displayStatus, 'Active');
  });

  test('chỉ đơn Confirmed được đổi giờ, Modified thì không', () {
    final soon = now.add(const Duration(hours: 1));
    expect(_reservation('Confirmed', soon).canChangeTime, isTrue);
    expect(_reservation('Modified', soon).canChangeTime, isFalse);
    expect(_reservation('Pending', soon).canChangeTime, isFalse);
  });

  test('quá 30 phút sau giờ hẹn thì đặt chỗ hết hiệu lực', () {
    final late20 = _reservation('Confirmed', now.subtract(const Duration(minutes: 20)));
    final late40 = _reservation('Confirmed', now.subtract(const Duration(minutes: 40)));
    expect(late20.isUpcoming, isTrue);
    expect(late40.isUpcoming, isFalse);
    expect(late40.canModify, isFalse);
  });

  test('đặt chỗ đọc biển số và tiền cọc', () {
    final r = _reservation('Confirmed', now);
    expect(r.licensePlate, '51A-123.45');
    expect(r.depositAmount, 20000);
  });

  test('nhãn thân thiện cho lượt gửi Exception và sự cố Cancelled', () {
    expect(StatusInfo.session('Exception').label, 'Cần bãi xử lý');
    expect(StatusInfo.incident('Cancelled').label, 'Đã huỷ');
  });

  test('chỉ tài khoản khách là customer', () {
    expect(_user('customer').isCustomer, isTrue);
    for (final role in ['staff', 'manager', 'admin', 'Staff']) {
      expect(_user(role).isCustomer, isFalse, reason: role);
    }
  });

  test('nhân sự đăng nhập bị đăng xuất ngay và không vào app', () async {
    final repo = _FakeAuthRepository(_user('staff'));
    final bloc = AuthBloc(authRepository: repo)
      ..add(const AuthLoginSubmitted(email: 'staff', password: 'x'));
    final state = await bloc.stream.firstWhere((s) => s.status != AuthStatus.loading);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.staffAccountBlocked, isTrue);
    expect(repo.logouts, 1);
    await bloc.close();
  });

  test('phiên cũ của quản lý cũng bị từ chối khi mở app', () async {
    final repo = _FakeAuthRepository(_user('manager'));
    final bloc = AuthBloc(authRepository: repo)..add(AuthCheckRequested());
    final state = await bloc.stream.first;
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.staffAccountBlocked, isTrue);
    expect(repo.logouts, 1);
    await bloc.close();
  });

  test('khách đăng nhập bình thường', () async {
    final bloc = AuthBloc(authRepository: _FakeAuthRepository(_user('customer')))
      ..add(const AuthLoginSubmitted(email: 'kh', password: 'x'));
    final state = await bloc.stream.firstWhere((s) => s.status != AuthStatus.loading);
    expect(state.status, AuthStatus.authenticated);
    expect(state.staffAccountBlocked, isFalse);
    await bloc.close();
  });
}
