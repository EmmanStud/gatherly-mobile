import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/gatherly_api.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';

/// "Your events" card: search, status filter, paged list, edit and delete.
class EventsPanel extends StatefulWidget {
  const EventsPanel({super.key});

  @override
  State<EventsPanel> createState() => _EventsPanelState();
}

class _EventsPanelState extends State<EventsPanel> {
  static const int _pageSize = 3;
  static const List<String> _filters = [
    'All events',
    'On sale',
    'Draft',
    'Archive',
  ];

  String _search = '';
  String _filter = 'All events';
  int _page = 1;

  List<Event> _applyFilters(List<Event> all) {
    final query = _search.trim().toLowerCase();
    return all.where((event) {
      final matchesSearch =
          query.isEmpty ||
          event.name.toLowerCase().contains(query) ||
          event.venue.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        'Archive' =>
          event.status == EventStatus.finished ||
              event.status == EventStatus.cancelled,
        'All events' => true,
        _ => event.status.label == _filter,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _edit(Event event) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CreateEventScreen(event: event)),
    );
    if (message != null && mounted) showToast(context, message);
  }

  Future<void> _delete(Event event) async {
    final state = AppScope.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete this event?',
      message: '“${event.name}” will be removed. This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await state.deleteEvent(event.id);
    } catch (error) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Could not delete event'),
          content: Text(
            error is GatherlyApiException ? error.message : 'Please try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _page = 1);
    showToast(context, 'Event deleted.');
  }

  void _open(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: event.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final filtered = _applyFilters(state.events);
    final totalPages = filtered.isEmpty
        ? 1
        : (filtered.length + _pageSize - 1) ~/ _pageSize;
    final page = _page.clamp(1, totalPages);
    final start = (page - 1) * _pageSize;
    final paged = filtered.skip(start).take(_pageSize).toList();

    return Panel(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(wide),
              const Divider(height: 1, color: AppColors.border),
              if (state.dataError != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.dataError!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      TextButton(
                        onPressed: state.loadOrganizerData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (state.isLoadingData && state.events.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (wide) _columnTitles(),
              for (final event in paged)
                _EventRow(
                  event: event,
                  wide: wide,
                  onOpen: () => _open(event),
                  onEdit: () => _edit(event),
                  onDelete: () => _delete(event),
                ),
              if (!state.isLoadingData &&
                  state.dataError == null &&
                  filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 56),
                  child: Column(
                    children: [
                      Text(
                        'No events found',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Try another search or filter.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              _footer(filtered.length, start, page, totalPages),
            ],
          );
        },
      ),
    );
  }

  Widget _header(bool wide) {
    final search = TextField(
      onChanged: (value) => setState(() {
        _search = value;
        _page = 1;
      }),
      decoration: const InputDecoration(
        hintText: 'Search events or venues...',
        prefixIcon: Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
    final filter = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          items: [
            for (final f in _filters)
              DropdownMenuItem(value: f, child: Text(f)),
          ],
          onChanged: (value) => setState(() {
            _filter = value ?? 'All events';
            _page = 1;
          }),
        ),
      ),
    );
    const title = PanelTitle('Your events', 'Manage your upcoming schedule');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: wide
          ? Row(
              children: [
                const Expanded(child: title),
                SizedBox(width: 280, child: search),
                const SizedBox(width: 8),
                filter,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 8),
                    filter,
                  ],
                ),
              ],
            ),
    );
  }

  Widget _columnTitles() {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
      color: Color(0x59000000),
    );
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('EVENT', style: style)),
          Expanded(flex: 2, child: Text('DATE & TIME', style: style)),
          Expanded(flex: 3, child: Text('TICKETS SOLD', style: style)),
          SizedBox(width: 90, child: Text('STATUS', style: style)),
          SizedBox(width: 124),
        ],
      ),
    );
  }

  Widget _footer(int total, int start, int page, int totalPages) {
    final from = total == 0 ? 0 : start + 1;
    final to = (start + _pageSize).clamp(0, total);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $from–$to of $total events',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
          _PagerButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous page',
            onTap: page > 1 ? () => setState(() => _page = page - 1) : null,
          ),
          const SizedBox(width: 4),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$page',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _PagerButton(
            icon: Icons.chevron_right,
            tooltip: 'Next page',
            onTap: page < totalPages
                ? () => setState(() => _page = page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onTap == null ? .25 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x12000000)),
            ),
            child: Icon(icon, size: 18, color: AppColors.mutedStrong),
          ),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.wide,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Event event;
  final bool wide;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Widget get _title => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        event.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 13,
            color: AppColors.muted,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              event.venue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    ],
  );

  Widget get _when => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        formatDate(event.startAt),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(
        formatTime(event.startAt),
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    ],
  );

  Widget get _sold => Row(
    children: [
      SizedBox(width: 80, child: ProgressBar(value: event.fill)),
      const SizedBox(width: 12),
      Text(
        '${event.sold}/${event.capacity}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0x80000000),
        ),
      ),
    ],
  );

  Widget get _status {
    final onSale = event.status == EventStatus.onSale;
    return StatusPill(
      event.status.label,
      dot: true,
      background: onSale ? AppColors.successBg : const Color(0x0D000000),
      foreground: onSale ? AppColors.success : const Color(0x73000000),
    );
  }

  Widget get _actions => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (event.status == EventStatus.draft ||
          event.status == EventStatus.onSale)
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(48, 36),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Edit'),
        ),
      if (event.status == EventStatus.draft)
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.danger,
            minimumSize: const Size(48, 36),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Delete'),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final content = wide
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(flex: 4, child: _title),
                Expanded(flex: 2, child: _when),
                Expanded(flex: 3, child: _sold),
                SizedBox(
                  width: 90,
                  child: Align(alignment: Alignment.centerLeft, child: _status),
                ),
                SizedBox(
                  width: 124,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _actions,
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _title,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${formatDate(event.startAt)} · ${formatTime(event.startAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _status,
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(padding: const EdgeInsets.only(right: 8), child: _sold),
                Align(alignment: Alignment.centerRight, child: _actions),
              ],
            ),
          );

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: InkWell(onTap: onOpen, child: content),
    );
  }
}
