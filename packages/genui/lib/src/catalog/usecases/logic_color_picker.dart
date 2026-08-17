// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A color picker: HSV sliders that return the picked color as a hex string
/// (and hand it back via an optional event context). The model can preset an
/// initial color ("pick the accent color").
final class LogicColorPicker {
  static final catalogItem = CatalogItem(
    name: 'LogicColorPicker',
    dataSchema: S.object(
      description: 'Pick a color; returns its hex value.',
      properties: {
        'title': S.string(),
        'initial': S.string(description: 'Initial hex color (e.g. #4ECDC4).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? initial = (ctx.data as Map)['initial'];
      return LogicColorPickerWidget(
        title: title is String ? title : 'Color',
        initial: initial is String ? _parse(initial) : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicColorPicker","title":"Accent","initial":"#4ECDC4"}
]''',
    ],
  );

  static Color? _parse(String hex) {
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
}

class LogicColorPickerWidget extends StatefulWidget {
  const LogicColorPickerWidget(
      {super.key, required this.title, this.initial});
  final String title;
  final Color? initial;
  @override
  State<LogicColorPickerWidget> createState() => _LogicColorPickerWidgetState();
}

class _LogicColorPickerWidgetState extends State<LogicColorPickerWidget> {
  late double _hue;
  late double _sat;
  late double _val;

  @override
  void initState() {
    super.initState();
    final Color c = widget.initial ?? Colors.teal;
    final (double h, double s, double v) = _toHsv(c);
    _hue = h;
    _sat = s;
    _val = v;
  }

  (double, double, double) _toHsv(Color c) {
    final double r = c.r, g = c.g, b = c.b;
    final double max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final double min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final double d = max - min;
    double h = 0;
    if (d != 0) {
      if (max == r) h = ((g - b) / d) % 6;
      else if (max == g) h = (b - r) / d + 2;
      else h = (r - g) / d + 4;
      h *= 60;
      if (h < 0) h += 360;
    }
    final double s = max == 0 ? 0 : d / max;
    return (h, s, max);
  }

  Color get _color {
    final Color c = HSVColor.fromAHSV(1, _hue, _sat, _val).toColor();
    return c;
  }

  String get _hex {
    final Color c = _color;
    String h(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${h((c.r * 255).round())}${h((c.g * 255).round())}'
        '${h((c.b * 255).round())}';
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
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Center(
                child: Text(
                  _hex,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _val > 0.6 ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SliderRow(
              label: 'Hue',
              value: _hue,
              max: 360,
              onChange: (v) => setState(() => _hue = v),
            ),
            _SliderRow(
              label: 'Saturation',
              value: _sat,
              max: 1,
              onChange: (v) => setState(() => _sat = v),
            ),
            _SliderRow(
              label: 'Brightness',
              value: _val,
              max: 1,
              onChange: (v) => setState(() => _val = v),
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
    required this.value,
    required this.max,
    required this.onChange,
  });
  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChange;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(0, max),
            max: max,
            onChanged: onChange,
          ),
        ),
      ],
    );
  }
}
