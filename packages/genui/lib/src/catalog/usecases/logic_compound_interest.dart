// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Compound-interest calculator: principal, annual rate, years, compounding
/// frequency -> future value + earned interest. Updates live via sliders.
final class LogicCompoundInterest {
  static final catalogItem = CatalogItem(
    name: 'LogicCompoundInterest',
    dataSchema: S.object(
      description: 'Compound interest calculator.',
      properties: {'title': S.string(), 'years': S.integer()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? years = (ctx.data as Map)['years'];
      return LogicCompoundInterestWidget(
        title: title is String ? title : 'Compound Interest',
        initialYears: years is int && years > 0 ? years : 10,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicCompoundInterest","title":"Savings","years":10}
]''',
    ],
  );
}

class LogicCompoundInterestWidget extends StatefulWidget {
  const LogicCompoundInterestWidget({
    super.key,
    this.title = 'Compound Interest',
    this.initialYears = 10,
  });
  final String title;
  final int initialYears;

  @override
  State<LogicCompoundInterestWidget> createState() =>
      _LogicCompoundInterestWidgetState();
}

class _LogicCompoundInterestWidgetState extends State<LogicCompoundInterestWidget> {
  int _principal = 1000; // USD
  double _rate = 5; // % per year
  late int _years;
  int _perYear = 12; // compounding periods per year

  @override
  void initState() {
    super.initState();
    _years = widget.initialYears.clamp(1, 40).toInt();
  }

  double get _futureValue =>
      _principal * math.pow(1 + _rate / 100 / _perYear, _years * _perYear).toDouble();

  @override
  Widget build(BuildContext context) {
    final double fv = _futureValue;
    final double interest = fv - _principal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _SliderRow(
              label: 'Principal',
              valueLabel: '\$$_principal',
              value: _principal.toDouble(),
              min: 100,
              max: 100000,
              divisions: 999,
              onChanged: (v) => setState(() => _principal = v.round()),
            ),
            _SliderRow(
              label: 'Annual rate',
              valueLabel: '${_rate.toStringAsFixed(1)}%',
              value: _rate,
              min: 0,
              max: 20,
              divisions: 400,
              onChanged: (v) => setState(() => _rate = v),
            ),
            _SliderRow(
              label: 'Years',
              valueLabel: '$_years',
              value: _years.toDouble(),
              min: 1,
              max: 40,
              divisions: 39,
              onChanged: (v) => setState(() => _years = v.round()),
            ),
            _SliderRow(
              label: 'Compounds / year',
              valueLabel: '$_perYear',
              value: _perYear.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (v) => setState(() => _perYear = v.round()),
            ),
            const Divider(height: 24),
            Text(
              'Future value: \$${fv.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Interest earned: \$${interest.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
