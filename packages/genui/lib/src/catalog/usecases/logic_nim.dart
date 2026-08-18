// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// NIM: take 1–3 stones from the pile; the player who takes the LAST stone
/// wins. The AI plays optimally (leaving a multiple of 4), so it is
/// unbeatable from a winning position.
final class LogicNim {
  static final catalogItem = CatalogItem(
    name: 'LogicNim',
    dataSchema: S.object(
      description: 'Classic Nim game: remove 1–3 stones, last stone wins.',
      properties: {
        'title': S.string(),
        'stones': S.integer(description: 'Starting stones (e.g. 15).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? stones = (ctx.data as Map)['stones'];
      return LogicNimWidget(
        title: title is String ? title : 'Nim',
        stones: stones is int && stones > 0 ? stones : 15,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicNim","title":"Nim","stones":15}
]''',
    ],
  );
}

class LogicNimWidget extends StatefulWidget {
  const LogicNimWidget({
    super.key,
    this.title = 'Nim',
    this.stones = 15,
  });

  final String title;
  final int stones;

  @override
  State<LogicNimWidget> createState() => _LogicNimWidgetState();
}

class _LogicNimWidgetState extends State<LogicNimWidget> {
  final math.Random _rng = math.Random();
  Timer? _timer;
  late int _stones;
  bool _playerTurn = true;
  String? _winner;
  String _lastMove = 'Your turn — take 1 to 3 stones.';

  @override
  void initState() {
    super.initState();
    _stones = widget.stones;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Optimal move in single-heap Nim (last stone wins, take 1–3):
  /// leave a multiple of 4. From a losing position, take 1 (best delay).
  int _aiMove(int stones) {
    final int leave = stones % 4;
    if (leave != 0) return leave;
    return math.min(1 + _rng.nextInt(3), stones); // losing position: stall
  }

  void _playerMove(int take) {
    if (_winner != null || !_playerTurn) return;
    _applyMove(take, isPlayer: true);
  }

  void _applyMove(int take, {required bool isPlayer}) {
    setState(() {
      _stones -= take;
      _lastMove = isPlayer
          ? 'You took $take.'
          : 'NIM took $take.';
      if (_stones == 0) {
        _winner = isPlayer ? 'You win!' : 'NIM wins';
      } else {
        _playerTurn = !isPlayer;
      }
    });
    if (_winner == null && !_playerTurn) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted || _winner != null) return;
        _applyMove(_aiMove(_stones), isPlayer: false);
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _stones = widget.stones;
      _playerTurn = true;
      _winner = null;
      _lastMove = 'Your turn — take 1 to 3 stones.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = _winner != null || !_playerTurn;
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
                TextButton(onPressed: _reset, child: const Text('Restart')),
              ],
            ),
            const SizedBox(height: 4),
            Text(_lastMove, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _stones == 0
                  ? Center(
                      child: Text('Pile empty',
                          style: Theme.of(context).textTheme.bodyMedium),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < _stones; i++)
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _stones <= 4
                                  ? Colors.red.shade400
                                  : Colors.blueGrey.shade300,
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _winner ?? 'Stones left: $_stones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _winner == null
                          ? null
                          : (_winner == 'You win!'
                              ? Colors.green.shade700
                              : Colors.red.shade700),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final int n in [1, 2, 3])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FilledButton.tonal(
                      onPressed: disabled ? null : () => _playerMove(n),
                      child: Text('Take $n'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
