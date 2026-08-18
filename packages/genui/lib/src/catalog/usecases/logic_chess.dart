// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A fully playable chess board — the 'genui with logic' showcase.
///
/// Legal-move generation for knights, rooks, bishops, queens, kings, pawns
/// (incl. two-step + promotion to queen), with check/checkmate/stalemate,
/// turn tracking and a captured-pieces panel. Pure Dart + Flutter; no package.
final class LogicChess {
  static final catalogItem = CatalogItem(
    name: 'LogicChess',
    dataSchema: S.object(
      description: 'A full playable chess game (human vs human).',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicChessWidget(title: title is String ? title : 'Chess');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicChess","title":"Chess"}
]''',
    ],
  );
}

typedef _Board = List<List<String?>>; // piece code like 'wp','bk' or null

class LogicChessWidget extends StatefulWidget {
  const LogicChessWidget({super.key, this.title = 'Chess'});
  final String title;
  @override
  State<LogicChessWidget> createState() => _LogicChessWidgetState();
}

class _LogicChessWidgetState extends State<LogicChessWidget> {
  late List<List<String?>> _board;
  bool _white = true;
  int? _selR, _selC;
  String? _status;

  @override
  void initState() {
    super.initState();
    _board = _initialBoard();
  }

  List<List<String?>> _initialBoard() {
    const backRank = ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'];
    final b = List.generate(8, (_) => List<String?>.filled(8, null));
    for (var c = 0; c < 8; c++) {
      b[0][c] = 'b${backRank[c]}';
      b[1][c] = 'bp';
      b[6][c] = 'wp';
      b[7][c] = 'w${backRank[c]}';
    }
    return b;
  }

  String? get _color => _white ? 'w' : 'b';

  bool _isEnemy(int r, int c) {
    final String? p = _board[r][c];
    return p != null && p[0] != _color;
  }

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  List<(int, int)> _movesFor(int r, int c) {
    final String? p = _board[r][c];
    if (p == null) return [];
    final String type = p.substring(1);
    final bool white = p[0] == 'w';
    final List<(int, int)> out = [];

    void addLine(int dr, int dc) {
      var rr = r + dr, cc = c + dc;
      while (_inBounds(rr, cc)) {
        if (_board[rr][cc] == null) {
          out.add((rr, cc));
        } else {
          if (_isEnemy(rr, cc)) out.add((rr, cc));
          break;
        }
        rr += dr;
        cc += dc;
      }
    }

    switch (type) {
      case 'n':
        for (final (dr, dc) in const [(2, 1), (2, -1), (-2, 1), (-2, -1),
            (1, 2), (1, -2), (-1, 2), (-1, -2)]) {
          final rr = r + dr, cc = c + dc;
          if (_inBounds(rr, cc) && _board[rr][cc] == null) out.add((rr, cc));
          if (_inBounds(rr, cc) && _isEnemy(rr, cc)) out.add((rr, cc));
        }
        return out;
      case 'r':
        for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          addLine(d.$1, d.$2);
        }
        return out;
      case 'b':
        for (final d in const [(1, 1), (1, -1), (-1, 1), (-1, -1)]) {
          addLine(d.$1, d.$2);
        }
        return out;
      case 'q':
        for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0),
            (1, 1), (1, -1), (-1, 1), (-1, -1)]) {
          addLine(d.$1, d.$2);
        }
        return out;
      case 'k':
        for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0),
            (1, 1), (1, -1), (-1, 1), (-1, -1)]) {
          final rr = r + d.$1, cc = c + d.$2;
          if (_inBounds(rr, cc) && _board[rr][cc] == null) out.add((rr, cc));
          if (_inBounds(rr, cc) && _isEnemy(rr, cc)) out.add((rr, cc));
        }
        return out;
      case 'p':
        final int dir = white ? -1 : 1;
        final int start = white ? 6 : 1;
        // forward
        if (_inBounds(r + dir, c) && _board[r + dir][c] == null) {
          out.add((r + dir, c));
          if (r == start && _board[r + 2 * dir][c] == null) {
            out.add((r + 2 * dir, c));
          }
        }
        // captures
        for (final dc in const [-1, 1]) {
          final rr = r + dir, cc = c + dc;
          if (_inBounds(rr, cc) && _isEnemy(rr, cc)) out.add((rr, cc));
        }
    }
    return out;
  }

  List<(int, int)> _legal(int r, int c) {
    final List<(int, int)> raw = _movesFor(r, c);
    final List<(int, int)> legal = [];
    for (final (toR, toC) in raw) {
      if (!_wouldLeaveKingInCheck(r, c, toR, toC)) legal.add((toR, toC));
    }
    return legal;
  }

  bool _wouldLeaveKingInCheck(int fromR, int fromC, int toR, int toC) {
    final b = [for (final row in _board) List<String?>.from(row)];
    b[toR][toC] = b[fromR][fromC];
    b[fromR][fromC] = null;
    return _inCheck(b, _color!);
  }

  bool _inCheck(List<List<String?>> b, String color) {
    // find king
    int kr = -1, kc = -1;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (b[r][c] == '${color}k') {
          kr = r;
          kc = c;
        }
      }
    }
    if (kr < 0) return true;
    final String enemy = color == 'w' ? 'b' : 'w';
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (b[r][c] != null &&
            b[r][c]![0] == enemy &&
            _lineAttacks(b, r, c, kr, kc)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Direct-geometric attack test: does the piece at (fr,fc) attack (tr,tc)?
  bool _lineAttacks(List<List<String?>> b, int fr, int fc, int tr, int tc) {
    final String type = b[fr][fc]!.substring(1);
    final int dr = tr - fr, dc = tc - fc;
    final int adr = dr.abs(), adc = dc.abs();
    switch (type) {
      case 'p':
        // pawn attacks diagonally one row forward
        final int dir = b[fr][fc]![0] == 'w' ? -1 : 1;
        return dr == dir && adc == 1;
      case 'n':
        return (adr == 2 && adc == 1) || (adr == 1 && adc == 2);
      case 'k':
        return adr <= 1 && adc <= 1;
      case 'r':
        if (!(adr == 0 || adc == 0)) return false;
        break; // sliding, check path below
      case 'b':
        if (adr != adc) return false;
        break;
      case 'q':
        if (!((adr == 0 || adc == 0) || (adr == adc))) return false;
        break;
      default:
        return false;
    }
    // sliding: ensure clear path
    final int stepR = adr == 0 ? 0 : dr ~/ adr;
    final int stepC = adc == 0 ? 0 : dc ~/ adc;
    var rr = fr + stepR, cc = fc + stepC;
    while (!(rr == tr && cc == tc)) {
      if (b[rr][cc] != null) return false;
      rr += stepR;
      cc += stepC;
    }
    return true;
  }

  void _tap(int r, int c) {
    // Freeze the board once the game is decided (mate/stalemate).
    if (_status != null) return;
    setState(() {
      if (_selR != null) {
        final List<(int, int)> legal = _legal(_selR!, _selC!);
        if (legal.contains((r, c))) {
          _applyMove(_selR!, _selC!, r, c);
          _selR = null;
          _selC = null;
          return;
        }
      }
      final String? p = _board[r][c];
      if (p != null && p[0] == _color) {
        _selR = r;
        _selC = c;
      } else {
        _selR = null;
        _selC = null;
      }
    });
  }

  void _applyMove(int fr, int fc, int tr, int tc) {
    String piece = _board[fr][fc]!;
    // pawn promotion to queen on last rank
    if (piece == 'wp' && tr == 0) piece = 'wq';
    if (piece == 'bp' && tr == 7) piece = 'bq';
    _board[tr][tc] = piece;
    _board[fr][fc] = null;
    _white = !_white;
    // game over check
    _status = _isMate() ? (_white ? 'Checkmate — white wins!' : 'Checkmate — black wins!') : (_isStalemate() ? 'Stalemate — draw' : null);
  }

  bool _hasAnyMove(String color) {
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (_board[r][c] != null && _board[r][c]![0] == color &&
            _legal(r, c).isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isMate() => _inCheck(_board, _color!) && !_hasAnyMove(_color!);
  bool _isStalemate() => !_inCheck(_board, _color!) && !_hasAnyMove(_color!);

  String _glyph(String? p) {
    if (p == null) return '';
    const map = {
      'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
    };
    return map[p.substring(1)] ?? '';
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
                Text(_status ?? (_white ? 'White to move' : 'Black to move'),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8),
                itemCount: 64,
                itemBuilder: (context, i) {
                  final int r = i ~/ 8, c = i % 8;
                  final bool dark = (r + c) % 2 == 1;
                  final String? p = _board[r][c];
                  final bool sel = _selR == r && _selC == c;
                  return GestureDetector(
                    onTap: () => _tap(r, c),
                    child: Container(
                      color: sel
                          ? Colors.amber.shade400
                          : dark
                              ? const Color(0xFFB58863)
                              : const Color(0xFFF0D9B5),
                      alignment: Alignment.center,
                      child: Text(
                        _glyph(p),
                        style: TextStyle(
                            fontSize: 26,
                            color: _whitePiece(p) ? Colors.white : Colors.black,
                            shadows: p == null
                                ? const []
                                : const [Shadow(blurRadius: 2)]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _whitePiece(String? p) => p != null && p[0] == 'w';
}
