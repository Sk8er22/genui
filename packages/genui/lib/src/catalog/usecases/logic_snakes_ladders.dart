// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Snakes & Ladders: a single player rolls a die and moves along a 5x6 board
/// with snakes and ladders, until they reach the last square.
final class LogicSnakesLadders {
  static final catalogItem = CatalogItem(
    name: 'LogicSnakesLadders',
    dataSchema: S.object(
      description: 'Snakes & ladders single-player board game.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicSnakesLaddersWidget(
          title: title is String ? title : 'Snakes & Ladders');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSnakesLadders","title":"Snakes"}
]''',
    ],
  );
}

class _Snakes {
  // pos -> next pos (ladders up, snakes down)
  static const Map<int, int> map = {
    3: 22, 8: 12, 14: 34, 21: 9, 27: 16, 35: 5, 39: 15, 46: 4, 50: 40,
  };
}

class LogicSnakesLaddersWidget extends StatefulWidget {
  const LogicSnakesLaddersWidget({super.key, this.title = 'Snakes & Ladders'});
  final String title;
  @override
  State<LogicSnakesLaddersWidget> createState() =>
      _LogicSnakesLaddersWidgetState();
}

class _LogicSnakesLaddersWidgetState extends State<LogicSnakesLaddersWidget> {
  static const int _max = 50;
  final math.Random _rng = math.Random();
  int _pos = 1;
  int _die = 0;
  String? _msg;
  bool _rollable = true;

  void _roll() {
    if (!_rollable) return;
    setState(() {
      _die = 1 + _rng.nextInt(6);
      _pos += _die;
      if (_pos > _max) _pos = _max - (_pos - _max); // overshoot bounce
      final int? jump = _Snakes.map[_pos];
      if (jump == null) {
        if (_pos == _max) {
          _msg = 'You reached $_max! 🎉';
          _rollable = false;
        } else {
          _msg = 'Rolled $_die → square $_pos';
        }
      } else if (jump > _pos) {
        _msg = 'Ladder! $_pos → $jump';
        _pos = jump;
        if (_pos == _max) {
          _msg = 'You reached $_max! 🎉';
          _rollable = false;
        }
      } else {
        _msg = 'Snake! $_pos → $jump 🐍';
        _pos = jump;
      }
    });
  }

  void _restart() {
    setState(() {
      _pos = 1;
      _die = 0;
      _msg = null;
      _rollable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_msg ?? 'Press Roll to start',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 10),
                itemCount: 100,
                itemBuilder: (context, i) {
                  final int pos = i + 1;
                  final bool isPlayer = pos == _pos;
                  final bool hasSnake = _Snakes.map.containsKey(pos);
                  return Container(
                    decoration: BoxDecoration(
                      color: isPlayer
                          ? Colors.amber.shade300
                          : (i % 2 == 0
                              ? Colors.blueGrey.shade50
                              : Colors.blueGrey.shade100),
                      border: Border.all(color: Colors.black12),
                    ),
                    alignment: Alignment.center,
                    child: isPlayer
                        ? const Icon(Icons.person, size: 16, color: Colors.indigo)
                        : hasSnake
                            ? const Icon(Icons.warning, size: 12, color: Colors.red)
                            : Text('$pos',
                                style: const TextStyle(fontSize: 8)),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Square $_pos', style: Theme.of(context).textTheme.bodyMedium),
                FilledButton.icon(
                  onPressed: _rollable ? _roll : null,
                  icon: const Icon(Icons.casino),
                  label: Text('Roll ${_die == 0 ? '' : _die}'),
                ),
              ],
            ),
            if (!_rollable)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                    onPressed: _restart, child: const Text('Play again')),
              ),
          ],
        ),
      ),
    );
  }
}
