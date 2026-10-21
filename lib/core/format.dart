// Display formatting, ported from RXFormat.

import 'strings.dart';

class RXFormat {
  static String percent(double value) =>
      value.isFinite ? value.round().toString() : '0';

  static String oneDecimal(double value) =>
      value.isFinite ? value.toStringAsFixed(1) : '0';

  /// Decimal units (1000), like the Swift app.
  static (String, String) bytes(double bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var value = bytes.isFinite ? (bytes < 0 ? 0.0 : bytes) : 0.0;
    var index = 0;
    while (value >= 1000 && index < units.length - 1) {
      value /= 1000;
      index += 1;
    }
    if (index == 0 || value >= 100) return ('${value.round()}', units[index]);
    return (value.toStringAsFixed(1), units[index]);
  }

  static String bytesString(double value) {
    final (v, u) = bytes(value);
    return '$v $u';
  }

  static (String, String) rate(double bytesPerSecond) {
    final (v, u) = bytes(bytesPerSecond);
    return (v, '$u/s');
  }

  static String rateString(double bytesPerSecond) {
    final (v, u) = rate(bytesPerSecond);
    return '$v $u';
  }

  /// "3d 4h", "5h 12m", "7m": at most two units, like DateComponentsFormatter.
  static String duration(double seconds) {
    if (!seconds.isFinite || seconds <= 0) return '—';
    final total = seconds ~/ 60;
    final days = total ~/ (24 * 60);
    final hours = (total ~/ 60) % 24;
    final minutes = total % 60;
    if (days > 0) return S.l.durationDaysHours(days, hours);
    if (hours > 0) return S.l.durationHoursMinutes(hours, minutes);
    return S.l.durationMinutes(minutes);
  }

  /// "Never", "Now", "5 minutes ago", "3 days ago"; localized.
  static String relative(DateTime date, {DateTime? now}) {
    now ??= DateTime.now();
    if (date.millisecondsSinceEpoch < 86400 * 365 * 1000) return S.l.never;
    final diff = now.difference(date);
    final seconds = diff.inSeconds.abs();
    if (seconds < 60) return S.l.now;
    final future = diff.isNegative;
    if (seconds < 3600) {
      final n = seconds ~/ 60;
      return future ? S.l.inMinutes(n) : S.l.minutesAgo(n);
    } else if (seconds < 86400) {
      final n = seconds ~/ 3600;
      return future ? S.l.inHours(n) : S.l.hoursAgo(n);
    } else if (seconds < 86400 * 365) {
      final n = seconds ~/ 86400;
      return future ? S.l.inDays(n) : S.l.daysAgo(n);
    }
    final n = seconds ~/ (86400 * 365);
    return future ? S.l.inDays(n * 365) : S.l.yearsAgo(n);
  }

  /// File sizes in the Files table: binary units, like Finder's "1.2 MB".
  static String fileSize(int? bytes) {
    if (bytes == null) return '—';
    return bytesString(bytes.toDouble());
  }

  static String dateTime(DateTime? date) {
    if (date == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
