// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Flip-card flashcard deck. Model supplies [{"front","back"}] pairs.
final class LogicFlashcards {
  static final catalogItem = CatalogItem(
    name: 'LogicFlashcards',
    dataSchema: S.object(
      description: 'Spaced-style flip flashcards.',
      properties: {
        'title': S.string(),
        'cards': S.list(
          items: S.object(properties: {
            'front': S.string(),
            'back': S.string(),
          }, required: ['front', 'back']),
        ),
      },
      required: ['title', 'cards'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? cards = (ctx.data as Map)['cards'];
      final List<FlashCard> parsed = cards is List
          ? cards.map((c) {
              final m = c is Map ? c : const <String, Object?>{};
              return FlashCard(
                (m['front'] as String?) ?? '',
                (m['back'] as String?) ?? '',
              );
            }).toList()
          : const [];
      return LogicFlashcardsWidget(
          title: title is String ? title : 'Flashcards', cards: parsed);
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicFlashcards","title":"Spanish",
  "cards":[
    {"front":"Hola","back":"Hello"},
    {"front":"Gracias","back":"Thank you"}
  ]}
]''',
    ],
  );
}

class FlashCard {
  const FlashCard(this.front, this.back);
  final String front;
  final String back;
}

class LogicFlashcardsWidget extends StatefulWidget {
  const LogicFlashcardsWidget({super.key, required this.title, this.cards = const []});
  final String title;
  final List<FlashCard> cards;
  @override
  State<LogicFlashcardsWidget> createState() => _LogicFlashcardsWidgetState();
}

class _LogicFlashcardsWidgetState extends State<LogicFlashcardsWidget> {
  int _index = 0;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    if (widget.cards.isEmpty) {
      // no-op; UI shows empty state
    }
  }

  void _go(int delta) {
    if (widget.cards.isEmpty) return;
    setState(() {
      _index = (_index + delta + widget.cards.length) % widget.cards.length;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (widget.cards.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: Text('No cards.')),
              )
            else ...[
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _flipped = !_flipped),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(_flipped),
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 160),
                      decoration: BoxDecoration(
                        color: _flipped
                            ? Colors.green.shade100
                            : Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          _flipped
                              ? widget.cards[_index].back
                              : widget.cards[_index].front,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: _flipped
                                    ? Colors.green.shade800
                                    : null,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('${_index + 1} / ${widget.cards.length}  •  '
                    'tap card to flip',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                      onPressed: () => _go(-1), child: const Text('Prev')),
                  TextButton(
                    onPressed: () => setState(() => _flipped = !_flipped),
                    child: const Text('Flip'),
                  ),
                  OutlinedButton(
                      onPressed: () => _go(1), child: const Text('Next')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
