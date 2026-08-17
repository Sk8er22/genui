// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Ear-training piano — 7 keys (C major). The widget plays a random note (or
/// a sequence); the user must reproduce the same note(s) on the keys. Correct
/// = advance; no audio engine needed (frequency rendered into a sine wave its
/// own). Pure Dart + Flutter only.
final class LogicPiano {
  static final _schema = S.object(
    description: 'Reproduce the note(s) you hear on a 7-key piano.',
    properties: {
      'title': S.string(description: 'Prompt, e.g. "Class 1: C major".'),
      'sequenceLength': S.integer(description: '1 = single note, 2+ = short ear-training motif.'),
    },
    required: ['title'],
  );

  static final catalogItem = CatalogItem(
    name: 'LogicPiano',
    dataSchema: _schema,
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? len = (ctx.data as Map)['sequenceLength'];
      return LogicPianoWidget(
        title: title is String ? title : 'Reproduce the note',
        sequenceLength: len is int && len > 1 ? len : 1,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPiano",
  "title":"Class 1: C major","sequenceLength":1}
]''',
    ],
  );
}

class LogicPianoWidget extends StatefulWidget {
  const LogicPianoWidget({super.key, this.title = 'Reproduce the note', this.sequenceLength = 1});
  final String title;
  final int sequenceLength;
  @override
  State<LogicPianoWidget> createState() => _LogicPianoWidgetState();
}

class _LogicPianoWidgetState extends State<LogicPianoWidget> {
  // C  D  E  F  G  A  B  (white keys), frequencies (A4 = 440).
  static const List<double> freqs = [
    261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88,
  ];
  static const List<String> names = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  List<int> _target = [];
  List<int> _answered = [];
  bool _playing = false;
  String? _feedback;

  final math.Random _rng = math.Random();
  final ap.AudioPlayer _player = ap.AudioPlayer();

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _newRound() {
    _target = [
      for (var i = 0; i < widget.sequenceLength; i++) _rng.nextInt(7),
    ];
    _answered = [];
    _feedback = 'Tap "Play" then reproduce the note(s).';
  }

  Future<void> _playSequence() async {
    setState(() => _playing = true);
    for (final int idx in _target) {
      await _playTone(idx);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (mounted) setState(() => _playing = false);
  }

  /// Synthesizes a short sine wave for [freqs[idx]] as a WAV in memory and
  /// plays it though audioplayers, so the user actually hears the note.
  Future<void> _playTone(int idx) async {
    final double freq = freqs[idx];
    final Uint8List wav = _sineWav(freq, durationMs: 700);
    final ap.Source src = ap.BytesSource(wav);
    await _player.stop();
    await _player.play(src, mode: ap.PlayerMode.lowLatency);
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  /// Builds a 16-bit mono PCM sine WAV at 44100 Hz.
  Uint8List _sineWav(double freq, {required int durationMs}) {
    const int rate = 44100;
    final int n = (rate * durationMs / 1000).round();
    final int dataBytes = n * 2;
    final ByteData out = ByteData(44 + dataBytes);

    void wStr(int off, String s) {
      for (var i = 0; i < s.length; i++) {
        out.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    wStr(0, 'RIFF');
    out.setUint32(4, 36 + dataBytes, Endian.little);
    wStr(8, 'WAVE');
    wStr(12, 'fmt ');
    out.setUint32(16, 16, Endian.little); // fmt chunk size
    out.setUint16(20, 1, Endian.little); // PCM
    out.setUint16(22, 1, Endian.little); // mono
    out.setUint32(24, rate, Endian.little);
    out.setUint32(28, rate * 2, Endian.little); // byte rate
    out.setUint16(32, 2, Endian.little); // block align
    out.setUint16(34, 16, Endian.little); // bits per sample
    wStr(36, 'data');
    out.setUint32(40, dataBytes, Endian.little);
    for (var i = 0; i < n; i++) {
      final double t = i / rate;
      // gentle attack/decay envelope to avoid clicks
      final double env =
          math.min(1.0, t / 0.02) * math.min(1.0, ((durationMs / 1000) - t) / 0.05);
      final double v = env *
          math.sin(2 * math.pi * freq * t) *
          0.35;
      out.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return out.buffer.asUint8List();
  }

  void _press(int idx) {
    if (_playing || _answered.length == _target.length) return;
    setState(() {
      _answered.add(idx);
      if (_answered.length == _target.length) _judge();
    });
  }

  void _judge() {
    final bool ok = _listEq(_answered, _target);
    _feedback = ok
        ? 'Perfect! You reproduced the ${names[_target.first]} motif.'
        : 'Close — expected ${_namesOf(_target)}, you played ${_namesOf(_answered)}.';
  }

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _namesOf(List<int> l) => l.map((i) => names[i]).join('-');

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
                Text('${widget.sequenceLength}-note',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(_feedback ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            // The 7 keys — a simple white-key piano row.
            SizedBox(
              height: 110,
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Material(
                          color: Colors.white,
                          elevation: _answered.length > 0 &&
                                  i == _answered[_answered.length - 1]
                              ? 4
                              : 1,
                          child: InkWell(
                            onTap: () => _press(i),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(names[i],
                                      style: const TextStyle(color: Colors.black87)),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _playing ? null : _playSequence,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
                TextButton(
                  onPressed: () => setState(_newRound),
                  child: const Text('New note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
