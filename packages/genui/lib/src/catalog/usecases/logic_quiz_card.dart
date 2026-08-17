// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A multiple-choice quiz card. The model supplies the question, options,
/// the correct index, and optional explanation. Deterministic scoring.
final class LogicQuizCard {
  static final catalogItem = CatalogItem(
    name: 'LogicQuizCard',
    dataSchema: S.object(
      description: 'A single multiple-choice quiz question.',
      properties: {
        'question': S.string(),
        'options': S.list(items: S.string()),
        'answer': S.integer(
            description: '0-based index of the correct option.'),
        'explanation': S.string(description: 'Shown after answering.'),
      },
      required: ['question', 'options', 'answer'],
    ),
    widgetBuilder: (ctx) {
      final Object? q = (ctx.data as Map)['question'];
      final Object? options = (ctx.data as Map)['options'];
      final Object? answer = (ctx.data as Map)['answer'];
      final Object? explanation = (ctx.data as Map)['explanation'];
      return LogicQuizCardWidget(
        question: q is String ? q : '?',
        options: options is List ? options.whereType<String>().toList() : const [],
        answer: answer is int ? answer : 0,
        explanation: explanation is String ? explanation : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicQuizCard","question":"What is 2+2?",
  "options":["3","4","5"],"answer":1,"explanation":"2+2=4"}
]''',
    ],
  );
}

class LogicQuizCardWidget extends StatefulWidget {
  const LogicQuizCardWidget({
    super.key,
    required this.question,
    required this.options,
    required this.answer,
    this.explanation,
  });
  final String question;
  final List<String> options;
  final int answer;
  final String? explanation;
  @override
  State<LogicQuizCardWidget> createState() => _LogicQuizCardWidgetState();
}

class _LogicQuizCardWidgetState extends State<LogicQuizCardWidget> {
  int? _selected;
  bool get _revealed => _selected != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < widget.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  color: _revealed
                      ? (i == widget.answer
                          ? Colors.green.shade100
                          : i == _selected
                              ? Colors.red.shade100
                              : null)
                      : null,
                  child: ListTile(
                    leading: Text('${i + 1}'),
                    title: Text(widget.options[i]),
                    trailing:
                        _revealed && i == widget.answer
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                    onTap: _revealed ? null : () => setState(() => _selected = i),
                  ),
                ),
              ),
            if (_revealed && widget.explanation != null) ...[
              const Divider(),
              Text(widget.explanation!,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            if (_revealed)
              Text(
                _selected == widget.answer ? 'Correct! ✓' : 'Not quite.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selected == widget.answer
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _selected = widget.answer),
                  child: const Text('Reveal answer'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
