// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Color practice — the model defines a target gradient; the user picks the
/// colors from a palette that matches that gradient, building it color by
/// color. When they finish, the widget compares against the target and marks
/// it correct/incorrect (dispatchable as an event).
final class LogicGradientColors {
  static final _schema = S.object(
    description: 'Match a gradient by picking colors in order.',
    properties: {
      'target': S.list(
        items: S.string(),
        description: 'Target gradient hex colors in order, e.g. [#FF6B6B, #4ECDC4].',
      ),
      'palette': S.list(
        items: S.string(),
        description: 'Swatch hex colors the user may pick from (includes the '
            'target colors plus distractors).',
      ),
      'title': S.string(description: 'Optional prompt line.'),
    },
    required: ['target', 'palette'],
  );

  static final catalogItem = CatalogItem(
    name: 'LogicGradientColors',
    dataSchema: _schema,
    widgetBuilder: (ctx) {
      final Object? target = (ctx.data as Map)['target'];
      final Object? palette = (ctx.data as Map)['palette'];
      final Object? title = (ctx.data as Map)['title'];
      return LogicGradientColorsWidget(
        target: target is List ? target.whereType<String>().toList() : const [],
        palette:
            palette is List ? palette.whereType<String>().toList() : const [],
        title: title is String ? title : 'Match the gradient',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicGradientColors",
  "title":"Sunset",
  "target":["#FF6B6B","#FFD93D","#6BCB77"],
  "palette":["#FF6B6B","#4ECDC4","#FFD93D","#1A535C","#6BCB77","#ED6A5A"]}
]''',
    ],
  );
}

class LogicGradientColorsWidget extends StatefulWidget {
  const LogicGradientColorsWidget({
    super.key,
    required this.target,
    required this.palette,
    required this.title,
  });
  final List<String> target;
  final List<String> palette;
  final String title;
  @override
  State<LogicGradientColorsWidget> createState() =>
      _LogicGradientColorsWidgetState();
}

class _LogicGradientColorsWidgetState extends State<LogicGradientColorsWidget> {
  final List<String> _picked = [];
  String? _feedback;

  int get _remaining => widget.target.length - _picked.length;

  Color _c(String hex) {
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xFF000000;
    return Color(0xFF000000 | v);
  }

  void _pick(String hex) {
    if (_remaining <= 0) return;
    setState(() {
      final int at = _picked.length;
      if (at < widget.target.length && _c(hex) == _c(widget.target[at])) {
        _picked.add(hex);
        if (at + 1 == widget.target.length) {
          _feedback = 'Perfect match! Gradient complete.';
        } else {
          _feedback = 'Correct. Next color.';
        }
      } else {
        _feedback = 'Not quite — try another swatch.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Pick ${_remaining} color(s) to match the gradient.'),
            const SizedBox(height: 12),
            // Hidden target preview (small) + the user's build-strip.
            Row(
              children: [
                Row(
                  children: [
                    for (final hex in widget.target)
                      Container(
                        width: 28,
                        height: 28,
                        color: _c(hex),
                        margin: const EdgeInsets.only(right: 4),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Text('your build:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                Row(
                  children: [
                    for (final hex in _picked)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _c(hex),
                          border: Border.all(color: Colors.black26),
                        ),
                        margin: const EdgeInsets.only(right: 4),
                      ),
                    if (_remaining > 0)
                      for (var i = 0; i < _remaining; i++)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.black12),
                          ),
                          margin: const EdgeInsets.only(right: 4),
                        ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _feedback!,
                  style: TextStyle(
                    color: _feedback!.startsWith('Perfect')
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in widget.palette)
                  InkWell(
                    onTap: _remaining > 0 ? () => _pick(hex) : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _c(hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  _picked.clear();
                  _feedback = null;
                }),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
