// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Anagram unscramble: the model gives a scrambled word (or a puzzle word)
/// and the player rearranges a letter rack, tapping letters to build the
/// answer; check reveals correctness. Optional taps-on-target mode.
final class LogicAnagram {
  static final catalogItem = CatalogItem(
    name: 'LogicAnagram',
    dataSchema: S.object(
      description: 'Unscramble an anagram from a letter rack.',
      properties: {
        'title': S.string(),
        'word': S.string(description: 'The correct word.'),
        'hint': S.string(description: 'Optional definition hint.'),
      },
      required: ['title', 'word'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? word = (ctx.data as Map)['word'];
      final Object? hint = (ctx.data as Map)['hint'];
      String w = word is String ? word.trim().toUpperCase() : '';
      w = w.replaceAll(RegExp(r'[^A-Z]'), '');
      if (w.length < 2) w = 'GENUI';
      return LogicAnagramWidget(
        title: title is String ? title : 'Anagram',
        word: w,
        hint: hint is String ? hint : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicAnagram","title":"Word","word":"GENIUS","hint":"smart"}
]''',
    ],
  );
}

class LogicAnagramWidget extends StatefulWidget {
  const LogicAnagramWidget(
      {super.key, required this.title, required this.word, this.hint});
  final String title;
  final String word;
  final String? hint;
  @override
  State<LogicAnagramWidget> createState() => _LogicAnagramWidgetState();
}

class _LogicAnagramWidgetState extends State<LogicAnagramWidget> {
  late final List<String> _rack;
  final List<int> _chosen = []; // indices into rack currently selected
  String? _msg;

  @override
  void initState() {
    super.initState();
    _rack = widget.word.split('')..shuffle(math.Random());
  }

  String get _guess => _chosen.map((i) => _rack[i]).join();

  void _tapRack(int i) {
    if (_chosen.contains(i) || _msg == 'Correct') return;
    setState(() {
      _chosen.add(i);
      _msg = null;
    });
  }

  void _tapWord(int at) {
    if (at < 0 || at >= _chosen.length) return;
    setState(() {
      _chosen.removeAt(at);
      _msg = null;
    });
  }

  void _check() {
    setState(() {
      _msg = _guess == widget.word
          ? 'Correct! "${widget.word}" ✔'
          : 'Not yet — ${_guess.isEmpty ? "empty" : _guess}';
    });
  }

  void _shuffle() {
    setState(() {
      _rack.shuffle(math.Random());
      _chosen.clear();
      _msg = null;
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
            if (widget.hint != null) ...[
              const SizedBox(height: 4),
              Text('Hint: ${widget.hint}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            // answer slots
            Wrap(
              children: [
                for (var i = 0; i < _chosen.length; i++)
                  ActionChip(
                    label: Text(_rack[_chosen[i]]),
                    onPressed: () => _tapWord(i),
                  ),
                if (_chosen.isEmpty)
                  Text('Tap letters below to build the word',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            // rack
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _rack.length; i++)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _chosen.contains(i)
                        ? Colors.grey.shade300
                        : Colors.teal.shade200,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap:
                          _chosen.contains(i) ? null : () => _tapRack(i),
                      child: Center(
                        child: Text(_rack[i],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_msg != null)
              Text(_msg!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                    onPressed: _shuffle, child: const Text('Shuffle')),
                FilledButton(onPressed: _check, child: const Text('Check')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
