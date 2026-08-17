// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Tarot reader — a pure-Dart deck. Model sets the spread size (1 = single
/// card, 3 = past/present/future); tapping draws a card face-up with a
/// deterministic meaning. "Shuffle" re-draws.
final class LogicTarot {
  static final _schema = S.object(
    description: 'Tarot reading: draw 1 or 3 cards with meanings.',
    properties: {
      'title': S.string(description: 'Reading label, e.g. "Daily card".'),
      'spread': S.integer(description: '1 or 3 (past/present/future).'),
    },
    required: ['title'],
  );

  static final List<TarotCard> _deck = _buildDeck();

  static final catalogItem = CatalogItem(
    name: 'LogicTarot',
    dataSchema: _schema,
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? spread = (ctx.data as Map)['spread'];
      final int n = spread is int && (spread == 1 || spread == 3) ? spread : 1;
      return LogicTarotWidget(
        title: title is String ? title : 'Tarot',
        spread: n,
        deck: _deck,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTarot","title":"Daily card","spread":1}
]''',
    ],
  );

  static List<TarotCard> _buildDeck() {
    const List<String> majors = [
      'The Fool', 'The Magician', 'The High Priestess', 'The Empress',
      'The Emperor', 'The Hierophant', 'The Lovers', 'The Chariot',
      'Strength', 'The Hermit', 'Wheel of Fortune', 'Justice',
      'The Hanged Man', 'Death', 'Temperance', 'The Devil', 'The Tower',
      'The Star', 'The Moon', 'The Sun', 'Judgement', 'The World',
    ];
    const List<String> meanings = [
      'New beginnings, leaps of faith', 'Manifestation, action', 'Intuition, secrets',
      'Abundance, nurture', 'Authority, structure', 'Tradition, guidance',
      'Union, choices', 'Determination, progress', 'Courage, inner strength',
      'Solitude, introspection', 'Change, cycles', 'Fairness, accountability',
      'Surrender, pause', 'Endings, transformation', 'Balance, moderation',
      'Shadow, temptation', 'Sudden upheaval, awakening', 'Hope, inspiration',
      'Illusion, reflection', 'Success, joy', 'Rebirth, reckoning',
      'Completion, fulfillment',
    ];
    return List.generate(majors.length,
        (i) => TarotCard(majors[i], meanings[i], reversalMeaning(meanings[i]), i));
  }

  static String reversalMeaning(String m) => '$m — reversed: go inward';
}

class TarotCard {
  const TarotCard(this.name, this.meaning, this.reversed, this.index);
  final String name;
  final String meaning;
  final String reversed;
  final int index;
}

class LogicTarotWidget extends StatefulWidget {
  const LogicTarotWidget({
    super.key,
    required this.title,
    required this.spread,
    required this.deck,
  });
  final String title;
  final int spread;
  final List<TarotCard> deck;
  @override
  State<LogicTarotWidget> createState() => _LogicTarotWidgetState();
}

class _LogicTarotWidgetState extends State<LogicTarotWidget> {
  final math.Random _rng = math.Random();
  List<TarotCard> _drawn = [];
  bool _revealed = false;

  void _draw() {
    final List<TarotCard> deck = [...widget.deck]..shuffle(_rng);
    setState(() {
      _drawn = deck.take(widget.spread).toList();
      _revealed = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _draw();
  }

  static const List<String> _position = ['Past', 'Present', 'Future'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!_revealed)
              const Text('Tap any card to reveal.')
            else
              ..._drawn.asMap().entries.map((e) {
                final TarotCard c = e.value;
                final String pos = widget.spread == 3 ? _position[e.key] : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.style, size: 28),
                    title: Text('${pos.trim().isEmpty ? '' : '$pos — '}${c.name}'),
                    subtitle: Text(c.meaning),
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _draw,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle'),
                ),
                FilledButton(
                  onPressed: () => setState(() => _revealed = true),
                  child: const Text('Reveal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
