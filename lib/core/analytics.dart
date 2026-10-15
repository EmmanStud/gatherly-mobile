import '../models/models.dart';

enum RevenuePeriod { day, week, month }

class RevenueBucket {
  const RevenueBucket({
    required this.key,
    required this.label,
    required this.amountCents,
  });

  final String key;
  final String label;
  final int amountCents;
}

List<RevenueBucket> buildRevenueBuckets({
  required Iterable<Order> orders,
  required RevenuePeriod period,
  required DateTime now,
}) {
  final manilaNow = _manilaWallTime(now);
  final today = DateTime.utc(manilaNow.year, manilaNow.month, manilaNow.day);
  final buckets = switch (period) {
    RevenuePeriod.day => List.generate(24, (hour) {
      final time = today.add(Duration(hours: hour));
      final key = '${_dateKey(time)}T${hour.toString().padLeft(2, '0')}';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return RevenueBucket(
        key: key,
        label: '$displayHour ${hour < 12 ? 'AM' : 'PM'}',
        amountCents: 0,
      );
    }),
    RevenuePeriod.week => List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return RevenueBucket(
        key: _dateKey(date),
        label: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][
          date.weekday - 1
        ],
        amountCents: 0,
      );
    }),
    RevenuePeriod.month => _monthBuckets(today),
  };

  final bucketIndex = {
    for (var index = 0; index < buckets.length; index++)
      buckets[index].key: index,
  };
  final totals = List<int>.filled(buckets.length, 0);
  for (final order in orders) {
    if (order.status != 'Paid' || order.paidAt == null) continue;
    final paidAt = _manilaWallTime(order.paidAt!);
    if (period == RevenuePeriod.month &&
        (paidAt.year != manilaNow.year || paidAt.month != manilaNow.month)) {
      continue;
    }
    final key = switch (period) {
      RevenuePeriod.day =>
        '${_dateKey(DateTime.utc(paidAt.year, paidAt.month, paidAt.day))}T${paidAt.hour.toString().padLeft(2, '0')}',
      RevenuePeriod.week =>
        _dateKey(DateTime.utc(paidAt.year, paidAt.month, paidAt.day)),
      RevenuePeriod.month => _monthWeekKey(paidAt),
    };
    final index = bucketIndex[key];
    if (index != null) totals[index] += order.amountCents;
  }
  return [
    for (var index = 0; index < buckets.length; index++)
      RevenueBucket(
        key: buckets[index].key,
        label: buckets[index].label,
        amountCents: totals[index],
      ),
  ];
}

DateTime _manilaWallTime(DateTime value) =>
    value.toUtc().add(const Duration(hours: 8));

List<RevenueBucket> _monthBuckets(DateTime today) {
  final first = DateTime.utc(today.year, today.month);
  final last = DateTime.utc(today.year, today.month + 1, 0);
  final mondayOffset = first.weekday - DateTime.monday;
  var weekStart = first.subtract(Duration(days: mondayOffset));
  final buckets = <RevenueBucket>[];
  while (!weekStart.isAfter(last)) {
    final visibleStart = weekStart.isBefore(first) ? first : weekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final visibleEnd = weekEnd.isAfter(last) ? last : weekEnd;
    buckets.add(RevenueBucket(
      key: _dateKey(weekStart),
      label: '${visibleStart.day}–${visibleEnd.day}',
      amountCents: 0,
    ));
    weekStart = weekStart.add(const Duration(days: 7));
  }
  return buckets;
}

String _monthWeekKey(DateTime manilaDate) {
  final day = DateTime.utc(manilaDate.year, manilaDate.month, manilaDate.day);
  final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
  return _dateKey(monday);
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
