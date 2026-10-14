import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Định dạng thời gian theo ngôn ngữ đang chọn (Intl.defaultLocale do LocaleController đặt).
class DateFormatter {
  DateFormatter._();

  static DateFormat get _date => DateFormat.yMd();
  static DateFormat get _time => DateFormat.Hm();
  static DateFormat get _dayMonth => DateFormat.Md();

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final local = dateTime.toLocal();
    return '${_time.format(local)}, ${_date.format(local)}';
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _date.format(dateTime.toLocal());
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return _time.format(dateTime.toLocal());
  }

  /// "Hôm nay 14:30", "Today 14:30", "今日 14:30"... hoặc giờ kèm ngày.
  static String formatRelativeDay(AppLocalizations t, DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final diff = DateTime(local.year, local.month, local.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final time = _time.format(local);
    if (diff == 0) return t.timeToday(time);
    if (diff == 1) return t.timeTomorrow(time);
    if (diff == -1) return t.timeYesterday(time);
    return t.timeOnDate(time, _dayMonth.format(local));
  }

  /// Nhãn nhóm ngày (Hôm nay / Ngày mai / ngày cụ thể), dùng cho bộ chọn giờ.
  static String dayLabel(AppLocalizations t, DateTime dateTime) {
    final full = formatRelativeDay(t, dateTime);
    final time = _time.format(dateTime.toLocal());
    final label = full.replaceAll(time, '').replaceAll(',', '').trim();
    return label.isEmpty ? formatDate(dateTime) : label;
  }

  static String formatDuration(AppLocalizations t, Duration duration) {
    final d = duration.isNegative ? Duration.zero : duration;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return t.durationDaysHours('$days', '$hours');
    if (hours > 0) return t.durationHoursMinutes('$hours', '$minutes');
    return t.durationMinutes('$minutes');
  }

  static String timeAgo(AppLocalizations t, DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inMinutes < 1) return t.agoJustNow;
    if (diff.inMinutes < 60) return t.agoMinutes(diff.inMinutes);
    if (diff.inHours < 24) return t.agoHours(diff.inHours);
    if (diff.inDays < 7) return t.agoDays(diff.inDays);
    return formatDate(dateTime);
  }
}
