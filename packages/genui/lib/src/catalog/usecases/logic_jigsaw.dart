// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A 3x3 sliding-tile jigsaw picture puzzle: tap a tile next to the empty
/// slot to slide it into place. Tracks moves, timer and win detection.
final class LogicJigsaw {
  static final catalogItem = CatalogItem(
    name: 'LogicJigsaw',
    dataSchema: S.object(
      description: 'Sliding-tile jigsaw puzzle.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicJigsawWidget(title: title is String ? title : 'Jigsaw');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicJigsaw","title":"Jigsaw"}
]''',
    ],
  );
}

const int _size = 3;
const int _count = _size * _size;

class LogicJigsawWidget extends StatefulWidget {
  const LogicJigsawWidget({super.key, this.title = 'Jigsaw'});
  final String title;
  @override
  State<LogicJigsawWidget> createState() => _LogicJigsawWidgetState();
}

class _LogicJigsawWidgetState extends State<LogicJigsawWidget> {
  final math.Random _rng = math.Random();
  late List<int> _board; // value 0 = empty slot, 1..8 = picture pieces
  late int _empty;
  int _moves = 0;
  int _seconds = 0;
  bool _playing = false; // timer started after first player move
  bool _won = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scramble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetClock() {
    _timer?.cancel();
    _seconds = 0;
    _moves = 0;
    _playing = false;
    _won = false;
  }

  void _scramble() {
    setState(() {
      _resetClock();
      _board = [for (var i = 1; i < _count; i++) i, 0]; // solved: 1..8, 0
      _empty = _count - 1;
      // Perform a long run of legal random moves so the board stays solvable.
      for (var s = 0; s < 200; s++) {
        final int r = _empty ~/ _size, c = _empty % _size;
        final List<(int, int)> nbr = [];
        if (r > 0) nbr.add((r - 1, c));
        if (r < _size - 1) nbr.add((r + 1, c));
        if (c > 0) nbr.add((r, c - 1));
        if (c < _size - 1) nbr.add((r, c + 1));
        final (int nr, int nc) = nbr[_rng.nextInt(nbr.length)];
        final int target = nr * _size + nc;
        _board[_empty] = _board[target];
        _board[target] = 0;
        _empty = target;
      }
    });
  }

  void _startClock() {
    _playing = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _onTap(int index) {
    if (_won || index == _empty) return;
    final int er = _empty ~/ _size, ec = _empty % _size;
    final int tr = index ~/ _size, tc = index % _size;
    final bool adjacent = (tr == er && (tc - ec).abs() == 1) ||
        (tc == ec && (tr - er).abs() == 1);
    if (!adjacent) return;

    setState(() {
      _board[_empty] = _board[index];
      _board[index] = 0;
      _empty = index;
      _moves++;
      if (!_playing) _startClock();
      _won = _isSolved();
      if (_won) _timer?.cancel();
    });
  }

  bool _isSolved() {
    for (var i = 0; i < _count - 1; i++) {
      if (_board[i] != i + 1) return false;
    }
    return _board[_count - 1] == 0;
  }

  @override
  Widget build(BuildContext context) {
    final int cell =
        (MediaQuery.sizeOf(context).width.clamp(0, 320) - 48) ~/ _size;
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
                Text('Moves $_moves',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 10),
                Text(_fmt(_seconds),
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: cell * _size.toDouble() + 8,
                height: cell * _size.toDouble() + 8,
                child: GridView.builder(
                  padding: const EdgeInsets.all(4),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _size,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0),
                  itemCount: _count,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _onTap(i),
                    child: _TileView(
                        piece: _board[i],
                        slotIndex: i,
                        cell: cell.toDouble()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  if (_won)
                    Text('Solved in $_moves moves, ${_fmt(_seconds)} 🎉',
                        style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  OutlinedButton(
                      onPressed: _scramble,
                      child: const Text('Scramble')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int s) {
    final int m = s ~/ 60;
    final int r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}

/// Draws one 3x3 cell of the puzzle. If [piece] is the empty slot it renders
/// a blank tile, otherwise it paints the slice of the picture that belongs at
/// that piece's home location, translated so it lines up inside the current
/// grid slot.
class _TileView extends StatelessWidget {
  const _TileView(
      {required this.piece, required this.slotIndex, required this.cell});

  final int piece;
  final int slotIndex;
  final double cell;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(cell, cell),
      painter: _TilePainter(piece: piece, slotIndex: slotIndex),
    );
  }
}

class _TilePainter extends CustomPainter {
  _TilePainter({required this.piece, required this.slotIndex});

  final int piece;
  final int slotIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width;
    if (piece == 0) {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, cell, cell),
          Paint()
            ..color = const Color(0xFFE0E0E0)
            ..style = PaintingStyle.fill);
      return;
    }
    final int home = piece - 1; // solved slot of this piece
    final int hr = home ~/ _size, hc = home % _size;
    final int r = slotIndex ~/ _size, c = slotIndex % _size;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cell, cell));
    // Slide the whole picture so this piece's home cell aligns with this slot.
    canvas.translate((c - hc) * cell, (r - hr) * cell);
    _paintPicture(canvas, Size(cell * _size, cell * _size));
    canvas.restore();

    // Tile border for a clean jigsaw edge.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, cell, cell),
        Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  void _paintPicture(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    final double cell = w / _size;

    // Sky gradient.
    final Rect full = Offset.zero & size;
    canvas.drawRect(
        full,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF79C7FF), Color(0xFFCFEFFF)])
              .createShader(full));

    // Scattered clouds (drawn in picture coordinates).
    final Paint cloud = Paint()..color = Colors.white.withValues(alpha: 0.9);
    _circle(canvas, cloud, w * 0.22, h * 0.18, cell * 0.45);
    _circle(canvas, cloud, w * 0.30, h * 0.18, cell * 0.55);
    _circle(canvas, cloud, w * 0.70, h * 0.22, cell * 0.40);
    _circle(canvas, cloud, w * 0.78, h * 0.22, cell * 0.50);

    // Sun.
    canvas.drawCircle(
        Offset(w * 0.72, h * 0.30),
        cell * 0.55,
        Paint()..color = const Color(0xFFFFD54F));

    // Rolling green hills.
    final Paint hillBack = Paint()..color = const Color(0xFF7CB342);
    final Paint hillFront = Paint()..color = const Color(0xFF558B2F);
    canvas.drawOval(
        Rect.fromLTWH(-cell, h * 0.52, w + cell * 2, h * 0.9), hillBack);
    canvas.drawOval(
        Rect.fromLTWH(-cell * 0.5, h * 0.62, w + cell * 2, h * 1.1), hillFront);

    // A little lake at the bottom between the hills.
    canvas.drawOval(
        Rect.fromLTWH(w * 0.34, h * 0.78, cell * 1.3, cell * 0.7),
        Paint()..color = const Color(0xFF40C4FF));
  }

  void _circle(Canvas canvas, Paint paint, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  @override
  bool shouldRepaint(covariant _TilePainter old) =>
      old.piece != piece || old.slotIndex != slotIndex;
}
