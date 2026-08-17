// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Countdown timer to a target timestamp (the model can set a goal date).
final class LogicCountdown {
  static final catalogItem = CatalogItem(
    name: 'LogicCountdown',
    dataSchema: S.object(
      description: 'Countdown to a target date/time.',
      properties: {
        'title': S.string(),
        'target': S.string(
            description: 'ISO-8601 target datetime, e.g. 2026-12-31T23:59:00Z'),
      },
      required: ['title', 'target'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? target = (ctx.data as Map)['target'];
      final DateTime? t =
          target is String ? DateTime.tryParse(target) : null;
      return LogicCountdownWidget(
          title: title is String ? title : 'Countdown', target: t);
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicCountdown","title":"New Year","target":"2026-12-31T23:59:00Z"}
]''',
    ],
  );
}

class LogicCountdownWidget extends StatefulWidget {
  const LogicCountdownWidget(
      {super.key, this.title = 'Countdown', this.target});
  final String title;
  final DateTime? target;
  @override
  State<LogicCountdownWidget> createState() => _LogicCountdownWidgetState();
}

class _LogicCountdownWidgetState extends State<LogicCountdownWidget> {
  Timer? _ticker;
  DateTime _target = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    if (widget.target != null) {
      _target = widget.target!;
    } else {
      // fallback: 7 days from now (still visibly ticking)
      _target = DateTime.now().add(const Duration(days: 7));
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Duration left = _target.difference(DateTime.now());
    final bool expired = left.isNegative;
    final Duration d = expired ? Duration.zero : left;
    final String dd = d.inDays.toString().padLeft(2, '0');
    final String hh = (d.inHours % 24).toString().padLeft(2, '0');
    final String mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String ss = (d.inSeconds % 60).toString().padLeft(2, '0');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (expired)
              Center(
                child: Text('Time reached 🎉',
                    style: Theme.of(context).textTheme.titleLarge),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Unit(label: 'days', value: dd),
                  _Unit(label: 'hours', value: hh),
                  _Unit(label: 'min', value: mm),
                  _Unit(label: 'sec', value: ss),
                ],
              ),
            const SizedBox(height: 12),
            Center(
              child: Text('Target: ${_fmtTarget()}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTarget() {
    final DateTime t = _target.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}

class _Unit extends StatelessWidget {
  const _Unit({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w300,
                fontFeatures: [FontFeature.tabularFigures()])),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
