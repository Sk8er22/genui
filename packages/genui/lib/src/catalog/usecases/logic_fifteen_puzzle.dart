// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Fifteen puzzle: slide tiles on a 4x4 board to order them 1..15 with the
/// blank last. The model can optionally pass a title.
final class LogicFifteenPuzzle {
  static final catalogItem = CatalogItem(
    name: 'LogicFifteenPuzzle',
    dataSchema: S.object(
      description: 'Classic 4x4 sliding-tile puzzle.',
      properties: {
        'title': S.string(),
      },
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicFifteenPuzzleWidget(
        title: title is String ? title : '15 puzzle',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicFifteenPuzzle","title":"15 puzzle"}
]''',
    ],
  );
}

class LogicFifteenPuzzleWidget extends StatefulWidget {
  const LogicFifteenPuzzleWidget({super.key, this.title = '15 puzzle'});
  final String title;
  @override
  State<LogicFifteenPuzzleWidget> createState() =>
      _LogicFifteenPuzzleWidgetState();
}

class _LogicFifteenPuzzleWidgetState extends State<LogicFifteenPuzzleWidget> {
  static const int _size = 4;
  static const List<List<int>> _blankLastSolved = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
    [13, 14, 15, 0],
  ];

  final math.Random _rng = math.Random();
  late List<List<int>> _board;
  int _blankRow = _size - 1;
  int _blankCol = _size - 1;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  bool get _solved {
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (_board[r][c] != _blankLastSolved[r][c]) return false;
      }
    }
    return true;
  }

  /// Builds the solved board, then performs many random valid slides so the
  /// resulting shuffle is always solvable.
  void _reset() {
    _board = [
      for (var r = 0; r < _size; r++) [..._blankLastSolved[r]],
    ];
    _blankRow = _size - 1;
    _blankCol = _size - 1;
    _moves = 0;
    do {
      final int steps = 60 + _rng.nextInt(40);
      for (var i = 0; i < steps; i++) {
        final List<(int, int)> options = [];
        for (final (int dr, int dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
          final int r = _blankRow + dr;
          final int c = _blankCol + dc;
          if (r >= 0 && r < _size && c >= 0 && c < _size) {
            options.add((r, c));
          }
        }
        final (int r, int c) = options[_rng.nextInt(options.length)];
        _board[_blankRow][_blankCol] = _board[r][c];
        _board[r][c] = 0;
        _blankRow = r;
        _blankCol = c;
      }
    } while (_solved); // practically never, but never start already solved
  }

  void _tryMove(int row, int col) {
    if (_solved) return;
    final int dr = (row - _blankRow).abs();
    final int dc = (col - _blankCol).abs();
    if (dr + dc != 1) return; // not adjacent to the blank
    setState(() {
      _board[_blankRow][_blankCol] = _board[row][col];
      _board[row][col] = 0;
      _blankRow = row;
      _blankCol = col;
      _moves++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool solved = _solved;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            if (solved) ...[
              Text(
                'Solved! ✅',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _size * _size,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _size,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6),
                itemBuilder: (context, i) {
                  final int row = i ~/ _size;
                  final int col = i % _size;
                  final int value = _board[row][col];
                  final bool blank = value == 0;
                  final bool moves = !solved && !blank;
                  return Material(
                    color: blank
                        ? Colors.white
                        : solved
                            ? Colors.green.shade100
                            : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: moves ? () => _tryMove(row, col) : null,
                      child: Center(
                        child: blank
                            ? const SizedBox.shrink()
                            : Text('$value',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => setState(_reset),
                child: const Text('Shuffle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
