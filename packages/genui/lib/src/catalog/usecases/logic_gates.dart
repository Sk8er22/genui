// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A digital logic trainer: pick a gate, flip the inputs and watch the output.
///
/// An interactive truth-table explorer for AND, OR, NAND, NOR, XOR, XNOR and
/// NOT gates. Great for teaching how combinational logic actually behaves.
final class LogicGates {
  static final catalogItem = CatalogItem(
    name: 'LogicGates',
    dataSchema: S.object(
      description:
          'Interactive truth-table trainer for AND, OR, NAND, NOR, XOR, XNOR '
          'and NOT logic gates.',
      properties: {
        'title': S.string(description: 'Heading shown above the trainer.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicGatesWidget(
        title: title is String && title.isNotEmpty ? title : 'Logic gates',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicGates","title":"AND gate trainer"}
]''',
      () => '''
[
 {"id":"root","component":"LogicGates","title":"XOR on its own"}
]''',
    ],
  );
}

/// A single gate flavour: a human readable name, an equation and a truth
/// function. Binary gates use both [a] and [b]; the unary NOT ignores [b].
class _Gate {
  const _Gate(this.name, this.formula, this.fn);
  final String name;
  final String formula;
  final bool Function(bool a, bool b) fn;
}

const List<_Gate> _gates = [
  _Gate('AND', 'A · B', _and),
  _Gate('OR', 'A + B', _or),
  _Gate('NAND', '¬(A · B)', _nand),
  _Gate('NOR', '¬(A + B)', _nor),
  _Gate('XOR', 'A ⊕ B', _xor),
  _Gate('XNOR', 'A ⊙ B', _xnor),
  _Gate('NOT', '¬A', _not),
];

bool _and(bool a, bool b) => a && b;
bool _or(bool a, bool b) => a || b;
bool _nand(bool a, bool b) => !(a && b);
bool _nor(bool a, bool b) => !(a || b);
bool _xor(bool a, bool b) => a != b;
bool _xnor(bool a, bool b) => a == b;
bool _not(bool a, bool b) => !a;

class LogicGatesWidget extends StatefulWidget {
  const LogicGatesWidget({super.key, this.title = 'Logic gates'});
  final String title;
  @override
  State<LogicGatesWidget> createState() => _LogicGatesWidgetState();
}

class _LogicGatesWidgetState extends State<LogicGatesWidget> {
  int _gateIndex = 0;
  bool _inputA = false;
  bool _inputB = false;

  _Gate get _gate => _gates[_gateIndex];
  bool get _output => _gate.fn(_inputA, _inputB);
  bool get _isUnary => _gate == _gates.last; // NOT

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool out = _output;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // Gate picker.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _gates.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_gates[i].name),
                        selected: _gateIndex == i,
                        onSelected: (_) => setState(() => _gateIndex = i),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(_gate.formula,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontFamily: 'monospace')),
            ),
            const SizedBox(height: 16),
            // Inputs.
            Row(
              children: [
                Expanded(
                  child: _InputSwitch(
                    label: 'Input A',
                    value: _inputA,
                    onChanged: (v) => setState(() => _inputA = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputSwitch(
                    label: 'Input B',
                    value: _inputB,
                    enabled: !_isUnary,
                    onChanged: (v) => setState(() => _inputB = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Output LED.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: out ? scheme.primary : scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Output: $out',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: out
                            ? scheme.onPrimary
                            : scheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Truth table',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                },
                children: [
                  _truthRow(context, 'A', 'B', '${_gate.name}', scheme,
                      bold: true),
                  for (final (bool a, bool b) in _allInputs)
                    _truthRow(context, '$a', _isUnary ? '–' : '$b',
                        '${_gate.fn(a, b)}', scheme,
                        highlight: _inputA == a &&
                            (_isUnary || _inputB == b)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(bool, bool)> get _allInputs =>
      _isUnary ? const [(false, false), (true, false)] : const [
        (false, false),
        (false, true),
        (true, false),
        (true, true),
      ];

  TableRow _truthRow(BuildContext context, String a, String b, String out,
      ColorScheme scheme,
      {bool bold = false, bool highlight = false}) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: highlight ? scheme.primary : null,
        );
    return TableRow(
      decoration: highlight
          ? BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.4))
          : null,
      children: [
        for (final String cell in [a, b, out])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(cell, textAlign: TextAlign.center, style: style),
          ),
      ],
    );
  }
}

class _InputSwitch extends StatelessWidget {
  const _InputSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: enabled ? scheme.outline : scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: enabled ? null : scheme.outline,
                    )),
            const SizedBox(height: 4),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
            Text(value ? 'HIGH (1)' : 'LOW (0)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}
