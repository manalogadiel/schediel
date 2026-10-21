import 'package:flutter/material.dart';

import '../../../app/widgets/labeled_field.dart';
import '../domain/candidate_resolution.dart';

class ScanRepeatPicker extends StatelessWidget {
  const ScanRepeatPicker({super.key, required this.value, required this.onChanged});
  final CandidateRepeat value;
  final ValueChanged<CandidateRepeat> onChanged;

  @override
  Widget build(BuildContext context) => FieldLabel(
    label: 'Repeats',
    child: SegmentedButton<CandidateRepeat>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: const [
        ButtonSegment(value: CandidateRepeat.oneTime, label: Text('One time', textAlign: TextAlign.center)),
        ButtonSegment(value: CandidateRepeat.weekly, label: Text('Weekly', textAlign: TextAlign.center)),
      ],
      selected: {value},
      onSelectionChanged: (values) => onChanged(values.single),
    ),
  );
}
