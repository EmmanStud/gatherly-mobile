import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/assets.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'create_event_screen.dart';

/// Opened from "Manage event" and from tapping an event in the list.
class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({super.key, required this.eventId});

  final int eventId;

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
    if (!ok) return;
    state.deleteEvent(event.id);
    navigator.pop();
    showToastOn(messenger, 'Event deleted.');
  }

  void _togglePublish(BuildContext context, AppState state, Event event) {
    final publishing = event.status == EventStatus.draft;
    state.setEventStatus(
      event.id,
      publishing ? EventStatus.onSale : EventStatus.draft,
    );
    showToast(context, publishing ? 'Event published. Tickets are on sale.' : 'Event moved back to draft.');
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
                  const SizedBox(height: 8),
                  _DetailLine(Icons.schedule, formatTime(event.startAt)),
                  const SizedBox(height: 8),
                  _DetailLine(Icons.location_on_outlined, event.venue),
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _edit(context, event),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit event'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _togglePublish(context, state, event),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(color: Color(0x1A000000)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(onSale ? Icons.visibility_off_outlined : Icons.rocket_launch_outlined, size: 18),
                        label: Text(onSale ? 'Move to draft' : 'Publish event'),
                      ),
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