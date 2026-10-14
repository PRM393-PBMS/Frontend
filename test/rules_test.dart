import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/utils/validators.dart';
import 'package:prm393_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:prm393_frontend/features/reservations/data/reservation_repository.dart';
import 'package:prm393_frontend/features/reservations/presentation/time_slot_picker.dart';
import 'package:prm393_frontend/l10n/app_localizations.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('vi'));

  group('Validators khớp backend', () {
    test('số điện thoại theo regex backend', () {
      expect(Validators.phone(t, '0912345678'), isNull);
      expect(Validators.phone(t, '+84912345678'), isNull);
      expect(Validators.phone(t, '0212345678'), isNotNull);
      expect(Validators.phone(t, '', optional: true), isNull);
    });

    test('biển số chuẩn hoá về A-Z0-9, 4-15 ký tự', () {
      expect(Validators.normalizePlate(' 51h-123.45 '), '51H12345');
      expect(Validators.plate(t, '51H-123.45'), isNull);
      expect(Validators.plate(t, '5A'), isNotNull);
    });

    test('OTP gồm 6 chữ số', () {
      expect(Validators.otp(t, '482917'), isNull);
      expect(Validators.otp(t, '48291'), isNotNull);
      expect(Validators.otp(t, '48291a'), isNotNull);
    });
  });

  group('Khung giờ đặt chỗ', () {
    test('mốc 15 phút, trong khoảng 15 phút đến 5 tiếng', () {
      final now = DateTime(2026, 10, 15, 9, 7);
      final slots = buildTimeSlots(now: now);
      expect(slots.first, DateTime(2026, 10, 15, 9, 30));
      expect(slots.last.isBefore(now.add(const Duration(hours: 5))), isTrue);
      expect(slots.every((s) => s.minute % 15 == 0), isTrue);
    });
  });

  group('Quy tắc đặt chỗ', () {
    Reservation r(String status, Duration fromNow) => Reservation(
          id: 'x',
          vehicleTypeName: 'Ô tô',
          expectedEntryTime: DateTime.now().add(fromNow),
          status: status,
          createdAt: null,
          ticket: null,
        );

    test('chỉ Confirmed và trước giờ hẹn >= 15 phút mới được đổi giờ', () {
      expect(r('Confirmed', const Duration(hours: 1)).canChangeTime, isTrue);
      expect(
          r('Confirmed', const Duration(minutes: 10)).canChangeTime, isFalse);
      expect(r('Modified', const Duration(hours: 1)).canChangeTime, isFalse);
      expect(r('Pending', const Duration(hours: 1)).canChangeTime, isFalse);
    });

    test('không hủy được khi đã vào bãi', () {
      expect(r('CheckedIn', Duration.zero).canCancel, isFalse);
      expect(r('Pending', const Duration(hours: 1)).canCancel, isTrue);
    });
  });

  group('Phân vai trò', () {
    UserEntity u(String role) =>
        UserEntity(id: '1', userName: 'a', email: 'a@b.c', roleName: role);

    test('Staff và Manager vào khu nhân viên, User/Customer vào khu khách', () {
      expect(u('Staff').isStaff, isTrue);
      expect(u('Manager').isStaff, isTrue);
      expect(u('User').isCustomer, isTrue);
      expect(u('Customer').isCustomer, isTrue);
      expect(u('Admin').isSupported, isFalse);
    });
  });
}
