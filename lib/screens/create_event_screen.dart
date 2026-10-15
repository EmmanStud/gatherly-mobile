import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/gatherly_api.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

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
  final _description = TextEditingController();
  final _category = TextEditingController();
  final _headliner = TextEditingController();
  final _price = TextEditingController();
  final _dateText = TextEditingController();
  final _timeText = TextEditingController();
  final _endDateText = TextEditingController();
  final List<TextEditingController> _ticketNames = [];
  final List<TextEditingController> _ticketPrices = [];
  DateTime? _date;
  DateTime? _endDate;
  TimeOfDay? _time;
  bool _multipleDay = false;
  bool _saving = false;
  String _pricingMode = 'free';
  String? _errorMessage;

  bool get _editing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event == null) {
      _addTicketType();
      _addTicketType();
      return;
    }
    _name.text = event.name;
    _venue.text = event.venue;
    _capacity.text = '${event.total}';
    _description.text = event.description;
    _category.text = event.category;
    _headliner.text = event.headliner;
    _multipleDay = event.multipleDay;
    _pricingMode = event.pricingMode;
    _price.text = (event.priceCents / 100).toStringAsFixed(2);
    _date = DateTime.tryParse(event.date);
    _endDate = DateTime.tryParse(event.endDate);
    _time = _parseTime(event.time);
    if (_date != null) _dateText.text = formatDate(_date!);
    if (_endDate != null) _endDateText.text = formatDate(_endDate!);
    if (_time != null) _timeText.text = _formatTime(_time!);
    for (final ticket in event.ticketTypes) {
      _addTicketType(ticket);
    }
    while (_ticketNames.length < 2) {
      _addTicketType();
    }
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  void _addTicketType([TicketType? ticket]) {
    _ticketNames.add(TextEditingController(text: ticket?.name ?? ''));
    _ticketPrices.add(TextEditingController(
      text: ticket == null ? '' : (ticket.priceCents / 100).toStringAsFixed(2),
    ));
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _venue, _capacity, _description, _category, _headliner, _price,
      _dateText, _timeText, _endDateText, ..._ticketNames, ..._ticketPrices,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({bool end = false}) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final current = end ? _endDate : _date;
    final afterStart = _date == null
        ? now
        : DateUtils.dateOnly(_date!).add(const Duration(days: 1));
    final first = end
        ? (afterStart.isAfter(now) ? afterStart : now)
        : (current != null && current.isBefore(now) ? current : now);
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(first) ? current : first,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (end) {
        _endDate = picked;
        _endDateText.text = formatDate(picked);
      } else {
        _date = picked;
        _dateText.text = formatDate(picked);
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
          _endDateText.clear();
        }
      }
      _errorMessage = null;
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
      _errorMessage = null;
    });
  }

  String? _validateRequired(String? value, String label, int max) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.length > max) return 'Enter $label (up to $max characters).';
    return null;
  }

  String? _validateCapacity(String? value) {
    final number = int.tryParse((value ?? '').trim());
    if (number == null || number < 1 || number > 100000) {
      return 'Enter a capacity from 1 to 100,000.';
    }
    final sold = widget.event?.sold ?? 0;
    if (number < sold) return 'Capacity can’t be lower than the $sold tickets sold.';
    return null;
  }

  int? _priceInCents(String input) {
    final value = double.tryParse(input.trim());
    if (value == null || value <= 0 || value > 1000000) return null;
    final cents = (value * 100).round();
    return cents > 0 && cents <= 100000000 ? cents : null;
  }

  Future<void> _save() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null || (_multipleDay &&
        (_endDate == null || !_endDate!.isAfter(_date!)))) {
      setState(() => _errorMessage = 'Choose a valid date, time, and later end date.');
      return;
    }
    final total = int.parse(_capacity.text.trim());
    final priceCents = _pricingMode == 'single' ? _priceInCents(_price.text) : null;
    if (_pricingMode == 'single' && priceCents == null) {
      setState(() => _errorMessage = 'Enter a ticket price greater than zero.');
      return;
    }
    final tickets = <TicketType>[];
    if (_pricingMode == 'multiple') {
      for (var i = 0; i < _ticketNames.length; i++) {
        final price = _priceInCents(_ticketPrices[i].text);
        if (_ticketNames[i].text.trim().isEmpty ||
            _ticketNames[i].text.trim().length > 80 || price == null) {
          setState(() => _errorMessage =
              'Enter a name (up to 80 characters) and a valid price for each ticket type.');
          return;
        }
        tickets.add(TicketType(id: '', name: _ticketNames[i].text.trim(), priceCents: price));
      }
    }
    setState(() => _saving = true);
    try {
      final existing = widget.event;
      final event = Event(
        id: existing?.id ?? '',
        name: _name.text.trim(),
        date: _isoDate(_date!),
        time: _formatTime(_time!),
        multipleDay: _multipleDay,
        endDate: _multipleDay ? _isoDate(_endDate!) : '',
        venue: _venue.text.trim(),
        description: _description.text.trim(),
        category: _category.text.trim(),
        headliner: _headliner.text.trim(),
        total: total,
        sold: existing?.sold ?? 0,
        eventCode: existing?.eventCode ?? '',
        registrationUrl: existing?.registrationUrl ?? '',
        pricingMode: _pricingMode,
        priceCents: priceCents ?? 0,
        ticketTypes: tickets,
        status: existing?.status ?? EventStatus.draft,
      );
      await AppScope.of(context).saveEvent(event);
      if (mounted) Navigator.of(context).pop(
        _editing ? 'Event details updated.' : 'Event created and saved as a draft.',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error is GatherlyApiException
            ? error.message
            : 'Unable to save the event. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
  );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int max = 200,
    int lines = 1,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      TextFormField(
        controller: controller,
        maxLength: max,
        maxLines: lines,
        validator: validator ?? (value) => _validateRequired(value, label.toLowerCase(), max),
        decoration: InputDecoration(hintText: hint, counterText: lines > 1 ? null : ''),
        onChanged: (_) => setState(() => _errorMessage = null),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(scrolledUnderElevation: 0, title: Text(_editing ? 'Edit event' : 'Create event')),
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
                  Text(_editing ? 'EDIT EVENT' : 'NEW EVENT',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(_editing ? 'Update event details' : 'Create something memorable',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8)),
                  const SizedBox(height: 24),
                  _textField(controller: _name, label: 'Event name', hint: 'e.g. Philippine Tech Expo',
                      max: 120),
                  const SizedBox(height: 16),
                  _textField(controller: _category, label: 'Category', hint: 'e.g. Technology', max: 100),
                  const SizedBox(height: 16),
                  _textField(controller: _headliner, label: 'Headliner', hint: 'Featured speaker or performer', max: 150),
                  const SizedBox(height: 16),
                  _textField(controller: _description, label: 'Description', hint: 'Tell guests about the event',
                      max: 5000, lines: 4),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _datePicker('Date', _dateText, () => _pickDate())),
                    const SizedBox(width: 12),
                    Expanded(child: _datePicker('Time', _timeText, _pickTime)),
                  ]),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Multiple-day event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    value: _multipleDay,
                    onChanged: (value) => setState(() {
                      _multipleDay = value;
                      _errorMessage = null;
                    }),
                  ),
                  if (_multipleDay) ...[
                    _datePicker('End date', _endDateText, () => _pickDate(end: true)),
                    const SizedBox(height: 16),
                  ],
                  _textField(controller: _venue, label: 'Venue', hint: 'Venue or online link', max: 200),
                  const SizedBox(height: 16),
                  _textField(controller: _capacity, label: 'Total capacity', hint: '100',
                      validator: _validateCapacity),
                  const SizedBox(height: 16),
                  _label('Pricing'),
                  DropdownButtonFormField<String>(
                    value: _pricingMode,
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free')),
                      DropdownMenuItem(value: 'single', child: Text('Single price')),
                      DropdownMenuItem(value: 'multiple', child: Text('Multiple ticket types')),
                    ],
                    onChanged: (value) => setState(() {
                      _pricingMode = value ?? 'free';
                      _errorMessage = null;
                    }),
                  ),
                  if (_pricingMode == 'single') ...[
                    const SizedBox(height: 12),
                    _priceField(_price, 'Ticket price (PHP)'),
                  ],
                  if (_pricingMode == 'multiple') ...[
                    const SizedBox(height: 12),
                    for (var i = 0; i < _ticketNames.length; i++) ...[
                      Row(children: [
                        Expanded(child: TextFormField(controller: _ticketNames[i],
                          maxLength: 80, decoration: InputDecoration(hintText: 'Ticket type ${i + 1}', counterText: ''),
                          onChanged: (_) => setState(() => _errorMessage = null))),
                        const SizedBox(width: 8),
                        Expanded(child: _priceField(_ticketPrices[i], 'Price PHP')),
                        if (_ticketNames.length > 2)
                          IconButton(onPressed: () => setState(() {
                            _ticketNames.removeAt(i).dispose();
                            _ticketPrices.removeAt(i).dispose();
                          }), icon: const Icon(Icons.remove_circle_outline)),
                      ]),
                      const SizedBox(height: 8),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _ticketNames.length >= 10 ? null : () => setState(() => _addTicketType()),
                        icon: const Icon(Icons.add),
                        label: const Text('Add ticket type (2–10)'),
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_editing ? 'Save changes' : 'Create draft'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _datePicker(String label, TextEditingController controller, VoidCallback onTap) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          validator: (_) => controller.text.isEmpty ? 'Select $label.' : null,
          decoration: InputDecoration(
            hintText: label == 'Time' ? 'Select time' : 'Select date',
            suffixIcon: Icon(label == 'Time' ? Icons.schedule : Icons.calendar_today_outlined, size: 18),
          ),
        ),
      ]);

  Widget _priceField(TextEditingController controller, String hint) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(hintText: hint, prefixText: '₱ '),
    validator: (value) => _priceInCents(value ?? '') == null ? 'Enter a valid price.' : null,
    onChanged: (_) => setState(() => _errorMessage = null),
  );
}
