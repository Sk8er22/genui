// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Blackjack (twenty-one) played against a simple dealer.
final class LogicBlackjack {
  static final catalogItem = CatalogItem(
    name: 'LogicBlackjack',
    dataSchema: S.object(
      description: 'Blackjack vs a dealer: hit, stand, chips.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicBlackjackWidget(
        title: title is String ? title : 'Blackjack',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicBlackjack","title":"Blackjack"}
]''',
    ],
  );
}

/// A single playing card. Aces are worth 11 and can be downgraded to 1.
class LogicBlackjackCard {
  const LogicBlackjackCard(this.rank, this.suit);

  /// Rank as 'A', '2'..'10', 'J', 'Q' or 'K'.
  final String rank;

  /// Suit glyph: '♠', '♥', '♦' or '♣'.
  final String suit;

  bool get isAce => rank == 'A';

  int get value {
    switch (rank) {
      case 'J' || 'Q' || 'K':
        return 10;
      case 'A':
        return 11;
      default:
        return int.parse(rank);
    }
  }

  String get label => '$rank$suit';

  Color get color =>
      (suit == '♥' || suit == '♦') ? Colors.red : Colors.black87;

  @override
  String toString() => label;
}

/// Computes the best (highest <= 21) blackjack hand value.
int handValue(List<LogicBlackjackCard> cards) {
  int total = 0;
  int aces = 0;
  for (final c in cards) {
    if (c.isAce) {
      aces++;
      total += 11;
    } else {
      total += c.value;
    }
  }
  while (total > 21 && aces > 0) {
    total -= 10;
    aces--;
  }
  return total;
}

class LogicBlackjackWidget extends StatefulWidget {
  const LogicBlackjackWidget({super.key, this.title = 'Blackjack'});
  final String title;
  @override
  State<LogicBlackjackWidget> createState() => _LogicBlackjackWidgetState();
}

class _LogicBlackjackWidgetState extends State<LogicBlackjackWidget> {
  final math.Random _rng = math.Random();
  late List<LogicBlackjackCard> _deck;
  List<LogicBlackjackCard> _player = [];
  List<LogicBlackjackCard> _dealer = [];
  bool _gameOver = false;
  int _chips = 100;
  int _bet = 10;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _deck = _buildDeck()..shuffle(_rng);
    _player = [_draw(), _draw()];
    _dealer = [_draw(), _draw()];
    _gameOver = false;
  }

  List<LogicBlackjackCard> _buildDeck() {
    const suits = ['♠', '♥', '♦', '♣'];
    const ranks = [
      'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K',
    ];
    return [
      for (final s in suits)
        for (final r in ranks) LogicBlackjackCard(r, s),
    ];
  }

  LogicBlackjackCard _draw() => _deck.removeLast();

  String? get _result {
    if (!_gameOver) return null;
    final p = handValue(_player);
    final d = handValue(_dealer);
    if (p > 21) return 'Bust — dealer wins';
    if (d > 21) return 'Dealer bust — you win!';
    if (p > d) return 'You win!';
    if (d > p) return 'Dealer wins';
    return 'Push (tie)';
  }

  void _adjustBet(int delta) {
    if (_gameOver) return;
    setState(() {
      _bet = (_bet + delta).clamp(5, math.min(_chips, 100)).toInt();
    });
  }

  void _hit() {
    if (_gameOver) return;
    setState(() {
      _player.add(_draw());
      if (handValue(_player) > 21) _settle();
    });
  }

  void _stand() {
    if (_gameOver) return;
    setState(() {
      // dealer draws to 17
      while (handValue(_dealer) < 17) {
        _dealer.add(_draw());
      }
      _settle();
    });
  }

  void _settle() {
    _gameOver = true;
    if (_result!.startsWith('You win')) {
      _chips += _bet;
    } else if (_result!.startsWith('Bust') ||
        _result!.startsWith('Dealer wins')) {
      _chips -= _bet;
    }
    if (_chips < 5) _chips = 5;
  }

  void _newRoundOrGame() {
    setState(_newGame);
  }

  @override
  Widget build(BuildContext context) {
    final pValue = handValue(_player);
    final dValue = handValue(_dealer);
    final theme = Theme.of(context);
    final revealDealer = _gameOver;

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
                Text('Chips: $_chips', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            _Hand(
              label: 'Dealer',
              cards: revealDealer
                  ? _dealer
                  : (_dealer.isEmpty ? [] : [_dealer.first]),
              value: revealDealer ? dValue : handValue([_dealer.first]),
            ),
            const SizedBox(height: 8),
            _Hand(label: 'You', cards: _player, value: pValue),
            const SizedBox(height: 12),
            if (_gameOver)
              Center(
                child: Text(_result!, style: theme.textTheme.titleMedium),
              )
            else ...[
              const Center(child: Text('Hit or stand to play')),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: _gameOver || pValue >= 21 ? null : _hit,
                  child: const Text('Hit'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _gameOver ? null : _stand,
                  child: const Text('Stand'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _newRoundOrGame,
                  child: Text(_gameOver ? 'New round' : 'Restart'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bet:', style: theme.textTheme.bodyMedium),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _gameOver ? null : () => _adjustBet(-10),
                ),
                SizedBox(
                  width: 48,
                  child: Text('$_bet', textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _gameOver ? null : () => _adjustBet(10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Hand extends StatelessWidget {
  const _Hand({
    required this.label,
    required this.cards,
    required this.value,
  });
  final String label;
  final List<LogicBlackjackCard> cards;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$label ', style: theme.textTheme.bodyLarge),
            Text('($value)', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (cards.isEmpty)
              const SizedBox(
                width: 44,
                height: 60,
                child: Placeholder(color: Colors.grey),
              )
            else
              for (final c in cards)
                Container(
                  width: 44,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(c.label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.color)),
                ),
          ],
        ),
      ],
    );
  }
}
