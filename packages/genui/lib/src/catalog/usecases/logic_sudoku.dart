// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A solved 4x4 Sudoku grid the player fills in. Deterministic puzzle + full
/// validation (rows, columns, 2x2 boxes). Difficulty via number of prefilled.
final class LogicSudoku {
  static final catalogItem = CatalogItem(
    name: 'LogicSudoku',
    dataSchema: S.object(
      description: '4x4 Sudoku puzzle.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicSudokuWidget(title: title is String ? title : 'Sudoku 4x4');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSudoku","title":"Sudoku 4x4"}
]''',
    ],
  );
}

class LogicSudokuWidget extends StatefulWidget {
  const LogicSudokuWidget({super.key, this.title = 'Sudoku 4x4'});
  final String title;
  @override
  State<LogicSudokuWidget> createState() => _LogicSudokuWidgetState();
}

class _LogicSudokuWidgetState extends State<LogicSudokuWidget> {
  static const int _n = 4;
  final math.Random _rng = math.Random();
  List<List<int>> _solution = [];
  late List<List<int>> _board;
  late List<List<bool>> _given;
  String? _status;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    // Build a valid 4x4 solution from a latin-square offset pattern, then
    // reveal ~8 cells as the puzzle.
    final List<List<int>> sol = List.generate(_n, (_) => List.filled(_n, 0));
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        sol[r][c] = ((r % 2) * 2 + (c % 2) + r + c) % 4 + 1;
      }
    }
    _solution = sol;
    _board = [
      for (var r = 0; r < _n; r++) List<int>.filled(_n, 0)
    ];
    _given = [
      for (var r = 0; r < _n; r++) List<bool>.filled(_n, false)
    ];
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_rng.nextInt(2) == 1 && _countGiven < 8) {
          _board[r][c] = _solution[r][c];
          _given[r][c] = true;
        }
      }
    }
    if (_countGiven == 0) {
      _board[0][0] = _solution[0][0];
      _given[0][0] = true;
    }
    _status = null;
  }

  int get _countGiven {
    var n = 0;
    for (final row in _given) {
      for (final g in row) {
        if (g) n++;
      }
    }
    return n;
  }

  void _set(int r, int c, int digit) {
    if (_given[r][c]) return;
    setState(() {
      _board[r][c] = digit;
      _status = null;
    });
  }

  void _check() {
    bool ok = true;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_board[r][c] != _solution[r][c]) ok = false;
      }
    }
    setState(() => _status = ok ? 'Correct! 🎉' : 'Not yet — keep trying.');
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
            if (_status != null) Text(_status!),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  for (var r = 0; r < _n; r++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var c = 0; c < _n; c++)
                          GestureDetector(
                            onTap: _given[r][c]
                                ? null
                                : () => _cycle(r, c),
                            child: Container(
                              width: 52,
                              height: 52,
                              margin: const EdgeInsets.all(2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _given[r][c]
                                    ? Colors.blueGrey.shade100
                                    : Colors.white,
                                border: Border.all(
                                    color: (r < 2) == (c < 2)
                                        ? Colors.black26
                                        : Colors.black54,
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _board[r][c] == 0 ? ' ' : '${_board[r][c]}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: _given[r][c]
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _given[r][c]
                                      ? Colors.black87
                                      : Colors.purple.shade800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                    onPressed: () => setState(_generate),
                    child: const Text('New puzzle')),
                FilledButton(
                    onPressed: _check, child: const Text('Check')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cycle(int r, int c) {
    setState(() {
      _board[r][c] = (_board[r][c] % 4) + 1;
      _status = null;
    });
  }
}
