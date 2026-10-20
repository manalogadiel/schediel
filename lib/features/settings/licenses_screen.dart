import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';
import '../../app/widgets/common.dart';

/// Short credits first; the original, complete notices stay available.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Credits and licenses')),
    body: ListView(
      padding: const EdgeInsets.all(Tokens.md),
      children: [
        const Text(
          'Schediel is built with Flutter and open-source fonts, icons and libraries. Tap a name to read its full notice.',
        ),
        const SizedBox(height: Tokens.lg),
        SectionGroup(
          header: 'Fonts and icons',
          children: [
            for (final (name, description, asset) in const [
              ('Inter', 'App text', 'assets/fonts/LICENSE-Inter.txt'),
              ('Caveat', 'Sketch headings', 'assets/fonts/LICENSE-Caveat.txt'),
              (
                'Silkscreen',
                'Pixel headings',
                'assets/fonts/LICENSE-Silkscreen.txt',
              ),
              (
                'Lucide icons',
                'Interface icons',
                'assets/icons/LICENSE-lucide.txt',
              ),
            ])
              ListTile(
                title: Text(name),
                subtitle: Text(description),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _BundledNotice(title: name, asset: asset),
                  ),
                ),
              ),
          ],
        ),
        OutlinedButton(
          onPressed: () =>
              showLicensePage(context: context, applicationName: 'Schediel'),
          child: const Text('All library licenses'),
        ),
      ],
    ),
  );
}

class _BundledNotice extends StatefulWidget {
  const _BundledNotice({required this.title, required this.asset});
  final String title, asset;

  @override
  State<_BundledNotice> createState() => _BundledNoticeState();
}

class _BundledNoticeState extends State<_BundledNotice> {
  late final Future<String> _notice = rootBundle.loadString(widget.asset);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<String>(
      future: _notice,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmptyState(
            title: 'Could not load this notice',
            action: TextButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Schediel',
              ),
              child: const Text('All library licenses'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(Tokens.md),
          child: SelectableText(
            snapshot.data!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    ),
  );
}
