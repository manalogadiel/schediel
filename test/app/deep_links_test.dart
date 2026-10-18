import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/deep_links.dart';
import 'package:schediel/features/sharing/application/sharing_config.dart';
void main() {
  test('HTTPS links route to preview without putting the bearer in router location', () {
    final container = ProviderContainer(overrides: [sharingConfigProvider.overrideWithValue(
      const SharingConfig(apiUrl:'https://api.example',publishableKey:'public-fixture',shareHost:'share.example'))]);
    addTearDown(container.dispose);
    final links = container.read(deepLinkCoordinatorProvider);
    final token = 'A' * 43;
    expect(links.routeFor(Uri.parse('https://share.example/s/6f1c2b1e-9d3a-4c55-8e21-0a7b3c4d5e6f#token=$token')), '/share/open');
    for (final text in ['https://other.example/s/6f1c2b1e-9d3a-4c55-8e21-0a7b3c4d5e6f#token=$token',
      'https://user@share.example/s/6f1c2b1e-9d3a-4c55-8e21-0a7b3c4d5e6f#token=$token',
      'https://share.example/s/bad#token=$token']) {
      expect(links.routeFor(Uri.parse(text)), isNull);
    }
    expect(links.routeFor(Uri.parse('schediel://occurrence/source-a/2026-11-02')), '/occurrence/source-a/2026-11-02');
    expect(links.routeFor(Uri.parse('schediel://create')), isNull);
  });

  test('a distinct, explicitly configured app-link host opens the same preview', () {
    final container = ProviderContainer(overrides: [sharingConfigProvider.overrideWithValue(
      const SharingConfig(apiUrl:'https://api.example',publishableKey:'public-fixture',shareHost:'share.example',appLinkHost:'app.example'))]);
    addTearDown(container.dispose);
    final links = container.read(deepLinkCoordinatorProvider);
    final token = 'A' * 43;
    const id = '6f1c2b1e-9d3a-4c55-8e21-0a7b3c4d5e6f';
    expect(links.routeFor(Uri.parse('https://app.example/s/$id#token=$token')), '/share/open');
    expect(links.shareLinkFor(Uri.parse('https://app.example/s/$id#token=$token'))?.shareId, id);
    for (final text in ['https://sub.app.example/s/$id#token=$token', 'https://user@app.example/s/$id#token=$token',
      'https://app.example/s/$id?x=1#token=$token', 'http://app.example/s/$id#token=$token']) {
      expect(links.routeFor(Uri.parse(text)), isNull, reason: text);
    }
  });

  test('an app-link host equal to the share host or a placeholder is ignored', () {
    for (final app in ['share.example', 'schediel.invalid', 'not a host']) {
      expect(SharingConfig(apiUrl:'https://api.example',publishableKey:'public-fixture',shareHost:'share.example',appLinkHost:app).validAppLinkHost, isNull, reason: app);
    }
  });
}
