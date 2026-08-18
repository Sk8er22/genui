// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A slot machine: spin three reels, matching symbols pay out credits.
final class LogicSlots {
  static final catalogItem = CatalogItem(
    name: 'LogicSlots',
    dataSchema: S.object(
      description: 'Slot machine with three reels and credit payouts.',
      properties: {
        'title': S.string(),
        'credits': S.integer(description: 'Starting credits.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? credits = (ctx.data as Map)['credits'];
      return LogicSlotsWidget(
        title: title is String ? title : 'Slots',
        credits: credits is int && credits > 0 ? credits : 10,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSlots","title":"Lucky 777","credits":10}
]''',
    ],
  );
}

/// The symbols that can appear on a reel.
const List<String> _symbols = ['7', '💎', '🔔', '⭐', '🍒', '🍋'];

/// Payout multiple for three of a kind, per symbol.
const Map<String, int> _triplePayouts = {
  '7': 50,
  '💎': 30,
  '🔔': 20,
  '⭐': 15,
  '🍒': 10,
  '🍋': 5,
};

class LogicSlotsWidget extends StatefulWidget {
  const LogicSlotsWidget({super.key, this.title = 'Slots', this.credits = 10});
  final String title;
  final int credits;

  @override
  State<LogicSlotsWidget> createState() => _LogicSlotsWidgetState();
}

class _LogicSlotsWidgetState extends State<LogicSlotsWidget> {
  final math.Random _rng = math.Random();
  late List<String> _reels;
  late int _credits;
  bool _spinning = false;
  Timer? _timer;
  int _tick = 0;
  int? _lastPayout;

  @override
  void initState() {
    super.initState();
    _credits = widget.credits;
    _reels = [for (var i = 0; i < 3; i++) _randomSymbol()];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _randomSymbol() => _symbols[_rng.nextInt(_symbols.length)];

  void _spin() {
    if (_spinning || _credits <= 0) return;
    setState(() {
      _spinning = true;
      _lastPayout = null;
      _credits -= 1;
    });
    _timer?.cancel();
    _ticker();
  }

  /// Advances the reels; after a fixed number of ticks, settles the result.
  void _ticker() {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _tick++;
      setState(() {
        for (var i = 0; i < 3; i++) {
          _reels[i] = _randomSymbol();
        }
      });
      if (_tick >= 10) {
        _timer?.cancel();
        _settle();
      }
    });
  }

  void _settle() {
    final String a = _reels[0];
    final String b = _reels[1];
    final String c = _reels[2];
    int payout;
    if (a == b && b == c) {
      payout = _triplePayouts[a] ?? 0;
    } else if (a == b || a == c || b == c) {
      payout = 2; // any pair pays 2x.
    } else {
      payout = 0;
    }
    setState(() {
      _credits += payout;
      _lastPayout = payout;
      _spinning = false;
      _tick = 0;
    });
  }

  bool get _locked => _spinning || _credits <= 0;

  @override
  Widget build(BuildContext context) {
    final int? payout = _lastPayout;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Center(child: _reelRow()),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Credits: $_credits',
                    style: Theme.of(context).textTheme.titleMedium),
                if (payout != null)
                  Text(
                    payout > 0 ? 'You win $payout!' : 'No win',
                    style: TextStyle(
                      color: payout > 0 ? Colors.green.shade700 : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: FilledButton.icon(
                onPressed: _locked ? null : _spin,
                icon: const Icon(Icons.casino_outlined),
                label: Text(_credits <= 0 ? 'Out of credits' : 'Spin (1)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reelRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in _reels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: s == '7' ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
