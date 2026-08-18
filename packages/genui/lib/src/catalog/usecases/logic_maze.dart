// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Maze explorer: the model sets the grid size; a maze is generated with a
/// randomized depth-first search and the player taps cells to walk from the
/// top-left to the exit in the bottom-right corner, counting moves.
final class LogicMaze {
  static final catalogItem = CatalogItem(
    name: 'LogicMaze',
    dataSchema: S.object(
      description: 'Navigate a generated maze to the exit.',
      properties: {
        'title': S.string(),
        'rows': S.integer(description: 'Maze rows (4..16).'),
        'cols': S.integer(description: 'Maze columns (4..16).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? rows = (ctx.data as Map)['rows'];
      final Object? cols = (ctx.data as Map)['cols'];
      return LogicMazeWidget(
        title: title is String ? title : 'Maze',
        rows: rows is int ? rows.clamp(4, 16) : 8,
        cols: cols is int ? cols.clamp(4, 16) : 8,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicMaze","title":"Maze","rows":8,"cols":8}
]''',
    ],
  );
}

class LogicMazeWidget extends StatefulWidget {
  const LogicMazeWidget(
      {super.key, this.title = 'Maze', this.rows = 8, this.cols = 8});
  final String title;
  final int rows;
  final int cols;
  @override
  State<LogicMazeWidget> createState() => _LogicMazeWidgetState();
}

class _LogicMazeWidgetState extends State<LogicMazeWidget> {
  static const List<(int, int)> _dirs = [(0, 1), (0, -1), (1, 0), (-1, 0)];

  final math.Random _rng = math.Random();
  late int _rows;
  late int _cols;
  late List<List<bool>> _right; // wall between (r, c) and (r, c + 1)
  late List<List<bool>> _down; // wall between (r, c) and (r + 1, c)
  late List<List<bool>> _vis;
  late int _pr, _pc; // player position
  int _moves = 0;
  int? _best;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _newMaze();
  }

  void _newMaze() {
    _rows = widget.rows.clamp(4, 16);
    _cols = widget.cols.clamp(4, 16);
    _right = [
      for (var r = 0; r < _rows; r++) List<bool>.filled(_cols - 1, true),
    ];
    _down = [
      for (var r = 0; r < _rows - 1; r++) List<bool>.filled(_cols, true),
    ];
    _vis = [
      for (var r = 0; r < _rows; r++) List<bool>.filled(_cols, false),
    ];
    _carve(0, 0);
    _pr = 0;
    _pc = 0;
    _moves = 0;
    _won = false;
  }

  /// Randomized depth-first search that carves a fully connected maze.
  void _carve(int r, int c) {
    _vis[r][c] = true;
    final dirs = [..._dirs]..shuffle(_rng);
    for (final (dr, dc) in dirs) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
      if (_vis[nr][nc]) continue;
      if (dr == 0 && dc == 1) {
        _right[r][c] = false; // open passage to the right
      } else if (dr == 0 && dc == -1) {
        _right[r][nc] = false; // open passage to the left
      } else if (dr == 1 && dc == 0) {
        _down[r][c] = false; // open passage below
      } else {
        _down[nr][c] = false; // open passage above
      }
      _carve(nr, nc);
    }
  }

  bool _isOpen(int r, int c, int nr, int nc) {
    if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) return false;
    if (nr == r + 1 && nc == c) return !_down[r][c];
    if (nr == r - 1 && nc == c) return !_down[nr][c];
    if (nr == r && nc == c + 1) return !_right[r][c];
    if (nr == r && nc == c - 1) return !_right[r][nc];
    return false;
  }

  /// Walk one step along the shortest path from the player to the tapped cell.
  void _onTap(int tr, int tc) {
    if (_won || (tr == _pr && tc == _pc)) return;
    final List<List<int>> parent =
        List.generate(_rows, (_) => List<int>.filled(_cols, -1));
    final Queue<({int r, int c})> q = Queue();
    q.add((r: _pr, c: _pc));
    parent[_pr][_pc] = _pr * _cols + _pc;
    ({int r, int c})? found;
    while (q.isNotEmpty && found == null) {
      final cur = q.removeFirst();
      for (final (dr, dc) in _dirs) {
        final nr = cur.r + dr, nc = cur.c + dc;
        if (!_isOpen(cur.r, cur.c, nr, nc)) continue;
        if (parent[nr][nc] != -1) continue;
        parent[nr][nc] = cur.r * _cols + cur.c;
        if (nr == tr && nc == tc) {
          found = (r: nr, c: nc);
          break;
        }
        q.add((r: nr, c: nc));
      }
    }
    if (found == null) return; // target unreachable
    // Walk the parent chain back to the first step away from the player.
    var cr = found.r, cc = found.c;
    while (true) {
      final p = parent[cr][cc];
      final pr = p ~/ _cols, pc = p % _cols;
      if (pr == _pr && pc == _pc) break;
      cr = pr;
      cc = pc;
    }
    setState(() {
      _pr = cr;
      _pc = cc;
      _moves++;
      if (_pr == _rows - 1 && _pc == _cols - 1) {
        _won = true;
        if (_best == null || _moves < _best!) _best = _moves;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(
                  'moves: $_moves${_best == null ? '' : '  best: $_best'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: AspectRatio(
                aspectRatio: _cols / _rows,
                child: LayoutBuilder(builder: (context, constraints) {
                  final Size size = constraints.biggest;
                  return GestureDetector(
                    onTapDown: (details) {
                      final double cell = math.min(
                          size.width / _cols, size.height / _rows);
                      final double ox = (size.width - cell * _cols) / 2;
                      final double oy = (size.height - cell * _rows) / 2;
                      final double localDx = details.localPosition.dx - ox;
                      final double localDy = details.localPosition.dy - oy;
                      if (localDx < 0 || localDy < 0) return;
                      final int c = (localDx / cell).floor();
                      final int r = (localDy / cell).floor();
                      if (r >= 0 && r < _rows && c >= 0 && c < _cols) {
                        _onTap(r, c);
                      }
                    },
                    child: CustomPaint(
                      size: size,
                      painter: _MazePainter(
                        rows: _rows,
                        cols: _cols,
                        right: _right,
                        down: _down,
                        pr: _pr,
                        pc: _pc,
                        exitR: _rows - 1,
                        exitC: _cols - 1,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_won)
                  Text('You escaped! 🎉',
                      style: Theme.of(context).textTheme.titleMedium)
                else
                  Text('Tap the exit to walk there',
                      style: Theme.of(context).textTheme.bodySmall),
                FilledButton.icon(
                  onPressed: () => setState(_newMaze),
                  icon: const Icon(Icons.refresh),
                  label: const Text('New maze'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter({
    required this.rows,
    required this.cols,
    required this.right,
    required this.down,
    required this.pr,
    required this.pc,
    required this.exitR,
    required this.exitC,
  });

  final int rows;
  final int cols;
  final List<List<bool>> right;
  final List<List<bool>> down;
  final int pr, pc, exitR, exitC;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell =
        math.min(size.width / cols, size.height / rows);
    final double ox = (size.width - cell * cols) / 2;
    final double oy = (size.height - cell * rows) / 2;

    // Background.
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, cell * cols, cell * rows),
      Paint()..color = Colors.grey.shade100,
    );

    // Highlight the exit cell.
    canvas.drawRect(
      Rect.fromLTWH(ox + exitC * cell, oy + exitR * cell, cell, cell),
      Paint()..color = Colors.green.shade200,
    );

    final Paint wall = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Vertical inner walls.
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols - 1; c++) {
        if (right[r][c]) {
          final double x = ox + (c + 1) * cell;
          canvas.drawLine(Offset(x, oy + r * cell),
              Offset(x, oy + (r + 1) * cell), wall);
        }
      }
    }
    // Horizontal inner walls.
    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < cols; c++) {
        if (down[r][c]) {
          final double y = oy + (r + 1) * cell;
          canvas.drawLine(Offset(ox + c * cell, y),
              Offset(ox + (c + 1) * cell, y), wall);
        }
      }
    }
    // Outer border.
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, cell * cols, cell * rows),
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Player.
    canvas.drawCircle(
      Offset(ox + (pc + 0.5) * cell, oy + (pr + 0.5) * cell),
      cell * 0.32,
      Paint()..color = Colors.indigo.shade600,
    );
  }

  @override
  bool shouldRepaint(covariant _MazePainter old) =>
      old.rows != rows ||
      old.cols != cols ||
      old.pr != pr ||
      old.pc != pc ||
      old.right != right ||
      old.down != down;
}
