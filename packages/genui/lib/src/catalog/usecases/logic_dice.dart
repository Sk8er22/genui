// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A dice roller: model sets how many dice + sides. Tap to roll; shows totals.
final class LogicDice {
  static final catalogItem = CatalogItem(
    name: 'LogicDice',
    dataSchema: S.object(
      description: 'Roll dice (e.g. 2d6).',
      properties: {
        'title': S.string(),
        'dice': S.integer(description: 'Number of dice.'),
        'sides': S.integer(description: 'Sides per die.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? dice = (ctx.data as Map)['dice'];
      final Object? sides = (ctx.data as Map)['sides'];
      return LogicDiceWidget(
        title: title is String ? title : 'Dice',
        dice: dice is int && dice > 0 ? dice : 2,
        sides: sides is int && sides > 0 ? sides : 6,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicDice","title":"2d6","dice":2,"sides":6}
]''',
    ],
  );
}

class LogicDiceWidget extends StatefulWidget {
  const LogicDiceWidget(
      {super.key, this.title = 'Dice', this.dice = 2, this.sides = 6});
  final String title;
  final int dice;
  final int sides;
  @override
  State<LogicDiceWidget> createState() => _LogicDiceWidgetState();
}

class _LogicDiceWidgetState extends State<LogicDiceWidget> {
  final math.Random _rng = math.Random();
  late List<int> _values;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _values = List.filled(widget.dice, 1);
  }

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() => _rolling = true);
    List<int> next = [];
    for (var i = 0; i < 8; i++) {
      next = [for (var d = 0; d < widget.dice; d++) 1 + _rng.nextInt(widget.sides)];
      setState(() => _values = List<int>.from(next));
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    setState(() {
      _values = next;
      _rolling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int total = _values.fold(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.title}  (${widget.dice}d${widget.sides})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final v in _values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black38, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              offset: Offset(1, 2), blurRadius: 3,
                              color: Colors.black26),
                        ],
                      ),
                      child: Text('$v',
                          style:
                              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: $total',
                    style: Theme.of(context).textTheme.titleMedium),
                FilledButton.icon(
                  onPressed: _rolling ? null : _roll,
                  icon: const Icon(Icons.casino),
                  label: const Text('Roll'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
