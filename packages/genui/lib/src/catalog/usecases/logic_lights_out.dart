// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Lights Out: switch off all 25 lights on a 5x5 board. Tapping a light
/// toggles it and its four orthogonal neighbors.
final class LogicLightsOut {
  static final catalogItem = CatalogItem(
    name: 'LogicLightsOut',
    dataSchema: S.object(
      description: 'Classic 5x5 Lights Out puzzle.',
      properties: {
        'title': S.string(),
      },
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicLightsOutWidget(
        title: title is String ? title : 'Lights Out',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicLightsOut","title":"Lights Out"}
]''',
    ],
  );
}

class LogicLightsOutWidget extends StatefulWidget {
  const LogicLightsOutWidget({super.key, this.title = 'Lights Out'});
  final String title;
  @override
  State<LogicLightsOutWidget> createState() => _LogicLightsOutWidgetState();
}

class _LogicLightsOutWidgetState extends State<LogicLightsOutWidget> {
  static const int _n = 5;
  static const List<(int, int)> _dirs = [
    (0, 0),
    (-1, 0),
    (1, 0),
    (0, -1),
    (0, 1),
  ];
  final math.Random _rng = math.Random();
  late List<List<bool>> _grid; // true = light on
  int _moves = 0;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    // All lights on to start.
    _grid = List.generate(_n, (_) => List.filled(_n, true));
    _moves = 0;
    _solved = false;
    // Starting from all-on, apply ~20 random cell toggles. Because every
    // toggle is its own inverse, the resulting board is guaranteed solvable.
    for (var i = 0; i < 20; i++) {
      _toggleCell(_rng.nextInt(_n), _rng.nextInt(_n));
    }
    _solved = !_grid.any((row) => row.any((on) => on));
  }

  void _toggleCell(int r, int c) {
    for (final (dr, dc) in _dirs) {
      final int rr = r + dr, cc = c + dc;
      if (rr >= 0 && rr < _n && cc >= 0 && cc < _n) {
        _grid[rr][cc] = !_grid[rr][cc];
      }
    }
  }

  void _onTap(int r, int c) {
    if (_solved) return;
    setState(() {
      _toggleCell(r, c);
      _moves++;
      _solved = !_grid.any((row) => row.any((on) => on));
    });
  }

  void _restart() {
    setState(_newGame);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('moves: $_moves',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            if (_solved)
              Text(
                'Solved! in $_moves moves 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              )
            else
              Text('Switch off every light!',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _n,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4),
                itemCount: _n * _n,
                itemBuilder: (context, i) {
                  final int r = i ~/ _n, c = i % _n;
                  final bool on = _grid[r][c];
                  return Material(
                    color: on ? Colors.amber.shade400 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _solved ? null : () => _onTap(r, c),
                      child: Center(
                        child: Icon(
                          on
                              ? Icons.lightbulb
                              : Icons.lightbulb_outline,
                          size: 22,
                          color:
                              on ? Colors.amber.shade900 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: _restart, child: const Text('New game')),
            ),
          ],
        ),
      ),
    );
  }
}
