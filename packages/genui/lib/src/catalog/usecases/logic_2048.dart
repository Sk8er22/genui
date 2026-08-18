// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// The 2048 sliding-tile game with swipe + score + game-over detection.
final class Logic2048 {
  static final catalogItem = CatalogItem(
    name: 'Logic2048',
    dataSchema: S.object(
      description: 'Sliding tile game 2048.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return Logic2048Widget(title: title is String ? title : '2048');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"Logic2048","title":"2048"}
]''',
    ],
  );
}

class Logic2048Widget extends StatefulWidget {
  const Logic2048Widget({super.key, this.title = '2048'});
  final String title;
  @override
  State<Logic2048Widget> createState() => _Logic2048WidgetState();
}

class _Logic2048WidgetState extends State<Logic2048Widget> {
  final math.Random _rng = math.Random();
  late List<List<int>> _g;
  int _score = 0;
  bool _won = false, _over = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _g = List.generate(4, (_) => List.filled(4, 0));
    _score = 0;
    _won = _over = false;
    _spawn();
    _spawn();
  }

  void _spawn() {
    final List<(int, int)> empty = [];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_g[r][c] == 0) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return;
    final (r, c) = empty[_rng.nextInt(empty.length)];
    _g[r][c] = (_rng.nextInt(10) == 0) ? 4 : 2;
  }

  bool _move(int dr, int dc) {
    bool moved = false;
    // Walk each lane starting from the destination edge, stepping inward, so
    // indices never leave the board. Lane is the fixed row (horizontal) or
    // column (vertical); position steps toward the edge the tiles slide to.
    final int edge = dr != 0 ? (dr > 0 ? 3 : 0) : (dc > 0 ? 3 : 0);
    final int step = dr != 0 ? (dr > 0 ? -1 : 1) : (dc > 0 ? -1 : 1);

    for (var lane = 0; lane < 4; lane++) {
      final List<int> line = [];
      var k = edge;
      for (var t = 0; t < 4; t++) {
        line.add(dr != 0 ? _g[k][lane] : _g[lane][k]);
        k += step;
      }
      final List<int> vals = line.where((v) => v != 0).toList();
      if (vals.isEmpty) continue;
      final List<int> merged = [];
      for (var t = 0; t < vals.length; t++) {
        if (t + 1 < vals.length && vals[t] == vals[t + 1]) {
          final int nv = vals[t] * 2;
          merged.add(nv);
          _score += nv;
          if (nv == 2048) _won = true;
          t++;
        } else {
          merged.add(vals[t]);
        }
      }
      k = edge;
      for (var t = 0; t < 4; t++) {
        final int value = t < merged.length ? merged[t] : 0;
        final int cur = dr != 0 ? _g[k][lane] : _g[lane][k];
        if (cur != value) moved = true;
        if (dr != 0) {
          _g[k][lane] = value;
        } else {
          _g[lane][k] = value;
        }
        k += step;
      }
    }
    return moved;
  }

  void _swipe(String dir) {
    if (_over) return;
    final (dr, dc) = switch (dir) {
      'up' => (-1, 0), 'down' => (1, 0),
      'left' => (0, -1), _ => (0, 1),
    };
    final bool moved = _move(dr, dc);
    if (moved) {
      _spawn();
      if (!_anyMove()) _over = true;
    }
    setState(() {});
  }

  bool _anyMove() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_g[r][c] == 0) return true;
        if (r + 1 < 4 && _g[r][c] == _g[r + 1][c]) return true;
        if (c + 1 < 4 && _g[r][c] == _g[r][c + 1]) return true;
      }
    }
    return false;
  }

  Color _tileColor(int v) => switch (v) {
        0 => Colors.grey.shade200,
        2 => Colors.amber.shade50,
        4 => Colors.amber.shade100,
        8 => Colors.orange.shade200,
        16 => Colors.orange.shade300,
        32 => Colors.deepOrange.shade300,
        64 => Colors.red.shade300,
        128 => Colors.purple.shade300,
        256 => Colors.purple.shade400,
        512 => Colors.indigo.shade300,
        1024 => Colors.blue.shade400,
        _ => Colors.blueGrey.shade600,
      };

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
                Text('score: $_score',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onHorizontalDragEnd: (d) => _swipe(
                  d.primaryVelocity! > 0 ? 'right' : 'left'),
              onVerticalDragEnd: (d) => _swipe(
                  d.primaryVelocity! > 0 ? 'down' : 'up'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4),
                    itemCount: 16,
                    itemBuilder: (context, i) {
                      final int r = i ~/ 4, c = i % 4;
                      final int v = _g[r][c];
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _tileColor(v),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          v == 0 ? '' : '$v',
                          style: TextStyle(
                            fontSize: v >= 100 ? 20 : 26,
                            fontWeight: FontWeight.bold,
                            color: v >= 128 ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  if (_won)
                    Text('You made 2048! 🎉',
                        style: Theme.of(context).textTheme.titleMedium),
                  if (_over && !_won)
                    Text('Game over — no moves',
                        style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  OutlinedButton(
                      onPressed: () => setState(_reset),
                      child: const Text('New game')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
