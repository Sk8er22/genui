// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A simple RPN-style calculator with full keypad given by the model (its
/// layout) or default. Pure-Dart evaluation, no package.
final class LogicCalculator {
  static final _schema = S.object(
    description: 'A working calculator keypad.',
    properties: {
      'title': S.string(description: 'Optional label, e.g. budget calc.'),
    },
    required: ['title'],
  );

  static final catalogItem = CatalogItem(
    name: 'LogicCalculator',
    dataSchema: _schema,
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicCalculatorWidget(
          title: title is String ? title : 'Calculator');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicCalculator","title":"Calculator"}
]''',
    ],
  );
}

class LogicCalculatorWidget extends StatefulWidget {
  const LogicCalculatorWidget({super.key, this.title = 'Calculator'});
  final String title;
  @override
  State<LogicCalculatorWidget> createState() => _LogicCalculatorWidgetState();
}

class _LogicCalculatorWidgetState extends State<LogicCalculatorWidget> {
  // Shunting-yard infix evaluation state.
  final List<String> _tokens = [];
  String _display = '0';
  bool _justEvaluated = false;

  static const List<List<String>> _keys = [
    ['C', '(', ')', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['0', '.', '⌫', '='],
  ];

  void _press(String k) {
    setState(() {
      if (k == 'C') {
        _tokens.clear();
        _display = '0';
        _justEvaluated = false;
      } else if (k == '⌫') {
        if (_tokens.isNotEmpty) _tokens.removeLast();
        _display = _tokens.isEmpty ? '0' : _tokens.join();
      } else if (k == '=') {
        _run();
      } else {
        if (_justEvaluated && _isOp(k)) {
          _justEvaluated = false;
        } else if (_justEvaluated) {
          _tokens.clear();
          _justEvaluated = false;
        }
        _tokens.add(k);
        _display = _tokens.join();
      }
    });
  }

  bool _isOp(String s) => '()+−×÷'.contains(s);

  void _run() {
    final String? r = _eval(_tokens);
    _display = r ?? 'Error';
    _tokens.clear();
    _justEvaluated = true;
  }

  /// Evaluates an infix token list with + − × ÷ ( ) using precedence.
  String? _eval(List<String> toks) {
    final List<double> values = [];
    final List<String> ops = [];
    int i = 0;
    double apply(String op, double a, double b) => switch (op) {
          '+' => a + b, '−' => a - b,
          '×' => a * b, '÷' => b == 0 ? double.nan : a / b,
          _ => double.nan,
        };
    int prec(String op) => (op == '+' || op == '−') ? 1 : 2;

    while (i < toks.length) {
      final String t = toks[i];
      if (t == '(') {
        ops.add('(');
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          // Degenerate input (e.g. unbalanced/repeated operators) can leave
          // fewer than two operands; collapse to 'Error' instead of crashing.
          if (values.length < 2) return null;
          final double b = values.removeLast();
          final double a = values.removeLast();
          values.add(apply(ops.removeLast(), a, b));
        }
        if (ops.isNotEmpty) ops.removeLast(); // pop '('
      } else if (_isOp(t)) {
        while (ops.isNotEmpty && ops.last != '(' &&
            prec(ops.last) >= prec(t)) {
          // Same guard: '5 + + 3' must show 'Error', not throw StateError.
          if (values.length < 2) return null;
          final double b = values.removeLast();
          final double a = values.removeLast();
          values.add(apply(ops.removeLast(), a, b));
        }
        ops.add(t);
      } else {
        final double? v = double.tryParse(t);
        if (v == null) return null;
        values.add(v);
      }
      i++;
    }
    while (ops.isNotEmpty) {
      final String op = ops.removeLast();
      if (op == '(') return null;
      if (values.length < 2) return null;
      final double b = values.removeLast();
      final double a = values.removeLast();
      values.add(apply(op, a, b));
    }
    if (values.isEmpty) return null;
    final double r = values.removeLast();
    if (r.isNaN || r.isInfinite) return null;
    return r == r.roundToDouble() && r.abs() < 1e12
        ? r.toInt().toString()
        : r.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
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
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _display,
                style: const TextStyle(fontSize: 26, fontFeatures: [
                  // monospace-ish
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in _keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    for (final k in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: FilledButton.tonal(
                            onPressed: () => _press(k),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  _isOp(k) || k == '=' || k == '⌫' || k == 'C'
                                      ? Colors.blueGrey.shade100
                                      : null,
                            ),
                            child: Text(k, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
