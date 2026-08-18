// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Tower of Hanoi: move all 4 disks from the leftmost rod to the rightmost
/// rod. Tap a rod to pick up its top disk, tap another rod to drop it there
/// when legal (empty rod or a smaller disk on top). Illegal drops are
/// rejected; the move counter only counts legal moves.
final class LogicTowerOfHanoi {
  static final catalogItem = CatalogItem(
    name: 'LogicTowerOfHanoi',
    dataSchema: S.object(
      description: 'Classic Tower of Hanoi puzzle with 4 disks.',
      properties: {
        'title': S.string(),
      },
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicTowerOfHanoiWidget(
        title: title is String ? title : 'Tower of Hanoi',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTowerOfHanoi","title":"Tower of Hanoi"}
]''',
    ],
  );
}

class LogicTowerOfHanoiWidget extends StatefulWidget {
  const LogicTowerOfHanoiWidget({super.key, this.title = 'Tower of Hanoi'});
  final String title;
  @override
  State<LogicTowerOfHanoiWidget> createState() =>
      _LogicTowerOfHanoiWidgetState();
}

class _LogicTowerOfHanoiWidgetState extends State<LogicTowerOfHanoiWidget> {
  static const int _diskCount = 4;
  static const int _rodCount = 3;

  /// `_rods[r]` holds the disk values on rod `r`, from bottom (largest) to
  /// top (smallest). The disk value is its width index (0 = smallest).
  late List<List<int>> _rods;
  int _moves = 0;
  bool _solved = false;

  /// The rod whose top disk is currently in hand, or null if nothing is
  /// picked up.
  int? _selectedRod;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    // Rod 0 starts with the full tower, biggest disk at the bottom.
    _rods = [
      [for (var d = _diskCount - 1; d >= 0; d--) d],
      <int>[],
      <int>[],
    ];
    _moves = 0;
    _solved = false;
    _selectedRod = null;
  }

  bool get _isSolved =>
      _rods[2].length == _diskCount &&
      _rods[0].isEmpty &&
      _rods[1].isEmpty;

  void _tapRod(int i) {
    if (_solved) return;
    setState(() {
      final int? from = _selectedRod;
      if (from == null) {
        // No disk in hand: pick up this rod's top disk, if it has one.
        if (_rods[i].isNotEmpty) _selectedRod = i;
        return;
      }
      if (from == i) {
        // Dropped on the same rod: simply put the disk back down.
        _selectedRod = null;
        return;
      }
      final int disk = _rods[from].last;
      final List<int> target = _rods[i];
      final bool legal = target.isEmpty || target.last > disk;
      if (!legal) return; // Illegal drop: rejected, disk stays in hand.
      target.add(disk);
      _rods[from].removeLast();
      _selectedRod = null;
      _moves++;
      _solved = _isSolved;
    });
  }

  double _diskWidth(int value) => 26 + value * 14;

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
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('moves: $_moves',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            if (_solved)
              Text(
                'Solved! in $_moves moves 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              )
            else
              Text('Move all disks to the rightmost rod.',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _rodCount; i++) _buildRod(i),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                  onPressed: _reset, child: const Text('Reset')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRod(int i) {
    final List<int> rod = _rods[i];
    // The selected disk is the top disk of the rod currently in hand.
    final bool selected = _selectedRod == i && rod.isNotEmpty;
    return Expanded(
      child: InkWell(
        onTap: _solved ? null : () => _tapRod(i),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Disks, smallest on top (render top-to-bottom by reversing
            // the bottom-to-top stored order). Widths scale with value.
            for (final int v in rod.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Container(
                  height: 24,
                  width: _diskWidth(v),
                  decoration: BoxDecoration(
                    color: selected && v == rod.last
                        ? Colors.amber.shade500
                        : Colors.indigo.shade400,
                    borderRadius: BorderRadius.circular(6),
                    border: selected && v == rod.last
                        ? Border.all(
                            color: Colors.deepOrange.shade800, width: 2)
                        : null,
                  ),
                ),
              ),
            // Peg base.
            Container(
              height: 8,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.brown.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
