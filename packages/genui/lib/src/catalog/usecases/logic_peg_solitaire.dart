// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Peg Solitaire: the classic single-player puzzle on the 33-hole English
/// board. Jump a peg orthogonally over an adjacent peg into an empty hole,
/// removing the jumped peg. The goal is to finish with exactly one peg.
final class LogicPegSolitaire {
  static final catalogItem = CatalogItem(
    name: 'LogicPegSolitaire',
    dataSchema: S.object(
      description: 'Classic English 33-hole peg solitaire puzzle.',
      properties: {
        'title': S.string(),
      },
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicPegSolitaireWidget(
        title: title is String ? title : 'Peg Solitaire',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPegSolitaire","title":"Peg Solitaire"}
]''',
    ],
  );
}

/// A row/column pair on the 7x7 board.
typedef _Pos = (int, int);

class LogicPegSolitaireWidget extends StatefulWidget {
  const LogicPegSolitaireWidget({super.key, this.title = 'Peg Solitaire'});
  final String title;
  @override
  State<LogicPegSolitaireWidget> createState() =>
      _LogicPegSolitaireWidgetState();
}

class _LogicPegSolitaireWidgetState extends State<LogicPegSolitaireWidget> {
  static const int _size = 7;

  /// Board cells: `null` = outside the board, `true` = peg, `false` = hole.
  late List<List<bool?>> _board;
  int _pegs = 0;
  int _moves = 0;
  _Pos? _selected;
  final List<(_Pos from, _Pos over, _Pos to)> _history = [];
  bool _solved = false;

  /// True for the 33 holes of the standard English board.
  static bool _isHole(int r, int c) {
    if (r < 0 || r >= _size || c < 0 || c >= _size) return false;
    final bool cornerRow = r == 0 || r == _size - 1;
    final bool cornerCol = c == 0 || c == _size - 1;
    if (cornerRow && (c < 2 || c > _size - 3)) return false;
    if (cornerCol && (r < 2 || r > _size - 3)) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _board = List.generate(_size, (r) {
      return List<bool?>.generate(_size, (c) {
        if (!_isHole(r, c)) return null;
        // Start with a single empty hole in the centre and a peg elsewhere.
        return !(r == 3 && c == 3);
      });
    });
    _pegs = 32;
    _moves = 0;
    _selected = null;
    _history.clear();
    _solved = false;
  }

  void _restart() {
    setState(_newGame);
  }

  void _onTap(int r, int c) {
    final bool? cell = _board[r][c];
    if (cell == null) return;

    final _Pos? sel = _selected;
    if (cell == true) {
      // Tap a peg: select it (or deselect it if already selected).
      setState(() => _selected = _selected == (r, c) ? null : (r, c));
      return;
    }

    // Tap an empty hole: try to jump there from the selected peg.
    if (sel == null) return;
    final (int sr, int sc) = sel;
    final int dr = (r - sr).abs();
    final int dc = (c - sc).abs();
    // A jump is orthogonally two cells away with a peg in between.
    if (!((dr == 2 && dc == 0) || (dr == 0 && dc == 2))) return;

    final _Pos over = ((sr + r) ~/ 2, (sc + c) ~/ 2);
    if (_board[over.$1][over.$2] != true) return;

    setState(() {
      _board[sr][sc] = false; // origin is now an empty hole
      _board[over.$1][over.$2] = false; // the jumped peg is removed
      _board[r][c] = true; // landing hole is filled
      _pegs--;
      _moves++;
      _history.add((sel, over, (r, c)));
      _selected = null;
      _solved = _pegs == 1;
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      final (from, over, to) = _history.removeLast();
      _board[from.$1][from.$2] = true;
      _board[over.$1][over.$2] = true;
      _board[to.$1][to.$2] = false;
      _pegs++;
      _moves--;
      _selected = null;
      _solved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
                      style: theme.textTheme.titleMedium),
                ),
                Text('moves: $_moves · pegs: $_pegs',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            if (_solved)
              const Text(
                'Solved — one peg left! 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              )
            else
              Text(
                'Jump a peg over a neighbour to remove it. '
                'Leave just one peg.',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _size,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4),
                itemCount: _size * _size,
                itemBuilder: (context, i) {
                  final int r = i ~/ _size, c = i % _size;
                  final bool? cell = _board[r][c];
                  if (cell == null) return const SizedBox.shrink();
                  final bool isSelected = _selected == (r, c);
                  return Material(
                    color: cell
                        ? (isSelected
                            ? Colors.blue.shade400
                            : Colors.orange.shade700)
                        : Colors.grey.shade200,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _onTap(r, c),
                      child: Center(
                        child: Icon(
                          cell ? Icons.circle : Icons.circle_outlined,
                          size: 22,
                          color: cell
                              ? Colors.white
                              : Colors.brown.shade400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _history.isEmpty ? null : _undo,
                  child: const Text('Undo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                    onPressed: _restart, child: const Text('New game')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
