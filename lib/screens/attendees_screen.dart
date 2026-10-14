import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AttendeesPanel extends StatelessWidget {
  const AttendeesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final attendees = state.attendees;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: PanelTitle(
              'Attendee check-in',
              '${state.checkedInCount} of ${attendees.length} guests checked in.',
            ),
          ),
          if (attendees.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Center(child: Text('No attendees yet.')),
            ),
          for (final person in attendees)
            _AttendeeRow(
              person: person,
              onToggle: () => state.toggleCheckIn(person.id),
            ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({required this.person, required this.onToggle});

  final Attendee person;
  final VoidCallback onToggle;

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
            child: Text(checked ? 'Checked in' : 'Check in'),
          ),
        ],
      ),
    );
  }
}