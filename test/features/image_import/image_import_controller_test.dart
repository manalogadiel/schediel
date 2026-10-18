import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/image_import/application/image_import_controller.dart';
import 'package:schediel/features/image_import/data/local_image_preparer.dart';
import 'package:schediel/features/image_import/domain/image_preparation.dart';
import 'package:schediel/features/image_import/domain/image_services.dart';
import 'package:schediel/features/image_import/domain/ocr_document.dart';

class FakePicker implements ImageSourcePicker {
  String? path = 'photo.png';
  Completer<String?>? pending;
  int calls = 0;
  @override
  Future<String?> pick(ImagePickKind kind) async { calls++; return pending == null ? path : pending!.future; }
}
class OwnedProbe extends PreparedImageFile {
  OwnedProbe(int revision) : super(path: 'prepared-$revision.png', width: 100, height: 100, sourceRevision: revision);
  int removals = 0;
  @override
  Future<void> remove() async { removals++; }
}
class FakePreparer implements ImageFilePreparer {
  final outputs = <OwnedProbe>[];
  Completer<PreparedImageFile>? pending;
  @override
  Future<PreparedImageFile> prepare(String path, {required int sourceRevision, PixelCrop? crop, int quarterTurns = 0}) async {
    if (pending != null) return pending!.future;
    final value = OwnedProbe(sourceRevision);
    outputs.add(value);
    return value;
  }
}
class FakeOcr implements OnDeviceOcr {
  String text = 'Exam | March 5';
  ImageImportFailure? error;
  Completer<OcrDocument>? pending;
  @override
  Future<OcrDocument> recognize(PreparedImageFile image) async {
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return OcrDocument.plain(text, sourceRevision: image.sourceRevision, width: image.width, height: image.height);
  }
}

void main() {
  late FakePicker picker;
  late FakePreparer preparer;
  late FakeOcr ocr;
  late ImageImportController controller;
  setUp(() {
    picker = FakePicker(); preparer = FakePreparer(); ocr = FakeOcr();
    controller = ImageImportController(picker: picker, preparer: preparer, ocr: ocr, newId: () => 'draft-id');
    addTearDown(controller.dispose);
  });
  test('pick and local scan create only unresolved in-memory drafts; recoverable error retains edits', () async {
    expect(picker.calls, 0);
    await controller.pick(ImagePickKind.gallery);
    expect(controller.image, isNotNull);
    await controller.scan();
    final c = controller.candidates.single;
    expect(controller.reviewEntries(), isNull);
    final raw = controller.edits[c.candidateId]!;
    raw.title = 'Edited exam'; raw.date = '2027-03-05'; raw.associationConfirmed = true;
    ocr.error = const ImageImportFailure(ImageFailureCode.ocrFailed);
    await controller.scan();
    expect(controller.failure!.code, ImageFailureCode.ocrFailed);
    expect(controller.edits[c.candidateId], same(raw));
    final entries = controller.reviewEntries()!;
    expect(entries.single.draft.title, 'Edited exam');
    expect(entries.single.alerts, isEmpty);
    expect(entries.single.draft.categoryId, isNull);
    await controller.cancelDraft();
    expect(controller.candidates, isEmpty);
    expect(preparer.outputs.single.removals, 1);
  });
  test('crop and rotate creates a new source revision and invalidates old candidates', () async {
    await controller.pick(ImagePickKind.gallery);
    await controller.scan();
    final previous = controller.image!;
    await controller.transform(const PixelCrop(0, 0, 50, 50), 1);
    expect(controller.image!.sourceRevision, greaterThan(previous.sourceRevision));
    expect(controller.candidates, isEmpty);
    expect(controller.sourceText, isNull);
    expect(controller.stage, ImageImportStage.ready);
    expect((previous as OwnedProbe).removals, 1);
  });

  test('stale OCR cannot attach to a newer selected image', () async {
    await controller.pick(ImagePickKind.gallery);
    final old = controller.image!;
    final pending = Completer<OcrDocument>(); ocr.pending = pending;
    final scanning = controller.scan();
    await controller.pick(ImagePickKind.gallery);
    final latest = controller.image!;
    expect(latest.sourceRevision, isNot(old.sourceRevision));
    pending.complete(OcrDocument.plain('Old | 2027-03-05', sourceRevision: old.sourceRevision));
    await scanning;
    expect(controller.image, same(latest));
    expect(controller.candidates, isEmpty);
    expect(controller.stage, ImageImportStage.ready);
  });

  test('cancel invalidates pending preparation and removes its late transient file', () async {
    final pending = Completer<PreparedImageFile>(); preparer.pending = pending;
    final selecting = controller.pick(ImagePickKind.gallery);
    await Future<void>.delayed(Duration.zero);
    await controller.cancelDraft();
    final lateFile = OwnedProbe(1); pending.complete(lateFile);
    await selecting;
    expect(controller.image, isNull);
    expect(lateFile.removals, 1);
    expect(controller.stage, ImageImportStage.idle);
  });

  test('new OCR run wins over older completion on the same image', () async {
    await controller.pick(ImagePickKind.gallery);
    final pending = Completer<OcrDocument>(); ocr.pending = pending;
    final first = controller.scan();
    ocr.pending = null; ocr.text = 'Newest | 2027-03-05';
    await controller.scan();
    pending.complete(OcrDocument.plain('Old | 2027-03-05', sourceRevision: controller.image!.sourceRevision));
    await first;
    expect(controller.candidates.single.title.value, 'Newest');
  });

  test('picker cancellation preserves old draft and source removal invalidates pending OCR', () async {
    picker.path = null;
    await controller.pick(ImagePickKind.gallery);
    expect(controller.stage, ImageImportStage.idle);
    expect(controller.failure, isNull);
    picker.path = 'photo.png'; await controller.pick(ImagePickKind.gallery); await controller.scan();
    final raw = controller.edits.values.single;
    picker.path = null; await controller.pick(ImagePickKind.gallery);
    expect(controller.edits.values.single, same(raw));
    final pending = Completer<OcrDocument>(); ocr.pending = pending;
    final scanning = controller.scan(); await controller.removeSource();
    pending.complete(OcrDocument.plain('Stale | 2027-03-05', sourceRevision: 1)); await scanning;
    expect(controller.candidates.single.title.value, 'Exam');
    expect(controller.image, isNull);
    expect(preparer.outputs.single.removals, 1);
  });

  test('no text and no schedule have separate failures without active entries', () async {
    await controller.pick(ImagePickKind.gallery);
    ocr.text = ''; await controller.scan();
    expect(controller.failure!.code, ImageFailureCode.noText);
    ocr.text = 'Plain nonschedule text'; await controller.scan();
    expect(controller.failure!.code, ImageFailureCode.noCandidates);
    expect(controller.reviewEntries(), isNull);
  });
}
