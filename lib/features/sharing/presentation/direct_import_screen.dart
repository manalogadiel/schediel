import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/icons.dart';
import '../../../app/widgets/common.dart';
import '../../imports/domain/import_entry.dart';
import '../../imports/presentation/import_review_screen.dart';
import '../../schedules/data/schedule_repository.dart';
import '../application/share_sender.dart';
import '../domain/direct_share.dart';

/// Opens an offline schedule link in the import review. Nothing is added
/// until the recipient confirms there.
class DirectImportScreen extends ConsumerWidget {
  const DirectImportScreen({super.key, required this.link});

  final Uri? link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = link;
    final payload = uri == null ? null : DirectShare.decode(uri, ref.read(sharePayloadValidatorProvider));
    if (payload == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shared schedules'),
          leading: IconButton(tooltip: 'Close', onPressed: () => Navigator.of(context).maybePop(), icon: const AppIcon(AppIcons.close)),
        ),
        body: const EmptyState(
          title: 'This link can’t be opened',
          message: 'It may be incomplete or made by a newer version of Schediel. Ask the sender to share it again.',
        ),
      );
    }
    final source = DirectShare.sourceId(payload);
    return ImportReviewScreen(
      title: 'Shared schedules',
      entries: [
        for (final item in payload.items)
          ImportEntry(
            candidateId: item.sourceItemId,
            sourceType: 'share',
            shareId: source,
            sourceItemId: item.sourceItemId,
            sourceRevision: item.revision,
            draft: ScheduleDraft.fromSeries(item.toSeries()),
            exceptions: item.exceptions,
          ),
      ],
      sourceCategoryLabels: {for (final item in payload.items) item.sourceItemId: item.categoryLabel},
    );
  }
}
