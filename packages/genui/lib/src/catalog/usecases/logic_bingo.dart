// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A classic BINGO game: a 5×5 card plus an automatic caller.
///
/// The model can pass a [LogicBingo.title]. Press **Call** to draw a random
/// number (1-75); numbers on your card are marked automatically and you can
/// also tap cells to mark them yourself. The widget detects a win on any
/// row, column or corner-to-corner diagonal and announces BINGO.
final class LogicBingo {
  static final catalogItem = CatalogItem(
    name: 'LogicBingo',
    dataSchema: S.object(
      description: 'Classic BINGO game with an automatic caller.',
      properties: {
        'title': S.string(),
        'freeCenter': S.boolean(
            description: 'Mark the center square as a free space (default true).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? freeCenter = (ctx.data as Map)['freeCenter'];
      return LogicBingoWidget(
        title: title is String ? title : 'BINGO',
        freeCenter: freeCenter is bool ? freeCenter : true,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicBingo","title":"BINGO"}
]''',
    ],
  );
}

class LogicBingoWidget extends StatefulWidget {
  const LogicBingoWidget({super.key, this.title = 'BINGO', this.freeCenter = true});
  final String title;
  final bool freeCenter;
  @override
  State<LogicBingoWidget> createState() => _LogicBingoWidgetState();
}

class _LogicBingoWidgetState extends State<LogicBingoWidget> {
  static const int _n = 5;
  static const int _center = 12; // row 2, col 2
  static const List<String> _letters = ['B', 'I', 'N', 'G', 'O'];

  final math.Random _rng = math.Random();
  late List<int> _board; // 25 unique numbers, per-column ranges
  late List<bool> _marked; // 25 marks
  final Set<int> _called = {};
  int? _lastCalled;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _board = _freshBoard();
    _marked = List.filled(25, false);
  }

  List<int> _freshBoard() {
    final List<int> board = List.filled(_n * _n, 0);
    for (var col = 0; col < _n; col++) {
      final int lo = col * 15 + 1;
      final Set<int> used = {};
      for (var row = 0; row < _n; row++) {
        int v;
        do {
          v = lo + _rng.nextInt(15);
        } while (!used.add(v));
        board[row * _n + col] = v;
      }
    }
    return board;
  }

  bool get _centerMarked => widget.freeCenter;

  bool _isMarked(int i) => _centerMarked && i == _center ? true : _marked[i];

  void _newCard() {
    setState(() {
      _board = _freshBoard();
      _marked = List.filled(25, false);
      _called.clear();
      _lastCalled = null;
      _won = false;
    });
  }

  void _call() {
    if (_won) return;
    if (_called.length >= 75) return;
    int v;
    do {
      v = 1 + _rng.nextInt(75);
    } while (_called.contains(v));
    final int idx = _board.indexOf(v);
    setState(() {
      _called.add(v);
      _lastCalled = v;
      if (idx >= 0) {
        _marked[idx] = true;
      }
      _won = _checkWin();
    });
  }

  void _toggle(int i) {
    if (_won) return;
    if (_centerMarked && i == _center) return;
    setState(() {
      _marked[i] = !_marked[i];
      _won = _checkWin();
    });
  }

  bool _checkWin() {
    for (var i = 0; i < _n * _n; i += _n) {
      if (List.generate(_n, (c) => _isMarked(i + c)).every((m) => m)) return true;
    }
    for (var c = 0; c < _n; c++) {
      if (List.generate(_n, (r) => _isMarked(r * _n + c)).every((m) => m)) {
        return true;
      }
    }
    if (List.generate(_n, (i) => _isMarked(i * _n + i)).every((m) => m)) return true;
    if (List.generate(_n, (i) => _isMarked(i * _n + (_n - 1 - i))).every((m) => m)) {
      return true;
    }
    return false;
  }

  String _shout(String word) => '${word.toUpperCase()}!';

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.title}  (${_called.length} called)',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _calledBanner(scheme),
            const SizedBox(height: 8),
            _buildBoard(scheme),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _newCard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New card'),
                ),
                FilledButton.icon(
                  onPressed: _won || _called.length >= 75 ? null : _call,
                  icon: const Icon(Icons.style),
                  label: const Text('Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calledBanner(ColorScheme scheme) {
    if (_won) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _shout('Bingo'),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: scheme.onPrimaryContainer),
        ),
      );
    }
    final int? last = _lastCalled;
    final String label =
        last == null ? 'Press Call to draw a number' : 'Last call: $last';
    return Text(label, textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge);
  }

  Widget _buildBoard(ColorScheme scheme) {
    final List<Widget> rows = [];
    // Column letter labels.
    rows.add(Row(
      children: [
        for (var c = 0; c < _n; c++)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              alignment: Alignment.center,
              color: scheme.primary,
              child: Text(
                _letters[c],
                style: TextStyle(
                    color: scheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    ));
    for (var r = 0; r < _n; r++) {
      rows.add(Row(
        children: [
          for (var c = 0; c < _n; c++)
            Expanded(child: _cell(r * _n + c, scheme)),
        ],
      ));
    }
    return Column(children: rows);
  }

  Widget _cell(int i, ColorScheme scheme) {
    final bool free = _centerMarked && i == _center;
    final bool marked = _isMarked(i);
    final bool inCalled = _called.contains(_board[i]);
    final Color bg;
    if (free) {
      bg = Colors.lightBlue.shade100;
    } else if (marked) {
      bg = _won ? Colors.orangeAccent : Colors.greenAccent;
    } else if (inCalled) {
      bg = scheme.surfaceContainerHighest;
    } else {
      bg = Colors.white;
    }
    final String text = free ? '★' : '${_board[i]}';
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        onTap: () => _toggle(i),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: marked ? Colors.green : Colors.black26),
          ),
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
