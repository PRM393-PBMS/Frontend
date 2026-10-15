import 'package:intl/intl.dart';

/// Định dạng thời gian theo tiếng Việt.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateTime = DateFormat('HH:mm · dd/MM/yyyy', 'vi');
  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'vi');
  static final DateFormat _time = DateFormat('HH:mm', 'vi');
  static final DateFormat _dayShort = DateFormat('EEE, dd/MM', 'vi');

  static String formatDateTime(DateTime? d) => d == null ? '--:--' : _dateTime.format(d);
  static String formatDate(DateTime? d) => d == null ? '--/--/----' : _date.format(d);
  static String formatTime(DateTime? d) => d == null ? '--:--' : _time.format(d);

  /// "Hôm nay", "Ngày mai", hoặc "T5, 16/10".
  static String formatDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    if (diff == -1) return 'Hôm qua';
    return _dayShort.format(d);
  }

  /// "Hôm nay 14:30".
  static String formatDayTime(DateTime d) => '${formatDay(d)} ${formatTime(d)}';

  /// Đồng hồ đỗ xe: "02:07" (giờ:phút) hoặc "1n 03:20" khi quá 24h.
  static String clock(Duration d) {
    final days = d.inDays;
    final h = d.inHours.remainder(24).toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return days > 0 ? '${days}n $h:$m' : '$h:$m';
  }

  /// "2 giờ 7 phút".
  static String humanDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '$m phút';
    if (m == 0) return '$h giờ';
    return '$h giờ $m phút';
  }

  /// "5 phút trước", "3 giờ trước", "12/10".
  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return _date.format(d);
  }
}
