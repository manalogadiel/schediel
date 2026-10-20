import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../features/sharing/application/sharing_config.dart';
import '../features/sharing/domain/direct_share.dart';
import '../features/sharing/domain/share_link.dart';

import 'app.dart';

/// Routes received links (spec 12.4). Internal schediel:// links only open
/// existing details or Today; share links open a preview. No link creates
/// schedules, enables alerts or imports data by itself.
class DeepLinkCoordinator {
  DeepLinkCoordinator(this._ref);

  final Ref _ref;
  final List<StreamSubscription<Uri?>> _subscriptions = [];
  String? _lastHandled;
  DateTime _lastHandledAt = DateTime.fromMillisecondsSinceEpoch(0);


  Future<void> start() async {
    try {
      final initialWidget = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialWidget != null) handle(initialWidget);
      _subscriptions.add(HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) handle(uri);
      }));
    } on MissingPluginException {
      // Not running on a device with the widget plugin.
    } on PlatformException {
      // Ignore: widget launches are optional.
    }
    try {
      final links = AppLinks();
      final initial = await links.getInitialLink();
      if (initial != null) handle(initial);
      _subscriptions.add(links.uriLinkStream.listen(handle));
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
  }

  /// Returns the route opened, or null when the link was ignored.
  String? handle(Uri uri) {
    final text = uri.toString();
    final now = DateTime.now();
    if (text == _lastHandled && now.difference(_lastHandledAt) < const Duration(seconds: 2)) return null;
    _lastHandled = text;
    _lastHandledAt = now;
    final location = routeFor(uri);
    if (location == null) return null;
    final router = _ref.read(routerProvider);
    if (location == '/today') {
      router.go(location);
    } else {
      // Pushed on top so an unsaved editor underneath keeps its values.
      // The bearer remains in ephemeral arguments, not a route/query that
      // a router diagnostic or restoration log could disclose.
      router.push(location, extra: switch (location) {
        '/share/open' => shareLinkFor(uri),
        '/share/import' => uri,
        _ => null,
      });
    }
    return location;
  }

  /// Parses a bearer link on the share host or the configured hand-off host.
  ShareLink? shareLinkFor(Uri uri) {
    final config = _ref.read(sharingConfigProvider);
    if (!config.isConfigured || uri.scheme != 'https') return null;
    final app = config.validAppLinkHost;
    return ShareLink.tryParse(uri, host: config.shareHost) ??
        (app == null ? null : ShareLink.tryParse(uri, host: app));
  }

  String? routeFor(Uri uri) {
    if (uri.scheme == 'schediel') {
      if (uri.host == 'today') return '/today';
      if (DirectShare.isDirect(uri)) return '/share/import';
      if (uri.host == 'occurrence' && uri.pathSegments.length == 2) {
        final [seriesId, key] = uri.pathSegments;
        if (RegExp(r'^[0-9a-zA-Z-]{1,64}$').hasMatch(seriesId) && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
          return '/occurrence/$seriesId/$key';
        }
      }
      return null;
    }
    if (shareLinkFor(uri) != null) return '/share/open';
    return null;
  }
}

final deepLinkCoordinatorProvider = Provider<DeepLinkCoordinator>((ref) {
  final coordinator = DeepLinkCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
