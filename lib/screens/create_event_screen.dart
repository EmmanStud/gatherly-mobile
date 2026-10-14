import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Create a new event, or edit one when [event] is provided.
/// Pops with a short confirmation message that the caller shows as a toast.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, this.event});

  final Event? event;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _capacity = TextEditingController();
  final _dateText = TextEditingController();
  final _timeText = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;

  bool get _editing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _name.text = event.name;
      _venue.text = event.venue;
      _capacity.text = '${event.capacity}';
      _date = DateUtils.dateOnly(event.startAt);
      _time = TimeOfDay(hour: event.startAt.hour, minute: event.startAt.minute);
      _dateText.text = formatDate(event.startAt);
      _timeText.text = formatTime(event.startAt);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _capacity.dispose();
    _dateText.dispose();
    _timeText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = _date;
    final first = current != null && current.isBefore(today) ? current : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: first,
      lastDate: DateTime(today.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateText.text = formatDate(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      _time = picked;
      _timeText.text = formatTime(DateTime(2000, 1, 1, picked.hour, picked.minute));
    });
  }

  String? _validateCapacity(String? value) {
    final capacity = int.tryParse((value ?? '').trim());
    if (capacity == null || capacity < 1) return 'Enter a capacity of at least 1.';
    final sold = widget.event?.sold ?? 0;
    if (capacity < sold) return 'Capacity can’t be lower than the $sold tickets sold.';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final date = _date!;
    final time = _time!;
    final startAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final venue = _venue.text.trim().isEmpty
        ? 'Philippine venue to be announced'
        : _venue.text.trim();
    final capacity = int.parse(_capacity.text.trim());

    if (_editing) {
      state.updateEvent(
        widget.event!.id,
        name: _name.text.trim(),
        startAt: startAt,
        venue: venue,
        capacity: capacity,
      );
      Navigator.of(context).pop('Event details updated.');
    } else {
      state.addEvent(
        name: _name.text.trim(),
        startAt: startAt,
        venue: venue,
        capacity: capacity,
      );
      Navigator.of(context).pop('Event created and saved as a draft.');
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(_editing ? 'Edit event' : 'Create event'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _editing ? 'EDIT EVENT' : 'NEW EVENT',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _editing ? 'Update event details' : 'Create something memorable',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8),
                    ),
                    const SizedBox(height: 28),
                    _label('Event name'),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => requiredField(v) == null ? null : 'Enter an event name.',
                      decoration: const InputDecoration(hintText: 'e.g. Philippine Tech Expo'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Date'),
                              TextFormField(
                                controller: _dateText,
                                readOnly: true,
                                onTap: _pickDate,
                                validator: (_) => _date == null ? 'Pick a date.' : null,
                                decoration: const InputDecoration(
                                  hintText: 'Select date',
                                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Time'),
                              TextFormField(
                                controller: _timeText,
                                readOnly: true,
                                onTap: _pickTime,
                                validator: (_) => _time == null ? 'Pick a time.' : null,
                                decoration: const InputDecoration(
                                  hintText: 'Select time',
                                  suffixIcon: Icon(Icons.schedule, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _label('Venue'),
                    TextFormField(
                      controller: _venue,
                      decoration: const InputDecoration(
                        hintText: 'Add a Philippine venue or online link',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _label('Capacity'),
                    TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      validator: _validateCapacity,
                      decoration: const InputDecoration(
                        hintText: '100',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _save,
                          child: Text(_editing ? 'Save changes' : 'Create draft'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}