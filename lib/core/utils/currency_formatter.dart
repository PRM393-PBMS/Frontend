import 'package:intl/intl.dart';

/// Định dạng tiền tệ VNĐ cho các chi phí đỗ xe, đặt cọc và gói tháng
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String format(num amount) {
    return _formatter.format(amount);
  }
}
