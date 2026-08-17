// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A unit converter — the model can supply any (title, from-unit, to-unit,
/// factor) triple so arbitrary conversions (e.g. cm<->in, °C<->°F) work live.
final class LogicUnitConverter {
  static final catalogItem = CatalogItem(
    name: 'LogicUnitConverter',
    dataSchema: S.object(
      description: 'Convert a value between two units by a factor/offset.',
      properties: {
        'title': S.string(),
        'from': S.string(description: 'From unit label, e.g. "cm".'),
        'to': S.string(description: 'To unit label, e.g. "in".'),
        'factor': S.number(description: 'Multiplicative factor (from->base).'),
        'offset': S.number(description: 'Additive offset (from->base).'),
      },
      required: ['title', 'from', 'to', 'factor'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? from = (ctx.data as Map)['from'];
      final Object? to = (ctx.data as Map)['to'];
      final Object? factor = (ctx.data as Map)['factor'];
      final Object? offset = (ctx.data as Map)['offset'];
      return LogicUnitConverterWidget(
        title: title is String ? title : 'Convert',
        fromLabel: from is String ? from : 'cm',
        toLabel: to is String ? to : 'in',
        factor: factor is num ? factor.toDouble() : 1.0,
        offset: offset is num ? offset.toDouble() : 0.0,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicUnitConverter","title":"Length",
  "from":"cm","to":"in","factor":0.393701,"offset":0}
]''',
    ],
  );
}

class LogicUnitConverterWidget extends StatefulWidget {
  const LogicUnitConverterWidget({
    super.key,
    required this.title,
    required this.fromLabel,
    required this.toLabel,
    required this.factor,
    this.offset = 0,
  });
  final String title;
  final String fromLabel;
  final String toLabel;
  final double factor;
  final double offset;
  @override
  State<LogicUnitConverterWidget> createState() =>
      _LogicUnitConverterWidgetState();
}

class _LogicUnitConverterWidgetState extends State<LogicUnitConverterWidget> {
  final TextEditingController _c = TextEditingController();
  double _out = 0;

  void _convert([String? _]) {
    final double? v = double.tryParse(_c.text.trim());
    setState(() => _out = v == null ? 0 : (v + widget.offset) * widget.factor);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
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
            Text('${widget.fromLabel} → ${widget.toLabel}',
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
                      labelText: widget.fromLabel,
                      isDense: true,
                    ),
                    onSubmitted: _convert,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    '${_out.toStringAsFixed(4)} ${widget.toLabel}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _convert, child: const Text('Convert')),
            ),
          ],
        ),
      ),
    );
  }
}
