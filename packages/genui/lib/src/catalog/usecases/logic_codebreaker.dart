// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Mastermind-style codebreaker: guess a hidden 4-peg code; feedback shows
/// exact matches (black) and misplaced (white).
final class LogicCodebreaker {
  static final catalogItem = CatalogItem(
    name: 'LogicCodebreaker',
    dataSchema: S.object(
      description: 'Guess the secret color code (Mastermind).',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicCodebreakerWidget(
          title: title is String ? title : 'Codebreaker');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicCodebreaker","title":"Codebreaker"}
]''',
    ],
  );
}

class LogicCodebreakerWidget extends StatefulWidget {
  const LogicCodebreakerWidget({super.key, this.title = 'Codebreaker'});
  final String title;
  @override
  State<LogicCodebreakerWidget> createState() => _LogicCodebreakerWidgetState();
}

class _LogicCodebreakerWidgetState extends State<LogicCodebreakerWidget> {
  static const int _slots = 4, _colors = 6, _tries = 10;
  final math.Random _rng = math.Random();
  late List<int> _secret;
  final List<List<int>> _guesses = [];
  final List<(int, int)> _feedback = []; // (exact, misplaced)
  List<int> _current = List.filled(_slots, -1);
  int _slot = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _secret = [for (var i = 0; i < _slots; i++) _rng.nextInt(_colors)];
  }

  static const List<Color> _color = [
    Colors.red, Colors.green, Colors.blue, Colors.amber,
    Colors.purple, Colors.orange,
  ];

  void _pick(int ci) {
    if (_won) return;
    setState(() {
      _current[_slot] = ci;
      if (_slot < _slots - 1) {
        _slot++;
      }
    });
  }

  void _submit() {
    if (_current.contains(-1) || _won) return;
    final List<int> copy = [..._secret];
    int exact = 0;
    for (var i = 0; i < _slots; i++) {
      if (_current[i] == _secret[i]) exact++;
    }
    final List<int> used = List.filled(_colors, 0);
    for (final c in _secret) {
      used[c]++;
    }
    int misplaced = 0;
    for (final c in _current) {
      if (used[c] > 0) {
        used[c]--;
        misplaced++;
      }
    }
    misplaced -= exact;
    if (exact == _slots) _won = true;
    setState(() {
      _guesses.add(List<int>.from(_current));
      _feedback.add((exact, misplaced));
      _current = List.filled(_slots, -1);
      _slot = 0;
    });
  }

  void _reset() {
    setState(() {
      _secret = [for (var i = 0; i < _slots; i++) _rng.nextInt(_colors)];
      _guesses.clear();
      _feedback.clear();
      _current = List.filled(_slots, -1);
      _slot = 0;
      _won = false;
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
            Row(
              children: [
                Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleMedium)),
                if (_won) Text('Solved! 🎉'),
              ],
            ),
            const SizedBox(height: 8),
            // history
            ..._guesses.asMap().entries.map((e) => Row(
                  children: [
                    Text('${e.key + 1}.'),
                    ...e.value.map((ci) => _peg(ci, diameter: 18)),
                    const Spacer(),
                    Text('${e.value.first == -1 ? "" : _feedback[e.key].$1}● '
                        '${_feedback[e.key].$2}○'),
                  ],
                )),
            const SizedBox(height: 8),
            // pegs picker
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < _colors; i++)
                  GestureDetector(onTap: () => _pick(i), child: _peg(i)),
              ],
            ),
            if (_guesses.length >= _tries && !_won)
              Text('Out of tries — code was ${_secret.join('')}',
                  style: Theme.of(context).textTheme.bodyMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                    onPressed: _reset, child: const Text('New code')),
                FilledButton(
                    onPressed: _submit, child: const Text('Submit guess')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _peg(int ci, {double diameter = 34}) {
    return Container(
      width: diameter,
      height: diameter,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color[ci],
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
