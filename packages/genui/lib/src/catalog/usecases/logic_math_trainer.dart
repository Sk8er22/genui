// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Arithmetic drill: the model picks an operator and range; the player answers
/// for scoring + speed. Generates deterministic problems.
final class LogicMathTrainer {
  static final catalogItem = CatalogItem(
    name: 'LogicMathTrainer',
    dataSchema: S.object(
      description: 'Timed arithmetic practice (+ - * /).',
      properties: {
        'title': S.string(),
        'op': S.string(enumValues: ['+', '-', 'x', '/'], description: 'Operator.'),
        'max': S.integer(description: 'Max operand magnitude.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? op = (ctx.data as Map)['op'];
      final Object? max = (ctx.data as Map)['max'];
      return LogicMathTrainerWidget(
        title: title is String ? title : 'Math',
        op: op is String && '+-x/'.contains(op) ? op : '+',
        maxN: max is int && max > 1 ? max : 20,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicMathTrainer","title":"Add","op":"+","max":20}
]''',
    ],
  );
}

class LogicMathTrainerWidget extends StatefulWidget {
  const LogicMathTrainerWidget(
      {super.key, this.title = 'Math', this.op = '+', this.maxN = 20});
  final String title;
  final String op;
  final int maxN;
  @override
  State<LogicMathTrainerWidget> createState() => _LogicMathTrainerWidgetState();
}

class _LogicMathTrainerWidgetState extends State<LogicMathTrainerWidget> {
  final math.Random _rng = math.Random();
  final TextEditingController _c = TextEditingController();
  late int _a, _b, _answer;
  int _score = 0;
  int _asked = 0;
  String? _feedback;

  int _compute(int a, int b, String op) => switch (op) {
        '+' => a + b, '-' => a - b,
        'x' => a * b,
        _ => a ~/ b,
      };

  @override
  void initState() {
    super.initState();
    _newProblem();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _newProblem() {
    _a = 1 + _rng.nextInt(widget.maxN);
    _b = 1 + _rng.nextInt(widget.maxN);
    if (widget.op == '-') {
      if (_a < _b) {
        final t = _a;
        _a = _b;
        _b = t;
      }
    }
    if (widget.op == '/') {
      _b = 1 + _rng.nextInt(widget.maxN ~/ 2);
      _a = _b * (1 + _rng.nextInt(9));
    }
    _answer = _compute(_a, _b, widget.op);
    _feedback = null;
    _c.clear();
  }

  void _submit([String? _]) {
    final int? v = int.tryParse(_c.text.trim());
    if (v == null) return;
    setState(() {
      _asked++;
      if (v == _answer) {
        _score++;
        _feedback = 'Correct ✓  $_a ${widget.op} $_b = $_answer';
        _newProblem();
      } else {
        _feedback = 'Oops — try again';
        _c.clear();
      }
    });
    if (v == _answer) {
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _feedback = null);
      });
    }
  }

  String get _prob => '$_a ${widget.op} $_b = ?';

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
                Text('$_score/$_asked',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(_prob, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: 'Answer…', isDense: true),
                    onSubmitted: _submit,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: const Text('Go')),
              ],
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 8),
              Text(_feedback!, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}
