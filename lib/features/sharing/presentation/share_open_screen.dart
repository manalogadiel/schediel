import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/icons.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/labeled_field.dart';
import '../../../app/widgets/common.dart';
import '../../imports/domain/import_entry.dart';
import '../../imports/presentation/import_review_screen.dart';
import '../../schedules/data/schedule_repository.dart';
import '../application/share_sender.dart';
import '../application/sharing_config.dart';
import '../data/share_api.dart';
import '../domain/direct_share.dart';
import '../domain/share_link.dart';
import '../domain/share_payload.dart';

class ShareOpenScreen extends ConsumerStatefulWidget {
  const ShareOpenScreen({super.key, this.initialLink});
  final ShareLink? initialLink;
  @override ConsumerState<ShareOpenScreen> createState() => _ShareOpenScreenState();
}
class _ShareOpenScreenState extends ConsumerState<ShareOpenScreen> {
  final _text = TextEditingController();
  ShareLink? _link;
  SharePayload? _payload;
  String? _resolvedShareId;
  bool _loading = false;
  String? _error;

  Uri? _clipboardLink;
  ShareLink? _clipboardOnline;

  ShareLink? _onlineLink(String text) {
    final config = ref.read(sharingConfigProvider);
    if (!config.isConfigured) return null;
    return ShareLink.tryParseText(text, host: config.shareHost) ??
        (config.validAppLinkHost == null ? null : ShareLink.tryParseText(text, host: config.validAppLinkHost!));
  }

  @override void initState() {
    super.initState();
    if (widget.initialLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve(widget.initialLink!));
    } else {
      _checkClipboard();
    }
  }

  /// Offers a copied Schediel link; only read when this screen is opened.
  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final link = data?.text == null ? null : DirectShare.findInText(data!.text!);
      final online = data?.text == null ? null : _onlineLink(data!.text!);
      if (mounted) setState(() { _clipboardLink = link; _clipboardOnline = online; });
    } on Object {
      // Clipboard access is optional.
    }
  }

  void _openDirect(Uri link) => context.pushReplacement('/share/import', extra: link);
  @override void dispose() { _text.dispose(); super.dispose(); }

  void _open() {
    final direct = DirectShare.findInText(_text.text);
    if (direct != null) { _text.clear(); _openDirect(direct); return; }
    if (!ref.read(sharingConfigProvider).isConfigured) { setState(() => _error = 'invalid_token'); return; }
    final link = _onlineLink(_text.text);
    _text.clear();
    if (link == null) { setState(() => _error = 'invalid_token'); return; }
    _resolve(link);
  }

  Future<void> _resolve(ShareLink link) async {
    if (_loading || !ref.read(sharingConfigProvider).isConfigured) return;
    setState(() { _loading = true; _error = null; _link = link; });
    try {
      final result = await ref.read(shareApiProvider).resolve(shareId: link.shareId, token: link.token);
      if (!mounted) return;
      if (result.schemaVersion != sharePayloadSchemaVersion) {
        setState(() { _error = 'unsupported_schema_version'; _loading = false; });
        return;
      }
      final issues = ref.read(sharePayloadValidatorProvider).validate(result.payload);
      if (issues.isNotEmpty || !ShareLink.isShareId(result.shareId) || link.shareId != null && result.shareId != link.shareId) {
        setState(() { _error = 'invalid_request'; _loading = false; }); return;
      }
      final payload = SharePayload.fromJson(result.payload as Map<String, dynamic>);
      if (payload.items.length != result.itemCount) {
        setState(() { _error = 'invalid_request'; _loading = false; }); return;
      }
      setState(() { _payload = payload; _resolvedShareId = result.shareId; _loading = false; });
    } on ShareApiException catch (e) {
      if (mounted) setState(() { _error = e.code; _loading = false; });
    } on Object {
      if (mounted) setState(() { _error = 'network'; _loading = false; });
    }
  }

  @override Widget build(BuildContext context) {
    final config = ref.watch(sharingConfigProvider);
    final payload = _payload;
    if (config.isConfigured && payload != null) {
      return ImportReviewScreen(title: 'Shared schedules', entries: [
        for (final item in payload.items) ImportEntry(
          candidateId: item.sourceItemId, sourceType: 'share', shareId: _resolvedShareId!,
          sourceItemId: item.sourceItemId, sourceRevision: item.revision,
          draft: ScheduleDraft.fromSeries(item.toSeries()), exceptions: item.exceptions,
        ),
      ], sourceCategoryLabels: {for (final item in payload.items) item.sourceItemId: item.categoryLabel});
    }
    return Scaffold(appBar: AppBar(title: const Text('Open shared link'), leading: IconButton(
      tooltip: 'Close', onPressed: () => Navigator.of(context).maybePop(), icon: const AppIcon(AppIcons.close))),
      body: ListView(padding: const EdgeInsets.all(Tokens.md), children: [
        const Text('Paste a link or the whole message to review.'),
        if (_clipboardLink != null || _clipboardOnline != null) ...[
          const SizedBox(height: Tokens.md),
          FilledButton.tonalIcon(key: const ValueKey('paste-direct'), onPressed: () => _clipboardLink != null
              ? _openDirect(_clipboardLink!) : _resolve(_clipboardOnline!),
            icon: const AppIcon(AppIcons.copy, size: 18), label: const Text('Open copied link')),
        ],
        const SizedBox(height: Tokens.md),
        FieldLabel(label: 'Shared link', child: TextField(controller: _text, enabled: !_loading, autocorrect: false, enableSuggestions: false,
          keyboardType: TextInputType.url,
          onSubmitted: (_) => _open())),
        const SizedBox(height: Tokens.md),
        FilledButton(onPressed: _loading ? null : _open, child: const Text('Open preview')),
        if (_loading) const Padding(padding: EdgeInsets.all(Tokens.lg), child: Center(child: CircularProgressIndicator.adaptive())),
        if (_error != null) Semantics(liveRegion: true, child: EmptyState(title: shareErrorLabel(_error!),
          message: _error == 'rate_limited' ? 'Wait a moment before trying again.' : null,
          action: _link != null && !{'not_found','link_revoked','link_expired','invalid_token','invalid_request','unsupported_schema_version'}.contains(_error)
              ? TextButton(onPressed: () => _resolve(_link!), child: const Text('Try again')) : null)),
      ]));
  }
}

String shareErrorLabel(String code) => switch (code) {
  'link_expired' => 'Shared link expired',
  'link_revoked' => 'Shared link revoked',
  'not_found' || 'invalid_request' || 'invalid_token' => 'Shared link unavailable',
  'unsupported_schema_version' => 'This link needs a newer version',
  'rate_limited' => 'Too many requests',
  'quota_exceeded' => 'Sharing limit reached. Try again later.',
  'payload_too_large' => 'This selection is too large. Split it into smaller links.',
  'idempotency_expired' => 'This creation is too old to retry safely. Check your shared links before creating another.',
  'idempotency_mismatch' => 'The saved creation does not match this request.',
  'secret_unavailable' => 'The saved link secret is no longer available.',
  'share_owner_unavailable' => 'This attempt belongs to an earlier online identity, so it was not retried. Keep it, or discard it after checking your links.',
  'unauthenticated' => 'Could not verify this sharing session',
  'validation_failed' => 'Check the selected schedules before sharing',
  _ => 'Could not reach sharing. Check your connection and try again.',
};
