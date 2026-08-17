// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Natal / birth chart — computes the Western zodiac sun sign (+ optional
/// element/mode) from a given date. Pure-Dart astrology logic; deterministic.
final class LogicBirthChart {
  static final _schema = S.object(
    description: 'Birth chart: compute sun sign from a date.',
    properties: {
      'title': S.string(description: 'Chart label.'),
      'date': S.string(description: 'Birth date as YYYY-MM-DD, else today.'),
    },
    required: ['title'],
  );

  static final catalogItem = CatalogItem(
    name: 'LogicBirthChart',
    dataSchema: _schema,
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? date = (ctx.data as Map)['date'];
      return LogicBirthChartWidget(
        title: title is String ? title : 'Birth chart',
        date: date is String ? date : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicBirthChart","title":"Natal chart","date":"1990-08-17"}
]''',
    ],
  );
}

class BirthSign {
  const BirthSign(this.name, this.dateRange, this.element, this.mode);
  final String name;
  final String dateRange;
  final String element;
  final String mode;
}

final List<BirthSign> _signs = _buildSigns();

List<BirthSign> _buildSigns() => const [
      BirthSign('Capricorn', 'Dec 22 – Jan 19', 'Earth', 'Cardinal'),
      BirthSign('Aquarius', 'Jan 20 – Feb 18', 'Air', 'Fixed'),
      BirthSign('Pisces', 'Feb 19 – Mar 20', 'Water', 'Mutable'),
      BirthSign('Aries', 'Mar 21 – Apr 19', 'Fire', 'Cardinal'),
      BirthSign('Taurus', 'Apr 20 – May 20', 'Earth', 'Fixed'),
      BirthSign('Gemini', 'May 21 – Jun 20', 'Air', 'Mutable'),
      BirthSign('Cancer', 'Jun 21 – Jul 22', 'Water', 'Cardinal'),
      BirthSign('Leo', 'Jul 23 – Aug 22', 'Fire', 'Fixed'),
      BirthSign('Virgo', 'Aug 23 – Sep 22', 'Earth', 'Mutable'),
      BirthSign('Libra', 'Sep 23 – Oct 22', 'Air', 'Cardinal'),
      BirthSign('Scorpio', 'Oct 23 – Nov 21', 'Water', 'Fixed'),
      BirthSign('Sagittarius', 'Nov 22 – Dec 21', 'Fire', 'Mutable'),
    ];

/// Day-of-month cutoffs for each sign (month index from 0..11 -> sign of that
/// month when day >= cutoff, else the previous sign).
const List<int> _cutoffs = [
  20, // Jan -> Aquarius (20+)
  19, // Feb -> Pisces (19+)
  21, // Mar -> Aries
  20, // Apr -> Taurus
  21, // May -> Gemini
  21, // Jun -> Cancer
  23, // Jul -> Leo
  23, // Aug -> Virgo
  23, // Sep -> Libra
  23, // Oct -> Scorpio
  22, // Nov -> Sagittarius
  22, // Dec -> Capricorn
];

/// Returns the [BirthSign] for a (month 1-12, day 1-31).
BirthSign signFor(int month, int day) {
  if (month < 1 || month > 12) return _signs.first;
  // signs list is ordered Capricorn..Sagittarius => index shift:
  // month index 0 (Jan) -> cutoffs index 0 (Aquarius region).
  if (day >= _cutoffs[month - 1]) {
    // The sign that starts this month is at (month index + 1) mod 12 in the
    // Capricorn-first list.
    final int idx = (month) % 12;
    return _signs[idx];
  }
  return _signs[(month - 1 + 11) % 12];
}

class LogicBirthChartWidget extends StatefulWidget {
  const LogicBirthChartWidget({super.key, required this.title, this.date});
  final String title;
  final String? date;
  @override
  State<LogicBirthChartWidget> createState() => _LogicBirthChartWidgetState();
}

class _LogicBirthChartWidgetState extends State<LogicBirthChartWidget> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final DateTime? parsed = widget.date == null
        ? null
        : DateTime.tryParse(widget.date!);
    _date = parsed ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final BirthSign sign = signFor(_date.month, _date.day);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-'
                      '${_date.day.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blueGrey.shade100,
              child: Text(sign.name.substring(0, 1),
                  style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 12),
            Text(sign.name, style: Theme.of(context).textTheme.titleLarge),
            Text('${sign.dateRange}  •  ${sign.element}  •  ${sign.mode}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(sign.element)),
                Chip(label: Text(sign.mode)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
