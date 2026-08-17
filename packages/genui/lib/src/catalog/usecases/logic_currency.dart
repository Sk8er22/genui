// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Simple currency converter with built-in static rates (illustrative;
/// swaps direction too). The model can override the rate + symbols.
final class LogicCurrency {
  static final catalogItem = CatalogItem(
    name: 'LogicCurrency',
    dataSchema: S.object(
      description: 'Convert between two currencies (static rates).',
      properties: {
        'title': S.string(),
        'from': S.string(description: 'ISO code, e.g. USD'),
        'to': S.string(description: 'ISO code, e.g. EUR'),
        'rate': S.number(description: '1 from-unit in to-units.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? from = (ctx.data as Map)['from'];
      final Object? to = (ctx.data as Map)['to'];
      final Object? rate = (ctx.data as Map)['rate'];
      return LogicCurrencyWidget(
        title: title is String ? title : 'Currency',
        from: from is String ? from : 'USD',
        to: to is String ? to : 'EUR',
        rate: rate is num ? rate.toDouble() : 0.92,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicCurrency","title":"USD->EUR",
  "from":"USD","to":"EUR","rate":0.92}
]''',
    ],
  );
}

const Map<String, String> _sym = {
  'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'CAD': 'C\$',
  'AUD': 'A\$', 'CHF': 'Fr', 'CNY': '¥', 'BTC': '₿', 'ETH': 'Ξ',
};

class LogicCurrencyWidget extends StatefulWidget {
  const LogicCurrencyWidget({
    super.key,
    required this.title,
    required this.from,
    required this.to,
    required this.rate,
  });
  final String title;
  final String from;
  final String to;
  final double rate;
  @override
  State<LogicCurrencyWidget> createState() => _LogicCurrencyWidgetState();
}

class _LogicCurrencyWidgetState extends State<LogicCurrencyWidget> {
  final TextEditingController _c = TextEditingController(text: '1');
  bool _flip = false;
  double _out = 0;

  String _f(String s) => _sym[s.toUpperCase()] ?? s.toUpperCase();

  void _convert([String? _]) {
    final double? v = double.tryParse(_c.text.trim());
    setState(() {
      _out = v == null
          ? 0
          : (_flip ? v / widget.rate : v * widget.rate);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String a = _flip ? widget.to : widget.from;
    final String b = _flip ? widget.from : widget.to;
    final double rate = _flip ? 1 / widget.rate : widget.rate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('1 ${_f(a)} = ${rate.toStringAsFixed(4)} ${_f(b)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                        labelText: _f(a), isDense: true),
                    onSubmitted: _convert,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _flip = !_flip),
                  icon: const Icon(Icons.swap_horiz),
                ),
                SizedBox(
                  width: 120,
                  child: Text('${_out.toStringAsFixed(4)} ${_f(b)}',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child:
                  FilledButton(onPressed: _convert, child: const Text('Convert')),
            ),
          ],
        ),
      ),
    );
  }
}
