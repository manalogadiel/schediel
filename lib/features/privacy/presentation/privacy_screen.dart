import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../sharing/application/sharing_config.dart';
import '../../sharing/data/share_api.dart';
import '../../sharing/presentation/share_open_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../data/privacy_repository.dart';
import '../domain/backend_deletion.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});
  @override ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}
class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _busy = false;
  bool _expired = false;
  BackendDeletion? _job;
  String? _message;
  @override void initState() {
    super.initState();
    _loadJob();
  }
  Future<void> _loadJob() async {
    if (!ref.read(sharingConfigProvider).isConfigured) return;
    final repo = ref.read(privacyRepositoryProvider);
    final id = await repo.lastJobId();
    if (id != null && mounted) await _run(() async => _job = await repo.refreshBackendDeletion(id));
  }
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try { await action(); }
    on BackendDeletionExpired { _expired = true; _message = "The earlier deletion request can't be confirmed anymore. Request deletion again to send a new one."; }
    on ShareApiException catch (e) { _message = shareErrorLabel(e.code); }
    on Object { _message = 'Could not confirm the change. Check its status before trying again.'; }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<bool> _confirm(String title, String message, String action) async => await showDialog<bool>(
    context: context, builder: (c) => AlertDialog(title: Text(title), content: Text(message), actions: [
      TextButton(onPressed: () => Navigator.pop(c,false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(c,true), child: Text(action)),
    ])) == true;
  Future<void> _localDelete() async {
    var removeProfile = true;
    final confirmed = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(
      builder: (c, setDialog) => AlertDialog(
        scrollable: true,
        title: const Text('Delete local schedules?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('This removes saved schedules, their exceptions and alert preferences from this app. Categories and appearance stay. Shared links are not revoked.'),
          const SizedBox(height: Tokens.sm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: removeProfile,
            onChanged: (v) => setDialog(() => removeProfile = v ?? false),
            title: const Text('Also remove profile name and photo'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete schedules')),
        ],
      ),
    )) == true;
    if (!confirmed || !mounted) return;
    await _run(() async {
      await ref.read(privacyRepositoryProvider).deleteLocalSchedules();
      if (removeProfile) await ref.read(profileRepositoryProvider).clear();
      _message = 'Local schedules deleted. Native alerts and widgets will reconcile from the saved change.';
    });
  }
  Future<void> _backendDelete({bool fresh = false}) async {
    if (!await _confirm('Delete my backend data?', 'This revokes and removes shared snapshots owned by the current online identity. Local schedules and other people’s downloaded copies remain.', 'Delete backend data') || !mounted) return;
    await _run(() async {
      // A fresh command is saved before it is sent, so after a lost response
      // the next attempt must replay it rather than mint another one.
      _job = await ref.read(privacyRepositoryProvider).requestBackendDeletion(fresh: fresh, onSaved: () => _expired = false);
    });
  }
  @override Widget build(BuildContext context) {
    final configured = ref.watch(sharingConfigProvider).isConfigured;
    return Scaffold(appBar: AppBar(title: const Text('Privacy and data')), body: ListView(
      padding: const EdgeInsets.all(Tokens.md), children: [
        SectionGroup(header:'On this device', children: [
          const Padding(padding: EdgeInsets.all(Tokens.md), child: Text('Schedules are stored locally in the app database. They are not encrypted by Schediel and are not synchronized to a recovery account. Device security and platform backup behavior are separate. Uninstalling or losing the device can lose schedules. Your optional profile name and photo are stored the same way and are never uploaded by Schediel.')),
          ListTile(title: const Text('Delete local schedules'), onTap: _busy ? null : _localDelete),
        ]),
        const SectionGroup(header:'Image scanning', children:[
          Padding(padding: EdgeInsets.all(Tokens.md), child: Text('On-device scanning keeps the chosen image on this device. Recognition can be incomplete or wrong; review every selected entry. Cloud AI scanning is disabled until provider, audience, privacy and budget requirements are approved. There is no silent upload fallback.')),
        ]),
        SectionGroup(header:'Online sharing', children: [
          const Padding(padding: EdgeInsets.all(Tokens.md), child: Text('Only schedules and optional fields selected for a link are uploaded. Anyone with a forwarded link can view it until expiry or revocation. Downloaded or imported copies cannot be recalled. A lost anonymous session may lose management rights; this app does not promise recovery.')),
          if (!configured) const Padding(padding: EdgeInsets.all(Tokens.md), child: Text('Sharing backend is not configured in this build.')),
          if (configured && !_expired) ListTile(title: const Text('Delete my backend data'), onTap: _busy ? null : _backendDelete),
          if (configured && _expired) ListTile(title: const Text('Request deletion again'), onTap: _busy ? null : () => _backendDelete(fresh: true)),
          if (_job != null) Padding(padding: const EdgeInsets.all(Tokens.md), child: Semantics(liveRegion:true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Backend deletion: ${_job!.status}'),
              if (_job!.status == 'completed') Text('${_job!.deletedShareCount} shared snapshots deleted. Local schedules preserved.'),
              TextButton(onPressed: _busy ? null : () => _run(() async => _job = await ref.read(privacyRepositoryProvider).refreshBackendDeletion(_job!.deletionJobId)), child: const Text('Check deletion status')),
            ]))),
        ]),
        if (_busy) const LinearProgressIndicator(),
        if (_message != null) Semantics(liveRegion:true, child: Text(_message!)),
      ]));
  }
}
