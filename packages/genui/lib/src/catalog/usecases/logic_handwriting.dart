// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

/// Handwriting practice — "guide" lines made of dots (beginner) or blank
/// (advanced), stepping from single letters to short words.
///
/// The content is data-driven: the LLM supplies which letters / words to
/// practice and the level. Rendering (dotted guide, baseline, stroke hint)
/// is deterministic Dart.
final class LogicHandwriting {
  static final _schema = S.object(
    description: 'Handwriting practice for letters then short words.',
    properties: {
      'title': S.string(description: 'Section/class title, e.g. "Letters A-C".'),
      'items': S.list(items: S.string(),
          description: 'Letters (single char) or short words, in order.'),
      'level': S.string(
        enumValues: ['beginner', 'advanced'],
        description: 'beginner = dotted tracer + arrows; advanced = blank baseline',
      ),
    },
    required: ['title', 'items'],
  );

  static final catalogItem = CatalogItem(
    name: 'LogicHandwriting',
    dataSchema: _schema,
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? items = (ctx.data as Map)['items'];
      final Object? level = (ctx.data as Map)['level'];
      return LogicHandwritingWidget(
        title: title is String ? title : 'Practice',
        items: items is List ? items.whereType<String>().toList() : const [],
        beginner: level != 'advanced',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicHandwriting",
  "title":"Letters A-C","level":"beginner",
  "items":["A","B","C","A","BA","BAT"]}
]''',
    ],
  );
}

class LogicHandwritingWidget extends StatefulWidget {
  const LogicHandwritingWidget({
    super.key,
    required this.title,
    required this.items,
    this.beginner = true,
  });
  final String title;
  final List<String> items;
  final bool beginner;
  @override
  State<LogicHandwritingWidget> createState() => _LogicHandwritingWidgetState();
}

class _LogicHandwritingWidgetState extends State<LogicHandwritingWidget> {
  int _index = 0;

  String get _current =>
      widget.items.isEmpty ? 'A' : widget.items[_index % widget.items.length];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${_index + 1}/${widget.items.length}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            // Guide lines for one item.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 360,
                child: CustomPaint(
                  size: const Size(360, 140),
                  painter: _GuidePainter(_current, beginner: widget.beginner),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _index <= 0
                      ? null
                      : () => setState(() => _index--),
                  child: const Text('Prev'),
                ),
                FilledButton(
                  onPressed: () => setState(() =>
                      _index = (_index + 1) % widget.items.length),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a "handmade-looking" guide: light baseline + dotted tracer glyphs.
///
/// For beginner it draws dotted letter shapes (approximated by grid cells) to
/// trace; for advanced it draws only a baseline. Strokes use a slightly wobbly
/// path to feel hand-drawn.
class _GuidePainter extends CustomPainter {
  const _GuidePainter(this.item, {required this.beginner});
  final String item;
  final bool beginner;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint baseline = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    // handwriting guide: light horizontal guide lines (x-height + baseline).
    final double mid = size.height * 0.5;
    final double baseY = size.height * 0.85;
    canvas.drawLine(
        Offset(8, mid), Offset(size.width - 8, mid), baseline);
    canvas.drawLine(Offset(8, baseY), Offset(size.width - 8, baseY), baseline);

    if (!beginner) return;

    // Dotted tracer per glyph slot (handmade feel: staggered dots).
    final Paint dot = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final double slotW = 64.0;
    final double cellH = 6.5;
    for (var i = 0; i < item.length; i++) {
      final double cx = 48 + i * slotW;
      for (var r = 0; r < 12; r++) {
        final double y = (baseY - 74) + r * cellH + (i.isEven ? 0 : 2.5);
        canvas.drawCircle(Offset(cx + (r.isEven ? 0 : 3.5), y), 2.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.item != item || old.beginner != beginner;
}
