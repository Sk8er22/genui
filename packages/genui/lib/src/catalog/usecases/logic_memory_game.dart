// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Memory match game: a grid of face-down cards; flip pairs to find matches.
/// The model can pass the number of pairs (must be a perfect square grid).
final class LogicMemoryGame {
  static final catalogItem = CatalogItem(
    name: 'LogicMemoryGame',
    dataSchema: S.object(
      description: 'Classic memory match game.',
      properties: {
        'title': S.string(),
        'pairs': S.integer(description: 'Number of matching pairs (e.g. 8).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? pairs = (ctx.data as Map)['pairs'];
      return LogicMemoryGameWidget(
        title: title is String ? title : 'Memory',
        pairs: pairs is int && pairs >= 4 ? pairs : 8,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicMemoryGame","title":"Memory","pairs":8}
]''',
    ],
  );
}

class _MemoryCard {
  _MemoryCard(this.emoji, this.id);
  final String emoji;
  final int id;
  bool faceUp = false;
  bool matched = false;
}

class LogicMemoryGameWidget extends StatefulWidget {
  const LogicMemoryGameWidget(
      {super.key, this.title = 'Memory', this.pairs = 8});
  final String title;
  final int pairs;
  @override
  State<LogicMemoryGameWidget> createState() => _LogicMemoryGameWidgetState();
}

class _LogicMemoryGameWidgetState extends State<LogicMemoryGameWidget> {
  static const List<String> _emojis = ['🐶', '🐱', '🦊', '🐻', '🐼', '🐸', '🦁', '🐵', '🦄', '🐙', '🦋', '🦉'];
  late final List<_MemoryCard> _cards;
  int? _first;
  bool _busy = false;
  int _moves = 0;

  int get _cols {
    final int n = widget.pairs * 2;
    return math.sqrt(n).round();
  }

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final List<_MemoryCard> deck = [];
    for (var i = 0; i < widget.pairs; i++) {
      final String e = _emojis[i % _emojis.length];
      deck.add(_MemoryCard(e, i));
      deck.add(_MemoryCard(e, i));
    }
    deck.shuffle();
    _cards = deck;
    _first = null;
    _moves = 0;
  }

  Future<void> _flip(int idx) async {
    final _MemoryCard c = _cards[idx];
    if (_busy || c.faceUp || c.matched) return;
    setState(() {
      c.faceUp = true;
      _moves++;
    });
    if (_first == null) {
      _first = idx;
      return;
    }
    // second card of the turn
    _busy = true;
    final int a = _first!;
    _first = null;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {
      if (_cards[a].id == c.id) {
        _cards[a].matched = true;
        c.matched = true;
      } else {
        _cards[a].faceUp = false;
        c.faceUp = false;
      }
      _busy = false;
    });
    if (_cards.every((x) => x.matched)) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        // won — restart in place
        setState(() {
          _deal();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int won = _cards.where((c) => c.matched).length ~/ 2;
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
                Text('pairs $won/${widget.pairs} • moves $_moves',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _cols.clamp(3, 6),
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6),
              itemBuilder: (context, i) {
                final _MemoryCard c = _cards[i];
                return Material(
                  color: c.faceUp || c.matched
                      ? Colors.amber.shade50
                      : Colors.blueGrey,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _flip(i),
                    child: Center(
                      child: (c.faceUp || c.matched)
                          ? Text(c.emoji,
                              style: const TextStyle(fontSize: 26))
                          : const Icon(Icons.help_outline, color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: () => setState(_deal), child: const Text('Restart')),
            ),
          ],
        ),
      ),
    );
  }
}
