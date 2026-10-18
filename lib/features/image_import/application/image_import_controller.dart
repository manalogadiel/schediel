import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../imports/domain/import_entry.dart';
import '../domain/candidate_resolution.dart';
import '../domain/conservative_parser.dart';
import '../data/local_image_preparer.dart';
import '../domain/image_candidate.dart';
import '../domain/image_preparation.dart';
import '../domain/image_services.dart';

enum ImageImportStage { idle, picking, preparing, ready, scanning, review, error }

class ImageImportController extends ChangeNotifier {
  ImageImportController({required this.picker, required this.preparer, required this.ocr, required this.newId, ConservativeCandidateParser? parser}) : parser = parser ?? ConservativeCandidateParser();
  final ImageSourcePicker picker;
  final ImageFilePreparer preparer;
  final OnDeviceOcr ocr;
  final String Function() newId;
  final ConservativeCandidateParser parser;
  ImageImportStage stage = ImageImportStage.idle;
  PreparedImageFile? image;
  String? imageDraftId, sourceText, notice;
  ImageImportFailure? failure;
  List<ImageCandidate> candidates = [];
  final edits = <String, CandidateEdits>{};
  final selected = <String>{};
  final resolved = <String, ResolvedImageCandidate>{};
  int _revision = 0;
  int _sourceEpoch = 0, _scanEpoch = 0;
  bool _disposed = false;
  final _owned = <PreparedImageFile>{};
  bool get busy => [ImageImportStage.picking, ImageImportStage.preparing, ImageImportStage.scanning].contains(stage);
  void _emit() { if (!_disposed) notifyListeners(); }
  ImageImportStage get _resting => candidates.isNotEmpty ? ImageImportStage.review : image != null ? ImageImportStage.ready : ImageImportStage.idle;

  Future<void> pick(ImagePickKind kind) async {
    final epoch = ++_sourceEpoch; _scanEpoch++;
    if (_disposed) return;
    stage = ImageImportStage.picking; failure = null; notice = null; _emit();
    try {
      final path = await picker.pick(kind);
      if (_disposed || epoch != _sourceEpoch) return;
      if (path == null) {
        stage = _resting; notice = 'Image selection cancelled. Your existing draft is unchanged.'; _emit(); return;
      }
      stage = ImageImportStage.preparing; _emit();
      final next = await preparer.prepare(path, sourceRevision: ++_revision);
      _owned.add(next);
      if (_disposed || epoch != _sourceEpoch) { await _remove(next); return; }
      final previous = image;
      image = next; imageDraftId = newId();
      sourceText = null; candidates = []; edits.clear(); selected.clear(); resolved.clear();
      stage = ImageImportStage.ready; _emit();
      if (previous != null) await _remove(previous);
    } catch (e) {
      if (_disposed || epoch != _sourceEpoch) return;
      failure = e is ImageImportFailure ? e : const ImageImportFailure(ImageFailureCode.unreadable);
      stage = ImageImportStage.error; _emit();
    }
  }

  Future<void> transform(PixelCrop crop, int quarterTurns) async {
    final source = image;
    if (source == null || busy || _disposed) return;
    final epoch = ++_sourceEpoch; _scanEpoch++;
    stage = ImageImportStage.preparing; failure = null; _emit();
    try {
      final next = await preparer.prepare(source.path, sourceRevision: ++_revision,
        crop: crop, quarterTurns: quarterTurns);
      _owned.add(next);
      if (_disposed || epoch != _sourceEpoch) { await _remove(next); return; }
      image = next; imageDraftId = newId();
      sourceText = null; candidates = []; edits.clear(); selected.clear(); resolved.clear();
      notice = 'Image region updated. Scan again to recognize this region.';
      stage = ImageImportStage.ready; _emit();
      await _remove(source);
    } catch (e) {
      if (_disposed || epoch != _sourceEpoch) return;
      failure = e is ImageImportFailure ? e : const ImageImportFailure(ImageFailureCode.unreadable);
      stage = ImageImportStage.error; _emit();
    }
  }

