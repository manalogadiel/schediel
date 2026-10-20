import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/labeled_field.dart';
import '../../../core/time/local_date.dart';
import '../application/image_import_controller.dart';

class UniversityTermForm extends StatefulWidget {
  const UniversityTermForm({super.key, required this.controller, required this.initialZone});
  final ImageImportController controller;
  final String initialZone;
  @override
  State<UniversityTermForm> createState() => _UniversityTermFormState();
}

class _UniversityTermFormState extends State<UniversityTermForm> {
  final _start = TextEditingController(), _end = TextEditingController();
  late final _zone = TextEditingController(text: widget.initialZone);
  bool _checked = false;
  String? _error;

  @override
  void dispose() { _start.dispose(); _end.dispose(); _zone.dispose(); super.dispose(); }

  void _apply() {
    final start = LocalDate.tryParse(_start.text.trim()), end = LocalDate.tryParse(_end.text.trim());
    setState(() => _error = start == null || end == null
      ? 'Choose your term start and end dates.'
      : widget.controller.applyUniversityTerm(start: start, end: end,
          zone: _zone.text.trim(), checked: _checked));
  }

  Widget _date(String label, String key, TextEditingController controller) => FieldLabel(
    label: label, child: TextField(key: Key(key), controller: controller,
      keyboardType: TextInputType.datetime, decoration: const InputDecoration(hintText: 'YYYY-MM-DD')));

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(Tokens.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Class term', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: Tokens.md),
      _date('Term starts', 'university-term-start', _start),
      const SizedBox(height: Tokens.md),
      _date('Term ends', 'university-term-end', _end),
      const SizedBox(height: Tokens.md),
      FieldLabel(label: 'School time zone', child: TextField(key: const Key('university-zone'),
        controller: _zone, decoration: const InputDecoration(helperText: 'Confirm the zone for these classes.'))),
      CheckboxListTile(key: const Key('university-check'), contentPadding: EdgeInsets.zero,
        value: _checked, title: const Text('I checked the class details against the image.'),
        onChanged: (value) => setState(() => _checked = value == true)),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      FilledButton.tonal(onPressed: _apply, child: const Text('Apply to selected classes')),
    ]),
  ));
}
