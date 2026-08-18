// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// An interactive pathfinding visualizer (BFS and A*).
///
/// The user places a green start square and a red end square on a grid, paints
/// walls, and picks an algorithm (BFS or A*). Running animates the search as
/// the explored cells spread from the start, then draws the shortest path in
/// blue, with a step count. Pure Dart + Flutter; no graph/geometry package.
final class LogicPathfinding {
  static final catalogItem = CatalogItem(
    name: 'LogicPathfinding',
    dataSchema: S.object(
      description: 'Interactive pathfinding (BFS / A*) on a walled grid.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicPathfindingWidget(
          title: title is String ? title : 'Pathfinding');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPathfinding","title":"Pathfinding"}
]''',
    ],
  );
}

/// Grid cell kinds.
enum _Cell { empty, wall, start, end }

/// Currently selected edit tool.
enum _Tool { start, end, wall, erase }

/// Available search algorithms.
enum _Algo { bfs, astar }

class LogicPathfindingWidget extends StatefulWidget {
  const LogicPathfindingWidget({super.key, this.title = 'Pathfinding'});
  final String title;
  @override
  State<LogicPathfindingWidget> createState() => _LogicPathfindingWidgetState();
}

class _LogicPathfindingWidgetState extends State<LogicPathfindingWidget> {
  static const int _rows = 15;
  static const int _cols = 15;
  static const int _batch = 6; // cells expanded per animation tick

  late List<List<_Cell>> _grid;
  (int, int)? _start;
  (int, int)? _end;
  _Tool _tool = _Tool.wall;
  _Algo _algo = _Algo.astar;

  bool _running = false;
  Timer? _timer;
  int _startCode = -1;
  int _endCode = -1;
  final Set<int> _visited = {};
  Set<int> _frontier = {};
  final Set<int> _path = {};
  final Map<int, int> _parent = {};
  final Map<int, int> _g = {};
  List<int> _queue = [];
  int _expanded = 0;
  String _info = 'Set the start/end, paint walls, pick BFS or A*, hit Run.';

  @override
  void initState() {
    super.initState();
    _grid = List.generate(_rows, (_) => List<_Cell>.filled(_cols, _Cell.empty));
    _start = (2, 2);
    _end = (12, 12);
    _grid[2][2] = _Cell.start;
    _grid[12][12] = _Cell.end;
    _seedWalls();
  }

  /// A small wall pattern so the search has something to route around.
  void _seedWalls() {
    for (final (r, c) in const [
      (3, 4), (3, 5), (3, 6), (3, 7), (3, 8),
      (5, 7), (5, 8), (6, 7), (6, 8), (7, 7), (7, 8), (8, 7), (8, 8),
      (10, 3), (10, 4), (10, 5), (11, 5), (12, 5),
    ]) {
      _grid[r][c] = _Cell.wall;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _code(int r, int c) => r * _cols + c;
  int _row(int code) => code ~/ _cols;
  int _col(int code) => code % _cols;

  /// Clears the search overlay (and optionally all walls), cancelling timers.
  void _resetSearch({required bool keepWalls}) {
    if (!keepWalls) {
      for (final row in _grid) {
        for (var c = 0; c < row.length; c++) {
          if (row[c] == _Cell.wall) row[c] = _Cell.empty;
        }
      }
    }
    _timer?.cancel();
    _timer = null;
    _visited.clear();
    _frontier.clear();
    _path.clear();
    _parent.clear();
    _g.clear();
    _queue = [];
    _running = false;
    _expanded = 0;
  }

  bool _isAnchor(int r, int c) =>
      (_start != null && r == _start!.$1 && c == _start!.$2) ||
      (_end != null && r == _end!.$1 && c == _end!.$2);

  void _tap(int r, int c) {
    if (_running) return;
    setState(() {
      // Any edit while a result overlay is showing starts fresh.
      if (_timer != null || _visited.isNotEmpty || _path.isNotEmpty) {
        _resetSearch(keepWalls: true);
      }
      switch (_tool) {
        case _Tool.start:
          if (_isAnchor(r, c)) return;
          if (_start != null) _grid[_start!.$1][_start!.$2] = _Cell.empty;
          _start = (r, c);
          _grid[r][c] = _Cell.start;
        case _Tool.end:
          if (_isAnchor(r, c)) return;
          if (_end != null) _grid[_end!.$1][_end!.$2] = _Cell.empty;
          _end = (r, c);
          _grid[r][c] = _Cell.end;
        case _Tool.wall:
          if (_isAnchor(r, c)) return;
          _grid[r][c] = _grid[r][c] == _Cell.wall ? _Cell.empty : _Cell.wall;
        case _Tool.erase:
          if (_start != null && r == _start!.$1 && c == _start!.$2) {
            _start = null;
            _grid[r][c] = _Cell.empty;
          } else if (_end != null && r == _end!.$1 && c == _end!.$2) {
            _end = null;
            _grid[r][c] = _Cell.empty;
          } else {
            _grid[r][c] = _Cell.empty;
          }
      }
      _info = '';
    });
  }

  void _run() {
    if (_running) return;
    final int? sCode = _start == null ? null : _code(_start!.$1, _start!.$2);
    final int? eCode = _end == null ? null : _code(_end!.$1, _end!.$2);
    if (sCode == null || eCode == null) {
      setState(() => _info = 'Place a green start and a red end first.');
      return;
    }
    _resetSearch(keepWalls: true);
    _startCode = sCode;
    _endCode = eCode;
    _parent[sCode] = sCode;
    _g[sCode] = 0;
    _queue = [sCode];
    _frontier = {sCode};
    setState(() {
      _running = true;
      _info = _algo == _Algo.bfs ? 'BFS: spreading...' : 'A*: spreading...';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _step());
  }

  int _fScore(int code) => (_g[code] ?? 0) + _heuristic(code);

  /// Manhattan distance to the end (admissible heuristic for A*).
  int _heuristic(int code) =>
      (_row(code) - _end!.$1).abs() + (_col(code) - _end!.$2).abs();

  void _step() {
    for (var i = 0; i < _batch && _queue.isNotEmpty; i++) {
      final int cur;
      if (_algo == _Algo.bfs) {
        cur = _queue.removeAt(0);
      } else {
        int best = 0;
        for (var j = 1; j < _queue.length; j++) {
          if (_fScore(_queue[j]) < _fScore(_queue[best])) best = j;
        }
        cur = _queue.removeAt(best);
      }
      if (cur == _endCode) {
        _finishWithPath(cur);
        return;
      }
      _visited.add(cur);
      _expand(cur);
    }
    _frontier = Set.of(_queue);
    setState(() {});
    if (_queue.isEmpty) {
      _finishNoPath();
    }
  }

  /// Enqueue the four orthogonal neighbours of [cur] that are open.
  void _expand(int cur) {
    _expanded++;
    final int r = _row(cur);
    final int c = _col(cur);
    final int gCur = _g[cur] ?? 0;
    for (final (dr, dc) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      final int nr = r + dr;
      final int nc = c + dc;
      if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
      if (_grid[nr][nc] == _Cell.wall) continue;
      final int nCode = _code(nr, nc);
      if (_visited.contains(nCode)) continue;
      final int ng = gCur + 1;
      final int? oldG = _g[nCode];
      if (oldG != null && oldG <= ng) continue;
      _parent[nCode] = cur;
      _g[nCode] = ng;
      if (!_queue.contains(nCode)) _queue.add(nCode);
    }
  }

  void _finishWithPath(int cur) {
    _timer?.cancel();
    _timer = null;
    // Reconstruct the path by walking the parent chain back to the start.
    final Set<int> path = {cur};
    var c = cur;
    while (c != _startCode) {
      c = _parent[c]!;
      path.add(c);
    }
    _path.addAll(path);
    setState(() {
      _running = false;
      _frontier = {};
      _info = 'Shortest path ${path.length - 1} step(s) '
          'after $_expanded expanded cell(s).';
    });
  }

  void _finishNoPath() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _running = false;
      _frontier = {};
      _info = 'No path exists ($_expanded cells explored).';
    });
  }

  Color _colorAt(int r, int c) {
    final int code = _code(r, c);
    switch (_grid[r][c]) {
      case _Cell.wall:
        return Colors.grey.shade700;
      case _Cell.start:
        return Colors.green;
      case _Cell.end:
        return Colors.red;
      case _Cell.empty:
        break;
    }
    if (_path.contains(code)) return Colors.indigo.shade400;
    if (_frontier.contains(code)) return Colors.amber.shade300;
    if (_visited.contains(code)) return Colors.blueGrey.shade200;
    return Colors.grey.shade200;
  }

  Widget _toolChip(_Tool t, String label, Color? color) {
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        if (color != null) ...[
          Container(width: 12, height: 12,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        Text(label),
      ]),
      selected: _tool == t,
      onSelected: (_) => setState(() => _tool = t),
    );
  }

  Widget _algoChip(_Algo a, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _algo == a,
      onSelected: (_) {
        if (_running) return;
        setState(() => _algo = a);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: theme.textTheme.titleMedium),
                  ),
                  if (_running)
                    const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _toolChip(_Tool.start, 'Start', Colors.green),
                  _toolChip(_Tool.end, 'End', Colors.red),
                  _toolChip(_Tool.wall, 'Wall', Colors.grey.shade700),
                  _toolChip(_Tool.erase, 'Erase', null),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  _algoChip(_Algo.bfs, 'BFS'),
                  _algoChip(_Algo.astar, 'A*'),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _cols,
                ),
                itemCount: _rows * _cols,
                itemBuilder: (context, i) {
                  final int r = i ~/ _cols, c = i % _cols;
                  return GestureDetector(
                    onTap: () => _tap(r, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorAt(r, c),
                        border:
                            Border.all(color: Colors.white, width: 0.5),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(_info,
                        style: theme.textTheme.bodySmall, maxLines: 2),
                  ),
                  OutlinedButton(
                    onPressed: _running
                        ? null
                        : () => setState(() => _resetSearch(keepWalls: false)),
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _running ? null : _run,
                    child: const Text('Run'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
