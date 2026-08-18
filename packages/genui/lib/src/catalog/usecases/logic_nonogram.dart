// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Nonogram (Picross): deduce which cells are filled from the row and column
/// clues. Numbers tell the lengths of consecutive filled runs in that line.
/// Tap cycles a cell: empty -> filled -> crossed -> empty. Fully solving the
/// picture wins automatically.
final class LogicNonogram {
  static final catalogItem = CatalogItem(
    name: 'LogicNonogram',
    dataSchema: S.object(
      description: 'Classic 5x5 Nonogram picture-logic puzzle.',
      properties: {
        'title': S.string(),
        'size': S.integer(),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? size = (ctx.data as Map)['size'];
      return LogicNonogramWidget(
        title: title is String ? title : 'Nonogram',
        size: size is int ? size : 5,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicNonogram","title":"Nonogram","size":5}
]''',
    ],
  );
}

class LogicNonogramWidget extends StatefulWidget {
  const LogicNonogramWidget({super.key, this.title = 'Nonogram', this.size = 5});
  final String title;

  /// Board edge length. Kept in the playable 5..8 range.
  final int size;
  @override
  State<LogicNonogramWidget> createState() => _LogicNonogramWidgetState();
}

class _LogicNonogramWidgetState extends State<LogicNonogramWidget> {
  final math.Random _rng = math.Random();

  late final int _n = widget.size.clamp(5, 8);
  late List<List<bool>> _solution;
  late List<List<int>> _cells; // 0 = empty, 1 = filled, 2 = crossed
  late List<List<int>> _rowClues;
  late List<List<int>> _colClues;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    _solution = List.generate(
        _n, (_) => List.generate(_n, (_) => _rng.nextInt(100) < 40));
    // Keep at least one filled and one empty cell so the puzzle is non-trivial.
    var filled = 0;
    var empty = 0;
    for (final row in _solution) {
      for (final on in row) {
        filled += on ? 1 : 0;
        empty += on ? 0 : 1;
      }
    }
    if (filled == 0) {
      _solution[0][0] = true;
    } else if (empty == 0) {
      _solution[0][0] = false;
    }
    _cells = List.generate(_n, (_) => List<int>.filled(_n, 0));
    _rowClues = [for (final row in _solution) _clueFor(row)];
    _colClues = List.generate(
        _n, (c) => _clueFor([for (var r = 0; r < _n; r++) _solution[r][c]]));
    _solved = false;
  }

  /// Converts a row/column of booleans into nonogram run-length clues.
  static List<int> _clueFor(List<bool> line) {
    final List<int> clue = [];
    var run = 0;
    for (final v in line) {
      if (v) {
        run++;
      } else if (run > 0) {
        clue.add(run);
        run = 0;
      }
    }
    if (run > 0) clue.add(run);
    return clue.isEmpty ? [0] : clue;
  }

  void _cycle(int r, int c) {
    if (_solved) return;
    setState(() {
      _cells[r][c] = (_cells[r][c] + 1) % 3;
      _solved = _isSolved();
    });
  }

  bool _isSolved() {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_solution[r][c] != (_cells[r][c] == 1)) return false;
      }
    }
    return true;
  }

  /// Number of wrongly filled cells (highlighted as mistakes).
  int get _mistakes {
    var m = 0;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_cells[r][c] == 1 && !_solution[r][c]) m++;
      }
    }
    return m;
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
                Text('$_n x $_n', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            if (_solved)
              Text(
                'Solved! Great logic 🎉',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              )
            else
              Text(
                _mistakes > 0
                    ? '$_mistakes wrong fill${_mistakes == 1 ? '' : 's'}'
                    : 'Fill the picture from the clues.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Center(child: _buildBoard()),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: () => setState(_generate),
                  child: const Text('New puzzle')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    const double clueW = 26;
    const double cell = 34;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Column clues above the grid.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: clueW),
            for (var c = 0; c < _n; c++)
              SizedBox(
                width: cell,
                child: Center(
                  child: Text(
                    _colClues[c].join('\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, height: 1.1),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        for (var r = 0; r < _n; r++)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: clueW,
                  child: Center(
                    child: Text(
                      _rowClues[r].join(' '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                for (var c = 0; c < _n; c++) _buildCell(r, c, cell),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(int r, int c, double cell) {
    final int state = _cells[r][c];
    final bool wrong = state == 1 && !_solution[r][c];
    Color bg;
    if (state == 1) {
      bg = wrong ? Colors.red.shade300 : Colors.indigo.shade600;
    } else {
      bg = Colors.grey.shade100;
    }
    return GestureDetector(
      onTap: _solved ? null : () => _cycle(r, c),
      child: Container(
        width: cell,
        height: cell,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: state == 2
              ? Icon(Icons.close, size: 18, color: Colors.grey.shade500)
              : null,
        ),
      ),
    );
  }
}
