// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Clock-reading practice: shows an analog clock and asks "what time is it?"
/// with multiple choice; the model can preset a minute/hour target.
final class LogicClockReading {
  static final catalogItem = CatalogItem(
    name: 'LogicClockReading',
    dataSchema: S.object(
      description: 'Practise reading an analog clock.',
      properties: {
        'title': S.string(),
        'hour': S.integer(description: 'Optional fixed hour (1..12).'),
        'minute': S.integer(description: 'Optional fixed minute (0,15,30,45).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? hour = (ctx.data as Map)['hour'];
      final Object? minute = (ctx.data as Map)['minute'];
      return LogicClockReadingWidget(
        title: title is String ? title : 'Clock',
        fixedHour: hour is int && hour >= 1 && hour <= 12 ? hour : null,
        fixedMinute:
            minute is int && [0, 15, 30, 45].contains(minute) ? minute : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicClockReading","title":"Clock",
  "hour":3,"minute":30}
]''',
    ],
  );
}

class LogicClockReadingWidget extends StatefulWidget {
  const LogicClockReadingWidget(
      {super.key, this.title = 'Clock', this.fixedHour, this.fixedMinute});
  final String title;
  final int? fixedHour;
  final int? fixedMinute;
  @override
  State<LogicClockReadingWidget> createState() =>
      _LogicClockReadingWidgetState();
}

class _LogicClockReadingWidgetState extends State<LogicClockReadingWidget> {
  final math.Random _rng = math.Random();
  late int _hour, _minute;
  int? _chosen;
  bool _shown = false;
  int _score = 0, _asked = 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _hour = widget.fixedHour ?? 1 + _rng.nextInt(12);
    _minute = widget.fixedMinute ??
        const [0, 15, 30, 45][_rng.nextInt(4)];
    _chosen = null;
    _shown = false;
  }

  String _label(int h, int m) {
    final int displayH = m > 0 && ((m % 60) != 0) ? (h % 12) + (m >= 45 ? 1 : 0) : h % 12;
    final int hh = (displayH == 0 ? 12 : displayH);
    final String mm = m == 0 ? "o'clock" : m == 15 ? 'quarter past' :
        m == 45 ? 'quarter to' : m == 30 ? 'half past' : '$m';
    if (mm == "o'clock") return '$hh ';
    if (mm == 'half past' || mm == 'quarter past') return '$mm $hh';
    if (mm == 'quarter to') return 'quarter to $hh';
    return '$hh:$mm';
  }

  void _pick(int i) {
    setState(() {
      _chosen = i;
      _asked++;
      if (i == _hour - 1) _score++;
      _shown = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // options: correct time + 2 distractors
    final int correctOpt = _hour - 1;
    final List<int> opts = [];
    while (opts.length < 3) {
      final int o = _rng.nextInt(12);
      if (o != correctOpt && !opts.contains(o)) opts.add(o);
    }
    opts.insert(_rng.nextInt(4), correctOpt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('$_score/$_asked',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: CustomPaint(
                size: const Size(180, 180),
                painter: _ClockPainter((_hour % 12) + (_minute >= 45 ? 1 : 0),
                    _minute),
              ),
            ),
            const SizedBox(height: 12),
            ...opts.map((o) => Card(
                  color: _shown && o == correctOpt
                      ? Colors.green.shade100
                      : _shown && o == _chosen
                          ? Colors.red.shade100
                          : null,
                  child: ListTile(
                    dense: true,
                    title: Text(_label(o + 1, _minute)),
                    onTap: _shown ? null : () => _pick(o),
                  ),
                )),
            if (_shown)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => setState(_next),
                    child: const Text('Next')),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.hour, this.minute);
  final int hour;
  final int minute;
  static const double _pi = 3.14159265358979;
  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2 - 6;
    final Paint face = Paint()..color = Colors.white;
    canvas.drawCircle(c, r, face);
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.black87);
    // hour ticks
    for (var h = 1; h <= 12; h++) {
      final double a = h * _pi / 6;
      final double x1 = c.dx + (r - 6) * math.cos(a - _pi / 2);
      final double y1 = c.dy + (r - 6) * math.sin(a - _pi / 2);
      final double x2 = c.dx + (r - 16) * math.cos(a - _pi / 2);
      final double y2 = c.dy + (r - 16) * math.sin(a - _pi / 2);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2),
          Paint()..color = Colors.black87..strokeWidth = 2);
    }
    // hands
    final double ha = (hour % 12) * _pi / 6 + minute * _pi / 360;
    final double ma = minute * _pi / 30;
    canvas.drawLine(c,
        c + Offset((r * 0.5) * math.cos(ha - _pi / 2),
            (r * 0.5) * math.sin(ha - _pi / 2)),
        Paint()..color = Colors.black87..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawLine(c,
        c + Offset((r * 0.78) * math.cos(ma - _pi / 2),
            (r * 0.78) * math.sin(ma - _pi / 2)),
        Paint()..color = Colors.red.shade400..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, 4, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.hour != hour || old.minute != minute;
}
