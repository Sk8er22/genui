// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Hangman: guess a word letter-by-letter before 6 wrong guesses. The model
/// can pass a word; otherwise a built-in bank is used.
final class LogicHangman {
  static final catalogItem = CatalogItem(
    name: 'LogicHangman',
    dataSchema: S.object(
      description: 'Classic hangman word game.',
      properties: {
        'title': S.string(),
        'word': S.string(description: 'Optional word to guess.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? word = (ctx.data as Map)['word'];
      return LogicHangmanWidget(
        title: title is String ? title : 'Hangman',
        word: word is String ? word : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicHangman","title":"Animals","word":"ELEPHANT"}
]''',
    ],
  );
}

const List<String> _words = [
  'ELEPHANT', 'KANGAROO', 'GIRAFFE', 'DOLPHIN', 'PENGUIN', 'BUTTERFLY',
  'CHAMPION', 'BANANA', 'COMPUTER', 'WHISPER', 'JOURNEY', 'MOUNTAIN',
];

class LogicHangmanWidget extends StatefulWidget {
  const LogicHangmanWidget(
      {super.key, this.title = 'Hangman', this.word});
  final String title;
  final String? word;
  @override
  State<LogicHangmanWidget> createState() => _LogicHangmanWidgetState();
}

class _LogicHangmanWidgetState extends State<LogicHangmanWidget> {
  static const int _maxWrong = 6;
  final math.Random _rng = math.Random();
  late String _target;
  final Set<String> _guessed = {};
  int _wrong = 0;
  String? _result;

  @override
  void initState() {
    super.initState();
    _target = widget.word ?? _words[_rng.nextInt(_words.length)];
  }

  bool get _won => _target.split('').every(_guessed.contains);

  void _guess(String letter) {
    if (_result != null || _guessed.contains(letter)) return;
    setState(() {
      _guessed.add(letter);
      if (!_target.contains(letter)) _wrong++;
      if (_won) {
        _result = 'You win!';
      } else if (_wrong >= _maxWrong) {
        _result = 'Word was $_target';
      }
    });
  }

  String get _masked => _target
      .split('')
      .map((ch) => _guessed.contains(ch) ? ch : ' _ ')
      .join();

  void _restart() {
    setState(() {
      _target = widget.word ?? _words[_rng.nextInt(_words.length)];
      _guessed.clear();
      _wrong = 0;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
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
                Text('wrong: $_wrong/$_maxWrong',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(_masked,
                style: const TextStyle(
                    fontSize: 28, letterSpacing: 4, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _gallows(_wrong),
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(_result!, style: Theme.of(context).textTheme.titleMedium),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final ch in letters)
                  ActionChip(
                    label: Text(ch),
                    onPressed: _result != null ? null : () => _guess(ch),
                    backgroundColor: _guessed.contains(ch)
                        ? (_target.contains(ch)
                            ? Colors.green.shade200
                            : Colors.red.shade200)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child:
                  OutlinedButton(onPressed: _restart, child: const Text('New word')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gallows(int wrong) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: _GallowsPainter(steps: wrong),
    );
  }
}

class _GallowsPainter extends CustomPainter {
  _GallowsPainter({required this.steps});
  final int steps;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade400
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // gallows frame
    canvas.drawLine(Offset(20, size.height - 10), Offset(size.width - 20, size.height - 10), paint);
    canvas.drawLine(Offset(40, size.height - 10), Offset(40, 10), paint);
    canvas.drawLine(Offset(40, 10), Offset(size.width - 40, 10), paint);
    canvas.drawLine(Offset(size.width - 40, 10), Offset(size.width - 40, 25), paint);
    final c = Paint()..color = Colors.black87;
    final int s = steps;
    // head (1), body (2), arms (3,4), legs (5,6)
    final Offset neck = Offset(size.width - 40, 25);
    if (s >= 1) canvas.drawCircle(neck.translate(0, 10), 9, c);
    if (s >= 2) canvas.drawLine(neck.translate(0, 19), neck.translate(0, 55), c);
    if (s >= 3) canvas.drawLine(neck.translate(0, 28), neck.translate(-16, 42), c);
    if (s >= 4) canvas.drawLine(neck.translate(0, 28), neck.translate(16, 42), c);
    if (s >= 5) canvas.drawLine(neck.translate(0, 55), neck.translate(-12, 78), c);
    if (s >= 6) canvas.drawLine(neck.translate(0, 55), neck.translate(12, 78), c);
  }

  @override
  bool shouldRepaint(covariant _GallowsPainter old) => old.steps != steps;
}
