import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/gatherly_api.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AttendeesPanel extends StatefulWidget {
  const AttendeesPanel({super.key});

  @override
  State<AttendeesPanel> createState() => _AttendeesPanelState();
}

class _AttendeesPanelState extends State<AttendeesPanel> {
  String? _eventFilter;

  Future<void> _toggle(Attendee person) async {
    final state = AppScope.of(context);
    try {
      await state.setCheckedIn(person.id, !person.checkedIn);
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Could not update check-in'),
          content: Text(error is GatherlyApiException ? error.message : 'Please try again.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selectedEvent = _eventFilter == null
        ? null
        : state.events.where((event) => event.id == _eventFilter).firstOrNull;
    final attendees = selectedEvent == null
        ? state.attendees
        : state.attendees
              .where(
                (person) =>
                    person.eventId == selectedEvent.id ||
                    (selectedEvent.eventCode.isNotEmpty &&
                        person.eventCode == selectedEvent.eventCode),
              )
              .toList();
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: PanelTitle(
              'Attendee check-in',
              '${attendees.where((person) => person.checkedIn).length} of ${attendees.length} guests checked in.',
            ),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DropdownButtonFormField<String?>(
                initialValue: _eventFilter,
                decoration: const InputDecoration(labelText: 'Filter by event'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All events')),
                  for (final event in state.events)
                    DropdownMenuItem<String?>(value: event.id, child: Text(event.name)),
                ],
                onChanged: (value) => setState(() => _eventFilter = value),
              ),
            ),
            if (state.dataError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: Text(state.dataError!, style: const TextStyle(color: AppColors.danger))),
                  TextButton(onPressed: state.loadOrganizerData, child: const Text('Retry')),
                ]),
              ),
            if (state.isLoadingData && attendees.isEmpty)
              const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
          if (!state.isLoadingData && state.dataError == null && attendees.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Center(child: Text('No attendees yet.')),
            ),
          for (final person in attendees)
            _AttendeeRow(
              person: person,
              onToggle: () => _toggle(person),
            ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({required this.person, required this.onToggle});

  final Attendee person;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final checked = person.checkedIn;
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          InitialsAvatar(
            initials(person.name),
            radius: 20,
            background: const Color(0xFFDFE7F2),
            foreground: AppColors.kpiBlue,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${person.ticket} · ${person.eventName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onToggle,
            style: FilledButton.styleFrom(
              backgroundColor: checked ? AppColors.kpiGreenBg : AppColors.primary,
              foregroundColor: checked ? const Color(0xFF597450) : Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            child: Text(checked ? 'Undo' : 'Check in'),
          ),
        ],
      ),
    );
  }
}