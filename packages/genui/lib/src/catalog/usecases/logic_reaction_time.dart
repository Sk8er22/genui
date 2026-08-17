// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Reaction timer: tap when the screen turns green; measures latency.
/// Average + best over several rounds.
final class LogicReactionTime {
  static final catalogItem = CatalogItem(
    name: 'LogicReactionTime',
    dataSchema: S.object(
      description: 'Measure your reaction time.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicReactionTimeWidget(
          title: title is String ? title : 'Reaction time');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicReactionTime","title":"Reaction"}
]''',
    ],
  );
}

class LogicReactionTimeWidget extends StatefulWidget {
  const LogicReactionTimeWidget({super.key, this.title = 'Reaction'});
  final String title;
  @override
  State<LogicReactionTimeWidget> createState() =>
      _LogicReactionTimeWidgetState();
}

class _LogicReactionTimeWidgetState extends State<LogicReactionTimeWidget> {
  final math.Random _rng = math.Random();
  String _state = 'waiting'; // ready | waiting | go | result
  final Stopwatch _sw = Stopwatch();
  final List<int> _samples = [];
  Timer? _t;
  int _round = 0;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _startRound() {
    setState(() => _state = 'ready');
    _t?.cancel();
    _t = Timer(Duration(milliseconds: 800 + _rng.nextInt(2500)), () {
      if (mounted) {
        setState(() => _state = 'go');
        _sw..reset()..start();
      }
    });
  }

  void _tap() {
    if (_state == 'go') {
      final int ms = _sw.elapsedMilliseconds;
      _samples.add(ms);
      _round++;
      setState(() => _state = 'result');
      _t = Timer(const Duration(seconds: 1), () {
        if (mounted) _startRound();
      });
    } else if (_state == 'waiting') {
      _startRound();
    } else if (_state == 'ready') {
      // waited too early
    }
  }

  int? get _avg => _samples.isEmpty
      ? null
      : (_samples.reduce((a, b) => a + b) ~/ _samples.length);
  int? get _best => _samples.isEmpty ? null : _samples.reduce(math.min);

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (_state) {
      case 'ready':
        bg = Colors.red.shade400;
        label = 'Wait for green…';
      case 'go':
        bg = Colors.green.shade400;
        label = 'TAP!';
      case 'result':
        bg = Colors.blueGrey.shade300;
        label = '${_samples.last} ms';
      default:
        bg = Colors.grey.shade300;
        label = 'Tap to start';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('avg: ${_avg ?? '–'} ms • best: ${_best ?? '–'} ms',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _tap,
              child: Container(
                width: double.infinity,
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(label,
                    style: const TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Round $_round',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
