// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Wordle-style daily word game: guess a 5-letter word in 6 tries with
/// per-letter color feedback. The model can pass a target/answer word.
final class LogicWordle {
  static final catalogItem = CatalogItem(
    name: 'LogicWordle',
    dataSchema: S.object(
      description: 'Guess the 5-letter word (6 tries).',
      properties: {
        'title': S.string(),
        'word': S.string(description: 'Optional target word (5 letters).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? word = (ctx.data as Map)['word'];
      return LogicWordleWidget(
        title: title is String ? title : 'Wordle',
        word: word is String ? word : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicWordle","title":"Wordle","word":"ADOBE"}
]''',
    ],
  );
}

const List<String> _wordBank = [
  'ADOBE', 'BRAVE', 'CLOUD', 'DREAM', 'EPOCH', 'FIRST', 'GLOBE', 'HUMAN',
  'INDEX', 'JOKER', 'KNIFE', 'LEMON', 'MAGIC', 'NORTH', 'OCEAN', 'PIANO',
  'QUEST', 'RIVER', 'SMILE', 'TIGER', 'ULTRA', 'VOICE', 'WATER', 'YOUNG',
  'ZEBRA', 'APPLE', 'BREAD', 'CHEEK', 'DELTA', 'EAGER',
];

class _Tile {
  _Tile(this.ch);
  String ch;
  String state = 'empty'; // empty | exact | partial | absent
}

class LogicWordleWidget extends StatefulWidget {
  const LogicWordleWidget(
      {super.key, this.title = 'Wordle', this.word});
  final String title;
  final String? word;
  @override
  State<LogicWordleWidget> createState() => _LogicWordleWidgetState();
}

class _LogicWordleWidgetState extends State<LogicWordleWidget> {
  final math.Random _rng = math.Random();
  late String _target;
  late List<List<_Tile>> _rows;
  int _row = 0;
  String _current = '';
  bool _won = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _target = widget.word ?? _wordBank[_rng.nextInt(_wordBank.length)];
    _rows = [
      for (var r = 0; r < 6; r++)
        [for (var c = 0; c < 5; c++) _Tile('')]
    ];
  }

  void _press(String letter) {
    if (_won || _row >= 6) return;
    if (letter == '⌫') {
      if (_current.isNotEmpty) {
        setState(() => _current = _current.substring(0, _current.length - 1));
      }
    } else if (letter == '⏎') {
      if (_current.length < 5) return;
      _submit();
    } else if (_current.length < 5) {
      setState(() => _current += letter);
    }
  }

  void _submit() {
    final String guess = _current;
    final Map<String, int> counts = {};
    for (final ch in _target.split('')) {
      counts[ch] = (counts[ch] ?? 0) + 1;
    }
    final List<String> states = List.filled(5, '');
    for (var i = 0; i < 5; i++) {
      if (guess[i] == _target[i]) {
        states[i] = 'exact';
        counts[guess[i]] = counts[guess[i]]! - 1;
      }
    }
    for (var i = 0; i < 5; i++) {
      if (states[i] == 'exact') continue;
      final String ch = guess[i];
      if ((counts[ch] ?? 0) > 0) {
        states[i] = 'partial';
        counts[ch] = counts[ch]! - 1;
      } else {
        states[i] = 'absent';
      }
    }
    setState(() {
      for (var i = 0; i < 5; i++) {
        _rows[_row][i].ch = guess[i];
        _rows[_row][i].state = states[i];
      }
      _won = guess == _target;
      if (_won) {
        _message = 'You got it!';
      } else if (_row >= 5) {
        _message = 'Word was $_target';
      }
      _row++;
      _current = '';
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
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleMedium)),
                if (_message != null)
                  Text(_message!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  for (var r = 0; r < 6; r++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var c = 0; c < 5; c++)
                            _cell(r, c),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _keyboard(),
          ],
        ),
      ),
    );
  }

  Widget _cell(int r, int c) {
    // committed rows show their tile; the current (partial) row shows _current.
    final bool isCurrent = r == _row;
    final String ch;
    if (isCurrent) {
      ch = c < _current.length ? _current[c] : '';
    } else {
      ch = _rows[r][c].ch;
    }
    final String state = isCurrent ? 'empty' : _rows[r][c].state;
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: switch (state) {
          'exact' => Colors.green.shade600,
          'partial' => Colors.amber.shade600,
          'absent' => Colors.blueGrey.shade400,
          _ => Colors.grey.shade100,
        },
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(ch,
          style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _keyboard() {
    const rows = [
      'QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM',
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (row == 'ZXCVBNM') _key('⏎'),
                for (final ch in row.split('')) _key(ch),
                if (row == 'ZXCVBNM') _key('⌫'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(String ch) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _press(ch),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(ch.length > 1 ? '⌫' : ch),
          ),
        ),
      ),
    );
  }
}
