// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Times-table drill: answer multiplication facts for a chosen table (2..12).
/// The model can set the table; timed-ish score kept.
final class LogicTimesTable {
  static final catalogItem = CatalogItem(
    name: 'LogicTimesTable',
    dataSchema: S.object(
      description: 'Practice a multiplication table.',
      properties: {
        'title': S.string(),
        'table': S.integer(description: 'Which table, 2..12 (e.g. 7).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? table = (ctx.data as Map)['table'];
      return LogicTimesTableWidget(
        title: title is String ? title : 'Times table',
        table: table is int && table >= 2 && table <= 12 ? table : 7,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTimesTable","title":"7s","table":7}
]''',
    ],
  );
}

class LogicTimesTableWidget extends StatefulWidget {
  const LogicTimesTableWidget(
      {super.key, this.title = 'Times table', this.table = 7});
  final String title;
  final int table;
  @override
  State<LogicTimesTableWidget> createState() => _LogicTimesTableWidgetState();
}

class _LogicTimesTableWidgetState extends State<LogicTimesTableWidget> {
  final math.Random _rng = math.Random();
  final TextEditingController _c = TextEditingController();
  late int _a, _b, _answer;
  int _score = 0, _asked = 0;
  String? _fb;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _next() {
    _a = widget.table;
    _b = 1 + _rng.nextInt(12);
    _answer = _a * _b;
    _fb = null;
    _c.clear();
  }

  void _submit([String? _]) {
    final int? v = int.tryParse(_c.text.trim());
    if (v == null) return;
    setState(() {
      _asked++;
      if (v == _answer) {
        _score++;
        _fb = '✓ $_a × $_b = $_answer';
        _next();
      } else {
        _fb = 'Try again';
        _c.clear();
      }
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
                    child: Text('${widget.title} (×$_b)',
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('$_score/$_asked',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Text('$_a × ??', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: 'Answer…', isDense: true),
                    onSubmitted: _submit,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: const Text('Go')),
              ],
            ),
            if (_fb != null) ...[
              const SizedBox(height: 8),
              Text(_fb!, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}
