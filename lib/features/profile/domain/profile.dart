import 'package:flutter/foundation.dart';

/// Optional on-device profile. Only shown in this app; never shared, synced,
/// placed in widget snapshots or sent anywhere.
@immutable
class Profile {
  const Profile({this.name, this.photoPath});

  static const maxNameLength = 40;

  final String? name;

  /// App-private 512x512 JPEG, or null.
  final String? photoPath;

  bool get isEmpty => name == null && photoPath == null;

  /// Up to two initials for the avatar placeholder, or null without a name.
  String? get initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    final letters = [parts.first, if (parts.length > 1) parts.last].map((p) => String.fromCharCode(p.runes.first));
    return letters.join().toUpperCase();
  }

  @override
  bool operator ==(Object other) => other is Profile && other.name == name && other.photoPath == photoPath;

  @override
  int get hashCode => Object.hash(name, photoPath);
}
