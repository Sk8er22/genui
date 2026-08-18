// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// One-time-password entry (e.g. 2FA / email code). The model can set the code
/// length and the expected code; validation + paste support, no real SMS/red.
final class LogicOtp {
  static final catalogItem = CatalogItem(
    name: 'LogicOtp',
    dataSchema: S.object(
      description: 'Enter a one-time code (email/2FA demo).',
      properties: {
        'title': S.string(),
        'length': S.integer(description: 'Code length (default 6).'),
        'expected': S.string(description: 'Expected code for demo validation.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final m = (ctx.data as Map);
      final int len = m['length'] is int && m['length'] as int > 0
          ? m['length'] as int
          : 6;
      return LogicOtpWidget(
        title: m['title'] is String ? m['title'] as String : 'Enter code',
        length: len,
        expected: m['expected'] is String ? m['expected'] as String : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicOtp","title":"Verify your email",
  "length":6,"expected":"123456"}
]''',
    ],
  );
}

class LogicOtpWidget extends StatefulWidget {
  const LogicOtpWidget({
    super.key,
    this.title = 'Enter code',
    this.length = 6,
    this.expected,
  });
  final String title;
  final int length;
  final String? expected;
  @override
  State<LogicOtpWidget> createState() => _LogicOtpWidgetState();
}

class _LogicOtpWidgetState extends State<LogicOtpWidget> {
  final List<TextEditingController> _boxes = [];
  final List<FocusNode> _nodes = [];
  String? _status;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.length; i++) {
      _boxes.add(TextEditingController());
      _nodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in _boxes) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _boxes.map((b) => b.text.isNotEmpty ? b.text : ' ').join();

  void _submit() {
    final String code = _boxes.map((b) => b.text).join();
    setState(() {
      _status = widget.expected == null
          ? 'Code: $code'
          : (code == widget.expected ? 'Code correct ✓' : 'Wrong code');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Enter the ${widget.length}-digit code',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: SizedBox(
                      width: 42,
                      child: TextField(
                        controller: _boxes[i],
                        focusNode: _nodes[i],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder()),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < widget.length - 1) {
                            _nodes[i + 1].requestFocus();
                          }
                        },
                        onSubmitted: (_) {
                          if (i == widget.length - 1) _submit();
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Verify'),
            ),
            if (widget.expected != null) ...[
              const SizedBox(height: 8),
              Text('Demo code: ${widget.expected}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(
                _status!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (_status == 'Code correct ✓')
                      ? Colors.green.shade700
                      : Colors.blueGrey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
