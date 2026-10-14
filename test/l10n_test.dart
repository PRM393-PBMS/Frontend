import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/utils/status_labels.dart';
import 'package:prm393_frontend/core/utils/validators.dart';
import 'package:prm393_frontend/l10n/app_localizations.dart';

Map<String, dynamic> arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> keys(Map<String, dynamic> m) =>
    m.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  test('vi / en / ja có đúng cùng một bộ khóa, không chuỗi rỗng', () {
    final vi = arb('vi'), en = arb('en'), ja = arb('ja');
    expect(keys(en), keys(vi));
    expect(keys(ja), keys(vi));
    for (final m in [vi, en, ja]) {
      for (final k in keys(m)) {
        expect((m[k] as String).trim(), isNotEmpty,
            reason: '${m['@@locale']}.$k rỗng');
      }
    }
  });

  test('bản dịch không chứa dấu gạch dài (em/en dash)', () {
    for (final l in ['vi', 'en', 'ja']) {
      for (final v in keys(arb(l)).map((k) => arb(l)[k] as String)) {
        expect(v.contains('—') || v.contains('–'), isFalse, reason: '$l: $v');
      }
    }
  });

  test('validator và nhãn trạng thái trả về đúng ngôn ngữ', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final en = lookupAppLocalizations(const Locale('en'));
    final ja = lookupAppLocalizations(const Locale('ja'));
    expect(Validators.otp(vi, '1'), 'Mã OTP gồm 6 chữ số');
    expect(Validators.otp(en, '1'), 'The code has 6 digits');
    expect(Validators.otp(ja, '1'), '認証コードは6桁の数字です');
    expect(StatusLabels.reservation(en, 'Confirmed').label, 'Confirmed');
    expect(StatusLabels.reservation(ja, 'Confirmed').label, '確定');
    expect(en.passDaysLeft(1), '1 day left');
    expect(en.passDaysLeft(3), '3 days left');
    expect(ja.homeEnteredAt('10:00', 'Cổng A'), '10:00 に Cổng A から入庫');
    expect(en.dateRange('a', 'b'), 'a to b');
  });
}
