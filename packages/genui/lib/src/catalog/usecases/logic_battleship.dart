// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Battleship — guess where the hidden ships (given by the model as a layout
/// string or generated) are. Attacks placed; hit/miss/sunk tracked.
final class LogicBattleship {
  static final catalogItem = CatalogItem(
    name: 'LogicBattleship',
    dataSchema: S.object(
      description: 'Battleship: sink hidden ships by guessing cells.',
      properties: {
        'title': S.string(),
        'layout': S.string(
            description: 'Optional 5x5 grid of ships: "#" ship, "." water.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? layout = (ctx.data as Map)['layout'];
      return LogicBattleshipWidget(
        title: title is String ? title : 'Battleship',
        layout: layout is String ? layout : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicBattleship","title":"Ships",
  "layout":"#.#.#..###..###..###..###"}
]''',
    ],
  );
}

class LogicBattleshipWidget extends StatefulWidget {
  const LogicBattleshipWidget(
      {super.key, this.title = 'Battleship', this.layout});
  final String title;
  final String? layout;
  @override
  State<LogicBattleshipWidget> createState() => _LogicBattleshipWidgetState();
}

class _LogicBattleshipWidgetState extends State<LogicBattleshipWidget> {
  static const int _n = 5;
  final math.Random _rng = math.Random();
  late List<List<bool>> _ships;
  late List<List<String>> _state; // '', H, M
  int _hits = 0;
  int _totalShips = 0;
  int _shots = 0;
  String? _gameOver;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _ships = _generate();
    _totalShips = _ships.expand((r) => r).where((b) => b).length;
    _state = List.generate(_n, (_) => List.filled(_n, ''));
    _hits = 0;
    _shots = 0;
    _gameOver = null;
  }

  List<List<bool>> _generate() {
    // honor an optional model-provided 5x5 layout: '#' ship, '.' water
    final String? layout = widget.layout;
    if (layout != null && layout.length >= _n * _n) {
      return List.generate(_n, (r) => List.generate(
          _n, (c) => layout[r * _n + c] == '#'));
    }
    final List<List<bool>> grid =
        List.generate(_n, (_) => List.filled(_n, false));
    // place 3 ships: len 3 horizontal, len 3 vertical, len 2
    _tryPlace(grid, 3, horizontal: true);
    _tryPlace(grid, 3, horizontal: false);
    _tryPlace(grid, 2, horizontal: _rng.nextBool());
    return grid;
  }

  void _tryPlace(List<List<bool>> grid, int len, {required bool horizontal}) {
    for (var attempt = 0; attempt < 20; attempt++) {
      final int r = _rng.nextInt(_n);
      final int c = _rng.nextInt(_n);
      if (horizontal && c + len > _n) continue;
      if (!horizontal && r + len > _n) continue;
      bool ok = true;
      for (var i = 0; i < len; i++) {
        final rr = horizontal ? r : r + i;
        final cc = horizontal ? c + i : c;
        if (grid[rr][cc]) {
          ok = false;
          break;
        }
      }
      if (ok) {
        for (var i = 0; i < len; i++) {
          final rr = horizontal ? r : r + i;
          final cc = horizontal ? c + i : c;
          grid[rr][cc] = true;
        }
        return;
      }
    }
  }

  void _tap(int r, int c) {
    if (_state[r][c].isNotEmpty || _gameOver != null) return;
    setState(() {
      _shots++;
      if (_ships[r][c]) {
        _state[r][c] = 'H';
        _hits++;
        if (_hits == _totalShips) {
          _gameOver = 'All ships sunk in $_shots shots! 🎉';
        }
      } else {
        _state[r][c] = 'M';
      }
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
            const SizedBox(height: 6),
            Text('Shots: $_shots  •  Remaining: ${_totalShips - _hits}',
                style: Theme.of(context).textTheme.bodyMedium),
            if (_gameOver != null)
              Text(_gameOver!,
                  style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _n),
                itemCount: _n * _n,
                itemBuilder: (context, i) {
                  final int r = i ~/ _n, c = i % _n;
                  final String s = _state[r][c];
                  return InkWell(
                    onTap: () => _tap(r, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: s == 'H'
                            ? Colors.red.shade400
                            : s == 'M'
                                ? Colors.blueGrey.shade200
                                : Colors.blue.shade100,
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      alignment: Alignment.center,
                      child: s == 'H'
                          ? const Icon(Icons.whatshot, color: Colors.white)
                          : s == 'M'
                              ? const Icon(Icons.circle, size: 8)
                              : null,
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
}
