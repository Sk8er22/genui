// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:url_launcher/url_launcher.dart' as url;

/// A cross-platform "intent": do something real with a payload on the host OS.
///
/// The LLM picks the intent name + a [payload] (URI / deep-link / path). The
/// resolver below turns it into the platform-standard mechanism:
///   - mobile (Android/iOS)  : url_launcher / universal links / intents
///   - desktop (macos/linux/windows) : url_launcher -> default handler / xdg-open
///   - web                   : url_launcher -> browser tab
///
/// Supported intents (first slice): emailCompose, sms, tel, openMap, openUrl,
/// share, copy, calendarEvent, openInApp, runCommand(desktop), saveFile.
class UsecaseIntent {
  const UsecaseIntent(this.name, {this.payload = ''});
  final String name;
  final String payload;
}

/// Resolves [intent] to the platform mechanism and performs it.
///
/// Most intents are URIs launched via [url.launchUrl] (which already handles
/// per-OS dispatch: Android Intent, iOS universal link, desktop default app,
/// web tab). `copy` is handled natively via the Flutter clipboard. `runCommand`
/// is desktop-only.
Future<void> resolveUsecaseIntent(UsecaseIntent intent) async {
  switch (intent.name) {
    case 'copy':
      if (intent.payload.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: intent.payload));
      }
      return;
    case 'emailCompose':
    case 'sms':
    case 'tel':
    case 'openMap':
    case 'openUrl':
    case 'openInApp':
    case 'calendarEvent':
    case 'saveFile':
    case 'share':
      final Uri? uri = Uri.tryParse(intent.payload);
      if (uri == null) throw StateError('Malformed URI: ${intent.payload}');
      final bool ok = await url.launchUrl(
        uri,
        mode: kIsWeb
            ? url.LaunchMode.platformDefault
            : url.LaunchMode.externalApplication,
      );
      if (!ok) {
        throw StateError('Could not launch ${intent.name}: ${intent.payload}');
      }
      return;
    case 'runCommand':
      // Desktop-only command execution. Kept as a URI-based launch for now
      // (e.g. a file:// or a registered handler); true native Process.exec
      // needs a conditional dart:io import done per-card to stay web-safe.
      if (_isMobileOrWeb()) {
        throw UnsupportedError('runCommand is desktop-only');
      }
      if (intent.payload.isEmpty) throw StateError('No command given');
      final Uri? uri = Uri.tryParse(intent.payload);
      if (uri == null) throw StateError('Bad command payload');
      final bool ok = await url.launchUrl(uri,
          mode: url.LaunchMode.externalApplication);
      if (!ok) throw StateError('Could not run ${intent.payload}');
      return;
    default:
      throw UnsupportedError('Unknown intent: ${intent.name}');
  }
}

bool _isMobileOrWeb() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
