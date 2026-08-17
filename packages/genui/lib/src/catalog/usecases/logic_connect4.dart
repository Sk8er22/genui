// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Connect 4 — two players drop disks into a 6x7 grid; four-in-a-row wins.
final class LogicConnect4 {
  static final catalogItem = CatalogItem(
    name: 'LogicConnect4',
    dataSchema: S.object(
      description: 'Connect four-in-a-row for two players.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicConnect4Widget(
          title: title is String ? title : 'Connect 4');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicConnect4","title":"Connect 4"}
]''',
    ],
  );
}

class LogicConnect4Widget extends StatefulWidget {
  const LogicConnect4Widget({super.key, this.title = 'Connect 4'});
  final String title;
  @override
  State<LogicConnect4Widget> createState() => _LogicConnect4WidgetState();
}

class _LogicConnect4WidgetState extends State<LogicConnect4Widget> {
  static const int _rows = 6, _cols = 7;
  List<List<int?>> _board = []; // 0 = red, 1 = yellow
  bool _red = true;
  int? _winner; // 0 or 1
  int _redWins = 0, _yellowWins = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = [
      for (var r = 0; r < _rows; r++) List<int?>.filled(_cols, null)
    ];
    _red = true;
    _winner = null;
  }

  void _drop(int col) {
    if (_winner != null) return;
    // find lowest empty cell in the column
    int? row;
    for (var r = _rows - 1; r >= 0; r--) {
      if (_board[r][col] == null) {
        row = r;
        break;
      }
    }
    if (row == null) return; // column full
    setState(() {
      _board[row!][col] = _red ? 0 : 1;
      if (_checkWin(row, col)) {
        _winner = _red ? 0 : 1;
        if (_winner == 0) {
          _redWins++;
        } else {
          _yellowWins++;
        }
      } else {
        _red = !_red;
      }
    });
  }

  bool _checkWin(int r, int c) {
    final int me = _board[r][c]!;
    const dirs = [(0, 1), (1, 0), (1, 1), (1, -1)];
    for (final (dr, dc) in dirs) {
      int count = 1;
      for (final s in [1, -1]) {
        var rr = r + dr * s, cc = c + dc * s;
        while (rr >= 0 && rr < _rows && cc >= 0 && cc < _cols &&
            _board[rr][cc] == me) {
          count++;
          rr += dr * s;
          cc += dc * s;
        }
      }
      if (count >= 4) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final String status = _winner != null
        ? (_winner == 0 ? 'Red wins!' : 'Yellow wins!')
        : '${_red ? 'Red' : 'Yellow'} to move';
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
                Text('R $_redWins • Y $_yellowWins',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // column drop buttons
            Row(
              children: [
                for (var c = 0; c < _cols; c++)
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_drop_down_circle),
                      onPressed: _winner != null ? null : () => _drop(c),
                    ),
                  ),
              ],
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.blue.shade900,
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      for (var r = 0; r < _rows; r++)
                        Row(
                          children: [
                            for (var c = 0; c < _cols; c++)
                              Container(
                                width: 34,
                                height: 34,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _board[r][c] == 0
                                      ? Colors.red
                                      : _board[r][c] == 1
                                          ? Colors.yellow.shade600
                                          : Colors.white70,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: () => setState(_reset), child: const Text('New game')),
            ),
          ],
        ),
      ),
    );
  }
}
