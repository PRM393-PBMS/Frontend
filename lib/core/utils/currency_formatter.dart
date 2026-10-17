import 'package:intl/intl.dart';

/// Định dạng tiền VNĐ: "35.000 ₫".
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _plain = NumberFormat.decimalPattern('vi_VN');

  static String format(num amount) => _formatter.format(amount);

  /// Chỉ phần số, dùng khi đơn vị hiển thị tách riêng.
  static String number(num amount) => _plain.format(amount);
}