  Future<void> scan() async {
    final source = image;
    if (source == null || _disposed) return;
    final epoch = ++_scanEpoch;
    final sourceEpoch = _sourceEpoch;
    bool current() => !_disposed && epoch == _scanEpoch && sourceEpoch == _sourceEpoch && identical(source, image);
    stage = ImageImportStage.scanning; failure = null; notice = null; _emit();
    try {
      final document = await ocr.recognize(source);
      if (!current()) return;
      if (document.sourceRevision != source.sourceRevision || document.width != source.width || document.height != source.height) {
        throw const ImageImportFailure(ImageFailureCode.ocrFailed);
      }
      if (document.text.trim().isEmpty) throw const ImageImportFailure(ImageFailureCode.noText);
      final result = parser.parse(document);
      if (result.candidates.isEmpty) throw const ImageImportFailure(ImageFailureCode.noCandidates);
      final old = {for (final c in candidates) c.candidateId: c};
      final retained = <String, CandidateEdits>{};
      for (final c in result.candidates) {
        retained[c.candidateId] = old[c.candidateId]?.sourceLine.text == c.sourceLine.text && edits.containsKey(c.candidateId)
          ? edits[c.candidateId]! : CandidateEdits.fromCandidate(c);
      }
      candidates = result.candidates; sourceText = document.text;
      edits..clear()..addAll(retained);
      selected..clear()..addAll(candidates.map((c) => c.candidateId));
      resolved.clear();
      notice = result.layoutNotice; stage = ImageImportStage.review; _emit();
    } catch (e) {
      if (!current()) return;
      failure = e is ImageImportFailure ? e : const ImageImportFailure(ImageFailureCode.ocrFailed);
      stage = ImageImportStage.error; _emit();
    }
  }

  Future<void> _remove(PreparedImageFile file) async {
    try { await file.remove(); _owned.remove(file); }
    catch (_) { notice = 'The source was detached, but temporary-file cleanup failed. Close import and try again.'; _emit(); }
  }

  Future<void> cancelDraft() async {
    _sourceEpoch++; _scanEpoch++;
    image = null; imageDraftId = null; sourceText = null; candidates = [];
    edits.clear(); selected.clear(); resolved.clear(); failure = null; notice = null;
    stage = ImageImportStage.idle; _emit();
    for (final owned in _owned.toList()) { await _remove(owned); }
  }
  Future<void> removeSource() async {
    _sourceEpoch++; _scanEpoch++;
    final previous = image; image = null;
    stage = _resting; notice = 'Source image removed. Draft values and OCR evidence remain only for this review.'; _emit();
    if (previous != null) await _remove(previous);
  }
  void cancelWork() { _sourceEpoch++; _scanEpoch++; stage = _resting; notice = 'Scan cancelled. Nothing was added.'; _emit(); }

  void edited(String id) { resolved.remove(id); _emit(); }
  CandidateResolutionResult resolve(String id) {
    final candidate = candidates.firstWhere((c) => c.candidateId == id);
    final result = resolveImageCandidate(candidate, edits[id]!);
    if (result.resolved != null) resolved[id] = result.resolved!;
    _emit(); return result;
  }
  void select(String id, bool on) { on ? selected.add(id) : selected.remove(id); _emit(); }

  List<ImportEntry>? reviewEntries() {
    if (selected.isEmpty || busy) return null;
    final entries = <ImportEntry>[];
    for (final c in candidates.where((c) => selected.contains(c.candidateId))) {
      final result = resolveImageCandidate(c, edits[c.candidateId]!);
      if (result.resolved == null) { notice = 'Resolve the missing fields for each selected entry before review.'; _emit(); return null; }
      resolved[c.candidateId] = result.resolved!;
      entries.add(ImportEntry(candidateId: c.candidateId, draft: result.resolved!.draft, sourceType: 'image',
        imageDraftId: imageDraftId, sourceItemId: c.candidateId, sourceRevision: c.sourceRevision,
        alerts: const [], exceptions: const [], keepCopy: false));
    }
    return List.unmodifiable(entries);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancelDraft());
    super.dispose();
  }
}
