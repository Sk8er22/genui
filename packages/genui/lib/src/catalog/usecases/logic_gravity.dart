// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A falling-ball gravity sandbox: tap to drop a ball; it falls with gravity,
/// bounces off the floor/walls with restitution. Pure-Dart physics + a Timer.
final class LogicGravity {
  static final catalogItem = CatalogItem(
    name: 'LogicGravity',
    dataSchema: S.object(
      description: 'Drop balls and watch gravity + bounce.',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicGravityWidget(
          title: title is String ? title : 'Gravity');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicGravity","title":"Physics"}
]''',
    ],
  );
}

class _Ball {
  double x, y, vx = 0, vy = 0;
  final double r;
  final Color color;
  _Ball(this.x, this.y, this.r, this.color);
}

class LogicGravityWidget extends StatefulWidget {
  const LogicGravityWidget({super.key, this.title = 'Gravity'});
  final String title;
  @override
  State<LogicGravityWidget> createState() => _LogicGravityWidgetState();
}

class _LogicGravityWidgetState extends State<LogicGravityWidget> {
  static const double _g = 1500; // px/s^2
  static const double _restitution = 0.62;
  static const double _friction = 0.995;
  final List<_Ball> _balls = [];
  Timer? _dtick;
  Size _area = const Size(320, 360);

  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _dtick = Timer.periodic(const Duration(milliseconds: 16), (_) => _step());
  }

  @override
  void dispose() {
    _dtick?.cancel();
    super.dispose();
  }

  void _step() {
    setState(() {
      for (final b in _balls) {
        b.vy += _g * 0.016;
        b.vx *= _friction;
        b.x += b.vx * 0.016;
        b.y += b.vy * 0.016;
        if (b.y + b.r > _area.height) {
          b.y = _area.height - b.r;
          b.vy = -b.vy * _restitution;
        }
        if (b.x - b.r < 0) {
          b.x = b.r;
          b.vx = -b.vx * 0.7;
        }
        if (b.x + b.r > _area.width) {
          b.x = _area.width - b.r;
          b.vx = -b.vx * 0.7;
        }
      }
    });
  }

  void _dropAt(double x, double y) {
    setState(() {
      _balls.add(_Ball(
          x, y, 8 + _rng.nextInt(8).toDouble(),
          Colors.primaries[_rng.nextInt(Colors.primaries.length)]));
    });
  }

  void _clear() => setState(_balls.clear);

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
                Text('${_balls.length} balls',
                    style: Theme.of(context).textTheme.bodySmall),
                TextButton(onPressed: _clear, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              _area = Size(constraints.maxWidth, constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 360);
              return GestureDetector(
                onTapDown: (d) =>
                    _dropAt(d.localPosition.dx, d.localPosition.dy),
                child: Container(
                  width: double.infinity,
                  height: 330,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: CustomPaint(
                    size: const Size(double.infinity, 330),
                    painter: _BallsPainter(_balls),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text('Tap the box to drop a ball',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BallsPainter extends CustomPainter {
  _BallsPainter(this.balls);
  final List<_Ball> balls;
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in balls) {
      canvas.drawCircle(
          Offset(b.x, b.y), b.r, Paint()..color = b.color);
    }
  }

  @override
  bool shouldRepaint(covariant _BallsPainter old) => true;
}
