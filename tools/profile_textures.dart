// Run on a physical Android device with flutter run --profile
// -t tools/profile_textures.dart --build-number <newer-than-installed>.
// Temporarily replaces the app UI. Uses synthetic UI only; opens no database.
// Restore the normal release APK with adb install -r afterward; never uninstall.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:schediel/app/shell.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/app/widgets/theme_texture.dart';
import 'package:schediel/app/widgets/themed.dart';

void main() => runApp(const _Probe());

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _scroll = ScrollController();
  final _frames = <ui.FrameTiming>[];
  ThemeTexture _texture = ThemeTexture.none;
  bool _collect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(_timings);
    unawaited(_run());
  }

  void _timings(List<ui.FrameTiming> frames) {
    if (_collect) _frames.addAll(frames);
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    for (final texture in ThemeTexture.values) {
      setState(() => _texture = texture);
      _scroll.jumpTo(0);
      await Future<void>.delayed(const Duration(seconds: 1));
      _frames.clear();
      _collect = true;
      for (var i = 0; i < 4; i++) {
        await _scroll.animateTo(i.isEven ? 800 : 0,
            duration: const Duration(milliseconds: 1200), curve: Curves.linear);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _collect = false;
      final raster = _frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()..sort();
      final build = _frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()..sort();
      double percentile(List<double> data, double p) => data[(data.length * p).floor().clamp(0, data.length - 1)];
      // Aggregate timings only; no schedules, credentials or share links.
      // ignore: avoid_print
      print('TEXTURE_PERF ${jsonEncode({'texture': texture.name, 'frames': raster.length, 'raster_p50_ms': percentile(raster, .5), 'raster_p90_ms': percentile(raster, .9), 'raster_over_16ms': raster.where((n) => n > 16.667).length, 'build_p90_ms': percentile(build, .9)})}');
    }
    // ignore: avoid_print
    print('TEXTURE_PERF complete');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeTimingsCallback(_timings);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildTheme(theme: themeFor(ThemeId.lilac), brightness: Brightness.light,
        density: Density.comfortable, showCategoryColors: true, texture: _texture),
    home: Builder(builder: (context) => ThemeTextureSurface(
      texture: _texture,
      child: Scaffold(
        extendBody: true,
        body: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
          itemCount: 30,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ThemedCard(onTap: () {}, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Sample schedule $i', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12), const Text('10:00 AM – 11:00 AM'),
                const SizedBox(height: 12), const Text('Sample room · School')],
            )),
          ),
        ),
        bottomNavigationBar: FloatingNavBar(selectedIndex: 0, onSelect: (_) {}, onAdd: () {}),
      ),
    )),
  );
}
