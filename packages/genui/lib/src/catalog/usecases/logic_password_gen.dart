// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Secure password generator: length + char sets; strength estimate; copy.
final class LogicPasswordGen {
  static final catalogItem = CatalogItem(
    name: 'LogicPasswordGen',
    dataSchema: S.object(
      description: 'Generate a strong random password.',
      properties: {
        'title': S.string(),
        'length': S.integer(description: 'Password length (e.g. 16).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? len = (ctx.data as Map)['length'];
      return LogicPasswordGenWidget(
        title: title is String ? title : 'Password',
        length: len is int && len >= 6 ? len : 16,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPasswordGen","title":"Password","length":16}
]''',
    ],
  );
}

class LogicPasswordGenWidget extends StatefulWidget {
  const LogicPasswordGenWidget(
      {super.key, this.title = 'Password', this.length = 16});
  final String title;
  final int length;
  @override
  State<LogicPasswordGenWidget> createState() => _LogicPasswordGenWidgetState();
}

class _LogicPasswordGenWidgetState extends State<LogicPasswordGenWidget> {
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{};:,.<>?';
  final math.Random _rng = math.Random();
  bool _useUpper = true, _useDigits = true, _useSymbols = true;
  late int _len;
  late String _pw;

  @override
  void initState() {
    super.initState();
    _len = widget.length;
    _pw = _generate();
  }

  String _generate() {
    String chars = _lower;
    if (_useUpper) chars += _upper;
    if (_useDigits) chars += _digits;
    if (_useSymbols) chars += _symbols;
    return String.fromCharCodes([
      for (var i = 0; i < _len; i++)
        chars.codeUnitAt(_rng.nextInt(chars.length)),
    ]);
  }

  int get _strength {
    final int charsets =
        (_useUpper ? 1 : 0) + (_useDigits ? 1 : 0) + (_useSymbols ? 1 : 0);
    return (charsets * _len) ~/ 8;
  }

  void _copy() => Clipboard.setData(ClipboardData(text: _pw));

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
            SelectableText(
              _pw,
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_strength / 6).clamp(0, 1),
            ),
            const SizedBox(height: 4),
            Text('Strength: ${_strength.toStringAsFixed(1)}/6',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _len.toDouble(),
                    min: 6,
                    max: 32,
                    divisions: 26,
                    label: '$_len',
                    onChanged: (v) => setState(() {
                      _len = v.round();
                      _pw = _generate();
                    }),
                  ),
                ),
                Text('$_len'),
              ],
            ),
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _useUpper,
              title: const Text('Uppercase'),
              onChanged: (v) => setState(() {
                _useUpper = v ?? true;
                _pw = _generate();
              }),
            ),
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _useDigits,
              title: const Text('Digits'),
              onChanged: (v) => setState(() {
                _useDigits = v ?? true;
                _pw = _generate();
              }),
            ),
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _useSymbols,
              title: const Text('Symbols'),
              onChanged: (v) => setState(() {
                _useSymbols = v ?? true;
                _pw = _generate();
              }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                    onPressed: () => setState(() => _pw = _generate()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate')),
                const SizedBox(width: 8),
                FilledButton.icon(
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
}
