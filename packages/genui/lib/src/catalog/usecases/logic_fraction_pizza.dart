// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Fraction pizza: visualize a fraction (pieces of a pie) and let the model
/// set numerator/denominator for an educational "what fraction is colored?".
final class LogicFractionPizza {
  static final catalogItem = CatalogItem(
    name: 'LogicFractionPizza',
    dataSchema: S.object(
      description: 'Visual fraction of a pie (educational).',
      properties: {
        'title': S.string(),
        'numerator': S.integer(description: 'Colored slices (e.g. 2).'),
        'denominator': S.integer(description: 'Total slices (e.g. 4).'),
      },
      required: ['title', 'denominator'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? num = (ctx.data as Map)['numerator'];
      final Object? den = (ctx.data as Map)['denominator'];
      final int n = num is int && num >= 0 ? num : 1;
      final int d = den is int && den > 0 ? den : 4;
      return LogicFractionPizzaWidget(
        title: title is String ? title : 'Fractions',
        numerator: n.clamp(0, d),
        denominator: d,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicFractionPizza","title":"Pizza",
  "numerator":1,"denominator":4}
]''',
    ],
  );
}

class LogicFractionPizzaWidget extends StatefulWidget {
  const LogicFractionPizzaWidget({
    super.key,
    this.title = 'Fractions',
    required this.numerator,
    required this.denominator,
  });
  final String title;
  final int numerator;
  final int denominator;
  @override
  State<LogicFractionPizzaWidget> createState() =>
      _LogicFractionPizzaWidgetState();
}

class _LogicFractionPizzaWidgetState extends State<LogicFractionPizzaWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('What fraction is colored?',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _PizzaPainter(
                      widget.numerator, widget.denominator),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${widget.numerator} / ${widget.denominator}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PizzaPainter extends CustomPainter {
  _PizzaPainter(this.num, this.den);
  final int num;
  final int den;
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset c = Offset(r, r);
    final double sweep = 2 * 3.14159265358979 / den;
    for (var i = 0; i < den; i++) {
      final bool colored = i < num;
      final Paint p = Paint()
        ..color = colored ? Colors.deepOrange.shade400 : Colors.amber.shade100;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
          -3.14159265358979 / 2 + i * sweep, sweep, true, p);
    }
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black26);
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter old) => old.num != num || old.den != den;
}
