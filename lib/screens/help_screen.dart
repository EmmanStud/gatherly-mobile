import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/common.dart';

class HelpCenterPanel extends StatefulWidget {
  const HelpCenterPanel({super.key});

  @override
  State<HelpCenterPanel> createState() => _HelpCenterPanelState();
}

class _HelpCenterPanelState extends State<HelpCenterPanel> {
  static const _topics = [
    'Event setup',
    'Orders and refunds',
    'Attendee check-in',
    'Account and security',
  ];

  static const _faqs = [
    (
      'How do I publish a draft event?',
      'Open Events, tap an event, then choose Publish event once its details are complete.',
    ),
    (
      'Can I refund a ticket order?',
      'Yes. Open Orders and choose Refund beside a paid order, then confirm.',
    ),
    (
      'How does attendee check-in work?',
      'Open Attendees and choose Check in beside a guest. Select it again to undo the check-in.',
    ),
    (
      'Where can I see ticket performance?',
      'Analytics compares tickets sold with capacity for every event. Use the range selector to change the reporting period.',
    ),
  ];

  final _message = TextEditingController();
  String _query = '';
  String _topic = _topics.first;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    if (_message.text.trim().isEmpty) {
      showToast(context, 'Please enter a message.');
      return;
    }
    _message.clear();
    FocusScope.of(context).unfocus();
    showToast(context, 'Support request sent. We’ll reply by email.');
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matches = _faqs
        .where((f) => '${f.$1} ${f.$2}'.toLowerCase().contains(query))
        .toList();

    final articles = Panel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search help articles...',
              prefixIcon: Icon(Icons.search, size: 20),
              fillColor: AppColors.soft,
            ),
          ),
          const SizedBox(height: 24),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No help articles found.')),
            ),
          for (final item in matches)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x12000000)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  backgroundColor: AppColors.soft,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    item.$1,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  children: [
                    Text(
                      item.$2,
                      style: const TextStyle(fontSize: 12, height: 1.7, color: Color(0x80000000)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    final contact = Panel(
      color: AppColors.panel,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_outline, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Still need a hand?',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to the Gatherly support team.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 22),
          const Text('Topic', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _topic,
            isExpanded: true,
            dropdownColor: Colors.white,
            decoration: const InputDecoration(isDense: true),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
            items: [for (final t in _topics) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _topic = v ?? _topic),
          ),
          const SizedBox(height: 16),
          const Text('Message', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Tell us what you need help with...'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _send,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.ink,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            child: const Text('Send request'),
          ),
        ],
      ),
    );

    return TwoColumn(left: articles, right: contact, leftFlex: 6, rightFlex: 4, breakpoint: 900);
  }
}