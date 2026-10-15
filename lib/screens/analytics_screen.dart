import 'package:flutter/material.dart';

import '../core/analytics.dart';
import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AnalyticsPanel extends StatefulWidget {
  const AnalyticsPanel({super.key});

  @override
  State<AnalyticsPanel> createState() => _AnalyticsPanelState();
}

class _AnalyticsPanelState extends State<AnalyticsPanel> {
  RevenuePeriod _period = RevenuePeriod.week;
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final publishedEvents = state.events
        .where((event) => event.status == EventStatus.onSale)
        .toList();
    final selectedEvent = publishedEvents
        .where((event) => event.id == _selectedEventId)
        .firstOrNull;
    final scopedEvents = selectedEvent == null
        ? publishedEvents
        : [selectedEvent];
    final eventIds = scopedEvents.map((event) => event.id).toSet();
    final eventCodes = scopedEvents
        .map((event) => event.eventCode)
        .where((code) => code.isNotEmpty)
        .toSet();

    bool belongsToEvent(String eventId, String eventCode) =>
        eventIds.contains(eventId) ||
        (eventCode.isNotEmpty && eventCodes.contains(eventCode));

    final paidOrders = state.orders
        .where(
          (order) =>
              order.status == 'Paid' &&
              belongsToEvent(order.eventId, order.eventCode),
        )
        .toList();
    final revenueBuckets = buildRevenueBuckets(
      orders: paidOrders,
      period: _period,
      now: DateTime.now(),
    );
    final revenueTotal = revenueBuckets.fold<int>(
      0,
      (total, bucket) => total + bucket.amountCents,
    );
    final attendees = state.attendees
        .where(
          (attendee) => belongsToEvent(attendee.eventId, attendee.eventCode),
        )
        .toList();
    final checkedIn = attendees.where((attendee) => attendee.checkedIn).length;
    final unchecked = attendees.length - checkedIn;
    final rangeTitle = switch (_period) {
      RevenuePeriod.day => 'Today · Manila time',
      RevenuePeriod.week => 'Last 7 days · Manila time',
      RevenuePeriod.month => 'Current month · Manila time',
    };

    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelTitle(
            'Analytics',
            'Ticket sales, paid revenue, and attendee check-in.',
          ),
          const SizedBox(height: 18),
          if (state.dataError != null)
            _InlineNotice(
              message: state.dataError!,
              actionLabel: 'Retry',
              onAction: state.loadOrganizerData,
            ),
          if (state.isLoadingData &&
              state.events.isEmpty &&
              state.orders.isEmpty &&
              state.attendees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _EventTabs(
              events: publishedEvents,
              selectedId: selectedEvent?.id,
              onSelected: (id) => setState(() => _selectedEventId = id),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Ticket performance',
              subtitle: selectedEvent == null
                  ? 'Tickets sold against total capacity for each published event.'
                  : 'Ticket sales for ${selectedEvent.name}.',
              child: scopedEvents.isEmpty
                  ? const _EmptyMessage(
                      'Publish an event to see ticket performance.',
                    )
                  : Column(
                      children: [
                        for (final event in scopedEvents)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${event.percent}% · ${event.sold}/${event.total}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                ProgressBar(value: event.fill, height: 11),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Paid revenue',
              subtitle: rangeTitle,
              trailing: DropdownButton<RevenuePeriod>(
                value: _period,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(
                    value: RevenuePeriod.day,
                    child: Text('Day'),
                  ),
                  DropdownMenuItem(
                    value: RevenuePeriod.week,
                    child: Text('Week'),
                  ),
                  DropdownMenuItem(
                    value: RevenuePeriod.month,
                    child: Text('Month'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _period = value);
                },
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    formatPesoExact(revenueTotal),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (revenueTotal == 0)
                    const _EmptyMessage(
                      'No paid revenue recorded for this period.',
                    )
                  else
                    _RevenueChart(buckets: revenueBuckets, period: _period),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Attendance',
              subtitle: selectedEvent == null
                  ? 'Check-in status across published events.'
                  : 'Check-in status for ${selectedEvent.name}.',
              child: attendees.isEmpty
                  ? const _EmptyMessage(
                      'No attendee data for this selection yet.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _AttendanceCount(
                                label: 'Checked in',
                                count: checkedIn,
                                color: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: _AttendanceCount(
                                label: 'Not checked in',
                                count: unchecked,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: attendees.isEmpty
                                ? 0
                                : checkedIn / attendees.length,
                            backgroundColor: AppColors.soft,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$checkedIn of ${attendees.length} attendees checked in',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventTabs extends StatelessWidget {
  const _EventTabs({
    required this.events,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Event> events;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _TabButton(
          label: 'Overview',
          selected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        for (final event in events)
          _TabButton(
            label: event.name,
            selected: event.id == selectedId,
            onTap: () => onSelected(event.id),
          ),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 240),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.soft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: AppColors.muted),
    ),
  );
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.buckets, required this.period});

  final List<RevenueBucket> buckets;
  final RevenuePeriod period;

  @override
  Widget build(BuildContext context) {
    final maxAmount = buckets.fold<int>(
      0,
      (max, bucket) => bucket.amountCents > max ? bucket.amountCents : max,
    );
    final labelEvery = period == RevenuePeriod.day ? 4 : 1;
    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < buckets.length; index++)
            Expanded(
              child: Tooltip(
                message:
                    '${buckets[index].label}: ${formatPesoExact(buckets[index].amountCents)}',
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: period == RevenuePeriod.day ? 1 : 4,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: maxAmount == 0
                                ? 0
                                : buckets[index].amountCents / maxAmount,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 22,
                        child: index % labelEvery == 0
                            ? Text(
                                buckets[index].label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.muted,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceCount extends StatelessWidget {
  const _AttendanceCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        groupThousands(count),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color)),
    ],
  );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}
