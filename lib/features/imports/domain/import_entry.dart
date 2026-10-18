import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/schedule/models.dart';
import '../../../core/schedule/schedule_json.dart';
import '../../reminders/domain/alert_rule.dart';
import '../../schedules/data/schedule_repository.dart';

/// An editable, inactive candidate. Source identity is separate from the new
/// local series ID, and alert preferences are empty until the recipient acts.
@immutable
class ImportEntry {
  const ImportEntry({
    required this.candidateId,
    required this.draft,
    required this.sourceType,
    this.exceptions = const [],
    this.alerts = const [],
    this.shareId,
    this.sourceItemId,
    this.sourceRevision,
    this.imageDraftId,
    this.keepCopy = false,
  });

  final String candidateId;
  final ScheduleDraft draft;
  final String sourceType;
  final List<OccurrenceException> exceptions;
  final List<AlertPreference> alerts;
  final String? shareId;
  final String? sourceItemId;
  final int? sourceRevision;
  final String? imageDraftId;
  final bool keepCopy;

  ImportEntry copyWith({ScheduleDraft? draft, List<AlertPreference>? alerts, bool? keepCopy}) => ImportEntry(
        candidateId: candidateId, draft: draft ?? this.draft, sourceType: sourceType,
        exceptions: exceptions, alerts: alerts ?? this.alerts, shareId: shareId,
        sourceItemId: sourceItemId, sourceRevision: sourceRevision,
        imageDraftId: imageDraftId, keepCopy: keepCopy ?? this.keepCopy,
      );

  ScheduleSeries asSeries(String id, DateTime now) {
    final d = draft.normalized();
    return ScheduleSeries(id: id, revision: 1, title: d.title, time: d.time,
        categoryId: d.categoryId, recurrence: d.recurrence, details: d.details,
        exceptions: exceptions, createdAt: now, updatedAt: now);
  }

  Map<String, Object?> toCommandJson() => {
        'candidateId': candidateId, 'sourceType': sourceType, 'shareId': shareId,
        'sourceItemId': sourceItemId, 'sourceRevision': sourceRevision, 'imageDraftId': imageDraftId,
        'draft': {'title': draft.title, 'categoryId': draft.categoryId, 'time': timeToJson(draft.time),
          'recurrence': draft.recurrence == null ? null : recurrenceToJson(draft.recurrence!),
          'details': detailsToJson(draft.details)},
        'exceptions': exceptions.map(exceptionToJson).toList(), 'keepCopy': keepCopy,
        'alerts': [for (final a in alerts) {
          'kind': a.kind.name, 'enabled': a.enabled, 'offsetMinutes': a.offsetMinutes,
          'anchorTime': a.dateOnlyAnchorTime?.toHhMm(), 'anchorZone': a.dateOnlyAnchorZone,
          'details': a.lockScreenDetails.name, 'presentation': a.presentationPreference.name,
          'snoozeMinutes': a.snoozeMinutes,
        }],
      };
}

/// Content comparison only, not source identity. Normalize case and whitespace
/// in human text; preserve structured dates, zones, recurrence and exceptions.
/// A matching fingerprint is a warning, never authority to merge rows.
String scheduleFingerprint(ScheduleSeries s) {
  Object? normalized(Object? v) {
    if (v is String) return v.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (v is List) return v.map(normalized).toList();
    if (v is Map) {
      final keys = v.keys.cast<String>().toList()..sort();
      return {for (final k in keys) k: normalized(v[k])};
    }
    return v;
  }
  final exceptions = s.exceptions.toList()..sort((a, b) => a.originalKey.compareTo(b.originalKey));
  final value = normalized({'title': s.title, 'time': timeToJson(s.time),
    'recurrence': s.recurrence == null ? null : recurrenceToJson(s.recurrence!),
    'details': detailsToJson(s.details), 'exceptions': exceptions.map(exceptionToJson).toList()});
  return sha256.convert(utf8.encode(jsonEncode(value))).toString();
}

@immutable
class ImportDuplicate {
  const ImportDuplicate({this.exact = false, this.similar = false});
  final bool exact;
  final bool similar;
}

@immutable
class ReviewEdit {
  const ReviewEdit(this.draft, this.alerts);
  final ScheduleDraft draft;
  final List<AlertPreference> alerts;
}
