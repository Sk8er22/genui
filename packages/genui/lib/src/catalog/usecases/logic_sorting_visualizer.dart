// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A sorting visualizer: watch classic algorithms animate on a bar chart.
///
/// The model picks the array size and which algorithm to animate. The user can
/// play, pause, step frame-by-frame or reshuffle the data. Great for teaching
/// how comparison-based sorts actually execute.
final class LogicSortingVisualizer {
  static final catalogItem = CatalogItem(
    name: 'LogicSortingVisualizer',
    dataSchema: S.object(
      description:
          'Animated bar-chart visualizer for classic sorting algorithms.',
      properties: {
        'title': S.string(),
        'size': S.integer(description: 'Number of bars to sort (2-60).'),
        'algorithm': S.string(
            description: 'Bubble, Selection, Insertion, Merge or Quick.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? size = (ctx.data as Map)['size'];
      final Object? algorithm = (ctx.data as Map)['algorithm'];
      return LogicSortingVisualizerWidget(
        title: title is String ? title : 'Sorting visualizer',
        size: size is int && size > 0 ? size : 20,
        algorithm: algorithm is String ? algorithm : 'Bubble',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSortingVisualizer","title":"Bubble sort","size":20}
]''',
      () => '''
[
 {"id":"root","component":"LogicSortingVisualizer","title":"Merge sort","algorithm":"Merge"}
]''',
    ],
  );
}

const List<String> _algorithms = [
  'Bubble',
  'Selection',
  'Insertion',
  'Merge',
  'Quick',
];

/// One snapshot of the array plus the indices currently being compared/placed.
class _SortFrame {
  const _SortFrame(this.values, this.a, this.b);
  final List<int> values;
  final int a;
  final int b;
}

class LogicSortingVisualizerWidget extends StatefulWidget {
  const LogicSortingVisualizerWidget({
    super.key,
    this.title = 'Sorting visualizer',
    this.size = 20,
    this.algorithm = 'Bubble',
  });
  final String title;
  final int size;
  final String algorithm;
  @override
  State<LogicSortingVisualizerWidget> createState() =>
      _LogicSortingVisualizerWidgetState();
}

class _LogicSortingVisualizerWidgetState
    extends State<LogicSortingVisualizerWidget> {
  final Random _rng = Random();
  late String _algo;
  late int _size;
  int _speedMs = 60;
  List<int> _values = const [];
  List<_SortFrame> _frames = const [];
  int _frameIndex = 0;
  bool _playing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _algo = _algorithms.contains(widget.algorithm)
        ? widget.algorithm
        : _algorithms.first;
    _size = widget.size.clamp(2, 60).toInt();
    _initData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<int> _newData() =>
      List<int>.generate(_size, (_) => 5 + _rng.nextInt(96)); // 5..100

  void _initData() {
    _values = _newData();
    _frames = _buildFrames(_values, _algo);
    _frameIndex = 0;
    _playing = false;
  }

  void _reshuffle() {
    _timer?.cancel();
    setState(_initData);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _playing = false;
      _frameIndex = 0;
    });
  }

  void _setAlgo(String algo) {
    _timer?.cancel();
    setState(() {
      _algo = algo;
      _playing = false;
      _frames = _buildFrames(List<int>.of(_values), algo);
      _frameIndex = 0;
    });
  }

  void _setSize(double s) {
    _timer?.cancel();
    setState(() {
      _size = s.round().clamp(2, 60).toInt();
      _playing = false;
      _values = _newData();
      _frames = _buildFrames(_values, _algo);
      _frameIndex = 0;
    });
  }

  void _setSpeed(double ms) {
    setState(() => _speedMs = ms.round().clamp(10, 300).toInt());
    if (_playing) {
      _timer?.cancel();
      _timer =
          Timer.periodic(Duration(milliseconds: _speedMs), (_) => _tick());
    }
  }

  void _step() {
    _timer?.cancel();
    setState(() {
      _playing = false;
      if (_frameIndex < _frames.length - 1) _frameIndex++;
    });
  }

  void _playPause() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    // Replaying from the start if the animation already finished.
    if (_frameIndex >= _frames.length - 1) {
      setState(() => _frameIndex = 0);
    }
    setState(() => _playing = true);
    _timer =
        Timer.periodic(Duration(milliseconds: _speedMs), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      if (_frameIndex < _frames.length - 1) {
        _frameIndex++;
      } else {
        _timer?.cancel();
        _playing = false;
      }
    });
  }

  /// Record every mutation (plus the comparison that preceded it) so the
  /// widget can replay the sort frame-by-frame.
  List<_SortFrame> _buildFrames(List<int> data, String algo) {
    final List<int> a = List<int>.of(data);
    final List<_SortFrame> frames = [];
    switch (algo) {
      case 'Selection':
        for (int i = 0; i < a.length - 1; i++) {
          int minIdx = i;
          for (int j = i + 1; j < a.length; j++) {
            frames.add(_SortFrame(List<int>.of(a), minIdx, j));
            if (a[j] < a[minIdx]) minIdx = j;
          }
          if (minIdx != i) {
            final int t = a[i];
            a[i] = a[minIdx];
            a[minIdx] = t;
          }
          frames.add(_SortFrame(List<int>.of(a), i, minIdx));
        }
      case 'Insertion':
        for (int i = 1; i < a.length; i++) {
          int j = i;
          while (j > 0 && a[j - 1] > a[j]) {
            frames.add(_SortFrame(List<int>.of(a), j - 1, j));
            final int t = a[j - 1];
            a[j - 1] = a[j];
            a[j] = t;
            j--;
          }
          frames.add(_SortFrame(List<int>.of(a), i, j));
        }
      case 'Merge':
        _mergeFrames(a, frames, 0, a.length - 1);
      case 'Quick':
        _quickFrames(a, frames, 0, a.length - 1);
      default: // Bubble
        for (int i = 0; i < a.length - 1; i++) {
          for (int j = 0; j < a.length - i - 1; j++) {
            frames.add(_SortFrame(List<int>.of(a), j, j + 1));
            if (a[j] > a[j + 1]) {
              final int t = a[j];
              a[j] = a[j + 1];
              a[j + 1] = t;
              frames.add(_SortFrame(List<int>.of(a), j, j + 1));
            }
          }
        }
    }
    return frames;
  }

  void _mergeFrames(
      List<int> a, List<_SortFrame> frames, int lo, int hi) {
    if (lo >= hi) return;
    final int mid = (lo + hi) ~/ 2;
    _mergeFrames(a, frames, lo, mid);
    _mergeFrames(a, frames, mid + 1, hi);
    final List<int> tmp =
        List<int>.generate(hi - lo + 1, (k) => a[lo + k]);
    int i = 0; // left cursor inside tmp
    int j = mid - lo + 1; // right cursor inside tmp
    final int rightEnd = hi - lo;
    final int leftEnd = mid - lo;
    for (int k = lo; k <= hi; k++) {
      if (j > rightEnd || (i <= leftEnd && tmp[i] <= tmp[j])) {
        a[k] = tmp[i++];
      } else {
        a[k] = tmp[j++];
      }
      frames.add(_SortFrame(List<int>.of(a), k, k));
    }
  }

  void _quickFrames(List<int> a, List<_SortFrame> frames, int lo, int hi) {
    if (lo >= hi) return;
    // Random pivot keeps the animation fast even on nearly-sorted input.
    final int pIdx = lo + _rng.nextInt(hi - lo + 1);
    final int pt = a[pIdx];
    a[pIdx] = a[hi];
    a[hi] = pt;
    final int pivot = a[hi];
    int i = lo;
    for (int j = lo; j < hi; j++) {
      frames.add(_SortFrame(List<int>.of(a), j, hi));
      if (a[j] < pivot) {
        final int t = a[i];
        a[i] = a[j];
        a[j] = t;
        i++;
        frames.add(_SortFrame(List<int>.of(a), i - 1, j));
      }
    }
    final int t = a[i];
    a[i] = a[hi];
    a[hi] = t;
    frames.add(_SortFrame(List<int>.of(a), i, hi));
    _quickFrames(a, frames, lo, i - 1);
    _quickFrames(a, frames, i + 1, hi);
  }

  @override
  Widget build(BuildContext context) {
    final _SortFrame frame = _frames[_frameIndex];
    final bool done = _frameIndex >= _frames.length - 1;
    final int maxV = frame.values.fold<int>(1, (m, v) => v > m ? v : m);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: [
                  for (final String a in _algorithms)
                    ButtonSegment(value: a, label: Text(a)),
                ],
                selected: {_algo},
                onSelectionChanged: (Set<String> s) => _setAlgo(s.first),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < frame.values.length; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: (frame.values[i] / maxV) * 168,
                        decoration: BoxDecoration(
                          color: done
                              ? Colors.green.shade400
                              : (i == frame.a || i == frame.b)
                                  ? Colors.deepOrange.shade400
                                  : scheme.primaryContainer,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                done
                    ? 'Sorted — ${_frames.length} steps'
                    : 'Step ${_frameIndex + 1} of ${_frames.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: 'New random array',
                  onPressed: _reshuffle,
                  icon: const Icon(Icons.shuffle),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Back to start',
                  onPressed: _reset,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Step',
                  onPressed: _step,
                  icon: const Icon(Icons.skip_next),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: _playing ? 'Pause' : 'Play',
                  onPressed: _playPause,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.poll, size: 16),
                Expanded(
                  child: Slider(
                    value: _size.toDouble(),
                    min: 2,
                    max: 60,
                    divisions: 58,
                    label: 'Elements: $_size',
                    onChanged: _setSize,
                  ),
                ),
                Text('$_size', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.speed, size: 16),
                Expanded(
                  child: Slider(
                    value: _speedMs.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    label: '${_speedMs}ms',
                    onChanged: _setSpeed,
                  ),
                ),
                Text('${_speedMs}ms',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
