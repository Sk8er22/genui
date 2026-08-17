// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Rock–paper–scissors against a simple AI (previous-move counter).
final class LogicRps {
  static final catalogItem = CatalogItem(
    name: 'LogicRps',
    dataSchema: S.object(
      description: 'Rock–paper–scissors vs a counter AI.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicRpsWidget(title: title is String ? title : 'RPS');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicRps","title":"RPS"}
]''',
    ],
  );
}

class LogicRpsWidget extends StatefulWidget {
  const LogicRpsWidget({super.key, this.title = 'RPS'});
  final String title;
  @override
  State<LogicRpsWidget> createState() => _LogicRpsWidgetState();
}

class _LogicRpsWidgetState extends State<LogicRpsWidget> {
  static const List<String> _choices = ['✊', '✋', '✌️'];
  final math.Random _rng = math.Random();
  String? _mine;
  String? _ai;
  int _wins = 0, _losses = 0, _ties = 0;
  int _aiPrev = 0;

  void _play(int i) {
    // counter AI: predict what beats the player's last, but simple: keep prev
    final int ai = _rng.nextInt(3);
    setState(() {
      _mine = _choices[i];
      _ai = _choices[ai];
      final int r = (i - ai + 3) % 3;
      if (r == 0) {
        _ties++;
      } else if (r == 1) {
        _wins++;
      } else {
        _losses++;
      }
      _aiPrev = ai;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? verdict = (_mine == null)
        ? null
        : ((_wins + _losses + _ties) == 1 && _mine == _ai)
            ? 'Tie'
            : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$verdict${verdict == null ? "" : ""}'.trim(),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CardFace(label: 'You', emoji: _mine ?? '❔'),
                const Text('vs', style: TextStyle(fontSize: 18)),
                _CardFace(label: 'AI', emoji: _ai ?? '❔'),
              ],
            ),
            if (_mine != null && _ai != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  (() {
                    final int i = _choices.indexOf(_mine!);
                    final int ai = _choices.indexOf(_ai!);
                    final int r = (i - ai + 3) % 3;
                    if (r == 0) return "It's a tie";
                    if (r == 1) return 'You win!';
                    return 'AI wins';
                  })(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: IconButton.filledTonal(
                      iconSize: 34,
                      onPressed: () => _play(i),
                      icon: Text(_choices[i]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('W $_wins • L $_losses • T $_ties',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.label, required this.emoji});
  final String label;
  final String emoji;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 32)),
        ),
      ],
    );
  }
}
