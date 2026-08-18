// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// SNAKE: steer the snake with arrow/WASD keys or the on-screen pad to eat
/// apples. Each apple grows the snake and speeds the game up; running into
/// the wall or your own tail ends the run.
final class LogicSnake {
  /// The catalog item for the [LogicSnake] widget.
  static final catalogItem = CatalogItem(
    name: 'LogicSnake',
    dataSchema: S.object(
      description: 'Classic Snake game: eat apples, avoid yourself.',
      properties: {
        'title': S.string(),
        'gridSize': S.integer(description: 'Board cells per side (8..20).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? gridSize = (ctx.data as Map)['gridSize'];
      return LogicSnakeWidget(
        title: title is String ? title : 'Snake',
        gridSize: gridSize is int ? gridSize.clamp(8, 20) : 15,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSnake","title":"Snake","gridSize":15}
]''',
    ],
  );
}

/// A single-player Snake game board with keyboard and on-screen controls.
class LogicSnakeWidget extends StatefulWidget {
  /// Creates a [LogicSnakeWidget].
  const LogicSnakeWidget({
    super.key,
    this.title = 'Snake',
    this.gridSize = 15,
  });

  /// The widget title shown in the header.
  final String title;

  /// The number of cells on each side of the square board.
  final int gridSize;

  @override
  State<LogicSnakeWidget> createState() => _LogicSnakeWidgetState();
}

class _LogicSnakeWidgetState extends State<LogicSnakeWidget> {
  static const Duration _tick = Duration(milliseconds: 200);
  static const int _up = 0;
  static const int _right = 1;
  static const int _down = 2;
  static const int _left = 3;

  final math.Random _rng = math.Random();
  late int _size;
  late List<int> _snake; // head first; cell index = row * _size + col
  late int _food;
  int _dir = _right;
  int _nextDir = _right;
  int _score = 0;
  int _best = 0;
  bool _running = true;
  bool _paused = false;
  bool _gameOver = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setup();
    _timer = Timer.periodic(_tick, (_) => _step());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setup() {
    _size = widget.gridSize.clamp(8, 20);
    final int start = (_size ~/ 2) * _size + (_size ~/ 2 - 1);
    _snake = [start, start - 1, start - 2];
    _dir = _right;
    _nextDir = _right;
    _score = 0;
    _running = true;
    _paused = false;
    _gameOver = false;
    _food = _placeFood();
  }

  void _restart() {
    _timer?.cancel();
    setState(_setup);
    _timer = Timer.periodic(_tick, (_) => _step());
  }

  void _togglePause() {
    if (_gameOver) return;
    setState(() => _paused = !_paused);
  }

  /// Returns a free cell index for the next apple, or -1 if the board is
  /// full (the snake has won).
  int _placeFood() {
    if (_snake.length >= _size * _size) return -1;
    int candidate;
    do {
      candidate = _rng.nextInt(_size * _size);
    } while (_snake.contains(candidate));
    return candidate;
  }

  void _setDirection(int dir) {
    if (!_running || _paused || _gameOver) return;
    // Ignore a move that would reverse straight back into the body.
    if ((dir + 2) % 4 == _dir) return;
    _nextDir = dir;
  }

  void _step() {
    if (!mounted || !_running || _paused || _gameOver) return;
    _dir = _nextDir;
    final int head = _snake.first;
    final int row = head ~/ _size;
    final int col = head % _size;
    int nr = row;
    int nc = col;
    switch (_dir) {
      case _up:
        nr -= 1;
      case _right:
        nc += 1;
      case _down:
        nr += 1;
      case _left:
        nc -= 1;
    }
    if (nr < 0 || nr >= _size || nc < 0 || nc >= _size) {
      _finishGame();
      return;
    }
    final int newHead = nr * _size + nc;
    final bool grows = newHead == _food;
    // Moving into the tail is legal only when that cell is vacated this very
    // move (i.e. the snake is not growing).
    if (_snake.contains(newHead) && !(grows && newHead == _snake.last)) {
      _finishGame();
      return;
    }
    setState(() {
      _snake.insert(0, newHead);
      if (grows) {
        _score++;
        if (_score > _best) _best = _score;
        _food = _placeFood();
        if (_food < 0) {
          _running = false;
          _gameOver = true;
        }
      } else {
        _snake.removeLast();
      }
    });
  }

  void _finishGame() {
    _timer?.cancel();
    setState(() => _gameOver = true);
    _running = false;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    final int? dir = switch (key) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => _up,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => _right,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => _down,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => _left,
      _ => null,
    };
    if (dir == null) return KeyEventResult.ignored;
    _setDirection(dir);
    return KeyEventResult.handled;
  }

  Widget _cell(int index) {
    final int i = _snake.indexOf(index);
    final Color color;
    if (index == _food) {
      color = Colors.redAccent;
    } else if (i == 0) {
      color = Colors.green.shade800;
    } else if (i > 0) {
      color = Colors.green.shade400;
    } else if ((index + index ~/ _size).isEven) {
      color = Colors.green.shade50;
    } else {
      color = Colors.white;
    }
    return DecoratedBox(decoration: BoxDecoration(color: color));
  }

  Widget _buildPad() {
    Widget keyBtn(IconData icon, int dir) {
      return IconButton.filledTonal(
        onPressed: () => _setDirection(dir),
        icon: Icon(icon),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          keyBtn(Icons.arrow_upward, _up),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              keyBtn(Icons.arrow_back, _left),
              const SizedBox(width: 48),
              keyBtn(Icons.arrow_forward, _right),
            ],
          ),
          keyBtn(Icons.arrow_downward, _down),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String status;
    if (_gameOver) {
      status = _food < 0
          ? 'You filled the board! 🎉'
          : 'Game over — Restart to play again.';
    } else if (_paused) {
      status = 'Paused';
    } else {
      status = 'Arrows/WASD or tap the pad to steer';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: _paused ? 'Resume' : 'Pause',
                  visualDensity: VisualDensity.compact,
                  onPressed: _togglePause,
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                ),
                TextButton(onPressed: _restart, child: const Text('Restart')),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(status, style: theme.textTheme.bodySmall),
                ),
                Text('Best: $_best', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Focus(
                autofocus: true,
                onKeyEvent: _onKey,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _size,
                    ),
                    itemCount: _size * _size,
                    itemBuilder: (context, i) => _cell(i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildPad(),
          ],
        ),
      ),
    );
  }
}
