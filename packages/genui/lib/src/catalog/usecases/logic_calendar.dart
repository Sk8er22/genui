// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// An inline monthly calendar: the model can set the starting year, month and
/// a pre-selected day; the user flips months with the arrows (or jumps to
/// today) and taps a day to select it. The chosen date is shown as YYYY-MM-DD.
///
/// Useful whenever a visible calendar context is needed — booking a date,
/// choosing a deadline, or answering "what day is that?".
final class LogicCalendar {
  static final catalogItem = CatalogItem(
    name: 'LogicCalendar',
    dataSchema: S.object(
      description:
          'Inline monthly calendar with day selection and month navigation.',
      properties: {
        'title': S.string(description: 'Calendar label.'),
        'year': S.integer(description: 'Starting year (defaults to today).'),
        'month': S.integer(description: 'Starting month, 1-12 (defaults to today).'),
        'selectedDay': S.integer(description: 'Pre-selected day of the month.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? year = (ctx.data as Map)['year'];
      final Object? month = (ctx.data as Map)['month'];
      final Object? day = (ctx.data as Map)['selectedDay'];
      return LogicCalendarWidget(
        title: title is String ? title : 'Calendar',
        year: year is int ? year : null,
        month: month is int ? month : null,
        selectedDay: day is int ? day : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicCalendar","title":"Pick a date",
  "year":2025,"month":6,"selectedDay":15}
]''',
      () => '''
[
 {"id":"root","component":"LogicCalendar","title":"Calendar"}
]''',
    ],
  );
}

class LogicCalendarWidget extends StatefulWidget {
  const LogicCalendarWidget({
    super.key,
    this.title = 'Calendar',
    this.year,
    this.month,
    this.selectedDay,
  });
  final String title;

  /// Starting year shown; defaults to the current year.
  final int? year;

  /// Starting month shown (1-12); defaults to the current month.
  final int? month;

  /// Day of the starting month that starts selected; defaults to today.
  final int? selectedDay;
  @override
  State<LogicCalendarWidget> createState() => _LogicCalendarWidgetState();
}

class _LogicCalendarWidgetState extends State<LogicCalendarWidget> {
  static const int _minYear = 1900;
  static const int _maxYear = 2100;

  late int _viewYear;
  late int _viewMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _viewYear = widget.year ?? now.year;
    _viewMonth = widget.month ?? now.month;
    // Interpret the initial day within the starting view month (never another
    // month), clamping e.g. "31st" for a 30-day month.
    final int daysInViewMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final int initialDay =
        (widget.selectedDay ?? now.day).clamp(1, daysInViewMonth).toInt();
    _selected = DateTime(_viewYear, _viewMonth, initialDay);
  }

  bool get _canGoPrev => _viewYear > _minYear || _viewMonth > 1;
  bool get _canGoNext =>
      _viewYear < _maxYear || (_viewYear == _maxYear && _viewMonth < 12);

  /// Month navigation that never leaves the supported range and keeps the
  /// view anchored even across year boundaries.
  void _shiftMonth(int delta) {
    final DateTime target = DateTime(
        _viewYear, _viewMonth + delta, 1); // Dart normalizes overflowing months.
    if (target.year < _minYear || target.year > _maxYear) return;
    setState(() {
      _viewYear = target.year;
      _viewMonth = target.month;
    });
  }

  void _goToday() {
    final DateTime now = DateTime.now();
    setState(() {
      _viewYear = now.year;
      _viewMonth = now.month;
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  void _pickDay(int day) {
    setState(() => _selected = DateTime(_viewYear, _viewMonth, day));
  }

  /// True when [day] is the day that is currently selected in the shown month.
  bool _isSelected(int day) =>
      _selected.year == _viewYear &&
      _selected.month == _viewMonth &&
      _selected.day == day;

  @override
  Widget build(BuildContext context) {
    // Sunday-first grid: DateTime.weekday is 1 (Mon)..7 (Sun), so % 7 maps
    // Sun=0, Mon=1, ..., Sat=6 — the number of leading blank cells.
    final int firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday % 7;
    final int daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final DateTime now = DateTime.now();
    final bool isCurrentMonth =
        now.year == _viewYear && now.month == _viewMonth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(_format(_selected),
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _canGoPrev ? () => _shiftMonth(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Text(
                    '${_monthName(_viewMonth)} $_viewYear',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _canGoNext ? () => _shiftMonth(1) : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final String label in const [
                  'S', 'M', 'T', 'W', 'T', 'F', 'S',
                ])
                  Expanded(
                    child: Center(
                      child: Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            for (var week = 0; week * 7 - firstWeekday < daysInMonth; week++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _dayCell(
                        context,
                        day: week * 7 + col - firstWeekday + 1,
                        isToday: isCurrentMonth &&
                            week * 7 + col - firstWeekday + 1 == now.day,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _goToday,
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Today'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(BuildContext context,
      {required int day, required bool isToday}) {
    final bool inMonth = day >= 1 && day <= _daysInShownMonth();
    final ThemeData theme = Theme.of(context);
    if (!inMonth) {
      // Keep the grid aligned by reserving space for out-of-month cells.
      return const SizedBox(height: 34);
    }
    final bool selected = _isSelected(day);
    final ColorScheme scheme = theme.colorScheme;
    return SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: selected ? scheme.primary : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: isToday && !selected
                ? BorderSide(color: scheme.primary, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _pickDay(day),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  color: selected
                      ? scheme.onPrimary
                      : isToday
                          ? scheme.primary
                          : theme.textTheme.bodyMedium?.color,
                  fontWeight:
                      isToday || selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _daysInShownMonth() => DateTime(_viewYear, _viewMonth + 1, 0).day;

  static String _monthName(int m) => const {
        1: 'January', 2: 'February', 3: 'March', 4: 'April', 5: 'May',
        6: 'June', 7: 'July', 8: 'August', 9: 'September', 10: 'October',
        11: 'November', 12: 'December',
      }[m]!;

  static String _format(DateTime d) {
    String p(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)}';
  }
}
