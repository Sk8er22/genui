// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Othello / Reversi on an 8x8 board vs flip logic. Two humans.
final class LogicReversi {
  static final catalogItem = CatalogItem(
    name: 'LogicReversi',
    dataSchema: S.object(
      description: 'Othello / Reversi board game.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicReversiWidget(title: title is String ? title : 'Othello');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicReversi","title":"Othello"}
]''',
    ],
  );
}

class LogicReversiWidget extends StatefulWidget {
  const LogicReversiWidget({super.key, this.title = 'Othello'});
  final String title;
  @override
  State<LogicReversiWidget> createState() => _LogicReversiWidgetState();
}

class _LogicReversiWidgetState extends State<LogicReversiWidget> {
  static const int _n = 8;
  late List<List<int?>> _board; // 1 black, 2 white
  bool _black = true;
  bool _gameOver = false;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(_n, (_) => List<int?>.filled(_n, null));
    _board[3][3] = 2;
    _board[3][4] = 1;
    _board[4][3] = 1;
    _board[4][4] = 2;
    _black = true;
    _gameOver = false;
    _winner = null;
  }

  bool _in(int r, int c) => r >= 0 && r < _n && c >= 0 && c < _n;

  /// Flips to play for player `me` placed at (r,c); returns flips applied.
  int _applyPlace(int r, int c, int me, List<List<int?>> board) {
    final int opp = me == 1 ? 2 : 1;
    int flips = 0;
    for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0),
        (1, 1), (1, -1), (-1, 1), (-1, -1)]) {
      var rr = r + d.$1, cc = c + d.$2;
      final List<(int, int)> toFlip = [];
      while (_in(rr, cc) && board[rr][cc] == opp) {
        toFlip.add((rr, cc));
        rr += d.$1;
        cc += d.$2;
      }
      if (_in(rr, cc) && board[rr][cc] == me) {
        for (final (x, y) in toFlip) {
          board[x][y] = me;
        }
        flips += toFlip.length;
      }
    }
    return flips;
  }

  bool _isLegal(int r, int c, int me) {
    if (_board[r][c] != null) return false;
    // probe on a copy so legality checking never mutates the live board
    final List<List<int?>> probe =
        [for (final row in _board) List<int?>.from(row)];
    return _applyPlace(r, c, me, probe) > 0;
  }

  void _tap(int r, int c) {
    if (_gameOver || !_isLegal(r, c, _black ? 1 : 2)) return;
    setState(() {
      _board[r][c] = _black ? 1 : 2;
      _applyPlace(r, c, _black ? 1 : 2, _board);
      // switch sides; if no moves, pass
      if (!_anyMove(_black ? 2 : 1)) {
        if (!_anyMove(_black ? 1 : 2)) {
          _endGame();
          return;
        }
        // pass (keep same player implicitly skipping is handled below)
      } else {
        _black = !_black;
      }
      _checkPass();
    });
  }

  void _checkPass() {
    if (!_anyMove(_black ? 1 : 2) && !_gameOver) {
      // pass turn if current player has no move but other does
      if (_anyMove(_black ? 2 : 1)) {
        _black = !_black;
      } else {
        _endGame();
      }
    }
  }

  bool _anyMove(int me) {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_isLegal(r, c, me)) return true;
      }
    }
    return false;
  }

  void _endGame() {
    _gameOver = true;
    int black = 0, white = 0;
    for (final row in _board) {
      for (final v in row) {
        if (v == 1) black++;
        if (v == 2) white++;
      }
    }
    _winner = black > white ? 'Black wins ($black-$white)' :
        white > black ? 'White wins ($white-$black)' : 'Draw';
  }

  @override
  Widget build(BuildContext context) {
    final int black = _board.expand((r) => r).where((v) => v == 1).length;
    final int white = _board.expand((r) => r).where((v) => v == 2).length;
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
                Text('●$black  ○$white',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _gameOver
                  ? (_winner ?? 'Game over')
                  : '${_black ? 'Black' : 'White'} to move',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
                  final int? v = _board[r][c];
                  final bool legal = _isLegal(r, c, _black ? 1 : 2);
                  return InkWell(
                    onTap: () => _tap(r, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        border: Border.all(
                            color: Colors.green.shade900, width: .5),
                      ),
                      alignment: Alignment.center,
                      child: v == null
                          ? (legal
                              ? Icon(Icons.circle,
                                  size: 10,
                                  color: _black
                                      ? Colors.black12
                                      : Colors.white12)
                              : null)
                          : Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: v == 1 ? Colors.black : Colors.white,
                                boxShadow: const [
                                  BoxShadow(blurRadius: 2, color: Colors.black54),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_gameOver)
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
