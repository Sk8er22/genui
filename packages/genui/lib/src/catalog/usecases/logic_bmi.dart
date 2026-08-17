// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// BMI calculator: height (cm) + weight (kg) -> BMI + category.
final class LogicBmi {
  static final catalogItem = CatalogItem(
    name: 'LogicBmi',
    dataSchema: S.object(
      description: 'Body-mass-index calculator.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicBmiWidget(title: title is String ? title : 'BMI');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicBmi","title":"BMI"}
]''',
    ],
  );
}

class LogicBmiWidget extends StatefulWidget {
  const LogicBmiWidget({super.key, this.title = 'BMI'});
  final String title;
  @override
  State<LogicBmiWidget> createState() => _LogicBmiWidgetState();
}

class _LogicBmiWidgetState extends State<LogicBmiWidget> {
  final TextEditingController _height = TextEditingController(text: '170');
  final TextEditingController _weight = TextEditingController(text: '65');
  double? _bmi;

  void _compute() {
    final double? h = double.tryParse(_height.text.trim());
    final double? w = double.tryParse(_weight.text.trim());
    if (h == null || w == null || h <= 0) {
      setState(() => _bmi = null);
      return;
    }
    final double m = h / 100;
    setState(() => _bmi = w / (m * m));
  }

  String _category(double b) {
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
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
            const SizedBox(height: 12),
            TextField(
              controller: _height,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Height (cm)', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg)', isDense: true),
            ),
            const SizedBox(height: 12),
            if (_bmi != null) ...[
              Text(
                'BMI: ${_bmi!.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text('Category: ${_category(_bmi!)}',
                  style: Theme.of(context).textTheme.titleMedium),
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
