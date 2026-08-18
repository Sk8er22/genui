// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// AppRuntimeManifest — a tiny JSON manifest persisted to disk that lets a
// genui "app-control" widget's *applied* state survive an app restart, and
// lets the catalog advertise dynamically-added widgets.
//
// The widget proposes (theme color / logo / widget list); the APP decides to
// APPLY (the "always an Apply button" rule). On Apply the host writes this
// manifest. On next launch the host loads it and applies the saved state, so
// the changes take effect without the LLM having to re-send anything.

import 'dart:convert';
import 'dart:io';

/// Persisted runtime state for a genui app-control host.
class AppRuntimeManifest {
  /// Seed/accent color, stored as the index into [swatches] (see package
  /// usecases) OR as an ARGB int for generality. We store the ARGB int so the
  /// file is self-describing; the AppTheme widget maps to a swatch index.
  int? colorArgb;

  /// App/logo label applied.
  String? logoText;

  /// When the manifest was last written (ISO-8601 UTC).
  String? updatedAt;

  /// Extra JSON bag (e.g. catalog model list, nav tabs) preserved verbatim.
  final Map<String, Object> extra = {};

  AppRuntimeManifest();

  /// Load from [file]; returns a manifest with whatever was there, or an
  /// empty (default) manifest if the file is absent/invalid.
  static Future<AppRuntimeManifest> load(File file) async {
    final manifest = AppRuntimeManifest();
    try {
      if (!await file.exists()) return manifest;
      final raw = await file.readAsString();
      final Map<String, Object> map =
          (jsonDecode(raw) as Map).cast<String, Object>();
      manifest.colorArgb = map['colorArgb'] as int?;
      manifest.logoText = map['logoText'] as String?;
      manifest.updatedAt = map['updatedAt'] as String?;
      for (final k in map.keys) {
        if (k == 'colorArgb' || k == 'logoText' || k == 'updatedAt') continue;
        manifest.extra[k] = map[k] as Object;
      }
    } catch (_) {
      // Corrupt manifest -> fall back to defaults; never crash startup.
    }
    return manifest;
  }

  /// Persist to [file] (atomically). No-op-safe if called repeatedly.
  Future<void> save(File file) async {
    updatedAt = DateTime.now().toUtc().toIso8601String();
    final Map<String, Object> map = <String, Object>{
      if (colorArgb != null) 'colorArgb': colorArgb!,
      if (logoText != null) 'logoText': logoText!,
      if (updatedAt != null) 'updatedAt': updatedAt!,
      ...extra,
    };
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(map));
    await tmp.rename(file.path);
  }

  /// Convenience: the manifest file path for an app.
  static File filePathFor(String appName, {String? overriddenDir}) {
    final dir = overriddenDir ?? (Platform.environment['HOME'] ?? '.');
    return File('$dir/.genui_${appName}_manifest.json');
  }
}
