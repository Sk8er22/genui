// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test: AppRuntimeManifest survives an app "restart". A widget/app-control
// writes the manifest (Apply), a fresh load() (simulating a relaunch) restores
// the applied color/logo, and the host can drive its ThemeData from it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  late Directory tmp;
  File manifestFile = File('${Directory.systemTemp.path}/_noop');

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('genui_manifest_test');
    manifestFile = AppRuntimeManifest.filePathFor(
        'test_app',
        overriddenDir: tmp.path);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('empty manifest -> defaults (no file yet)', () async {
    final m = await AppRuntimeManifest.load(manifestFile);
    expect(m.colorArgb, isNull);
    expect(m.logoText, isNull);
  });

  test('apply -> save -> RESTART (fresh load) -> applied state restored',
      () async {
    // "Apply" step: the app-control widget / host mutates + persists.
    final applied = AppRuntimeManifest()
      ..colorArgb = 0xFF26A69A  // a teal
      ..logoText = 'AquaApp'
      ..extra['widgetCatalog'] = ['LogicAppTheme', 'LogicChess'];
    await applied.save(manifestFile);

    // Faithful relaunch: a BRAND-NEW manifest object re-reads from disk.
    final restarted = await AppRuntimeManifest.load(manifestFile);
    expect(restarted.colorArgb, 0xFF26A69A);
    expect(restarted.logoText, 'AquaApp');
    expect(restarted.extra['widgetCatalog'],
        ['LogicAppTheme', 'LogicChess']);
    expect(restarted.updatedAt, isNotNull);
  });

  test('corrupt manifest does not crash restart (falls back to defaults)',
      () async {
    await manifestFile.writeAsString('{not valid json');
    final m = await AppRuntimeManifest.load(manifestFile);
    expect(m.colorArgb, isNull);
    expect(m.logoText, isNull);
  });
}
