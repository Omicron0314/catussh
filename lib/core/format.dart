// Display formatting, ported from RXFormat.

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
    final parts = <String>[
      if (days > 0) '${days}d',
      if (hours > 0) '${hours}h',
      if (minutes > 0 || (days == 0 && hours == 0)) '${minutes}m',
    ];
    return parts.take(2).join(' ');
  }

  /// "Never", "Now", "5 minutes ago", "3 days ago".
  static String relative(DateTime date, {DateTime? now}) {
    now ??= DateTime.now();
    if (date.millisecondsSinceEpoch < 86400 * 365 * 1000) return 'Never';
    final diff = now.difference(date);
    final seconds = diff.inSeconds.abs();
    if (seconds < 60) return 'Now';
    String unit(int n, String name) => '$n $name${n == 1 ? '' : 's'}';
    final String amount;
    if (seconds < 3600) {
      amount = unit(seconds ~/ 60, 'minute');
    } else if (seconds < 86400) {
      amount = unit(seconds ~/ 3600, 'hour');
    } else if (seconds < 86400 * 7) {
      final days = seconds ~/ 86400;
      if (days == 1) return diff.isNegative ? 'tomorrow' : 'yesterday';
      amount = unit(days, 'day');
    } else if (seconds < 86400 * 30) {
      final weeks = seconds ~/ (86400 * 7);
      if (weeks == 1) return diff.isNegative ? 'next week' : 'last week';
      amount = unit(weeks, 'week');
    } else if (seconds < 86400 * 365) {
      final months = seconds ~/ (86400 * 30);
      if (months == 1) return diff.isNegative ? 'next month' : 'last month';
      amount = unit(months, 'month');
    } else {
      final years = seconds ~/ (86400 * 365);
      if (years == 1) return diff.isNegative ? 'next year' : 'last year';
      amount = unit(years, 'year');
    }
    return diff.isNegative ? 'in $amount' : '$amount ago';
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
