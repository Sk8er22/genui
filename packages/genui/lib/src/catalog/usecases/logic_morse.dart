// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Morse code encoder: type (or let the model give) a phrase; see + hear the
/// morse (beeps), copy it. Educational.
final class LogicMorse {
  static final catalogItem = CatalogItem(
    name: 'LogicMorse',
    dataSchema: S.object(
      description: 'Encode text as Morse code (with audio).',
      properties: {
        'title': S.string(),
        'text': S.string(description: 'Optional text to encode.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? text = (ctx.data as Map)['text'];
      return LogicMorseWidget(
        title: title is String ? title : 'Morse',
        seedText: text is String ? text : '',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicMorse","title":"Morse","text":"HELLO"}
]''',
    ],
  );
}

/// Morse encoder + decoder. Exposed for tests.
String encodeMorse(String input) {
  final out = <String>[];
  for (final ch in input.toUpperCase().split('')) {
    if (_code.containsKey(ch)) out.add(_code[ch]!);
  }
  return out.join(' ');
}

String decodeMorse(String morse) {
  final rev = {for (final e in _code.entries) e.value: e.key};
  return morse
      .trim()
      .split(RegExp(r'\s+'))
      .map((t) => rev[t] ?? '?')
      .join();
}

const Map<String, String> _code = {
  'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.',
  'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
  'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.',
  'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
  'Y': '-.--', 'Z': '--..', '0': '-----', '1': '.----', '2': '..---',
  '3': '...--', '4': '....-', '5': '.....', '6': '-....', '7': '--...',
  '8': '---..', '9': '----.',
};

class LogicMorseWidget extends StatefulWidget {
  const LogicMorseWidget({super.key, this.title = 'Morse', this.seedText = ''});
  final String title;
  final String seedText;
  @override
  State<LogicMorseWidget> createState() => _LogicMorseWidgetState();
}

class _LogicMorseWidgetState extends State<LogicMorseWidget> {
  final TextEditingController _c = TextEditingController();
  String _morse = '';

  @override
  void initState() {
    super.initState();
    _c.text = widget.seedText;
    _morse = encodeMorse(widget.seedText);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _reencode([String? _]) =>
      setState(() => _morse = encodeMorse(_c.text));

  void _copy() => Clipboard.setData(ClipboardData(text: _morse));

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Tap symbols to play the beeps',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              decoration: const InputDecoration(
                  labelText: 'Text', isDense: true, border: OutlineInputBorder()),
              onChanged: _reencode,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _morse.isEmpty ? '(no output)' : _morse,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                FilledButton.icon(
                    onPressed: _morse.isEmpty ? null : () => _playMorse(_morse),
                    icon: const Icon(Icons.graphic_eq),
                    label: const Text('Play')),
                OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playMorse(String morse) async {
    final fs = SystemSound.play(SystemSoundType.click);
    for (final ch in morse.split('')) {
      if (ch == '.') {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      } else if (ch == '-') {
        await Future<void>.delayed(const Duration(milliseconds: 320));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    await fs;
  }
}
