import '../../l10n/app_localizations.dart';

/// Validator form, khớp quy tắc phía backend PBMS. Thông điệp theo ngôn ngữ đang chọn.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  // Backend: /^(0|\+84)(3|5|7|8|9)[0-9]{8}$/
  static final RegExp _phone = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
  // Backend chuẩn hoá biển số về A-Z0-9, độ dài 4-15.
  static final RegExp _plate = RegExp(r'^[A-Z0-9]{4,15}$');

  static String normalizePlate(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String? required(AppLocalizations t, String? value, String field) {
    if (value == null || value.trim().isEmpty) return t.vRequired(field);
    return null;
  }

  static String? email(AppLocalizations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.vEmailRequired;
    if (!_email.hasMatch(v)) return t.vEmailInvalid;
    if (v.length > 100) return t.vMaxLength(t.fieldEmail, '100');
    return null;
  }

  static String? phone(AppLocalizations t, String? value,
      {bool optional = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return optional ? null : t.vPhoneRequired;
    if (!_phone.hasMatch(v)) return t.vPhoneInvalid;
    return null;
  }

  static String? userName(AppLocalizations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.vUserNameRequired;
    if (v.length > 50) return t.vMaxLength(t.fieldUserName, '50');
    return null;
  }

  static String? fullName(AppLocalizations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.vFullNameRequired;
    if (v.length > 100) return t.vMaxLength(t.fieldFullName, '100');
    return null;
  }

  static String? password(AppLocalizations t, String? value) {
    if ((value ?? '').isEmpty) return t.vPasswordRequired;
    return null;
  }

  static String? confirmPassword(
      AppLocalizations t, String? value, String original) {
    if (value == null || value.isEmpty) return t.vConfirmRequired;
    if (value != original) return t.vConfirmMismatch;
    return null;
  }

  static String? otp(AppLocalizations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.length != 6 || int.tryParse(v) == null) return t.vOtpInvalid;
    return null;
  }

  static String? plate(AppLocalizations t, String? value) {
    final v = normalizePlate(value ?? '');
    if (v.isEmpty) return t.vPlateRequired;
    if (!_plate.hasMatch(v)) return t.vPlateInvalid;
    return null;
  }

  static String? maxLength(
      AppLocalizations t, String? value, int max, String field) {
    if ((value ?? '').trim().length > max) return t.vMaxLength(field, '$max');
    return null;
  }
}
