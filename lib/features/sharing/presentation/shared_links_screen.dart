import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/time/local_date.dart';
import '../../../data/local/database.dart';
import '../application/share_sender.dart';
import '../application/sharing_config.dart';
import '../data/share_api.dart';
import 'share_open_screen.dart';

class SharedLinksScreen extends ConsumerStatefulWidget {
  const SharedLinksScreen({super.key});
  @override ConsumerState<SharedLinksScreen> createState() => _SharedLinksScreenState();
}
class _SharedLinksScreenState extends ConsumerState<SharedLinksScreen> {
  bool _busy = false;
  String? _error;
  List<PendingShareRow> _pending = [];
  @override void initState() {
    super.initState();
    if (ref.read(sharingConfigProvider).isConfigured) _refresh();
  }
  Future<void> _refresh() => _run(() async {
    final sender = ref.read(shareSenderProvider);
    // Show saved attempts even if the backend is offline.
    _pending = await sender.pending();
    if (mounted) setState(() {});
    await sender.refresh();
  });
  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await operation();
    } on ShareApiException catch (e) {
      _error = shareErrorLabel(e.code);
    } on Object {
      _error = 'Could not confirm this change. Refresh to check its current status.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> _revoke(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Revoke this link?'), content: const Text('People will no longer be able to open it. Already downloaded or imported copies remain.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Revoke link'))]));
    if (confirm != true || !mounted) return;
    await _run(() async {
      final status = await ref.read(shareSenderProvider).revoke(id);
      if (status.revokedAt == null) throw StateError('revoke_not_confirmed');
    });
  }
  Future<void> _copy(String id) => _run(() async {
    final link = await ref.read(shareSenderProvider).linkFor(id);
    if (link == null) {
      _error = 'The secret is no longer on this device. Create a replacement link.';
      return;
    }
    await Clipboard.setData(ClipboardData(text: link.toString()));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
  });
  @override Widget build(BuildContext context) {
    final configured = ref.watch(sharingConfigProvider).isConfigured;
    final links = configured ? ref.watch(ownedSharesProvider).value ?? const <OwnedShareLinkRow>[] : const <OwnedShareLinkRow>[];
    final now = ref.watch(nowProvider);
    final f = Formats.of(context);
    return Scaffold(appBar: AppBar(title: const Text('Shared links'), actions: [
      if (configured) IconButton(tooltip: 'Refresh shared links', onPressed: _busy ? null : _refresh, icon: const AppIcon(AppIcons.restore)),
    ]), body: !configured ? ListView(padding: const EdgeInsets.all(Tokens.md), children: [
      const Text('Send schedules', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: Tokens.sm),
      const Text('Choose schedules and tap Send link to share through your messaging app. The schedules travel inside the link; Schediel does not upload them.'),
      const SizedBox(height: Tokens.md),
      FilledButton(onPressed: () => context.push('/share/create'), child: const Text('Share schedules')),
      const SizedBox(height: Tokens.lg),
      const Text('Received a link?', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: Tokens.sm),
      const Text('Copy the message and open the link here. Review it before adding anything to your schedules.'),
      const SizedBox(height: Tokens.sm),
      OutlinedButton(onPressed: () => context.push('/share/open'), child: const Text('Open shared link')),
      const SizedBox(height: Tokens.lg),
      const Text('Sent links are not kept in a history here. They contain independent copies and cannot be expired or revoked.'),
    ]) : ListView(padding: const EdgeInsets.all(Tokens.md), children: [
      const Text('Only links owned by this online identity can be managed here. Losing the session or reinstalling may lose that access.'),
      if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: Tokens.md),
        child: Semantics(liveRegion: true, child: Text(_error!))),
      if (_busy) const LinearProgressIndicator(),
      for (final p in _pending) Card(child: Padding(padding: const EdgeInsets.all(Tokens.md), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Unconfirmed creation'),
        const Text('Retry uses the same saved secret and request, not a second link.'),
        Wrap(spacing: Tokens.sm, children: [
          TextButton(onPressed: _busy || now.difference(p.createdAt).inHours >= 24 ? null : () => _run(() async {
            await ref.read(shareSenderProvider).retry(p.idempotencyKey);
            _pending = await ref.read(shareSenderProvider).pending();
          }), child: const Text('Retry saved creation')),
          TextButton(onPressed: _busy ? null : () async {
            // Discard cannot recall a server link from an uncertain request.
            final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
              title: const Text('Discard this attempt?'), content: const Text('It may already exist on the server. Check the links below before creating another. Discarding does not revoke it.'),
              actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard attempt'))]));
            if (confirmed != true || !mounted) return;
            await _run(() async {
              await ref.read(shareSenderProvider).discard(p.idempotencyKey);
              _pending = await ref.read(shareSenderProvider).pending();
            });
          }, child: const Text('Discard attempt')),
        ]),
        if (now.difference(p.createdAt).inHours >= 24) const Text('Too old to retry safely. Refresh and check owner metadata.'),
      ]))),
      if (links.isEmpty && !_busy) const Padding(padding: EdgeInsets.all(Tokens.lg), child: Text('No shared links in the local list.')),
      for (final link in links) Card(child: Padding(padding: const EdgeInsets.all(Tokens.md), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${link.itemCount} ${link.itemCount == 1 ? 'schedule' : 'schedules'}', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(link.revokedAt != null ? 'Revoked' : !link.expiresAt.isAfter(now) ? 'Expired' : 'Active at last check'),
        Text('Expires ${f.fullDate(LocalDate.fromDateTime(link.expiresAt.toLocal()))}'),
        Wrap(spacing: Tokens.sm, children: [
          if (link.revokedAt == null && link.expiresAt.isAfter(now))
            TextButton(onPressed: _busy ? null : () => _copy(link.shareId), child: const Text('Copy link')),
          if (link.revokedAt == null)
            TextButton(onPressed: _busy ? null : () => _revoke(link.shareId), child: const Text('Revoke')),
        ]),
      ]))),
      FilledButton(onPressed: _busy ? null : () => context.push('/share/create'), child: const Text('Create a new link')),
    ]));
  }
}
