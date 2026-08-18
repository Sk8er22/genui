// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A number converter: type in decimal, binary, or hex — all three sync live.
final class LogicBinaryConverter {
  static final catalogItem = CatalogItem(
    name: 'LogicBinaryConverter',
    dataSchema: S.object(
      description: 'Convert a number between decimal, binary and hex.',
      properties: {
        'title': S.string(),
        'initialValue': S.integer(description: 'Initial decimal value.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? initial = (ctx.data as Map)['initialValue'];
      return LogicBinaryConverterWidget(
        title: title is String ? title : 'Number converter',
        initialValue: initial is int ? initial : 0,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicBinaryConverter","title":"Convert","initialValue":255}
]''',
      () => '''
[
 {"id":"root","component":"LogicBinaryConverter","title":"Binary/Hex"}
]''',
    ],
  );
}

class LogicBinaryConverterWidget extends StatefulWidget {
  const LogicBinaryConverterWidget({
    super.key,
    this.title = 'Number converter',
    this.initialValue = 0,
  });
  final String title;
  final int initialValue;
  @override
  State<LogicBinaryConverterWidget> createState() =>
      _LogicBinaryConverterWidgetState();
}

class _LogicBinaryConverterWidgetState
    extends State<LogicBinaryConverterWidget> {
  late final TextEditingController _decimalCtrl;
  late final TextEditingController _binaryCtrl;
  late final TextEditingController _hexCtrl;
  bool _syncing = false;
  int _lastValid = 0;

  @override
  void initState() {
    super.initState();
    _lastValid = widget.initialValue;
    _decimalCtrl = TextEditingController(text: '${widget.initialValue}');
    _binaryCtrl = TextEditingController(text: _toBinary(widget.initialValue));
    _hexCtrl = TextEditingController(text: _toHex(widget.initialValue));
    _decimalCtrl.addListener(() => _onChanged(_decimalCtrl, _parseDec));
    _binaryCtrl.addListener(() => _onChanged(_binaryCtrl, _parseBin));
    _hexCtrl.addListener(() => _onChanged(_hexCtrl, _parseHex));
  }

  @override
  void dispose() {
    _decimalCtrl.dispose();
    _binaryCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  static String _toBinary(int v) => v.toRadixString(2);
  static String _toHex(int v) => v.toRadixString(16).toUpperCase();
  static String _toDec(int v) => '$v';

  static int? _parseDec(String s) {
    final String t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  static int? _parseBin(String s) => int.tryParse(s.trim(), radix: 2);
  static int? _parseHex(String s) =>
      int.tryParse(s.trim().replaceAll('0x', ''), radix: 16);

  void _onChanged(TextEditingController src, int? Function(String) parse) {
    if (_syncing) return;
    // Recompute the value from the raw input; if it parses, sync the others.
    final int? value = parse(src.text);
    if (value == null) return;
    _lastValid = value;
    _syncing = true;
    try {
      if (src != _decimalCtrl) {
        _setQuietly(_decimalCtrl, _toDec(value));
      }
      if (src != _binaryCtrl) {
        _setQuietly(_binaryCtrl, _toBinary(value));
      }
      if (src != _hexCtrl) {
        _setQuietly(_hexCtrl, _toHex(value));
      }
    } finally {
      _syncing = false;
    }
  }

  static void _setQuietly(TextEditingController ctrl, String text) {
    if (ctrl.text == text) return;
    ctrl.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _field(context, 'DEC', _decimalCtrl, _isDec(_decimalCtrl.text),
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))),
            const SizedBox(height: 8),
            _field(context, 'BIN', _binaryCtrl, _isBin(_binaryCtrl.text),
                FilteringTextInputFormatter.allow(RegExp(r'[01]'))),
            const SizedBox(height: 8),
            _field(context, 'HEX', _hexCtrl, _isHex(_hexCtrl.text),
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))),
            const SizedBox(height: 12),
            Text(
              'Value: $_lastValid',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isDec(String s) => _parseDec(s) != null && s.trim().isNotEmpty;
  bool _isBin(String s) => _parseBin(s) != null && s.trim().isNotEmpty;
  bool _isHex(String s) => _parseHex(s) != null && s.trim().isNotEmpty;

  Widget _field(BuildContext context, String label,
      TextEditingController ctrl, bool valid, TextInputFormatter formatter) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.text,
      inputFormatters: [formatter],
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'monospace',
        color: valid ? null : Theme.of(context).colorScheme.error,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: valid ? null : 'Invalid',
      ),
    );
  }
}
