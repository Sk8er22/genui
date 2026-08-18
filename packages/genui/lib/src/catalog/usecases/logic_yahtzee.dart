// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Yahtzee: roll 5 dice up to 3 times per turn, then score into one of the
/// classic categories. Tap a die to keep (re-roll only the others). A
/// 5-of-a-kind scores the Yahtzee bonus.
final class LogicYahtzee {
  static final catalogItem = CatalogItem(
    name: 'LogicYahtzee',
    dataSchema: S.object(
      description: 'Roll 5 dice to score in Yahtzee categories.',
      properties: {
        'title': S.string(),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicYahtzeeWidget(
        title: title is String ? title : 'Yahtzee',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicYahtzee","title":"Yahtzee"}
]''',
    ],
  );
}

/// Scoring categories. Each has a key, a short label and a scoring rule.
enum _Category {
  ones('Ones'),
  twos('Twos'),
  threes('Threes'),
  fours('Fours'),
  fives('Fives'),
  sixes('Sixes'),
  threeOfKind('3 of a kind'),
  fourOfKind('4 of a kind'),
  fullHouse('Full House'),
  smallStraight('Sm. Straight'),
  largeStraight('Lg. Straight'),
  chance('Chance'),
  yahtzee('Yahtzee');

  const _Category(this.label);
  final String label;

  int score(List<int> d) {
    switch (this) {
      case ones:
        return d.where((x) => x == 1).length;
      case twos:
        return 2 * d.where((x) => x == 2).length;
      case threes:
        return 3 * d.where((x) => x == 3).length;
      case fours:
        return 4 * d.where((x) => x == 4).length;
      case fives:
        return 5 * d.where((x) => x == 5).length;
      case sixes:
        return 6 * d.where((x) => x == 6).length;
      case threeOfKind:
        return _counts(d).values.any((c) => c >= 3) ? d.sum : 0;
      case fourOfKind:
        return _counts(d).values.any((c) => c >= 4) ? d.sum : 0;
      case fullHouse:
        return _fullHouse(d);
      case smallStraight:
        return _runs(_distinctSorted(d)).any((r) => r >= 4) ? 30 : 0;
      case largeStraight:
        return _runs(_distinctSorted(d)).any((r) => r >= 5) ? 40 : 0;
      case chance:
        return d.sum;
      case yahtzee:
        return _counts(d).values.any((c) => c == 5) ? 50 : 0;
    }
  }
}

Map<int, int> _counts(List<int> dice) {
  final Map<int, int> m = {};
  for (final v in dice) {
    m[v] = (m[v] ?? 0) + 1;
  }
  return m;
}

int _fullHouse(List<int> d) {
  final List<int> counts = _counts(d).values.toList()..sort();
  // Exactly two distinct groups sized 2 and 3 (or all same for the joker
  // "full house from a Yahtzee" house rule).
  if ((counts.length == 2 && counts.contains(2) && counts.contains(3)) ||
      counts.length == 1) {
    return 25;
  }
  return 0;
}

List<int> _distinctSorted(List<int> dice) {
  final List<int> s = <int>{...dice}.toList();
  s.sort();
  return s;
}

/// Run-lengths of consecutive values (e.g. [1,2,3,3,4] -> [3,2]).
List<int> _runs(List<int> sortedDistinct) {
  final List<int> runs = [];
  var run = 1;
  for (var i = 1; i < sortedDistinct.length; i++) {
    if (sortedDistinct[i] == sortedDistinct[i - 1] + 1) {
      run++;
    } else {
      runs.add(run);
      run = 1;
    }
  }
  runs.add(run);
  return runs;
}

extension on List<int> {
  int get sum => fold(0, (a, b) => a + b);
}

class LogicYahtzeeWidget extends StatefulWidget {
  const LogicYahtzeeWidget({super.key, this.title = 'Yahtzee'});
  final String title;
  @override
  State<LogicYahtzeeWidget> createState() => _LogicYahtzeeWidgetState();
}

class _LogicYahtzeeWidgetState extends State<LogicYahtzeeWidget> {
  static const int _numDice = 5;
  static const int _maxRolls = 3;

  final math.Random _rng = math.Random();

  List<int> _dice = List.filled(_numDice, 1);
  // Which dice are kept (not re-rolled) — index -> bool.
  List<bool> _kept = List.filled(_numDice, false);
  int _rollsLeft = _maxRolls;
  int _turn = 1;
  bool _rolling = false;

  // category key -> null (unscored) or the points banked.
  final Map<_Category, int?> _scorecard = {
    for (final c in _Category.values) c: null,
  };
  int _yahtzeeBonusCount = 0;

  bool _finished() => _scorecard.values.every((v) => v != null);

  void _newTurn() {
    setState(() {
      _dice = List.filled(_numDice, 1);
      _kept = List.filled(_numDice, false);
      _rollsLeft = _maxRolls;
      _turn++;
    });
  }

  void _toggleKeep(int i) {
    if (_rolling) return;
    setState(() => _kept[i] = !_kept[i]);
  }

  Future<void> _roll() async {
    if (_rolling || _rollsLeft == 0) return;
    setState(() {
      _rolling = true;
      _rollsLeft--;
    });
    final next = List<int>.from(_dice);
    // Animate only the unkept dice.
    for (var step = 0; step < 7; step++) {
      for (var i = 0; i < _numDice; i++) {
        if (!_kept[i]) next[i] = 1 + _rng.nextInt(6);
      }
      setState(() => _dice = List<int>.from(next));
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
    setState(() {
      _dice = List<int>.from(next);
      _rolling = false;
    });
  }

  void _score(_Category c) {
    if (_rolling || _scorecard[c] != null) return;
    final int points = c.score(_dice);
    setState(() {
      _scorecard[c] = points;
      if (_counts(_dice).values.any((n) => n == 5)) {
        _yahtzeeBonusCount++; // Yahtzee scored, bank the bonus line.
      }
    });
    if (!_finished()) _newTurn();
  }

  int _upperTotal() {
    var t = 0;
    for (final _Category c in const [
      _Category.ones,
      _Category.twos,
      _Category.threes,
      _Category.fours,
      _Category.fives,
      _Category.sixes,
    ]) {
      t += _scorecard[c] ?? 0;
    }
    return t;
  }

  int _grandTotal() {
    final int upper = _upperTotal();
    final bonus = upper >= 63 ? 35 : 0;
    var lower = 0;
    for (final _Category c in _Category.values) {
      if (!c.label.contains('Yahtzee')) lower += _scorecard[c] ?? 0;
    }
    // The Yahtzee category points + any bonus lines from extra 5-of-a-kinds.
    final int yahtzeeCat = _scorecard[_Category.yahtzee] ?? 0;
    lower += yahtzeeCat + (45 * _yahtzeeBonusCount.clamp(0, 1));
    return upper + bonus + lower;
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Turn $_turn • rolls left $_rollsLeft',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            // Dice row (tap a die to keep / un-keep it).
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _numDice; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: InkWell(
                      onTap: () => _toggleKeep(i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kept[i]
                              ? Colors.green.shade200
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _kept[i]
                                ? Colors.green.shade700
                                : Colors.black38,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                                offset: Offset(1, 2),
                                blurRadius: 3,
                                color: Colors.black26),
                          ],
                        ),
                        child: Text('${_dice[i]}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('tap a die to keep it',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${_dice.sum}',
                    style: Theme.of(context).textTheme.titleMedium),
                FilledButton.icon(
                  onPressed: (_rolling || _rollsLeft == 0 || _finished())
                      ? null
                      : _roll,
                  icon: const Icon(Icons.casino),
                  label: const Text('Roll'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scorecard',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    ..._buildScoreRow(_Category.ones),
                    ..._buildScoreRow(_Category.twos),
                    ..._buildScoreRow(_Category.threes),
                    ..._buildScoreRow(_Category.fours),
                    ..._buildScoreRow(_Category.fives),
                    ..._buildScoreRow(_Category.sixes),
                    const Divider(height: 8, color: Colors.black12),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Upper subtotal'),
                          Text(_upperUpperText()),
                        ],
                      ),
                    ),
                    const Divider(height: 8, color: Colors.black12),
                    ..._buildScoreRow(_Category.threeOfKind),
                    ..._buildScoreRow(_Category.fourOfKind),
                    ..._buildScoreRow(_Category.fullHouse),
                    ..._buildScoreRow(_Category.smallStraight),
                    ..._buildScoreRow(_Category.largeStraight),
                    ..._buildScoreRow(_Category.chance),
                    ..._buildScoreRow(_Category.yahtzee),
                    if (_yahtzeeBonusCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Yahtzee bonus'),
                            Text('$_yahtzeeBonusCount × 45'),
                          ],
                        ),
                      ),
                    const Divider(height: 8, color: Colors.black12),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GRAND TOTAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text('${_grandTotal()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _dice = List.filled(_numDice, 1);
                  _kept = List.filled(_numDice, false);
                  _rollsLeft = _maxRolls;
                  _turn = 1;
                  for (final _Category k in _scorecard.keys) {
                    _scorecard[k] = null;
                  }
                  _yahtzeeBonusCount = 0;
                }),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _upperUpperText() {
    final int upper = _upperTotal();
    final bonus = upper >= 63 ? 35 : 0;
    return '$upper${bonus > 0 ? ' + $bonus bonus' : ''}';
  }

  List<Widget> _buildScoreRow(_Category c) {
    final int? points = _scorecard[c];
    final bool enabled = !_rolling && points == null;
    final int current =
        points ?? (enabled ? c.score(_dice) : 0);
    return [
      InkWell(
        onTap: enabled ? () => _score(c) : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sell_outlined, size: 15),
                  const SizedBox(width: 6),
                  Text(c.label),
                ],
              ),
              Text(
                points == null ? '$current' : '$current ✓',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: points == null
                      ? (enabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black54)
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
