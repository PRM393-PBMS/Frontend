import 'package:intl/intl.dart';

/// Định dạng thời gian vào/ra, đặt chỗ và hạn sử dụng vé xe
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateTimeFormat = DateFormat('HH:mm - dd/MM/yyyy');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--/--/----';
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return _timeFormat.format(dateTime.toLocal());
  }

  static String formatIso(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoString);
      return formatDateTime(dt);
    } catch (_) {
      return isoString;
    }
  }
}
