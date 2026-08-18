// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A typing-speed test: the user types a phrase while correctness is
/// highlighted live, then gets WPM and accuracy once the phrase is finished.
final class LogicTypingSpeed {
  static final catalogItem = CatalogItem(
    name: 'LogicTypingSpeed',
    dataSchema: S.object(
      description: 'Typing speed test (WPM + accuracy).',
      properties: {
        'title': S.string(),
        'text': S.string(
          description: 'Optional target phrase to type; a random pangram is '
              'picked when omitted.',
        ),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? text = (ctx.data as Map)['text'];
      return LogicTypingSpeedWidget(
        title: title is String ? title : 'Typing Test',
        text: text is String && text.isNotEmpty ? text : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTypingSpeed","title":"Typing Test"}
]''',
      () => '''
[
 {"id":"root","component":"LogicTypingSpeed","title":"Pangram","text":"The quick brown fox jumps over the lazy dog."}
]''',
    ],
  );
}

class LogicTypingSpeedWidget extends StatefulWidget {
  const LogicTypingSpeedWidget({
    super.key,
    this.title = 'Typing Test',
    this.text,
  });

  /// The widget heading.
  final String title;

  /// Optional fixed target phrase. When null or empty, a random pangram from
  /// [_LogicTypingSpeedWidgetState._defaults] is chosen per run.
  final String? text;

  @override
  State<LogicTypingSpeedWidget> createState() =>
      _LogicTypingSpeedWidgetState();
}

class _LogicTypingSpeedWidgetState extends State<LogicTypingSpeedWidget> {
  static const List<String> _defaults = [
    'The quick brown fox jumps over the lazy dog.',
    'Pack my box with five dozen liquor jugs.',
    'How razorback-jumping frogs can level six piqued gymnasts!',
    'Sphinx of black quartz, judge my vow.',
    'Crazy Fredericka bought many very exquisite opal jewels.',
  ];

  static const Duration _tick = Duration(milliseconds: 100);

  final math.Random _rng = math.Random();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  late String _target;
  Duration _elapsed = Duration.zero;
  DateTime? _startAt;
  Timer? _timer;
  bool _started = false;
  bool _done = false;
  int _errors = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _target = _pickTarget();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _pickTarget() {
    final String? fixed = widget.text;
    if (fixed != null && fixed.isNotEmpty) return fixed;
    return _defaults[_rng.nextInt(_defaults.length)];
  }

  void _onChanged(String value) {
    if (_done) return;
    final DateTime now = DateTime.now();
    if (!_started) {
      _started = true;
      _startAt = now;
      _timer = Timer.periodic(_tick, (_) {
        if (!mounted || !_started || _done) return;
        setState(() => _elapsed = DateTime.now().difference(_startAt!));
      });
    }
    final bool finished = value.length >= _target.length;
    setState(() {
      if (value.isNotEmpty) {
        final int idx = value.length - 1;
        if (idx < _target.length &&
            value.codeUnitAt(idx) != _target.codeUnitAt(idx)) {
          _errors++;
        }
      }
      if (finished) _done = true;
    });
    if (finished) {
      _timer?.cancel();
      _elapsed = DateTime.now().difference(_startAt!);
    }
  }

  void _restart() {
    _timer?.cancel();
    _controller.clear();
    setState(() {
      _target = _pickTarget();
      _started = false;
      _done = false;
      _errors = 0;
      _elapsed = Duration.zero;
      _startAt = null;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final String typed = _controller.text;
    final int correct = _correctCount(typed);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TargetLine(target: _target, typed: typed),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_done,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: _done
                    ? 'Finished!'
                    : 'Start typing here…',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time ${_formatDuration(_elapsed)}',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('Errors $_errors',
                    style: Theme.of(context).textTheme.bodyMedium),
                if (_started)
                  Text.rich(
                    TextSpan(
                      text: '${typed.isEmpty ? 0 : correct * 100 ~/ typed.length}% ',
                      children: const [TextSpan(text: 'accuracy')],
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
            if (_done) ...[
              const SizedBox(height: 12),
              _ResultPanel(
                wpm: _wpm(correct),
                accuracy: typed.isEmpty ? 0 : correct * 100 / typed.length,
                elapsed: _elapsed,
                errors: _errors,
              ),
              const SizedBox(height: 12),
              Center(
                child: FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _correctCount(String typed) {
    int correct = 0;
    final int n = typed.length < _target.length ? typed.length : _target.length;
    for (var i = 0; i < n; i++) {
      if (typed.codeUnitAt(i) == _target.codeUnitAt(i)) correct++;
    }
    return correct;
  }

  double _wpm(int correct) {
    // Standard typing metric: one "word" is 5 characters.
    final double words = correct / 5;
    final double minutes = _elapsed.inMilliseconds / 60000;
    if (minutes <= 0) return 0;
    return words / minutes;
  }
}

class _TargetLine extends StatelessWidget {
  const _TargetLine({required this.target, required this.typed});

  final String target;
  final String typed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < target.length; i++)
            Text(
              target[i] == ' ' ? '\u00A0' : target[i],
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
                decoration: i == typed.length
                    ? TextDecoration.underline
                    : null,
                decorationThickness: 2,
                color: i < typed.length
                    ? (typed[i] == target[i]
                        ? Colors.green.shade700
                        : Colors.red.shade600)
                    : Colors.black45,
                backgroundColor:
                    i == typed.length ? Colors.amber.shade200 : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.wpm,
    required this.accuracy,
    required this.elapsed,
    required this.errors,
  });

  final double wpm;
  final double accuracy;
  final Duration elapsed;
  final int errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(label: 'WPM', value: wpm.toStringAsFixed(0)),
          _Metric(
              label: 'Accuracy',
              value: '${accuracy.toStringAsFixed(0)}%'),
          _Metric(label: 'Time', value: _formatDuration2(elapsed)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  final int seconds = d.inSeconds;
  final int tenths = (d.inMilliseconds % 1000) ~/ 100;
  return '$seconds.${tenths}s';
}

String _formatDuration2(Duration d) {
  final int seconds = d.inSeconds;
  return '${seconds ~/ 60}m ${seconds % 60}s';
}
