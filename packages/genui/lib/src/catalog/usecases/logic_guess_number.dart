// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Guess the number: the model sets the range; player gets hint feedback
/// (higher/lower) and a move count.
final class LogicGuessNumber {
  static final catalogItem = CatalogItem(
    name: 'LogicGuessNumber',
    dataSchema: S.object(
      description: 'Guess a hidden number in a range.',
      properties: {
        'title': S.string(),
        'max': S.integer(description: 'Upper bound (e.g. 100).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? max = (ctx.data as Map)['max'];
      return LogicGuessNumberWidget(
        title: title is String ? title : 'Guess the number',
        max: max is int && max > 1 ? max : 100,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicGuessNumber","title":"1..100","max":100}
]''',
    ],
  );
}

class LogicGuessNumberWidget extends StatefulWidget {
  const LogicGuessNumberWidget(
      {super.key, this.title = 'Guess', this.max = 100});
  final String title;
  final int max;
  @override
  State<LogicGuessNumberWidget> createState() => _LogicGuessNumberWidgetState();
}

class _LogicGuessNumberWidgetState extends State<LogicGuessNumberWidget> {
  final math.Random _rng = math.Random();
  late int _secret;
  final TextEditingController _c = TextEditingController();
  int _moves = 0;
  String? _hint;
  String? _state;

  @override
  void initState() {
    super.initState();
    _secret = 1 + _rng.nextInt(widget.max);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _guess() {
    final int? v = int.tryParse(_c.text.trim());
    if (v == null) {
      setState(() => _hint = 'Enter a number.');
      return;
    }
    setState(() {
      _moves++;
      if (v == _secret) {
        _state = 'won';
        _hint = 'Correct in $_moves moves! 🎉';
      } else if (v < _secret) {
        _hint = 'Higher ⬆';
      } else {
        _hint = 'Lower ⬇';
      }
      _c.clear();
    });
  }

  void _restart() {
    setState(() {
      _secret = 1 + _rng.nextInt(widget.max);
      _moves = 0;
      _hint = null;
      _state = null;
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
            Row(
              children: [
                Expanded(
                    child: Text('${widget.title} (1..${widget.max})',
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('moves: $_moves',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            if (_hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _hint!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _state == 'won'
                        ? Colors.green.shade700
                        : Colors.black87,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: 'Your guess…', isDense: true),
                    enabled: _state != 'won',
                    onSubmitted: (_) => _guess(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _state == 'won' ? null : _guess,
                  child: const Text('Guess'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: _restart, child: const Text('New game')),
            ),
          ],
        ),
      ),
    );
  }
}
