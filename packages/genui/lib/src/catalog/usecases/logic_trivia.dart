// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A zero-data trivia quiz: the model supplies questions
/// [{"q","options":[...],"answer"(0-based),"fact"}] and the player answers
/// all with scoring + reveal.
final class LogicTrivia {
  static final catalogItem = CatalogItem(
    name: 'LogicTrivia',
    dataSchema: S.object(
      description: 'Answer a short trivia quiz.',
      properties: {
        'title': S.string(),
        'questions': S.list(items: S.object(properties: {
          'q': S.string(),
          'options': S.list(items: S.string()),
          'answer': S.integer(description: '0-based correct index.'),
          'fact': S.string(),
        }, required: ['q', 'options', 'answer'])),
      },
      required: ['title', 'questions'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? qs = (ctx.data as Map)['questions'];
      final List<TriviaQ> list = qs is List
          ? qs.map((q) {
              final m = q is Map ? q : const <String, Object?>{};
              final opts = (m['options'] is List)
                  ? (m['options'] as List).whereType<String>().toList()
                  : const <String>[];
              return TriviaQ(
                (m['q'] as String?) ?? '',
                opts,
                (m['answer'] as int?) ?? 0,
                (m['fact'] as String?) ?? '',
              );
            }).toList()
          : const [];
      return LogicTriviaWidget(
        title: title is String ? title : 'Trivia',
        questions: list.isNotEmpty ? list : defaultQuestions,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTrivia","title":"Trivia","questions":[
   {"q":"What planet is known as the Red Planet?","options":["Venus","Mars","Jupiter"],"answer":1,"fact":"Mars has rusty iron dust."}
 ]}]
''',
    ],
  );

  static final List<TriviaQ> defaultQuestions = [
    TriviaQ('What color do you get mixing red and blue?',
        ['Green', 'Purple', 'Orange'], 1,
        'Red + blue = purple (subtractive).'),
    TriviaQ('How many sides does a hexagon have?',
        ['5', '6', '7'], 1, 'Hexa = six.'),
  ];
}

class TriviaQ {
  const TriviaQ(this.q, this.options, this.answer, this.fact);
  final String q;
  final List<String> options;
  final int answer;
  final String fact;
}

class LogicTriviaWidget extends StatefulWidget {
  const LogicTriviaWidget(
      {super.key, this.title = 'Trivia', this.questions = const []});
  final String title;
  final List<TriviaQ> questions;
  @override
  State<LogicTriviaWidget> createState() => _LogicTriviaWidgetState();
}

class _LogicTriviaWidgetState extends State<LogicTriviaWidget> {
  final Map<int, int> _answers = {};
  bool _revealed = false;

  int get _correct {
    var c = 0;
    for (var i = 0; i < widget.questions.length; i++) {
      if (_answers[i] == widget.questions[i].answer) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
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
                if (_revealed)
                  Text('$_correct/${widget.questions.length}',
                      style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            for (var qi = 0; qi < widget.questions.length; qi++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${qi + 1}. ${widget.questions[qi].q}',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    for (var oi = 0; oi < widget.questions[qi].options.length; oi++)
                      RadioListTile<String>(
                        dense: true,
                        value: widget.questions[qi].options[oi],
                        groupValue: _answers[qi] == null
                            ? null
                            : widget.questions[qi].options[_answers[qi]!],
                        onChanged: _revealed
                            ? null
                            : (v) => setState(() =>
                                _answers[qi] = oi),
                        title: Text(widget.questions[qi].options[oi]),
                      ),
                    if (_revealed) ...[
                      const SizedBox(height: 2),
                      Text(
                        _answers[qi] == widget.questions[qi].answer
                            ? '✓ correct'
                            : '✗ answer: ${widget.questions[qi].options[widget.questions[qi].answer]}',
                        style: TextStyle(
                          color: _answers[qi] == widget.questions[qi].answer
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      if (widget.questions[qi].fact.isNotEmpty)
                        Text(widget.questions[qi].fact,
                            style:
                                Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Reveal results'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
