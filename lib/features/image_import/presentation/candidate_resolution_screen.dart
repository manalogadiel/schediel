import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/labeled_field.dart';
import '../../../core/schedule/models.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../application/image_import_controller.dart';
import '../domain/candidate_resolution.dart';
import '../domain/image_candidate.dart';
import 'scan_repeat_picker.dart';
import 'scan_date_field.dart';
import 'scan_time_field.dart';

/// Unknown fields stay blank. Only explicit user values resolve a candidate;
/// this child editor never inserts a schedule.
class CandidateResolutionScreen extends StatefulWidget {
  const CandidateResolutionScreen({super.key, required this.controller, required this.candidate, this.showErrors = false});
  final ImageImportController controller;
  final ImageCandidate candidate;
  final bool showErrors;
  @override State<CandidateResolutionScreen> createState() => _CandidateResolutionScreenState();
}
class _CandidateResolutionScreenState extends State<CandidateResolutionScreen> {
  late final CandidateEdits _edits = widget.controller.edits[widget.candidate.candidateId]!;
  late Map<String, String> _errors = widget.showErrors ? {...resolveImageCandidate(widget.candidate, _edits).errors} : {};
  void _changed() => widget.controller.edited(widget.candidate.candidateId);
  Widget field(String name, String label, String value, ValueChanged<String> update, {String? hint, Key? key}) => Padding(
    padding: const EdgeInsets.only(bottom: Tokens.md), child: FieldLabel(label: label, child: TextFormField(key: key, initialValue: value,
      decoration: InputDecoration(helperText: hint, errorText: _errors[name]),
      onChanged: (v) { update(v); _changed(); })));
  Widget dateField(String name, String label, String value, ValueChanged<String> update,
      {Key? key, bool optional = false, LocalDate? firstDate}) => Padding(
    padding: const EdgeInsets.only(bottom: Tokens.md),
    child: ScanDateField(key: key, label: label, value: LocalDate.tryParse(value),
      firstDate: firstDate, focusDate: firstDate, errorText: _errors[name], allowClear: optional,
      onChanged: (date) => setState(() {
        update(date?.toIso() ?? ''); _errors.remove(name); _changed();
      })));
  Widget timeField(String name, String label, String value, ValueChanged<String> update, {Key? key}) => Padding(
    padding: const EdgeInsets.only(bottom: Tokens.md),
    child: ScanTimeField(key: key, label: label, value: LocalTime.tryParse(value), errorText: _errors[name],
      onChanged: (time) => setState(() {
        update(time.toHhMm()); _errors.remove(name); _changed();
      })));
  Future<void> _use() async {
    final result = widget.controller.resolve(widget.candidate.candidateId);
    if (result.resolved == null) { setState(() => _errors = result.errors); return; }
    Navigator.of(context).pop(true);
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Resolve fields'), actions: [TextButton(onPressed: _use, child: const Text('Use draft values'))]),
    body: ListView(padding: const EdgeInsets.all(Tokens.md), children: [
      const Text('Check the source. Missing year, date order, time zone and duration are not guessed.'),
      const SizedBox(height: Tokens.sm),
      ExpansionTile(title: const Text('Source text'), children: [SelectableText(widget.candidate.sourceLine.text)]),
      const SizedBox(height: Tokens.md),
      field('title','Title',_edits.title,(v)=>_edits.title=v),
      FieldLabel(label:'Schedule type', child: DropdownButtonFormField<CandidateTimeKind>(isExpanded: true, initialValue:_edits.kind,
        decoration: InputDecoration(errorText:_errors['kind']),
        items: const [DropdownMenuItem(value:CandidateTimeKind.timed,child:Text('Timed')),
          DropdownMenuItem(value:CandidateTimeKind.dateOnly,child:Text('All day'))],
        onChanged:(v)=>setState(() { _edits.kind=v; _changed(); }))),
      const SizedBox(height:Tokens.md),
      ScanRepeatPicker(key: const Key('candidate-repeat'), value: _edits.repeat,
        onChanged: (value) => setState(() { _edits.repeat = value; _changed(); })),
      const SizedBox(height:Tokens.md),
      dateField('date','Start date',_edits.date,(v)=>_edits.date=v,key:const Key('candidate-date')),
      if (_edits.kind == CandidateTimeKind.dateOnly)
        dateField('lastDate','Last date (optional)',_edits.lastDate,(v)=>_edits.lastDate=v,
          optional: true, firstDate: LocalDate.tryParse(_edits.date)),
      if (_edits.kind == CandidateTimeKind.timed) ...[
        timeField('startTime','Start time',_edits.startTime,(v) {
          _edits.startTime=v; _edits.seedResolution=null;
        }, key:const Key('candidate-start-time')),
        field('timeZone','Source time zone',_edits.timeZone,(v)=>_edits.timeZone=v,hint:'IANA name, for example Asia/Manila'),
        FieldLabel(label:'End time choice', child: DropdownButtonFormField<CandidateEndChoice>(isExpanded: true, initialValue:_edits.endChoice,
          decoration:InputDecoration(errorText:_errors['endChoice']),
          items:const [DropdownMenuItem(value:CandidateEndChoice.noEnd,child:Text('No end time')),
            DropdownMenuItem(value:CandidateEndChoice.sameDay,child:Text('Ends on the same day')),
            DropdownMenuItem(value:CandidateEndChoice.nextDay,child:Text('Ends the next day'))],
          onChanged:(v)=>setState(() { _edits.endChoice=v; _changed(); }))),
        const SizedBox(height:Tokens.md),
        if (_edits.endChoice != CandidateEndChoice.noEnd)
          timeField('endTime','End time',_edits.endTime,(v) {
            _edits.endTime=v; _edits.endResolution=null;
          }, key:const Key('candidate-end-time')),
        if (_errors.containsKey('seedResolution') || _edits.seedResolution != null)
          _fold('seedResolution','Repeated start clock time',_edits.seedResolution,(v)=>_edits.seedResolution=v),
        if (_errors.containsKey('endResolution') || _edits.endResolution != null)
          _fold('endResolution','Repeated end clock time',_edits.endResolution,(v)=>_edits.endResolution=v),
      ],
      if (_edits.repeat == CandidateRepeat.weekly) ...[
        const Text('Term context · choose the actual weekdays and final date.'),
        Wrap(spacing:4,children:[for(var i=1;i<=7;i++) FilterChip(label:Text(const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i-1]),
          selected:_edits.weekdays.contains(i),onSelected:(on)=>setState(() {
            _edits.weekdays=[..._edits.weekdays]; on?_edits.weekdays.add(i):_edits.weekdays.remove(i); _changed();
          }))]),
        if (_errors['weekdays'] != null) Text(_errors['weekdays']!),
        dateField('termEnd','Term end date',_edits.termEnd,(v)=>_edits.termEnd=v,
          firstDate: LocalDate.tryParse(_edits.date)),
      ],
      field('details/location','Room or location (optional)',_edits.location,(v)=>_edits.location=v),
      field('details/professor','Professor or person (optional)',_edits.professor,(v)=>_edits.professor=v),
      field('details/subtitle','Subtitle (course code)',_edits.subtitle,(v)=>_edits.subtitle=v),
      CheckboxListTile(key:const Key('confirm-association'),contentPadding:EdgeInsets.zero,
        title:const Text('I checked which title, date and time belong together against the source.'),
        subtitle:_errors['association']==null?null:Text(_errors['association']!),
        value:_edits.associationConfirmed,onChanged:(v)=>setState(() { _edits.associationConfirmed=v==true; _changed(); })),
      for(final entry in _errors.entries.where((e)=>!{'title','date','kind','lastDate','startTime','endTime','timeZone','endChoice','seedResolution','endResolution','weekdays','termEnd','association','details/location','details/professor'}.contains(e.key)))
        Text(entry.value),
      const SizedBox(height:Tokens.md),
      FilledButton(onPressed:_use,child:const Text('Use draft values')),
    ]));
  Widget _fold(String name,String label,TimeResolution? value,ValueChanged<TimeResolution?> update) => Padding(
    padding:const EdgeInsets.only(bottom:Tokens.md),child:FieldLabel(label:label,child:DropdownButtonFormField<TimeResolution>(isExpanded: true, initialValue:value,
      decoration:InputDecoration(errorText:_errors[name]),items:const[
        DropdownMenuItem(value:TimeResolution.earlier,child:Text('Earlier occurrence')),
        DropdownMenuItem(value:TimeResolution.later,child:Text('Later occurrence'))],
      onChanged:(v)=>setState(() { update(v); _changed(); }))));
}
