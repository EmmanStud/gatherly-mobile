import 'dart:async';

import 'package:flutter/material.dart';

import '../services/gatherly_api.dart';
import '../state/app_state.dart';

class VenueAutocompleteField extends StatefulWidget {
  const VenueAutocompleteField({
    super.key,
    required this.controller,
    this.initiallySelected = false,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool initiallySelected;
  final VoidCallback onChanged;

  @override
  VenueAutocompleteFieldState createState() => VenueAutocompleteFieldState();
}

class VenueAutocompleteFieldState extends State<VenueAutocompleteField> {
  Timer? _debounce;
  int _requestId = 0;
  bool _selected = false;
  bool _loading = false;
  List<String> _suggestions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected;
  }

  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a venue.';
    }
    if (!_selected) {
      return 'Choose a venue suggestion located in the Philippines.';
    }
    return null;
  }

  void _onTextChanged(String value) {
    final query = value.trim();
    final requestId = ++_requestId;
    _debounce?.cancel();
    setState(() {
      _selected = false;
      _suggestions = const [];
      _error = null;
      _loading = query.length >= 3;
    });
    widget.onChanged();

    if (query.length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query, requestId);
    });
  }

  Future<void> _fetchSuggestions(String query, int requestId) async {
    try {
      final suggestions = await AppScope.of(
        context,
      ).api.venueSuggestions(query);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = error is GatherlyApiException
            ? error.message
            : 'Venue suggestions are unavailable. Please try again.';
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    ++_requestId;
    _debounce?.cancel();
    widget.controller.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    setState(() {
      _selected = true;
      _suggestions = const [];
      _loading = false;
      _error = null;
    });
    widget.onChanged();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showNoResults =
        !_selected &&
        widget.controller.text.trim().length >= 3 &&
        !_loading &&
        _suggestions.isEmpty &&
        _error == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          maxLength: 200,
          validator: validate,
          onChanged: _onTextChanged,
          decoration: const InputDecoration(
            hintText: 'Type at least 3 characters to find a venue',
            counterText: '',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        if (_loading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Searching Philippines venues…',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(suggestion),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (showNoResults)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No Philippine venue suggestions found.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
