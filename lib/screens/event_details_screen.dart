import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/assets.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/gatherly_api.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'create_event_screen.dart';

/// Opened from "Manage event" and from tapping an event in the list.
class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({super.key, required this.eventId});

  final String eventId;

  Future<void> _edit(BuildContext context, Event event) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CreateEventScreen(event: event)),
    );
    if (message != null) showToastOn(messenger, message);
  }

  Future<void> _delete(BuildContext context, AppState state, Event event) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete this event?',
      message: '“${event.name}” will be removed. This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await state.deleteEvent(event.id);
      navigator.pop();
      showToastOn(messenger, 'Event deleted.');
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _publish(BuildContext context, AppState state, Event event) async {
    final ok = await confirmDialog(
      context,
      title: 'Publish this event?',
      message: 'Guests will be able to register using its event link.',
      confirmLabel: 'Publish',
    );
    if (ok && context.mounted) {
      await _run(context, () => state.publishEvent(event.id), 'Event published.');
    }
  }

  Future<void> _cancel(BuildContext context, AppState state, Event event) async {
    final ok = await confirmDialog(
      context,
      title: 'Cancel this event?',
      message: 'The event will be marked as cancelled.',
      confirmLabel: 'Cancel event',
      destructive: true,
    );
    if (ok && context.mounted) {
      await _run(context, () => state.cancelEvent(event.id), 'Event cancelled.');
    }
  }

  Future<void> _finish(BuildContext context, AppState state, Event event) async {
    final ok = await confirmDialog(
      context,
      title: 'Mark this event finished?',
      message: 'This is only available after the event ends.',
      confirmLabel: 'Finish event',
    );
    if (ok && context.mounted) {
      await _run(context, () => state.finishEvent(event.id), 'Event marked as finished.');
    }
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (context.mounted) showToast(context, success);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Could not update event'),
        content: Text(error is GatherlyApiException ? error.message : 'Please try again.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final event = state.eventById(eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(scrolledUnderElevation: 0),
        body: const Center(child: Text('This event no longer exists.')),
      );
    }

    final onSale = event.status == EventStatus.onSale;
    final remaining = (event.capacity - event.sold).clamp(0, event.capacity);

    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0, title: const Text('Event details')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            kEventImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                const ColoredBox(color: AppColors.panel),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xE62D3142), Color(0x002D3142)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 16,
                            child: StatusPill(
                              event.status.label.toUpperCase(),
                              background: onSale ? AppColors.yellow : Colors.white,
                              foreground: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    event.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8, height: 1.15),
                  ),
                  const SizedBox(height: 14),
                  _DetailLine(Icons.calendar_today_outlined, formatDate(event.startAt)),
                  if (event.multipleDay)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _DetailLine(
                        Icons.event_available_outlined,
                        'Through ${formatDate(DateTime.tryParse(event.endDate) ?? event.startAt)}',
                      ),
                    ),
                  const SizedBox(height: 8),
                  _DetailLine(Icons.schedule, formatTime(event.startAt)),
                  const SizedBox(height: 8),
                  _DetailLine(Icons.location_on_outlined, event.venue),
                  if (event.category.isNotEmpty || event.headliner.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      [event.category, event.headliner].where((value) => value.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(event.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],
                  const SizedBox(height: 18),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PanelTitle('Event information', 'Details used for your published event.'),
                        const SizedBox(height: 14),
                        _DetailLine(
                          Icons.sell_outlined,
                          switch (event.pricingMode) {
                            'single' => 'Ticket price · ${formatPeso(event.priceCents)}',
                            'multiple' => 'Multiple ticket types',
                            _ => 'Free admission',
                          },
                        ),
                        if (event.pricingMode == 'multiple')
                          for (final ticket in event.ticketTypes)
                            Padding(
                              padding: const EdgeInsets.only(left: 27, top: 8),
                              child: Text(
                                '${ticket.name} · ${formatPeso(ticket.priceCents)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        const SizedBox(height: 12),
                        _DetailLine(
                          Icons.confirmation_number_outlined,
                          'Event code · ${event.eventCode.isEmpty ? 'Not assigned' : event.eventCode}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PanelTitle('Ticket sales', 'Tickets sold against capacity'),
                        const SizedBox(height: 20),
                        ProgressBar(value: event.fill, height: 10),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${event.sold} of ${event.capacity} sold',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${event.percent}% · $remaining left',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (onSale && event.registrationUrl.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PanelTitle('Registration link', 'Share this link with your guests.'),
                          const SizedBox(height: 10),
                          SelectableText(event.registrationUrl),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: event.registrationUrl));
                                if (context.mounted) {
                                  showToast(context, 'Registration link copied.');
                                }
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy registration link'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (event.status == EventStatus.draft || onSale)
                        FilledButton.icon(
                          onPressed: () => _edit(context, event),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit event'),
                        ),
                      if (event.status == EventStatus.draft)
                        OutlinedButton.icon(
                          onPressed: () => _publish(context, state, event),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: Color(0x1A000000)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                          label: const Text('Publish event'),
                        ),
                      if (event.status == EventStatus.onSale)
                        OutlinedButton.icon(
                          onPressed: () => _finish(context, state, event),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Finish event'),
                        ),
                      if (event.status == EventStatus.draft || onSale)
                        TextButton.icon(
                          onPressed: () => _cancel(context, state, event),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel event'),
                        ),
                      if (event.status == EventStatus.draft)
                        TextButton.icon(
                          onPressed: () => _delete(context, state, event),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}