// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Video poker (Jacks or Better): deal 5 cards, hold some, draw once and get
/// paid according to the strength of the final hand. Pure-Dart/Flutter.
final class LogicPoker {
  static final catalogItem = CatalogItem(
    name: 'LogicPoker',
    dataSchema: S.object(
      description:
          'Video poker: deal, hold and draw for the best five-card hand.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicPokerWidget(title: title is String ? title : 'Poker');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPoker","title":"Poker"}
]''',
    ],
  );
}

/// A single French-deck playing card. Ranks map to values 2..14 (A = 14).
class LogicPokerCard {
  const LogicPokerCard(this.rank, this.suit);

  /// Rank as 'A', '2'..'10', 'J', 'Q' or 'K'.
  final String rank;

  /// Suit glyph: '♠', '♥', '♦' or '♣'.
  final String suit;

  /// Numeric value used for hand evaluation (11=J, 12=Q, 13=K, 14=A).
  int get value {
    switch (rank) {
      case 'J':
        return 11;
      case 'Q':
        return 12;
      case 'K':
        return 13;
      case 'A':
        return 14;
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

/// The possible final hand ranks, best first, with their payout multiplier
/// (applied to the bet) for the Jacks or Better pay table.
enum PokerHand {
  highCard('High Card', 0),
  jacksOrBetter('Jacks or Better', 1),
  twoPair('Two Pair', 2),
  threeOfAKind('Three of a Kind', 3),
  straight('Straight', 4),
  flush('Flush', 6),
  fullHouse('Full House', 9),
  fourOfAKind('Four of a Kind', 25),
  straightFlush('Straight Flush', 50),
  royalFlush('Royal Flush', 250),
  ;

  const PokerHand(this.label, this.payout);
  final String label;
  final int payout;
}

/// Evaluates the best poker hand for a 5-card draw.
PokerHand evaluatePokerHand(List<LogicPokerCard> cards) {
  assert(cards.length == 5, 'A poker hand must have exactly 5 cards.');
  final List<int> values = cards.map((c) => c.value).toList()..sort();
  final bool isFlush = cards.every((c) => c.suit == cards.first.suit);

  final Map<int, int> counts = <int, int>{};
  for (final int v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final List<int> groups = counts.values.toList()..sort();

  // Straight, including the low-Ace "wheel" (A,2,3,4,5).
  bool isStraight = false;
  final List<int> unique = values.toSet().toList()..sort();
  if (unique.length == 5) {
    isStraight = unique.last - unique.first == 4 ||
        (unique[0] == 2 &&
            unique[1] == 3 &&
            unique[2] == 4 &&
            unique[3] == 5 &&
            unique[4] == 14);
  }

  if (isStraight && isFlush) {
    // A Royal Flush is an Ace-high straight flush (10,J,Q,K,A).
    return (values.contains(14) && values.contains(10))
        ? PokerHand.royalFlush
        : PokerHand.straightFlush;
  }
  if (groups.last == 4) return PokerHand.fourOfAKind;
  if (groups.length == 2 && groups.contains(3)) return PokerHand.fullHouse;
  if (groups.last == 3) return PokerHand.threeOfAKind;
  if (groups.where((int g) => g == 2).length == 2) return PokerHand.twoPair;
  if (groups.last == 2) {
    final int pairValue =
        counts.entries.firstWhere((e) => e.value == 2).key;
    return pairValue >= 11 ? PokerHand.jacksOrBetter : PokerHand.highCard;
  }
  if (isStraight) return PokerHand.straight;
  if (isFlush) return PokerHand.flush;
  return PokerHand.highCard;
}

class LogicPokerWidget extends StatefulWidget {
  const LogicPokerWidget({super.key, this.title = 'Poker'});
  final String title;
  @override
  State<LogicPokerWidget> createState() => _LogicPokerWidgetState();
}

enum _PokerPhase { start, hold, done }

class _LogicPokerWidgetState extends State<LogicPokerWidget> {
  final math.Random _rng = math.Random();
  late List<LogicPokerCard> _deck;
  final List<LogicPokerCard> _hand = [];
  final Set<int> _held = {};
  _PokerPhase _phase = _PokerPhase.start;
  int _credits = 100;
  int _bet = 5;
  PokerHand? _lastRank;
  int _lastPayout = 0;

  List<LogicPokerCard> _freshDeck() {
    const List<String> suits = ['♠', '♥', '♦', '♣'];
    const List<String> ranks = [
      'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K',
    ];
    return [
      for (final String s in suits)
        for (final String r in ranks) LogicPokerCard(r, s),
    ];
  }

  bool get _canBet => _credits >= _bet;

  void _betBy(int delta) {
    final _PokerPhase p = _phase;
    if (p == _PokerPhase.hold) return;
    setState(() {
      final int maxBet = math.max(1, math.min(5, _credits));
      _bet = (_bet + delta).clamp(1, maxBet).toInt();
    });
  }

  void _deal() {
    if (!_canBet) return;
    setState(() {
      _credits -= _bet;
      _deck = _freshDeck()..shuffle(_rng);
      _hand
        ..clear()
        ..addAll(List<LogicPokerCard>.generate(5, (_) => _deck.removeLast()));
      _held.clear();
      _phase = _PokerPhase.hold;
      _lastRank = null;
      _lastPayout = 0;
    });
  }

  void _draw() {
    if (_phase != _PokerPhase.hold) return;
    setState(() {
      for (int i = 0; i < _hand.length; i++) {
        if (!_held.contains(i)) _hand[i] = _deck.removeLast();
      }
      _lastRank = evaluatePokerHand(_hand);
      _lastPayout = _lastRank!.payout * _bet;
      if (_lastPayout > 0) _credits += _lastPayout;
      if (_credits < 1) _credits = 0;
      _phase = _PokerPhase.done;
    });
  }

  void _toggleHold(int index) {
    if (_phase != _PokerPhase.hold) return;
    setState(() {
      if (!_held.add(index)) _held.remove(index);
    });
  }

  void _resetBank() {
    setState(() {
      _credits = 100;
      _bet = 5;
      _phase = _PokerPhase.start;
      _hand.clear();
      _held.clear();
      _lastRank = null;
      _lastPayout = 0;
    });
  }

  String get _status {
    switch (_phase) {
      case _PokerPhase.start:
        return _canBet ? 'Deal a new hand (costs $_bet).' : 'Out of credits!';
      case _PokerPhase.hold:
        return 'Tap cards to hold, then draw.';
      case _PokerPhase.done:
        return _lastPayout > 0
            ? '${_lastRank!.label} — won $_lastPayout!'
            : '${_lastRank!.label} — no win.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
                Text('Credits: $_credits', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(_status, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                for (int i = 0; i < 5; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _PokerCardView(
                        card: _hand.isEmpty ? null : _hand[i],
                        held: _held.contains(i),
                        interactive: _phase == _PokerPhase.hold,
                        onTap: () => _toggleHold(i),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      _phase == _PokerPhase.hold ? null : () => _betBy(-1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('Bet: $_bet',
                    style: theme.textTheme.titleMedium),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      _phase == _PokerPhase.hold ? null : () => _betBy(1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _phase == _PokerPhase.hold
                      ? _draw
                      : (_canBet ? _deal : null),
                  child: Text(_phase == _PokerPhase.hold ? 'Draw' : 'Deal'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reset to 100 credits',
                  onPressed: _resetBank,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PokerCardView extends StatelessWidget {
  const _PokerCardView({
    required this.card,
    required this.held,
    required this.interactive,
    required this.onTap,
  });

  final LogicPokerCard? card;
  final bool held;
  final bool interactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color holdColor = theme.colorScheme.primary;
    final Widget inner;
    if (card == null) {
      inner = const Placeholder(color: Colors.grey);
    } else {
      inner = Text(
        card!.label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: card!.color,
        ),
      );
    }
    return GestureDetector(
      onTap: interactive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: held ? holdColor : Colors.grey.shade400,
            width: held ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            inner,
            if (held)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'HOLD',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: holdColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
