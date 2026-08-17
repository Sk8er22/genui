// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Minesweeper on a 8x8 grid with configurable mine count. Flood-fill reveal,
/// flag, win/lose detection.
final class LogicMinesweeper {
  static final catalogItem = CatalogItem(
    name: 'LogicMinesweeper',
    dataSchema: S.object(
      description: 'Minesweeper board game.',
      properties: {
        'title': S.string(),
        'mines': S.integer(description: 'Number of mines (default 10).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? mines = (ctx.data as Map)['mines'];
      return LogicMinesweeperWidget(
        title: title is String ? title : 'Minesweeper',
        mines: mines is int && mines > 0 ? mines : 10,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicMinesweeper","title":"Mines","mines":10}
]''',
    ],
  );
}

class _Cell {
  bool mine = false, revealed = false, flagged = false;
  int around = 0;
}

class LogicMinesweeperWidget extends StatefulWidget {
  const LogicMinesweeperWidget({super.key, this.title = 'Mines', this.mines = 10});
  final String title;
  final int mines;
  @override
  State<LogicMinesweeperWidget> createState() => _LogicMinesweeperWidgetState();
}

class _LogicMinesweeperWidgetState extends State<LogicMinesweeperWidget> {
  static const int _n = 8;
  final math.Random _rng = math.Random();
  late List<List<_Cell>> _grid;
  int _flags = 0;
  bool _over = false, _won = false;
  late int _safeTotal;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(_n, (_) =>
        List.generate(_n, (_) => _Cell()));
    final int mineCount = widget.mines.clamp(1, _n * _n - 1);
    int placed = 0;
    while (placed < mineCount) {
      final int r = _rng.nextInt(_n), c = _rng.nextInt(_n);
      if (!_grid[r][c].mine) {
        _grid[r][c].mine = true;
        placed++;
      }
    }
    _computeCounts();
    _flags = 0;
    _over = _won = false;
    _safeTotal = _n * _n - mineCount;
  }

  void _computeCounts() {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        int a = 0;
        for (final (dr, dc) in _dirs) {
          final rr = r + dr, cc = c + dc;
          if (rr >= 0 && rr < _n && cc >= 0 && cc < _n && _grid[rr][cc].mine) a++;
        }
        _grid[r][c].around = a;
      }
    }
  }

  static const List<(int, int)> _dirs = [
    (-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1),
  ];

  void _reveal(int r, int c) {
    if (_over || _won) return;
    final _Cell cell = _grid[r][c];
    if (cell.flagged || cell.revealed) return;
    if (cell.mine) {
      setState(() {
        _over = true;
        cell.revealed = true;
      });
      return;
    }
    // flood fill
    final List<(int, int)> stack = [(r, c)];
    int revealed = 0;
    while (stack.isNotEmpty) {
      final (cr, cc) = stack.removeLast();
      final _Cell cur = _grid[cr][cc];
      if (cur.revealed || cur.flagged || cur.mine) continue;
      cur.revealed = true;
      revealed++;
      if (cur.around == 0) {
        for (final (dr, dc) in _dirs) {
          final rr = cr + dr, cc2 = cc + dc;
          if (rr >= 0 && rr < _n && cc2 >= 0 && cc2 < _n) {
            stack.add((rr, cc2));
          }
        }
      }
    }
    setState(() => _won = revealed == _safeTotal);
  }

  void _flag(int r, int c) {
    if (_over || _won) return;
    final _Cell cell = _grid[r][c];
    if (cell.revealed) return;
    setState(() {
      cell.flagged = !cell.flagged;
      _flags += cell.flagged ? 1 : -1;
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
            Row(
              children: [
                Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('🚩 $_flags', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 6),
            if (_over)
              Text('💥 You hit a mine!',
                  style: Theme.of(context).textTheme.titleMedium)
            else if (_won)
              Text('You cleared the field! 🎉',
                  style: Theme.of(context).textTheme.titleMedium)
            else
              Text('Tap reveal, long-press flag',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _n, crossAxisSpacing: 2, mainAxisSpacing: 2),
                itemCount: _n * _n,
                itemBuilder: (context, i) {
                  final int r = i ~/ _n, c = i % _n;
                  final _Cell cell = _grid[r][c];
                  String ch = '';
                  Color? fg;
                  if (cell.flagged) {
                    ch = '🚩';
                  } else if (cell.revealed) {
                    if (cell.mine) {
                      ch = '💣';
                    } else if (cell.around > 0) {
                      ch = '${cell.around}';
                      fg = _numColor(cell.around);
                    }
                  }
                  return GestureDetector(
                    onTap: () => _reveal(r, c),
                    onLongPress: () => _flag(r, c),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cell.revealed
                            ? Colors.grey.shade200
                            : Colors.blueGrey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(ch,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: fg)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: () => setState(_reset),
                  child: const Text('New game')),
            ),
          ],
        ),
      ),
    );
  }

  Color? _numColor(int n) => switch (n) {
        1 => Colors.blue, 2 => Colors.green.shade700, 3 => Colors.red,
        4 => Colors.indigo, 5 => Colors.deepOrange, _ => Colors.black,
      };
}
