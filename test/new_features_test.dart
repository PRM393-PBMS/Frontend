import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/config/app_config.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/media_url.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/promo_carousel.dart';
import 'package:prm393_frontend/features/legal/legal_documents.dart';
import 'package:prm393_frontend/features/legal/legal_screen.dart';
import 'package:prm393_frontend/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:prm393_frontend/features/profile/presentation/widgets/delete_account_sheet.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/pass_sheets.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('Mã QR gửi xe 1 lần', () {
    Map<String, dynamic> json({String status = 'Active', Duration left = const Duration(hours: 5), bool qr = true}) => {
          'entryPassId': 'p1',
          'code': 'AB23CD',
          'status': status,
          'licensePlate': '51H12345',
          'vehicleName': 'Xe của mẹ',
          'vehicleTypeName': 'Ô tô',
          'createdAt': DateTime.now().toIso8601String(),
          'expiresAt': DateTime.now().add(left).toIso8601String(),
          'qrPayload': qr ? 'PBMS-ENTRY:p1:AB23CD' : null,
        };

    test('mã còn hạn và có QR thì dùng được', () {
      final p = EntryPassModel.fromJson(json());
      expect(p.isActive, isTrue);
      expect(p.vehicleName, 'Xe của mẹ');
      expect(p.isMotorbike, isFalse);
    });

    test('đã dùng, hết hạn hoặc không có QR thì không còn dùng được', () {
      expect(EntryPassModel.fromJson(json(status: 'Used', qr: false)).isActive, isFalse);
      expect(EntryPassModel.fromJson(json(left: const Duration(minutes: -1))).isActive, isFalse);
      expect(EntryPassModel.fromJson(json(qr: false)).isActive, isFalse);
    });
  });

  group('Xe có tên và mẫu', () {
    test('có tên tự đặt: tên lên trước, biển số xuống dòng phụ', () {
      final v = VehicleModel.fromJson({
        'vehicleId': 'v1',
        'vehicleTypeName': 'Ô tô',
        'licensePlate': '51H12345',
        'nickname': 'Xe của mẹ',
        'modelName': 'Toyota Vios',
      });
      expect(v.displayName, 'Xe của mẹ');
      expect(v.details, '51H12345, Toyota Vios, Ô tô');
    });

    test('máy chủ cũ / chuỗi rỗng: dùng biển số làm tên', () {
      final v = VehicleModel.fromJson({
        'vehicleId': 'v1',
        'vehicleTypeName': 'Xe máy',
        'licensePlate': '59A12345',
        'nickname': '  ',
      });
      expect(v.nickname, isNull);
      expect(v.displayName, '59A12345');
      expect(v.details, 'Xe máy');
    });
  });

  group('Vé theo bãi', () {
    test('gói mọi bãi không cần ô cố định', () {
      final pkg = SubscriptionPackageModel.fromJson({
        'packageId': 'k1',
        'packageName': 'Gói tháng mọi bãi ô tô',
        'vehicleTypeName': 'Ô tô',
        'requireFixedSlot': true,
        'allParkings': true,
      });
      expect(pkg.allParkings, isTrue);
      expect(pkg.needsFixedSlot, isFalse);
    });

    test('máy chủ cũ không có allParkings: coi là gói một bãi', () {
      final pkg = SubscriptionPackageModel.fromJson({
        'packageId': 'k2',
        'packageName': 'Gói tháng ô tô',
        'vehicleTypeName': 'Ô tô',
        'requireFixedSlot': true,
      });
      expect(pkg.allParkings, isFalse);
      expect(pkg.needsFixedSlot, isTrue);
    });

    test('vé đọc tên bãi áp dụng', () {
      final s = MonthlySubscriptionModel.fromJson({
        'subscriptionId': 's1',
        'licensePlate': '51H12345',
        'vehicleType': 'Ô tô',
        'packageName': 'Gói tháng ô tô',
        'price': 1500000,
        'status': 'Active',
        'parkingName': 'Bãi đỗ trung tâm',
      });
      expect(s.parkingName, 'Bãi đỗ trung tâm');
      expect(s.allParkings, isFalse);
    });
  });

  test('máy chủ chưa có thông báo: trang rỗng, đánh dấu không khả dụng', () {
    expect(NotificationPage.unavailable.available, isFalse);
    expect(NotificationPage.fromJson({'items': [], 'unreadCount': 0}).available, isTrue);
  });

  group('resolveMediaUrl', () {
    final host = Uri.parse(AppConfig.baseUrl).host;

    test('đường dẫn tương đối ghép với máy chủ', () {
      expect(resolveMediaUrl('/uploads/avatars/a.jpg'), '${AppConfig.baseUrl}/uploads/avatars/a.jpg');
    });

    test('máy chủ trả http cho chính nó thì đổi sang https', () {
      expect(resolveMediaUrl('http://$host/uploads/a.jpg'), 'https://$host/uploads/a.jpg');
    });

    test('host khác giữ nguyên, rỗng thì null', () {
      expect(resolveMediaUrl('http://example.com/a.jpg'), 'http://example.com/a.jpg');
      expect(resolveMediaUrl(''), isNull);
      expect(resolveMediaUrl(null), isNull);
    });
  });

  group('Điều khoản và chính sách', () {
    test('có phiên bản, ngày hiệu lực và nội dung chính', () {
      for (final d in [termsOfService, privacyPolicy]) {
        expect(d.version, isNotEmpty);
        expect(d.effectiveDate, isNotEmpty);
        expect(d.sections.length, greaterThanOrEqualTo(8));
        expect(d.sections.every((s) => s.paragraphs.isNotEmpty || s.bullets.isNotEmpty), isTrue);
      }
      String all(LegalDocument d) =>
          d.sections.expand((s) => [s.heading, ...s.paragraphs, ...s.bullets]).join('\n');
      expect(all(termsOfService), contains('24 giờ'));
      expect(all(privacyPolicy), contains('PayOS'));
      expect(all(privacyPolicy), contains('Plate Recognizer'));
    });

    testWidgets('chạm "Chính sách bảo mật" mở trang chính sách', (tester) async {
      await tester.pumpWidget(_app(const LegalLinks()));
      await tester.tap(find.text('Chính sách bảo mật'));
      await tester.pumpAndSettle();
      expect(find.text(privacyPolicy.title), findsOneWidget);
      expect(find.text(privacyPolicy.sections.first.heading), findsOneWidget);
    });
  });

  testWidgets('băng quảng cáo: hiện ảnh đầu, chạm gọi đúng hành động', (tester) async {
    var tapped = '';
    await tester.pumpWidget(_app(PromoCarousel(items: [
      PromoItem(
        image: 'assets/images/promo/reserve.jpg',
        title: 'Giữ chỗ ô tô',
        subtitle: 's',
        action: 'Đặt chỗ',
        onTap: () => tapped = 'reserve',
      ),
      PromoItem(
        image: 'assets/images/promo/wallet.jpg',
        title: 'Nạp ví',
        subtitle: 's',
        action: 'Nạp ví',
        onTap: () => tapped = 'wallet',
      ),
    ])));
    await tester.pump();
    expect(find.text('Giữ chỗ ô tô'), findsOneWidget);
    await tester.tap(find.byType(InkWell).first);
    expect(tapped, 'reserve');
  });

  testWidgets('chọn ô cố định qua hộp thoại', (tester) async {
    final slots = AsyncCubit<List<ParkingSlotModel>>(() async => [
          for (final code in ['B2-C01', 'B2-C02'])
            ParkingSlotModel.fromJson({
              'slotId': code,
              'floorName': 'Tầng B2',
              'slotCode': code,
              'status': 'Available',
              'isResident': true,
            }),
        ]);
    String? chosen;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) => FixedSlotPicker(
        slots: slots,
        selectedId: chosen,
        onSelected: (id) => setState(() => chosen = id),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Chọn ô đỗ'), findsOneWidget);
    await tester.tap(find.text('Chọn ô đỗ'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn ô đỗ cố định'), findsOneWidget);
    await tester.tap(find.text('B2-C02'));
    await tester.pumpAndSettle();
    expect(chosen, 'B2-C02');
    expect(find.text('Ô B2-C02'), findsOneWidget);
    await slots.close();
  });

  testWidgets('đổi mật khẩu: kiểm tra mật khẩu mới trước khi gửi', (tester) async {
    await tester.pumpWidget(_app(const ChangePasswordSheet()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'matkhaucu');
    await tester.enterText(fields.at(1), '123');
    await tester.enterText(fields.at(2), '456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu').last);
    await tester.pump();
    expect(find.text('Mật khẩu mới tối thiểu 6 ký tự'), findsOneWidget);
    expect(find.text('Mật khẩu nhập lại không khớp'), findsOneWidget);
  });

  testWidgets('xoá tài khoản: chỉ bấm được sau khi xác nhận', (tester) async {
    await tester.pumpWidget(_app(const DeleteAccountSheet()));
    FilledButton button() => tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });
}
