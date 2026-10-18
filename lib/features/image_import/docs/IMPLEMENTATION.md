# Phase 6 local image import implementation

Goal: bounded local JPEG/PNG preparation → on-device OCR → conservative, evidence-backed candidates → explicit resolution → shared transactional review. Implements SCHEDULER_SPEC.md §§8,16 and CONTRACTS.md §4. No cloud path, database writes, alerts, router or permission configuration in this feature.

## Tracer bullets (test first, observe RED, implement, GREEN)

1. `domain/image_preparation.dart`, `data/local_image_preparer.dart`: actual-signature admission (10 MiB/40Mpx before decode), static JPEG/PNG only; isolate orientation/crop/rotation, pixel-only output ≤5 MiB/12Mpx/4096 per dimension. Tests: spoofed/corrupt/animated/bomb inputs, orientation, exact crop/rotate, stripped metadata, normalization limits.
2. `domain/ocr_document.dart`, `domain/image_candidate.dart`, `domain/conservative_parser.dart`: bounded OCR and ≤100 candidates, ISO/text-month full dates, date-only posters, explicit clocks, weekly weekdays needing term context, exact spans/validated normalized regions and per-field provenance. Tests: missing year/order/AMPM/zone/title/association, overflow, hostile plain text.
3. `data/mlkit_ocr.dart`, `application/image_import_controller.dart`: injectable adapter/picker/preparer, close MLKit per run, distinct failure states, revisions invalidate stale pick/prep/OCR results, recoverable errors retain edits, own transient cleanup. Tests: mocked native channel through real normalization/parser pipeline, cancellation, retries, stale completion and disposal.
4. `presentation/image_import_screen.dart`, `image_crop_screen.dart`, `candidate_resolution_screen.dart`: gallery/optional camera only on tap, exact region preview with real pixel crop/quarter-turn rotation, removable source, editable unresolved values and explicit end/association decisions; pass only resolved `ImportEntry` drafts to `ImportReviewScreen`. Alerts/categories/duplicates/commit belong only to shared review. Widget tests cover unresolved form, source removal, cancel, preview handoff and no pre-review storage.

## Verification and release limits

Run `flutter analyze lib/features/image_import test/features/image_import` and `flutter test test/features/image_import` without editing other agents' paths. Windows mock-channel tests are not evidence of native OCR accuracy, gallery/camera permissions, mobile decoding performance or Android/iOS integration. Device QA remains required. Complex tables always carry a partial-layout warning; no completeness/confidence claim.
