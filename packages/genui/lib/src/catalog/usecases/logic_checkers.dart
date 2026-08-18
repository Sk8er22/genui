// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A two-player checkers board: pieces move diagonally, crown on the last
/// rank, and captures are forced when available.
final class LogicCheckers {
  static final catalogItem = CatalogItem(
    name: 'LogicCheckers',
    dataSchema: S.object(
      description: 'Two-player checkers game.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicCheckersWidget(title: title is String ? title : 'Checkers');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicCheckers","title":"Checkers"}
]''',
    ],
  );
}

class LogicCheckersWidget extends StatefulWidget {
  const LogicCheckersWidget({super.key, this.title = 'Checkers'});
  final String title;
  @override
  State<LogicCheckersWidget> createState() => _LogicCheckersWidgetState();
}

class _LogicCheckersWidgetState extends State<LogicCheckersWidget> {
  static const int _empty = 0;
  static const int _red = 1; // player 0, sits on top, moves toward row 7
  static const int _redKing = 2;
  static const int _black = 3; // player 1, sits on bottom, moves toward row 0
  static const int _blackKing = 4;

  late List<int> _board; // 64 cells, row = idx ~/ 8, col = idx % 8
  int _turn = 0; // 0 = red, 1 = black
  int? _selected;
  List<int> _moves = const [];
  bool _gameOver = false;
  int? _winner;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  int _playerOf(int p) =>
      (p == _red || p == _redKing) ? 0 : 1;
  bool _isKing(int p) => p == _redKing || p == _blackKing;

  List<(int, int)> _dirs(int p) {
    if (p == _red) return const [(-1, -1), (-1, 1)];
    if (p == _black) return const [(1, -1), (1, 1)];
    return const [(-1, -1), (-1, 1), (1, -1), (1, 1)];
  }

  /// Destination squares for single-step (non-capture) diagonal moves.
  List<int> _simpleDests(int from, List<int> board) {
    final p = board[from];
    final r0 = from ~/ 8, c0 = from % 8;
    final res = <int>[];
    for (final (dr, dc) in _dirs(p)) {
      final nr = r0 + dr, nc = c0 + dc;
      if (nr < 0 || nr > 7 || nc < 0 || nc > 7) continue;
      if (board[nr * 8 + nc] == _empty) res.add(nr * 8 + nc);
    }
    return res;
  }

  /// Landing squares (distance 2) after jumping an enemy piece.
  List<int> _captureDests(int from, List<int> board) {
    final p = board[from];
    final enemy = 1 - _playerOf(p);
    final r0 = from ~/ 8, c0 = from % 8;
    final res = <int>[];
    for (final (dr, dc) in _dirs(p)) {
      final mr = r0 + dr, mc = c0 + dc;
      final lr = r0 + 2 * dr, lc = c0 + 2 * dc;
      if (lr < 0 || lr > 7 || lc < 0 || lc > 7) continue;
      final mid = mr * 8 + mc, land = lr * 8 + lc;
      if (board[mid] != _empty &&
          _playerOf(board[mid]) == enemy &&
          board[land] == _empty) {
        res.add(land);
      }
    }
    return res;
  }

  bool _canAnyCapture(int player) {
    for (var i = 0; i < 64; i++) {
      final p = _board[i];
      if (p != _empty &&
          _playerOf(p) == player &&
          _captureDests(i, _board).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _hasAnyMove(int player) {
    if (_canAnyCapture(player)) return true;
    for (var i = 0; i < 64; i++) {
      final p = _board[i];
      if (p != _empty &&
          _playerOf(p) == player &&
          _simpleDests(i, _board).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  void _select(int i) {
    final p = _board[i];
    if (p == _empty || _playerOf(p) != _turn) return;
    final forceCapture = _canAnyCapture(_turn);
    final capDests = _captureDests(i, _board);
    if (forceCapture) {
      if (capDests.isEmpty) return; // piece cannot capture; forced-capture on
      setState(() {
        _selected = i;
        _moves = capDests;
      });
      return;
    }
    final simple = _simpleDests(i, _board);
    if (simple.isEmpty) return;
    setState(() {
      _selected = i;
      _moves = simple;
    });
  }

  void _onTap(int i) {
    if (_gameOver) return;
    if (_selected != null) {
      if (_moves.contains(i)) {
        _performMove(_selected!, i);
        return;
      }
      final p = _board[i];
      if (p != _empty && _playerOf(p) == _turn) {
        _select(i);
        return;
      }
      setState(() {
        _selected = null;
        _moves = const [];
      });
      return;
    }
    _select(i);
  }

  void _performMove(int from, int to) {
    final p = _board[from];
    final bool isCapture = (to ~/ 8 - from ~/ 8).abs() == 2;
    if (isCapture) {
      final mid =
          ((from ~/ 8 + to ~/ 8) ~/ 2) * 8 + ((from % 8 + to % 8) ~/ 2);
      _board[mid] = _empty;
    }
    _board[to] = p;
    _board[from] = _empty;

    // Crown on reaching the opponent's back rank.
    final r = to ~/ 8;
    if (p == _red && r == 7) _board[to] = _redKing;
    if (p == _black && r == 0) _board[to] = _blackKing;

    setState(() {
      if (isCapture) {
        final cont = _captureDests(to, _board);
        if (cont.isNotEmpty) {
          // Same piece must keep capturing (multi-jump); turn stays.
          _selected = to;
          _moves = cont;
          return;
        }
      }
      _selected = null;
      _moves = const [];
      _turn = 1 - _turn;
      _checkEnd();
    });
  }

  void _checkEnd() {
    var redCount = 0, blackCount = 0;
    for (final c in _board) {
      if (c == _red || c == _redKing) {
        redCount++;
      } else if (c == _black || c == _blackKing) {
        blackCount++;
      }
    }
    if (redCount == 0) {
      _gameOver = true;
      _winner = 1;
      return;
    }
    if (blackCount == 0) {
      _gameOver = true;
      _winner = 0;
      return;
    }
    if (!_hasAnyMove(_turn)) {
      _gameOver = true;
      _winner = 1 - _turn;
    }
  }

  void _reset() {
    _board = List<int>.filled(64, _empty);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r + c).isOdd) _board[r * 8 + c] = _red;
      }
    }
    for (var r = 5; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r + c).isOdd) _board[r * 8 + c] = _black;
      }
    }
    _turn = 0;
    _selected = null;
    _moves = const [];
    _gameOver = false;
    _winner = null;
  }

  String _status() {
    if (_gameOver) {
      return _winner == 0 ? 'Red wins! 🎉' : 'Black wins! 🎉';
    }
    final base = _turn == 0 ? "Red's turn" : "Black's turn";
    return _canAnyCapture(_turn) ? '$base (capture!)' : base;
  }

  Widget _piece(int p) {
    final isRed = (p == _red || p == _redKing);
    final isKing = _isKing(p);
    final Color color = isRed ? Colors.red.shade600 : Colors.blueGrey.shade900;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black45, width: 2),
        boxShadow: const [
          BoxShadow(offset: Offset(1, 2), blurRadius: 3, color: Colors.black26),
        ],
      ),
      child: isKing
          ? Icon(Icons.star, color: Colors.amber.shade300, size: 18)
          : null,
    );
  }

  Widget _square(int i) {
    final r = i ~/ 8, c = i % 8;
    final bool isDark = (r + c).isOdd;
    final int p = _board[i];
    final bool isSelected = _selected == i;
    final bool isTarget = _moves.contains(i);
    return GestureDetector(
      onTap: () => _onTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? Colors.lightBlue.shade400
            : (isDark ? Colors.brown.shade400 : Colors.brown.shade100),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isTarget)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.25),
                  border: Border.all(color: Colors.white70, width: 2),
                ),
              ),
            if (p != _empty) _piece(p),
          ],
        ),
      ),
    );
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
                Text(_status(), style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.brown.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8),
                  itemCount: 64,
                  itemBuilder: (context, i) => _square(i),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _swatch(Colors.red.shade600),
                    Text("Red", style: Theme.of(context).textTheme.bodyMedium),
                    _swatch(Colors.blueGrey.shade900),
                    Text("Black", style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                OutlinedButton(
                  onPressed: () => setState(_reset),
                  child: const Text('New game'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
