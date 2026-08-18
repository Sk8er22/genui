// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Conway's Game of Life: a cellular automaton where cells live, die, or are
/// born on an infinite (here wrapped) grid based on their neighbors.
final class LogicGameOfLife {
  static final catalogItem = CatalogItem(
    name: 'LogicGameOfLife',
    dataSchema: S.object(
      description: 'Conway\'s Game of Life cellular automaton.',
      properties: {
        'title': S.string(),
        'rows': S.integer(description: 'Number of grid rows.'),
        'columns': S.integer(description: 'Number of grid columns.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? rows = (ctx.data as Map)['rows'];
      final Object? columns = (ctx.data as Map)['columns'];
      return LogicGameOfLifeWidget(
        title: title is String ? title : 'Game of Life',
        rows: rows is int && rows >= 5 ? rows : 20,
        columns: columns is int && columns >= 5 ? columns : 26,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicGameOfLife","title":"Game of Life"}
]''',
      () => '''
[
 {"id":"root","component":"LogicGameOfLife","title":"Life","rows":15,"columns":20}
]''',
    ],
  );
}

class LogicGameOfLifeWidget extends StatefulWidget {
  const LogicGameOfLifeWidget({
    super.key,
    this.title = 'Game of Life',
    this.rows = 20,
    this.columns = 26,
  });
  final String title;
  final int rows;
  final int columns;

  @override
  State<LogicGameOfLifeWidget> createState() => _LogicGameOfLifeWidgetState();
}

class _LogicGameOfLifeWidgetState extends State<LogicGameOfLifeWidget> {
  late List<List<bool>> _cells;
  Timer? _timer;
  bool _running = false;
  int _generation = 0;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _cells = List.generate(
        widget.rows, (_) => List<bool>.filled(widget.columns, false));
    _seedGlider();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Places a classic glider pattern so the widget is alive even before the
  /// user taps "Random".
  void _seedGlider() {
    const offsets = [
      [1, 0],
      [2, 1],
      [0, 2],
      [1, 2],
      [2, 2],
    ];
    final int r = widget.rows ~/ 2 - 1;
    final int c = widget.columns ~/ 2 - 2;
    for (final o in offsets) {
      final int row = r + o[0];
      final int col = c + o[1];
      if (row >= 0 && row < widget.rows && col >= 0 && col < widget.columns) {
        _cells[row][col] = true;
      }
    }
    _recount();
  }

  int _liveCount() {
    var n = 0;
    for (final row in _cells) {
      for (final cell in row) {
        if (cell) n++;
      }
    }
    return n;
  }

  void _recount() => _live = _liveCount();
  int _live = 0;

  void _toggle(int row, int col) {
    if (_running) return; // edits only make sense while paused
    setState(() {
      _cells[row][col] = !_cells[row][col];
      _live = _liveCount();
    });
  }

  void _randomize() {
    setState(() {
      for (var r = 0; r < widget.rows; r++) {
        for (var c = 0; c < widget.columns; c++) {
          _cells[r][c] = _rng.nextDouble() < 0.28;
        }
      }
      _live = _liveCount();
      _generation = 0;
    });
  }

  void _clear() {
    _pause();
    setState(() {
      for (var r = 0; r < widget.rows; r++) {
        _cells[r].fillRange(0, widget.columns, false);
      }
      _live = 0;
      _generation = 0;
    });
  }

  /// Advances the simulation one generation, applying the classic rules.
  void _step() {
    setState(() {
      final next = List.generate(
          widget.rows, (_) => List<bool>.filled(widget.columns, false));
      for (var r = 0; r < widget.rows; r++) {
        for (var c = 0; c < widget.columns; c++) {
          final int n = _neighbors(r, c);
          next[r][c] = _cells[r][c] ? (n == 2 || n == 3) : (n == 3);
        }
      }
      _cells = next;
      _live = _liveCount();
      _generation++;
    });
  }

  int _neighbors(int r, int c) {
    var n = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final int rr = (r + dr + widget.rows) % widget.rows; // wrap edges
        final int cc = (c + dc + widget.columns) % widget.columns;
        if (_cells[rr][cc]) n++;
      }
    }
    return n;
  }

  void _toggleRunning() {
    if (_running) {
      _pause();
    } else {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 150), (_) => _step());
      setState(() => _running = true);
    }
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    if (_running) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis),
                Text(
                  'Gen $_generation · Live $_live',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: widget.columns / widget.rows,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      final double cellW = constraints.maxWidth / widget.columns;
                      final double cellH =
                          constraints.maxHeight / widget.rows;
                      final int col = (details.localPosition.dx / cellW).floor();
                      final int row =
                          (details.localPosition.dy / cellH).floor();
                      if (row >= 0 &&
                          row < widget.rows &&
                          col >= 0 &&
                          col < widget.columns) {
                        _toggle(row, col);
                      }
                    },
                    child: CustomPaint(
                      size: Size(
                          constraints.maxWidth, constraints.maxHeight),
                      painter: _LifePainter(
                        cells: _cells,
                        color: theme.colorScheme.primary,
                        gridColor: Colors.black12,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: _running ? 'Pause' : 'Play',
                  onPressed: _toggleRunning,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Step',
                  onPressed: _running ? null : _step,
                  icon: const Icon(Icons.skip_next),
                ),
                IconButton(
                  tooltip: 'Random',
                  onPressed: _randomize,
                  icon: const Icon(Icons.shuffle),
                ),
                IconButton(
                  tooltip: 'Clear',
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LifePainter extends CustomPainter {
  _LifePainter({
    required this.cells,
    required this.color,
    required this.gridColor,
  });

  final List<List<bool>> cells;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final int rows = cells.length;
    final int cols = cells.isEmpty ? 0 : cells.first.length;
    if (rows == 0 || cols == 0) return;
    final double cellW = size.width / cols;
    final double cellH = size.height / rows;

    // Cell body.
    final Paint live = Paint()..color = color;
    // Grid lines.
    final Paint line = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (cells[r][c]) {
          final double w = cellW > 2 ? cellW - 2 : 0;
          final double h = cellH > 2 ? cellH - 2 : 0;
          canvas.drawRect(
            Rect.fromLTWH(c * cellW + 1, r * cellH + 1, w, h),
            live,
          );
        }
      }
    }

    for (var c = 1; c < cols; c++) {
      final double x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var r = 1; r < rows; r++) {
      final double y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_LifePainter oldDelegate) => oldDelegate.cells != cells;
}
