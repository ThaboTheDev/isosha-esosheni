import 'package:intl/intl.dart';

/// All display times are Africa/Johannesburg (UTC+2, no daylight saving)
/// with en-ZA formatting.
library;

class Dates {
  Dates._();

  static const String sastLocale = 'en_ZA';
  static const Duration sastOffset = Duration(hours: 2);

  static DateTime toSast(DateTime utcInstant) {
    final u = utcInstant.toUtc();
    return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second)
        .add(sastOffset);
  }

  static DateTime sastNow() => toSast(DateTime.now().toUtc());

  static String parse(String? iso) {
    final v = iso == null ? null : DateTime.tryParse(iso);
    return v == null ? '' : fmt(v);
  }

  static String fmt(DateTime utcInstant) {
    final d = toSast(utcInstant);
    return DateFormat('d MMM yyyy, HH:mm', sastLocale).format(d);
  }

  static String fmtDate(DateTime utcInstant) {
    final d = toSast(utcInstant);
    return DateFormat('d MMMM yyyy', sastLocale).format(d);
  }

  static String fmtTime(DateTime utcInstant) {
    final d = toSast(utcInstant);
    return DateFormat('HH:mm', sastLocale).format(d);
  }

  /// Chat day separators: "Today", "Yesterday", weekday + date otherwise.
  static String dayLabel(DateTime utcInstant, {DateTime? nowUtc}) {
    final now = toSast(nowUtc ?? DateTime.now().toUtc());
    final d = toSast(utcInstant);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Today';
    if (today.difference(day) == const Duration(days: 1)) return 'Yesterday';
    return DateFormat('EEEE, d MMMM', sastLocale).format(d);
  }

  /// "just now", "N min ago", "N h ago", "N d ago", else the date.
  static String timeAgo(DateTime utcInstant, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final t = utcInstant.toUtc();
    if (t.isAfter(now)) return 'just now';
    final secs = now.difference(t).inSeconds;
    if (secs < 60) return 'just now';
    final mins = secs ~/ 60;
    if (mins < 60) return '$mins min ago';
    final hours = mins ~/ 60;
    if (hours < 24) return '$hours h ago';
    final days = hours ~/ 24;
    if (days < 8) return '$days d ago';
    return DateFormat('d MMM yyyy', sastLocale).format(toSast(t));
  }

  /// List/row timestamps: time-of-day when today, else a short date.
  static String listStamp(DateTime utcInstant, {DateTime? nowUtc}) {
    final now = toSast(nowUtc ?? DateTime.now().toUtc());
    final d = toSast(utcInstant);
    if (DateTime(now.year, now.month, now.day) ==
        DateTime(d.year, d.month, d.day)) {
      return fmtTime(utcInstant);
    }
    return DateFormat('d MMM', sastLocale).format(d);
  }

  static String dateInput(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
