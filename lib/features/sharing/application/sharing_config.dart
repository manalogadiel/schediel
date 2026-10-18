import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Link sharing configuration. Sharing stays off until a backend project and
/// an owned share domain are configured at build time:
/// --dart-define=SCHEDIEL_SUPABASE_URL=... --dart-define=SCHEDIEL_SUPABASE_KEY=...
/// --dart-define=SCHEDIEL_SHARE_HOST=... (and the Android schediel.shareHost
/// Gradle property for verified App Links).
/// Optional: --dart-define=SCHEDIEL_APP_LINK_HOST=... (and the Android
/// schediel.appLinkHost property) for a second owned host that the browser
/// preview hands off to. Browsers keep same-host navigation in the browser,
/// so the hand-off host must differ from the share host.
@immutable
class SharingConfig {
  const SharingConfig({required this.apiUrl, required this.publishableKey, required this.shareHost, this.appLinkHost = ''});

  const SharingConfig.fromEnvironment()
      : apiUrl = const String.fromEnvironment('SCHEDIEL_SUPABASE_URL'),
        publishableKey = const String.fromEnvironment('SCHEDIEL_SUPABASE_KEY'),
        shareHost = const String.fromEnvironment('SCHEDIEL_SHARE_HOST'),
        appLinkHost = const String.fromEnvironment('SCHEDIEL_APP_LINK_HOST');

  /// Supabase project URL.
  final String apiUrl;

  /// Public (publishable) project key; not a secret and not authorization.
  final String publishableKey;

  /// Owned HTTPS host serving /s/{shareId} and the domain associations.
  final String shareHost;

  /// Optional second owned host used only for browser-to-app hand-off.
  final String appLinkHost;

  static final _host = RegExp(r'^(?=.{1,253}$)(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$');

  /// [appLinkHost] when it is a real hostname distinct from [shareHost].
  String? get validAppLinkHost {
    final app = appLinkHost.toLowerCase();
    if (!_host.hasMatch(app) || app.endsWith('.invalid') || app == shareHost.toLowerCase()) return null;
    return app;
  }

  bool get isConfigured {
    final api = Uri.tryParse(apiUrl);
    return api != null && api.scheme == 'https' && api.host.isNotEmpty &&
        api.userInfo.isEmpty && !api.hasQuery && !api.hasFragment &&
        publishableKey.isNotEmpty && _host.hasMatch(shareHost) && !shareHost.endsWith('.invalid');
  }
}

final sharingConfigProvider = Provider<SharingConfig>((ref) => const SharingConfig.fromEnvironment());
