// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';
import '../../model/ui_models.dart';
import '../../app_control/app_control_bridge.dart'
    show appThemeColorIndexField, appThemeLogoField;

/// App-control widget: lets the LLM propose a new app theme (color + logo).
/// The user clicks APPLY to commit the change — the widget dispatches a
/// UserActionEvent (name `appTheme`) that the host app listens for and applies
/// to its real ThemeData. Nothing mutates until Apply is pressed.
const String appThemeEventName = 'appTheme';

final class LogicAppTheme {
  static final catalogItem = CatalogItem(
    name: 'LogicAppTheme',
    dataSchema: S.object(
      description: 'Pick a theme color + logo; Apply commits it to the app.',
      properties: {
        'title': S.string(),
        'colorIndex': S.integer(
            description: 'Suggested Material color index in the swatch row.'),
        'logoText': S.string(description: 'Suggested logo/app label.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (itemContext) {
      final m = (itemContext.data as Map);
      return LogicAppThemeWidget(
        title: m['title'] is String ? m['title'] as String : 'App theme',
        proposedColorIndex: m['colorIndex'] is int ? m['colorIndex'] as int : 7,
        proposedLogo: m['logoText'] is String ? m['logoText'] as String : '',
        itemContext: itemContext,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicAppTheme","title":"Rebrand my app",
  "colorIndex":9,"logoText":"Aqua"}
]''',
    ],
  );
}

class LogicAppThemeWidget extends StatefulWidget {
  const LogicAppThemeWidget({
    super.key,
    required this.itemContext,
    this.title = 'App theme',
    this.proposedColorIndex = 7,
    this.proposedLogo = '',
  });
  final CatalogItemContext itemContext;
  final String title;
  final int proposedColorIndex;
  final String proposedLogo;
  @override
  State<LogicAppThemeWidget> createState() => _LogicAppThemeWidgetState();
}

class _LogicAppThemeWidgetState extends State<LogicAppThemeWidget> {
  late int _colorIndex;
  late final TextEditingController _logoC;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _colorIndex = widget.proposedColorIndex.clamp(0, 14);
    _logoC = TextEditingController(text: widget.proposedLogo);
  }

  @override
  void dispose() {
    _logoC.dispose();
    super.dispose();
  }

  void _apply() {
    setState(() => _applied = true);
    widget.itemContext.dispatchEvent(UserActionEvent(
      name: appThemeEventName,
      sourceComponentId: widget.itemContext.id,
      context: {
        appThemeColorIndexField: '$_colorIndex',
        appThemeLogoField: _logoC.text.trim(),
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Color preview = Colors.primaries[_colorIndex];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            // live preview bar
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: preview,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                _logoC.text.isEmpty ? 'Logo' : _logoC.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            Text('Accent color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < Colors.primaries.length && i < 14; i++)
                    GestureDetector(
                      onTap: () => setState(() {
                        _colorIndex = i;
                        _applied = false;
                      }),
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.primaries[i],
                          shape: BoxShape.circle,
                          border: i == _colorIndex
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Logo / app name', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _logoC,
              onChanged: (_) => setState(() => _applied = false),
              decoration: const InputDecoration(
                  hintText: 'App name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              // Always an Apply button: nothing mutates until it is pressed.
              onPressed: _apply,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: preview),
              icon: const Icon(Icons.check),
              label: Text(_applied ? 'Applied ✓' : 'Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
