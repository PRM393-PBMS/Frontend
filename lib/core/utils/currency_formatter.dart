import 'package:intl/intl.dart';

/// Định dạng tiền VNĐ theo quy ước số của ngôn ngữ đang chọn (25.000 ₫ / ₫25,000).
class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(num amount) =>
      NumberFormat.currency(symbol: '₫', decimalDigits: 0).format(amount);
}
