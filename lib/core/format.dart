const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

/// 18 Oct 2026
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// 9:00 AM
String formatTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

/// Formats the weekday, day, month, and year.
String formatLongDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

/// 1234567 -> 1,234,567
String groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// Money is stored in centavos; 250000 -> ₱2,500
String formatPeso(int centavos) => '₱${groupThousands(centavos ~/ 100)}';

/// Builds up to two initials from the name.
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

String greeting(DateTime now) {
  if (now.hour < 12) return 'Magandang umaga';
  if (now.hour < 18) return 'Magandang hapon';
  return 'Magandang gabi';
}

String daysUntilLabel(DateTime from, DateTime to) {
  final days = DateTime(to.year, to.month, to.day)
      .difference(DateTime(from.year, from.month, from.day))
      .inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return '$days days';
}