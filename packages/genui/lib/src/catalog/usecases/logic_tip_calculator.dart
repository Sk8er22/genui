// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Tip calculator: bill amount + tip % + optional party size -> per-person.
final class LogicTipCalculator {
  static final catalogItem = CatalogItem(
    name: 'LogicTipCalculator',
    dataSchema: S.object(
      description: 'Compute a tip and per-person split.',
      properties: {
        'title': S.string(),
        'currencies': S.string(description: r'Currency symbol, e.g. USD or $'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? cur = (ctx.data as Map)['currencies'];
      return LogicTipCalculatorWidget(
        title: title is String ? title : 'Tip',
        currency: cur is String ? cur : r'$',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTipCalculator","title":"Dinner","currencies":"USD"}
]''',
    ],
  );
}

class LogicTipCalculatorWidget extends StatefulWidget {
  const LogicTipCalculatorWidget(
      {super.key, this.title = 'Tip', this.currency = r'$'});
  final String title;
  final String currency;
  @override
  State<LogicTipCalculatorWidget> createState() =>
      _LogicTipCalculatorWidgetState();
}

class _LogicTipCalculatorWidgetState extends State<LogicTipCalculatorWidget> {
  final TextEditingController _bill = TextEditingController();
  double _pct = 15;
  int _people = 1;
  double? _result;

  void _compute() {
    final double? bill = double.tryParse(_bill.text.trim());
    setState(() {
      _result = bill == null ? null : bill * (1 + _pct / 100);
    });
  }

  String get _sym {
    final String c = widget.currency.toUpperCase();
    return switch (c) { 'USD' => r'$', 'EUR' => '€', 'GBP' => '£', 'JPY' => '¥',
      _ => widget.currency };
  }

  @override
  void dispose() {
    _bill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double? bill = double.tryParse(_bill.text.trim());
    double? total;
    double? tip;
    if (bill != null) {
      total = bill * (1 + _pct / 100);
      tip = total - bill;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _bill,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Bill amount ($_sym)', isDense: true),
              onSubmitted: (_) => _compute(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Tip ${_pct.round()}%'),
                Expanded(
                  child: Slider(
                    value: _pct,
                    min: 0,
                    max: 35,
                    divisions: 35,
                    label: '${_pct.round()}%',
                    onChanged: (v) => setState(() => _pct = v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text('People $_people'),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _people > 1
                      ? () => setState(() => _people--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _people++),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_result != null && bill != null && total != null && tip != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tip (${_pct.round()}%)',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('${_sym}${tip.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Text('${_sym}${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              if (_people > 1) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Per person ($_people)',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('${_sym}${(total / _people).toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                  onPressed: _compute, child: const Text('Compute')),
            ),
          ],
        ),
      ),
    );
  }
}
