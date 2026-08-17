// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A stopwatch (or count-up timer) with lap. Pure-Dart/Flutter.
final class LogicStopwatch {
  static final catalogItem = CatalogItem(
    name: 'LogicStopwatch',
    dataSchema: S.object(
      description: 'Stopwatch with laps.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicStopwatchWidget(
          title: title is String ? title : 'Stopwatch');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicStopwatch","title":"Timer"}
]''',
    ],
  );
}

class LogicStopwatchWidget extends StatefulWidget {
  const LogicStopwatchWidget({super.key, this.title = 'Stopwatch'});
  final String title;
  @override
  State<LogicStopwatchWidget> createState() => _LogicStopwatchWidgetState();
}

class _LogicStopwatchWidgetState extends State<LogicStopwatchWidget> {
  Stopwatch _sw = Stopwatch();
  Timer? _ticker;
  final List<Duration> _laps = [];

  String get _elapsed => _fmt(_sw.elapsed);

  String _fmt(Duration d) {
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$m:$s.$ms';
  }

  void _toggle() {
    if (_sw.isRunning) {
      _sw.stop();
      _ticker?.cancel();
    } else {
      _sw.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 15), (_) {
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  void _lap() {
    if (_sw.isRunning) setState(() => _laps.insert(0, _sw.elapsed));
  }

  void _reset() {
    _sw.stop();
    _ticker?.cancel();
    setState(() {
      _sw = Stopwatch()..stop();
      _laps.clear();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
            Center(
              child: Text(
                _elapsed,
                style: const TextStyle(
                    fontSize: 44, fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  iconSize: 40,
                  onPressed: _toggle,
                  icon: Icon(_sw.isRunning ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: _lap,
                  icon: const Icon(Icons.flag),
                ),
              ],
            ),
            if (_laps.isNotEmpty) ...[
              const Divider(height: 24),
              ..._laps.take(8).toList().asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 32, child: Text('#${e.key + 1}')),
                        Text(_fmt(e.value)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
