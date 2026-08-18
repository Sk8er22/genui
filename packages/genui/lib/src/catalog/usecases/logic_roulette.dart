// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Numbers on a European wheel that are colored red.
const Set<int> _kRouletteReds = {
  1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36,
};

/// The balance a player starts with.
const int _kStartingBalance = 1000;

/// The smallest and largest single bet allowed.
const int _kMinBet = 5;

/// The largest single bet allowed.
const int _kMaxBet = 100;

/// The step used by the bet amount stepper.
const int _kBetStep = 5;

/// The payoff multiplier for even-money bets (Red/Black/Odd/Even/Low/High).
const int _kEvenMoneyPayout = 2;

/// The payoff multiplier for a straight number bet.
const int _kStraightPayout = 36;

/// A European roulette table: play Red/Black, Odd/Even, Low/High, or a
/// straight number, and watch the wheel decide your balance.
final class LogicRoulette {
  static final catalogItem = CatalogItem(
    name: 'LogicRoulette',
    dataSchema: S.object(
      description: 'Casino roulette: bet on Red/Black, Odd/Even, Low/High, '
          'or a single number and spin the wheel.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicRouletteWidget(
        title: title is String ? title : 'Roulette',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicRoulette","title":"Roulette"}
]''',
    ],
  );
}

/// Roulette widget that lets a player place even-money or straight bets.
class LogicRouletteWidget extends StatefulWidget {
  const LogicRouletteWidget({super.key, this.title = 'Roulette'});
  final String title;
  @override
  State<LogicRouletteWidget> createState() => _LogicRouletteWidgetState();
}

/// The even-money betting pools offered on the table.
enum RouletteBet {
  /// Bet the ball lands on a red pocket.
  red('Red'),

  /// Bet the ball lands on a black pocket.
  black('Black'),

  /// Bet the ball lands on an odd number.
  odd('Odd'),

  /// Bet the ball lands on an even number.
  even('Even'),

  /// Bet the ball lands on a number from 1 to 18.
  low('1-18'),

  /// Bet the ball lands on a number from 19 to 36.
  high('19-36');

  const RouletteBet(this.label);
  final String label;
}

class _LogicRouletteWidgetState extends State<LogicRouletteWidget> {
  int _balance = _kStartingBalance;
  int _bet = _kMinBet;
  int? _number; // straight-number bet; null means no straight bet.
  int? _lastNumber;
  int _lastNet = 0;
  int _resetCount = 0;
  final Set<RouletteBet> _bets = <RouletteBet>{};
  final Random _random = Random();

  /// Returns the wheel color for [number]: green for 0, else red/black.
  Color _colorOf(int number) {
    if (number == 0) return Colors.green.shade600;
    return _kRouletteReds.contains(number) ? Colors.red.shade600
        : Colors.black87;
  }

  /// Labelled color name for [number], e.g. 'red' or 'green'.
  String _colorName(int number) {
    if (number == 0) return 'green';
    return _kRouletteReds.contains(number) ? 'red' : 'black';
  }

  int _activeStake() {
    final int count = _bets.length + (_number == null ? 0 : 1);
    return _bet * count;
  }

  void _spin() {
    final int stake = _activeStake();
    if (stake <= 0 || stake > _balance) return;
    final int result = _random.nextInt(37);
    int winnings = 0;
    for (final RouletteBet bet in _bets) {
      final bool won = switch (bet) {
        RouletteBet.red => _colorOf(result) == Colors.red.shade600,
        RouletteBet.black => _colorOf(result) == Colors.black87,
        RouletteBet.odd => result.isOdd,
        RouletteBet.even => result != 0 && result.isEven,
        RouletteBet.low => result >= 1 && result <= 18,
        RouletteBet.high => result >= 19 && result <= 36,
      };
      if (won) winnings += _bet * _kEvenMoneyPayout;
    }
    if (_number != null && _number == result) {
      winnings += _bet * _kStraightPayout;
    }
    setState(() {
      _balance = _balance - stake + winnings;
      _lastNumber = result;
      _lastNet = winnings - stake;
    });
  }

  void _reset() {
    setState(() {
      _balance = _kStartingBalance;
      _bet = _kMinBet;
      _number = null;
      _lastNumber = null;
      _lastNet = 0;
      _resetCount += 1;
      _bets.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int activeBets = _bets.length + (_number == null ? 0 : 1);
    final int stake = _bet * activeBets;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: theme.textTheme.titleMedium),
                Text(
                  'Balance: $_balance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _balance >= _kStartingBalance
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Bet'),
                IconButton(
                  onPressed: _bet > _kMinBet
                      ? () => setState(() => _bet -= _kBetStep)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Decrease bet',
                ),
                Text('$_bet', style: theme.textTheme.titleSmall),
                IconButton(
                  onPressed: _bet < _kMaxBet
                      ? () => setState(() => _bet += _kBetStep)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Increase bet',
                ),
                const Spacer(),
                Text('Total stake: $stake'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: RouletteBet.values.map((RouletteBet bet) {
                return FilterChip(
                  label: Text(bet.label),
                  selected: _bets.contains(bet),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _bets.add(bet);
                      } else {
                        _bets.remove(bet);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              key: ValueKey<int>(_resetCount),
              initialValue: _number,
              decoration: const InputDecoration(
                labelText: 'Straight number bet',
                isDense: true,
              ),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('No straight bet'),
                ),
                for (int n = 0; n <= 36; n++)
                  DropdownMenuItem<int?>(value: n, child: Text('$n')),
              ],
              onChanged: (int? value) => setState(() => _number = value),
            ),
            const SizedBox(height: 12),
            if (_lastNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _colorOf(_lastNumber!),
                          child: Text(
                            '$_lastNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_colorName(_lastNumber!)} '
                          '${_lastNet >= 0 ? '+' : ''}$_lastNet',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _reset, child: const Text('Reset')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: stake > 0 && stake <= _balance ? _spin : null,
                  child: const Text('Spin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
