// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A minimal single-piece falling-block game (Tetris-lite): one tetromino
/// drops, you move it left/right, rotate, soft-drop, and a filled row clears.
/// Pure Dart + Timer.
final class LogicTetris {
  static final catalogItem = CatalogItem(
    name: 'LogicTetris',
    dataSchema: S.object(
      description: 'A tiny tetromino stacking game.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicTetrisWidget(title: title is String ? title : 'Tetris');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTetris","title":"Tetris"}
]''',
    ],
  );
}

class _Piece {
  // list of (row,col) relative cells
  List<(int, int)> cells;
  Color color;
  _Piece(this.cells, this.color);

  _Piece rotated() {
    // rotate cells 90° clockwise around origin
    return _Piece(cells.map((c) => (c.$2, -c.$1)).toList(), color);
  }
}

class _Falling {
  int r, c;
  _Piece piece;
  _Falling(this.piece, this.r, this.c);
}

class LogicTetrisWidget extends StatefulWidget {
  const LogicTetrisWidget({super.key, this.title = 'Tetris'});
  final String title;
  @override
  State<LogicTetrisWidget> createState() => _LogicTetrisWidgetState();
}

class _LogicTetrisWidgetState extends State<LogicTetrisWidget> {
  static const int _w = 8, _h = 14;
  final math.Random _rng = math.Random();
  late List<List<Color?>> _grid;
  _Falling? _cur;
  int _score = 0;
  bool _paused = false;
  bool _over = false;
  Timer? _tick;

  final List<_Piece> _shapes = [
    _Piece([(0, 0), (0, 1), (0, 2), (0, 3)], Colors.cyan),
    _Piece([(0, 1), (1, 0), (1, 1), (1, 2)], Colors.purple),
    _Piece([(0, 0), (1, 0), (1, 1), (1, 2)], Colors.green),
    _Piece([(0, 1), (1, 0), (1, 1)], Colors.orange),
  ];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _reset() {
    _grid = List.generate(_h, (_) => List<Color?>.filled(_w, null));
    _score = 0;
    _paused = false;
    _over = false;
    _spawn();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 700), (_) => _step());
  }

  void _spawn() {
    final _Piece shape = _shapes[_rng.nextInt(_shapes.length)];
    _cur = _Falling(shape, 0, (_w ~/ 2) - 1);
    if (!_canPlace(_cur!)) _over = true;
  }

  bool _canPlace(_Falling f) {
    for (final (dr, dc) in f.piece.cells) {
      final r = f.r + dr, c = f.c + dc;
      if (c < 0 || c >= _w || r >= _h) return false;
      if (r >= 0 && _grid[r][c] != null) return false;
    }
    return true;
  }

  void _step() {
    if (_paused || _over) return;
    setState(() {
      final _Falling next = _Falling(_cur!.piece, _cur!.r + 1, _cur!.c);
      if (_canPlace(next)) {
        _cur = next;
      } else {
        _lock();
      }
    });
  }

  void _lock() {
    for (final (dr, dc) in _cur!.piece.cells) {
      final r = _cur!.r + dr, c = _cur!.c + dc;
      if (r >= 0 && r < _h && c >= 0 && c < _w) _grid[r][c] = _cur!.piece.color;
    }
    // clear full rows
    for (var r = _h - 1; r >= 0; r--) {
      if (_grid[r].every((c) => c != null)) {
        _grid.removeAt(r);
        _grid.insert(0, List<Color?>.filled(_w, null));
        _score += 100;
        r++;
      }
    }
    _spawn();
  }

  void _move(int dc) {
    if (_cur == null || _over || _paused) return;
    final _Falling next = _Falling(_cur!.piece, _cur!.r, _cur!.c + dc);
    if (_canPlace(next)) setState(() => _cur = next);
  }

  void _rotate() =>
      _canPlace(_Falling(_cur!.piece.rotated(), _cur!.r, _cur!.c))
          ? setState(() => _cur!.piece = _cur!.piece.rotated())
          : null;

  void _hard() {
    if (_cur == null || _over || _paused) return;
    setState(() {
      while (_canPlace(_Falling(_cur!.piece, _cur!.r + 1, _cur!.c))) {
        _cur!.r++;
      }
      _lock();
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
                Text('score: $_score',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (_over)
              Text('Game over — score $_score',
                  style: Theme.of(context).textTheme.titleMedium),
            Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(4),
              child: AspectRatio(
                aspectRatio: _w / _h,
                child: CustomPaint(
                  painter: _GridPainter(_grid, _cur),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _move(-1), icon: const Icon(Icons.chevron_left)),
                Column(
                  children: [
                    IconButton(onPressed: _rotate, icon: const Icon(Icons.rotate_90_degrees_cw)),
                    IconButton(onPressed: _hard, icon: const Icon(Icons.keyboard_arrow_down)),
                  ],
                ),
                IconButton(onPressed: () => _move(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
            Center(
              child: TextButton(
                  onPressed: () => setState(_reset), child: const Text('Restart')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.grid, this.cur);
  final List<List<Color?>> grid;
  final _Falling? cur;
  @override
  void paint(Canvas canvas, Size size) {
    final int h = grid.length;
    final int w = grid[0].length;
    final double cw = size.width / w;
    final double ch = size.height / h;
    final Paint p = Paint();
    for (var r = 0; r < h; r++) {
      for (var c = 0; c < w; c++) {
        final Color? col = grid[r][c];
        if (col != null) {
          p.color = col;
          canvas.drawRect(
              Rect.fromLTWH(c * cw, r * ch, cw - 1, ch - 1), p);
        }
      }
    }
    if (cur != null) {
      p.color = cur!.piece.color;
      for (final (dr, dc) in cur!.piece.cells) {
        final r = cur!.r + dr, c = cur!.c + dc;
        if (r >= 0) {
          canvas.drawRect(
              Rect.fromLTWH(c * cw, r * ch, cw - 1, ch - 1), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => true;
}
