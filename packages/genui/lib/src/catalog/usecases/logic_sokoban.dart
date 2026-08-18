// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Sokoban: push every box onto a goal square using the on-screen D-pad.
/// Move count and win detection included.
final class LogicSokoban {
  static final catalogItem = CatalogItem(
    name: 'LogicSokoban',
    dataSchema: S.object(
      description: 'Sokoban puzzle: push all boxes onto the goals.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicSokobanWidget(title: title is String ? title : 'Sokoban');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSokoban","title":"Sokoban"}
]''',
    ],
  );
}

class _Cell {
  _Cell({required this.wall, required this.goal, required this.box});
  bool wall;
  bool goal;
  bool box;
}

class LogicSokobanWidget extends StatefulWidget {
  const LogicSokobanWidget({super.key, this.title = 'Sokoban'});
  final String title;
  @override
  State<LogicSokobanWidget> createState() => _LogicSokobanWidgetState();
}

class _LogicSokobanWidgetState extends State<LogicSokobanWidget> {
  // Level legend: '#' wall, ' ' floor, 'X' box, '.' goal, 'P' player.
  static const List<String> _level = [
    '#######',
    '#     #',
    '#  XX #',
    '#  .. #',
    '#  P  #',
    '#######',
  ];

  late List<List<_Cell>> _cells;
  late int _pr, _pc; // player row/col
  late int _rows, _cols;
  late int _onGoal; // boxes currently parked on goals
  late int _boxCount;
  int _moves = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _rows = _level.length;
    _cols = _level[0].length;
    _cells = List.generate(
      _rows,
      (r) => List.generate(_cols, (c) {
        final String ch = _level[r][c];
        return _Cell(
          wall: ch == '#',
          goal: ch == '.' || ch == '*',
          box: ch == 'X' || ch == '*',
        );
      }),
    );
    _boxCount = 0;
    _onGoal = 0;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        if (_level[r][c] == 'P') {
          _pr = r;
          _pc = c;
        } else if (_cells[r][c].box) {
          _boxCount++;
          if (_cells[r][c].goal) _onGoal++;
        }
      }
    }
    _moves = 0;
    _won = false;
  }

  bool _inside(int r, int c) => r >= 0 && r < _rows && c >= 0 && c < _cols;

  void _move(int dr, int dc) {
    if (_won) return;
    final int nr = _pr + dr, nc = _pc + dc;
    if (!_inside(nr, nc)) return;
    final _Cell target = _cells[nr][nc];
    if (target.wall) return;
    if (target.box) {
      final int br = nr + dr, bc = nc + dc;
      if (!_inside(br, bc)) return;
      final _Cell beyond = _cells[br][bc];
      if (beyond.wall || beyond.box) return;
      // Push the box one step.
      setState(() {
        target.box = false;
        beyond.box = true;
        if (target.goal) _onGoal--;
        if (beyond.goal) _onGoal++;
        _pr = nr;
        _pc = nc;
        _moves++;
        if (_onGoal == _boxCount) _won = true;
      });
      return;
    }
    setState(() {
      _pr = nr;
      _pc = nc;
      _moves++;
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
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('moves: $_moves',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            if (_won)
              Text('All boxes placed! 🎉',
                  style: Theme.of(context).textTheme.titleMedium)
            else
              Text('Push every 📦 onto a ●',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Center(
              child: AspectRatio(
                aspectRatio: _cols / _rows,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _cols, mainAxisSpacing: 2,
                      crossAxisSpacing: 2),
                  itemCount: _rows * _cols,
                  itemBuilder: (context, i) {
                    final int r = i ~/ _cols, c = i % _cols;
                    return _buildCell(r, c);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: _buildPad()),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    final _Cell cell = _cells[r][c];
    final bool isPlayer = r == _pr && c == _pc;
    final Color bg;
    if (cell.wall) {
      bg = Colors.blueGrey.shade700;
    } else if (cell.goal) {
      bg = Colors.teal.shade100;
    } else {
      bg = Colors.grey.shade200;
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: isPlayer
          ? const Text('🚶', style: TextStyle(fontSize: 16))
          : cell.box
              ? const Text('📦', style: TextStyle(fontSize: 16))
              : cell.goal
                  ? const Text('●',
                      style: TextStyle(fontSize: 10, color: Colors.teal))
                  : null,
    );
  }

  Widget _buildPad() {
    Widget btn(IconData icon, int dr, int dc) => IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => _move(dr, dc),
          icon: Icon(icon),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            btn(Icons.arrow_upward, -1, 0),
            Row(children: [
              btn(Icons.arrow_back, 0, -1),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(_build),
                icon: const Icon(Icons.refresh),
              ),
              btn(Icons.arrow_forward, 0, 1),
            ]),
            btn(Icons.arrow_downward, 1, 0),
          ],
        ),
      ],
    );
  }
}
