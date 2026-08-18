// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Password strength meter with live feedback + a checker for a demo target.
/// (No real password store — UI + validation only.)
final class LogicPasswordMeter {
  static final catalogItem = CatalogItem(
    name: 'LogicPasswordMeter',
    dataSchema: S.object(
      description: 'Live password strength meter + checks a demo target.',
      properties: {
        'title': S.string(),
        'target': S.string(description: 'Optional password to match (demo).'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final m = (ctx.data as Map);
      return LogicPasswordMeterWidget(
        title: m['title'] is String ? m['title'] as String : 'Password strength',
        target: m['target'] is String ? m['target'] as String : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPasswordMeter","title":"Strength",
  "target":"s3cure!"}
]''',
    ],
  );
}

/// Static, testable strength scoring.
int scorePassword(String pw) {
  if (pw.isEmpty) return 0;
  int score = 0;
  if (pw.length >= 8) score++;
  if (pw.length >= 12) score++;
  if (RegExp(r'[a-z]').hasMatch(pw)) score++;
  if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
  if (RegExp(r'[0-9]').hasMatch(pw)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score++;
  return score.clamp(0, 5);
}

class LogicPasswordMeterWidget extends StatefulWidget {
  const LogicPasswordMeterWidget(
      {super.key, this.title = 'Password strength', this.target});
  final String title;
  final String? target;
  @override
  State<LogicPasswordMeterWidget> createState() =>
      _LogicPasswordMeterWidgetState();
}

class _LogicPasswordMeterWidgetState extends State<LogicPasswordMeterWidget> {
  final _c = TextEditingController();
  bool _obscure = true;
  String? _status;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _label(int s) => switch (s) {
        0 => 'Very weak',
        1 => 'Weak',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Strong',
        _ => 'Excellent',
      };

  void _checkMatch() {
    setState(() {
      if (widget.target == null) {
        _status = null;
      } else {
        _status = _c.text == widget.target
            ? 'Matches target ✓'
            : 'Does not match target';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int score = scorePassword(_c.text);
    final Color color = switch (score) {
      0 || 1 => Colors.red, 2 => Colors.orange, 3 => Colors.amber,
      4 => Colors.lightGreen, _ => Colors.green,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              obscureText: _obscure,
              onChanged: (_) {
                setState(() {});
                _checkMatch();
              },
              decoration: InputDecoration(
                hintText: 'Type a password…',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 5,
                minHeight: 10,
                color: color,
                backgroundColor: color.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(RegExp(r'[a-z]').hasMatch(_c.text) ? '✓' : '•',
                    style: TextStyle(color: Colors.teal.shade700)),
                const SizedBox(width: 4),
                Text('lowercase', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 12),
                Text(RegExp(r'[A-Z]').hasMatch(_c.text) ? '✓' : '•',
                    style: TextStyle(color: Colors.teal.shade700)),
                const SizedBox(width: 4),
                Text('uppercase', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(_status!,
                  style: TextStyle(
                    color: _status == 'Matches target ✓'
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
