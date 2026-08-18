// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// AppControlBridge — connects genui app-control widgets to a real app.
//
// A LogicAppTheme widget dispatches a UserActionEvent named [appThemeActionName]
// wrapped in a UiInteractionPart. The HOST captures its outgoing message's
// parts and hands them to [applyAppControls] here, which:
//   1. recognizes the appTheme action,
//   2. updates + persists [AppRuntimeManifest] (a restart reapplies it),
//   3. fires [onApplied] so the host can rebuild its ThemeData live.
// Parser is defensive: never throws, so a malformed part can't break chat.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:genai_primitives/genai_primitives.dart';
import 'package:logging/logging.dart';

import '../model/parts/ui.dart' as parts;
import 'app_runtime_manifest.dart';

/// Action name the app-control widget dispatches (see logic_app_theme.dart).
const String appThemeActionName = 'appTheme';
const String appThemeColorIndexField = 'colorIndex'; // String-encoded int
const String appThemeLogoField = 'logo';

/// Try to apply any app-control action present in [standardParts].
/// Returns true if an appTheme action was found and applied.
/// [onApplied] is called with the (persisted) manifest when applied.
bool applyAppControls(
  Iterable<StandardPart> standardParts, {
  required AppRuntimeManifest manifest,
  required File manifestFile,
  required void Function(AppRuntimeManifest) onApplied,
  Logger? log,
}) {
  for (final part in standardParts) {
    if (!part.isUiInteractionPart) continue;
    final interaction = part.asUiInteractionPart!;
    try {
      final decoded = jsonDecode(interaction.interaction);
      if (decoded is! Map) continue;
      final action = decoded['action'];
      if (action is! Map) continue;
      if (action['name'] != appThemeActionName) continue;
      final ctx = action['context'];
      _apply(ctx is Map ? Map<String, Object?>.from(ctx) : const {}, manifest,
          manifestFile, onApplied, log);
      return true;
    } catch (_) {
      // malformed interaction part: ignore, never throw
    }
  }
  return false;
}

void _apply(
  Map<String, Object?> ctx,
  AppRuntimeManifest manifest,
  File manifestFile,
  void Function(AppRuntimeManifest) onApplied,
  Logger? log,
) {
  try {
    final idxStr = ctx[appThemeColorIndexField];
    final logo = ctx[appThemeLogoField];
    if (idxStr is String) {
      final idx = int.tryParse(idxStr);
      if (idx != null && idx >= 0 && idx < Colors.primaries.length) {
        manifest.colorArgb = Colors.primaries[idx].toARGB32();
      }
    }
    if (logo is String && logo.isNotEmpty) {
      manifest.logoText = logo;
    }
    if (manifest.colorArgb != null || manifest.logoText != null) {
      // persist immediately so a restart reapplies; never await/block the UI
      manifest.save(manifestFile);
      onApplied(manifest);
      log?.info(
          'app-control applied: color=${manifest.colorArgb} logo=${manifest.logoText}');
    }
  } catch (e) {
    log?.severe('app-control apply failed: $e');
  }
}
