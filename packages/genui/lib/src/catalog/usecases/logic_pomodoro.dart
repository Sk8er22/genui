// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Pomodoro timer: work/break cycles with a session counter. The model sets
/// work minutes + break minutes.
final class LogicPomodoro {
  static final catalogItem = CatalogItem(
    name: 'LogicPomodoro',
    dataSchema: S.object(
      description: 'Pomodoro focus timer with work/break cycles.',
      properties: {
        'title': S.string(),
        'workMinutes': S.integer(description: 'Focus length in minutes.'),
        'breakMinutes': S.integer(description: 'Break length in minutes.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? w = (ctx.data as Map)['workMinutes'];
      final Object? b = (ctx.data as Map)['breakMinutes'];
      return LogicPomodoroWidget(
        title: title is String ? title : 'Pomodoro',
        workMinutes: w is int && w > 0 ? w : 25,
        breakMinutes: b is int && b > 0 ? b : 5,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPomodoro","title":"Focus",
  "workMinutes":25,"breakMinutes":5}
]''',
    ],
  );
}

class LogicPomodoroWidget extends StatefulWidget {
  const LogicPomodoroWidget({
    super.key,
    this.title = 'Pomodoro',
    this.workMinutes = 25,
    this.breakMinutes = 5,
  });
  final String title;
  final int workMinutes;
  final int breakMinutes;
  @override
  State<LogicPomodoroWidget> createState() => _LogicPomodoroWidgetState();
}

class _LogicPomodoroWidgetState extends State<LogicPomodoroWidget> {
  late Duration _left;
  bool _break = false;
  bool _running = false;
  int _doneSessions = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _left = Duration(minutes: widget.workMinutes);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_left.inSeconds <= 0) {
          _advance();
        } else {
          _left = _left - const Duration(seconds: 1);
        }
      });
    });
  }

  void _advance() {
    if (!_break) {
      _doneSessions++;
      _break = true;
      _left = Duration(minutes: widget.breakMinutes);
    } else {
      _break = false;
      _left = Duration(minutes: widget.workMinutes);
    }
  }

  void _stopReset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _break = false;
      _left = Duration(minutes: widget.workMinutes);
    });
  }

  String get _label {
    final int m = _left.inMinutes;
    final int s = _left.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                Chip(
                  label: Text(_break ? 'Break' : 'Focus'),
                  backgroundColor:
                      _break ? Colors.teal.shade100 : Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _label,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Sessions completed: $_doneSessions',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _stopReset,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  iconSize: 40,
                  onPressed: _toggle,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
