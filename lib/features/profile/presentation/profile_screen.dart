import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../app/widgets/themed.dart';
import '../../image_import/application/image_import_providers.dart';
import '../../image_import/domain/image_preparation.dart';
import '../../image_import/domain/image_services.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';
import 'avatar_crop_screen.dart';

/// Reads an image's upright pixel size (decoding applies EXIF orientation).
typedef ImageSizeReader = Future<Size> Function(List<int> bytes);

Future<Size> _decodeSize(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  final frame = await codec.getNextFrame();
  final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  frame.image.dispose();
  codec.dispose();
  return size;
}

final imageSizeReaderProvider = Provider<ImageSizeReader>((ref) => _decodeSize);

/// Optional on-device profile: name and photo shown on Today.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  bool _loaded = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _nameError =>
      _name.text.trim().runes.length > Profile.maxNameLength ? 'Use ${Profile.maxNameLength} characters or fewer' : null;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on ProfilePhotoRejected {
      _message = 'That image could not be used. Choose a JPEG or PNG photo.';
    } on ImageImportFailure catch (e) {
      _message = e.code == ImageFailureCode.permissionDenied
          ? 'Photo access was not allowed.'
          : 'That image could not be read.';
    } on Object {
      _message = 'The photo could not be saved.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveName() async {
    if (_nameError != null) return;
    await _run(() => ref.read(profileRepositoryProvider).setName(_name.text));
    if (mounted && _message == null) FocusScope.of(context).unfocus();
  }

  Future<void> _choosePhoto() => _run(() async {
        final path = await ref.read(imageSourcePickerProvider).pick(ImagePickKind.gallery);
        if (path == null || !mounted) return;
        final bytes = await File(path).readAsBytes();
        final size = await ref.read(imageSizeReaderProvider)(bytes);
        if (!mounted) return;
        final crop = await Navigator.of(context).push<SquareCrop>(MaterialPageRoute(
          builder: (_) => AvatarCropScreen(image: MemoryImage(bytes), imageSize: size),
        ));
        if (crop == null) return; // Cancel leaves the profile unchanged.
        await ref.read(profileRepositoryProvider).setPhoto(bytes, crop: crop);
      });

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(title: Text(title), content: Text(body), actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
        ]),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (!_loaded && profile != null) {
      _loaded = true;
      _name.text = profile.name ?? '';
    }
    final c = context.scheduleColors;
    final current = profile ?? const Profile();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
        children: [
          Center(child: ThemedAvatar(profile: current, size: 112)),
          const SizedBox(height: Tokens.lg),
          SectionGroup(header: 'Name', children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _saveName(),
                ),
                const SizedBox(height: Tokens.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _busy || _nameError != null || _name.text.trim() == (current.name ?? '') ? null : _saveName,
                    child: const Text('Save name'),
                  ),
                ),
              ]),
            ),
          ]),
          SectionGroup(header: 'Photo', children: [
            ListTile(title: Text(current.photoPath == null ? 'Choose photo' : 'Change photo'), onTap: _busy ? null : _choosePhoto),
            if (current.photoPath != null)
              ListTile(
                title: const Text('Remove photo'),
                onTap: _busy
                    ? null
                    : () async {
                        if (!await _confirm('Remove photo?', 'The photo is deleted from this device.', 'Remove') || !mounted) return;
                        await _run(() => ref.read(profileRepositoryProvider).removePhoto());
                      },
              ),
          ]),
          if (!current.isEmpty)
            SectionGroup(children: [
              ListTile(
                title: Text('Remove profile', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: _busy
                    ? null
                    : () async {
                        if (!await _confirm('Remove profile?', 'Your name and photo are deleted from this device.', 'Remove') ||
                            !mounted) {
                          return;
                        }
                        await _run(() => ref.read(profileRepositoryProvider).clear());
                        _name.clear();
                      },
              ),
            ]),
          Text(
            'Your name and photo stay on this device. They are never included in shared links or home-screen widgets.',
            style: TextStyle(color: c.secondaryInk),
          ),
          if (_busy) const Padding(padding: EdgeInsets.only(top: Tokens.md), child: LinearProgressIndicator()),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: Tokens.md),
              child: Semantics(liveRegion: true, child: Text(_message!)),
            ),
        ],
      ),
    );
  }
}
