import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AnalyticsPanel extends StatefulWidget {
  const AnalyticsPanel({super.key});

  @override
  State<AnalyticsPanel> createState() => _AnalyticsPanelState();
}

class _AnalyticsPanelState extends State<AnalyticsPanel> {
  static const _ranges = ['7 days', '30 days', '12 months'];
  String _range = '30 days';

  @override
  Widget build(BuildContext context) {
    final events = AppScope.of(context).events;
    final Event? top = events.isEmpty
        ? null
        : events.reduce((a, b) => a.percent >= b.percent ? a : b);

    final rangePicker = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _range,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
          items: [for (final r in _ranges) DropdownMenuItem(value: r, child: Text(r))],
          onChanged: (value) => setState(() => _range = value ?? _range),
        ),
      ),
    );

    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const PanelTitle('Ticket performance', 'Sales performance across Philippine events.'),
              rangePicker,
            ],
          ),
          const SizedBox(height: 28),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Create an event to see ticket performance.')),
            ),
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${event.percent}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(value: event.fill, height: 12),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              top == null
                  ? 'Showing the last $_range.'
                  : 'Showing the last $_range. ${top.name} currently has the strongest ticket velocity.',
              style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0x8C000000)),
            ),
          ),
        ],
      ),
    );
  }
}