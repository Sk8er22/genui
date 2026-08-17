// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A "wheel of names" picker: the model supplies a list; a wedge wheel spins
/// and lands on an option (deterministic random pick).
final class LogicWheelPicker {
  static final catalogItem = CatalogItem(
    name: 'LogicWheelPicker',
    dataSchema: S.object(
      description: 'Spin a wheel to pick randomly among choices.',
      properties: {
        'title': S.string(),
        'options': S.list(items: S.string()),
      },
      required: ['title', 'options'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? options = (ctx.data as Map)['options'];
      final List<String> opts =
          options is List ? options.whereType<String>().toList() : const [];
      return LogicWheelPickerWidget(
        title: title is String ? title : 'The Wheel',
        options: opts.isNotEmpty ? opts : const ['A', 'B', 'C', 'D'],
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicWheelPicker","title":"Who goes first?",
  "options":["Ana","Ben","Cid","Dee"]}
]''',
    ],
  );
}

class LogicWheelPickerWidget extends StatefulWidget {
  const LogicWheelPickerWidget(
      {super.key, this.title = 'The Wheel', this.options = const []});
  final String title;
  final List<String> options;
  @override
  State<LogicWheelPickerWidget> createState() => _LogicWheelPickerWidgetState();
}

class _LogicWheelPickerWidgetState extends State<LogicWheelPickerWidget> {
  final math.Random _rng = math.Random();
  double _start = 0;
  String? _result;

  void _spin() {
    if (widget.options.isEmpty) return;
    setState(() {
      _start = _rng.nextDouble() * 2 * math.pi;
      final int idx = (_rng.nextDouble() * widget.options.length).floor();
      _result = widget.options[idx];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _WheelPainter(widget.options, _start),
                  child: Center(
                    child: Text(
                      _result ?? (widget.options.isEmpty ? '-' : 'Spin!'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: OutlinedButton.icon(
                  onPressed: _spin,
                  icon: const Icon(Icons.track_changes),
                  label: const Text('Spin')),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.options, this.start);
  final List<String> options;
  final double start;
  static const List<Color> _palette = [
    Color(0xFFF94144), Color(0xFFF3722C), Color(0xFFF8961E),
    Color(0xFFF9C74F), Color(0xFF90BE6D), Color(0xFF43AA8B),
    Color(0xFF577590), Color(0xFF9B5DE5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final int n = options.length;
    if (n == 0) return;
    final double sweep = 2 * math.pi / n;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (var i = 0; i < n; i++) {
      final Paint p = Paint()
        ..color = _palette[i % _palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0; // filled wedges below
      canvas.drawArc(rect, start + i * sweep, sweep, true,
          Paint()..color = _palette[i % _palette.length]);
    }
    // inner text labels
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < n; i++) {
      final double mid = start + i * sweep + sweep / 2;
      tp.text = TextSpan(
          text: options[i],
          style: const TextStyle(color: Colors.white, fontSize: 12,
              fontWeight: FontWeight.bold));
      tp.layout();
      final double r = size.width * 0.32;
      final Offset at = Offset(
        size.width / 2 + r * math.cos(mid),
        size.height / 2 + r * math.sin(mid),
      );
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }
    // center + pointer
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 6,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.start != start || old.options != options;
}
