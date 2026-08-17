// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A poll/opinion card: pick one option, see the tally as a bar, optionally
/// receiving an initial vote distribution from the model.
final class LogicPollVote {
  static final catalogItem = CatalogItem(
    name: 'LogicPollVote',
    dataSchema: S.object(
      description: 'Cast a vote in an on-the-spot poll with live results.',
      properties: {
        'title': S.string(),
        'options': S.list(items: S.string()),
        'votes': S.list(
          items: S.integer(),
          description: 'Optional initial vote counts aligned to options.',
        ),
      },
      required: ['title', 'options'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? options = (ctx.data as Map)['options'];
      final Object? votes = (ctx.data as Map)['votes'];
      final List<int> counts = votes is List
          ? votes.whereType<int>().toList()
          : const [];
      return LogicPollVoteWidget(
        title: title is String ? title : 'Poll',
        options: options is List ? options.whereType<String>().toList() : const [],
        initial: counts,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicPollVote","title":"Favorite color",
  "options":["Red","Green","Blue"],"votes":[3,1,5]}
]''',
    ],
  );
}

class LogicPollVoteWidget extends StatefulWidget {
  const LogicPollVoteWidget({
    super.key,
    required this.title,
    required this.options,
    this.initial = const [],
  });
  final String title;
  final List<String> options;
  final List<int> initial;
  @override
  State<LogicPollVoteWidget> createState() => _LogicPollVoteWidgetState();
}

class _LogicPollVoteWidgetState extends State<LogicPollVoteWidget> {
  late List<int> _votes;
  int? _myVote;
  bool _voted = false;

  @override
  void initState() {
    super.initState();
    _votes = [
      for (var i = 0; i < widget.options.length; i++)
        i < widget.initial.length ? widget.initial[i] : 0,
    ];
  }

  void _vote(int i) {
    if (_voted) return;
    setState(() {
      if (_myVote != null) _votes[_myVote!]--;
      _myVote = i;
      _votes[i]++;
      _voted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int total = _votes.fold(0, (a, b) => a + b);
    final int max = _votes.fold(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < widget.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(widget.options[i])),
                        Text('${_votes[i]}',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 6),
                        if (i == _myVote)
                          const Icon(Icons.check, size: 16, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : _votes[i] / max,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text('$total vote(s)',
                style: Theme.of(context).textTheme.bodySmall),
            if (_voted)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _votes[_myVote!]--;
                    _myVote = null;
                    _voted = false;
                  }),
                  child: const Text('Vote again'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
