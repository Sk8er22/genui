// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Eight Queens: place all 8 queens on the 8x8 board so that no two queens
/// attack each other. Tapping a cell toggles a queen on/off there. Cells
/// attacked by a queen (same row, column or diagonal) are highlighted in a red
/// warning color, as are queens that share a row/column/diagonal with another
/// queen.
final class LogicEightQueens {
  static final catalogItem = CatalogItem(
    name: 'LogicEightQueens',
    dataSchema: S.object(
      description: 'Classic 8-Queens chessboard puzzle.',
      properties: {
        'title': S.string(),
      },
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicEightQueensWidget(
        title: title is String ? title : 'Eight Queens',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicEightQueens","title":"Eight Queens"}
]''',
    ],
  );
}

class LogicEightQueensWidget extends StatefulWidget {
  const LogicEightQueensWidget({super.key, this.title = 'Eight Queens'});
  final String title;
  @override
  State<LogicEightQueensWidget> createState() => _LogicEightQueensWidgetState();
}

class _LogicEightQueensWidgetState extends State<LogicEightQueensWidget> {
  static const int _n = 8;

  /// `_board[r][c]` is true when a queen occupies that cell.
  late List<List<bool>> _board;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(_n, (_) => List.filled(_n, false));
    _solved = false;
  }

  int get _queenCount {
    var count = 0;
    for (final List<bool> row in _board) {
      for (final bool hasQueen in row) {
        if (hasQueen) count++;
      }
    }
    return count;
  }

  /// Cells currently attacked by at least one queen. A queen's own square is
  /// never marked by itself: it only counts as attacked when another queen
  /// shares its row, column or diagonal with it.
  List<List<bool>> _computeAttacked() {
    final List<List<bool>> attacked =
        List.generate(_n, (_) => List.filled(_n, false));
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (!_board[r][c]) continue;
        for (var r2 = 0; r2 < _n; r2++) {
          for (var c2 = 0; c2 < _n; c2++) {
            if (r2 == r && c2 == c) continue;
            // Same row, column or diagonal (uses the row+col / row-col
            // diagonal invariants).
            if (r2 == r ||
                c2 == c ||
                r2 + c2 == r + c ||
                r2 - c2 == r - c) {
              attacked[r2][c2] = true;
            }
          }
        }
      }
    }
    return attacked;
  }

  /// Number of pairs of queens that attack each other (share a row, column or
  /// diagonal).
  int _conflictCount() {
    final List<(int, int)> queens = <(int, int)>[];
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_board[r][c]) queens.add((r, c));
      }
    }
    var conflicts = 0;
    for (var i = 0; i < queens.length; i++) {
      for (var j = i + 1; j < queens.length; j++) {
        final (int r1, int c1) = queens[i];
        final (int r2, int c2) = queens[j];
        if (r1 == r2 ||
            c1 == c2 ||
            r1 + c1 == r2 + c2 ||
            r1 - c1 == r2 - c2) {
          conflicts++;
        }
      }
    }
    return conflicts;
  }

  void _onTap(int r, int c) {
    if (_solved) return;
    setState(() {
      _board[r][c] = !_board[r][c];
      _solved = _queenCount == _n && _conflictCount() == 0;
    });
  }

  void _clear() {
    setState(_reset);
  }

  @override
  Widget build(BuildContext context) {
    final int queens = _queenCount;
    final int conflicts = _conflictCount();
    final List<List<bool>> attacked = _computeAttacked();
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
                Text('queens: $queens/$_n · conflicts: $conflicts',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            if (_solved)
              Text(
                'Solved! $queens queens placed with zero conflicts 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              )
            else
              Text(
                'Place 8 queens so no two share a row, column or diagonal.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _n,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: _n * _n,
                itemBuilder: (context, i) {
                  final int r = i ~/ _n, c = i % _n;
                  return _buildCell(r, c, attacked[r][c]);
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: _clear, child: const Text('Clear')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int r, int c, bool isAttacked) {
    final bool hasQueen = _board[r][c];
    // Classic light/dark checkerboard pattern.
    final Color base =
        (r + c).isEven ? Colors.white : Colors.brown.shade200;
    final Color fill = hasQueen && isAttacked
        ? Colors.red.shade400
        : isAttacked
            ? Colors.red.shade200
            : base;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: _solved ? null : () => _onTap(r, c),
        child: Container(
          alignment: Alignment.center,
          child: hasQueen
              ? Text(
                  '♛',
                  style: TextStyle(
                    fontSize: 26,
                    color: isAttacked
                        ? Colors.red.shade900
                        : Colors.black87,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
