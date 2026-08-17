// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Tic-tac-toe — two human players on the same device. Pure-Dart win logic.
final class LogicTicTacToe {
  static final _schema = S.object(
    description: 'Tic-tac-toe for two players.',
    properties: {
      'title': S.string(description: 'Match label.'),
    },
    required: ['title'],
  );

  static final catalogItem = CatalogItem(
    name: 'LogicTicTacToe',
    dataSchema: _schema,
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicTicTacToeWidget(
          title: title is String ? title : 'Tic-tac-toe');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTicTacToe","title":"Round 1"}
]''',
    ],
  );
}

class LogicTicTacToeWidget extends StatefulWidget {
  const LogicTicTacToeWidget({super.key, this.title = 'Tic-tac-toe'});
  final String title;
  @override
  State<LogicTicTacToeWidget> createState() => _LogicTicTacToeWidgetState();
}

class _LogicTicTacToeWidgetState extends State<LogicTicTacToeWidget> {
  List<String?> _board = List.filled(9, null);
  bool _xTurn = true;
  String? _winner;
  int _xWins = 0;
  int _oWins = 0;

  static const List<List<int>> _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  void _tap(int i) {
    if (_board[i] != null || _winner != null) return;
    setState(() {
      _board[i] = _xTurn ? 'X' : 'O';
      _xTurn = !_xTurn;
      _winner = _checkWinner();
      if (_winner == 'X') _xWins++;
      if (_winner == 'O') _oWins++;
      if (_winner == null && !_board.contains(null)) {
        _winner = 'draw';
      }
    });
  }

  String? _checkWinner() {
    for (final l in _lines) {
      final String? a = _board[l[0]], b = _board[l[1]], c = _board[l[2]];
      if (a != null && a == b && b == c) return a;
    }
    return null;
  }

  void _reset() {
    setState(() {
      _board = List.filled(9, null);
      _winner = null;
      _xTurn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String status = switch (_winner) {
      'X' => 'X wins!',
      'O' => 'O wins!',
      'draw' => "It's a draw",
      _ => "${_xTurn ? 'X' : 'O'} to move",
    };
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
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('X $_xWins  •  O $_oWins',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(status, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemBuilder: (context, i) {
                final String? v = _board[i];
                return Material(
                  color: v == null ? Colors.grey.shade200 : Colors.blueGrey.shade50,
                  child: InkWell(
                    onTap: () => _tap(i),
                    child: Center(
                      child: Text(
                        v ?? '',
                        style: TextStyle(
                          fontSize: 34,
                          color: v == 'X' ? Colors.blue.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(onPressed: _reset, child: const Text('Reset')),
            ),
          ],
        ),
      ),
    );
  }
}
