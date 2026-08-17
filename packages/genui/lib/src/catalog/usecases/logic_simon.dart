// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Simon — watch and repeat an ever-growing sequence of colored buttons.
final class LogicSimon {
  static final catalogItem = CatalogItem(
    name: 'LogicSimon',
    dataSchema: S.object(
      description: 'Simon memory game: repeat the growing sequence.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicSimonWidget(title: title is String ? title : 'Simon');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSimon","title":"Simon"}
]''',
    ],
  );
}

class LogicSimonWidget extends StatefulWidget {
  const LogicSimonWidget({super.key, this.title = 'Simon'});
  final String title;
  @override
  State<LogicSimonWidget> createState() => _LogicSimonWidgetState();
}

class _LogicSimonWidgetState extends State<LogicSimonWidget> {
  static const List<Color> _colors = [
    Colors.red, Colors.green, Colors.blue, Colors.amber,
  ];
  final math.Random _rng = math.Random();
  final List<int> _seq = [];
  int _step = 0;
  int _showIndex = 0;
  bool _playing = true; // true = showing sequence, false = user's turn
  String _status = 'Watch the sequence';
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    _seq.clear();
    _step = 0;
    _add();
    _playSequence();
  }

  void _add() => _seq.add(_rng.nextInt(4));

  Future<void> _playSequence() async {
    setState(() {
      _playing = true;
      _status = 'Watch';
    });
    for (final int idx in _seq) {
      setState(() => _showIndex = idx);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      setState(() => _showIndex = -1);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    setState(() {
      _playing = false;
      _step = 0;
      _status = 'Your turn';
    });
  }

  void _press(int idx) {
    if (_playing) return;
    setState(() {
      if (_seq[_step] == idx) {
        _step++;
        if (_step == _seq.length) {
          _status = 'Correct! +1';
          _add();
          _playSequence();
        }
      } else {
        _status = 'Wrong! Score ${_seq.length - 1}';
        _playing = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                Text('len ${_seq.length}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(_status, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: 4,
                itemBuilder: (context, i) {
                  final bool lit = _showIndex == i;
                  return GestureDetector(
                    onTap: () => _press(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: lit
                            ? _colors[i].withValues(alpha: 1)
                            : _colors[i].withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(child: TextButton(
                onPressed: () => setState(_start), child: const Text('Restart'))),
          ],
        ),
      ),
    );
  }
}
