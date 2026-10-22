import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/labeled_field.dart';
import '../../../core/time/local_date.dart';
import '../application/image_import_controller.dart';
import '../domain/candidate_resolution.dart';
import 'scan_repeat_picker.dart';
import 'scan_date_field.dart';

class UniversityTermForm extends StatefulWidget {
  const UniversityTermForm({super.key, required this.controller, required this.initialZone});
  final ImageImportController controller;
  final String initialZone;
  @override
  State<UniversityTermForm> createState() => UniversityTermFormState();
}

class UniversityTermFormState extends State<UniversityTermForm> with AutomaticKeepAliveClientMixin {
  LocalDate? _start, _end;
  late final _zone = TextEditingController(text: widget.initialZone);
  bool _checked = false;
  CandidateRepeat _repeat = CandidateRepeat.weekly;
  String? _error;
  bool _needsApply = true;
  String? get validationMessage => _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() { _zone.dispose(); super.dispose(); }

  void _invalidate() {
    _needsApply = true;
    widget.controller.invalidateUniversityContext();
    setState(() => _error = null);
  }

  bool prepareForReview() {
    final selectedClasses = widget.controller.candidates.where((c) => c.universityTimetable &&
      widget.controller.selected.contains(c.candidateId));
    if (selectedClasses.isEmpty) return true;
    // Preserve individual overrides after applying shared dates, including
    // classes resolved entirely in their own editor.
    if ((!_needsApply || (_start == null && _end == null && !_checked)) &&
        selectedClasses.every((c) => widget.controller.edits[c.candidateId]!.associationConfirmed)) {
      return true;
    }
    return _apply();
  }

  bool _apply() {
    FocusScope.of(context).unfocus();
    final start = _start;
    final end = _repeat == CandidateRepeat.weekly ? _end : null;
    setState(() => _error = start == null || (_repeat == CandidateRepeat.weekly && end == null)
      ? (_repeat == CandidateRepeat.weekly ? 'Choose your term start and end dates.' : 'Choose a starting date.')
      : widget.controller.applyUniversityTerm(start: start, end: end, repeat: _repeat,
          zone: _zone.text.trim(), checked: _checked));
    if (_error == null) _needsApply = false;
    return _error == null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(child: Padding(
    padding: const EdgeInsets.all(Tokens.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Class schedule', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: Tokens.md),
      ScanRepeatPicker(key: const Key('university-repeat'), value: _repeat, onChanged: (value) {
        FocusScope.of(context).unfocus();
        setState(() => _repeat = value);
        _invalidate();
      }),
      const SizedBox(height: Tokens.md),
      ScanDateField(key: const Key('university-term-start'),
        label: _repeat == CandidateRepeat.weekly ? 'Term starts' : 'Starting date',
        value: _start, onChanged: (value) { _start = value; _invalidate(); }),
      if (_repeat == CandidateRepeat.weekly) ...[
        const SizedBox(height: Tokens.md),
        ScanDateField(key: const Key('university-term-end'), label: 'Term ends',
          value: _end, firstDate: _start, focusDate: _start,
          onChanged: (value) { _end = value; _invalidate(); }),
      ] else ...[
        const SizedBox(height: Tokens.sm),
        const Text('Adds each meeting once, from this date.'),
      ],
      const SizedBox(height: Tokens.md),
      FieldLabel(label: 'School time zone', child: TextField(key: const Key('university-zone'),
        controller: _zone, onChanged: (_) => _invalidate(), decoration: const InputDecoration())),
      CheckboxListTile(key: const Key('university-check'), contentPadding: EdgeInsets.zero,
        value: _checked, title: const Text('I checked the class details against the image.'),
        onChanged: (value) { setState(() => _checked = value == true); if (!_checked) _invalidate(); }),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      FilledButton.tonal(onPressed: _apply, child: const Text('Apply to selected classes')),
    ]),
    ));
  }
}
