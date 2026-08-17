// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A to-do list widget: add/remove/toggle items, filter by done. Optional seed
/// items from the model (e.g. extracted action items).
final class LogicTodoList {
  static final catalogItem = CatalogItem(
    name: 'LogicTodoList',
    dataSchema: S.object(
      description: 'Interactive checklist / to-do list.',
      properties: {
        'title': S.string(),
        'items': S.list(items: S.string(),
            description: 'Optional initial unchecked items.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? items = (ctx.data as Map)['items'];
      return LogicTodoListWidget(
        title: title is String ? title : 'To-do',
        seed: items is List ? items.whereType<String>().toList() : const [],
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicTodoList","title":"Actions",
  "items":["Write report","Ship release","Sync calendar"]}
]''',
    ],
  );
}

class TodoItem {
  TodoItem(this.text, {this.done = false});
  String text;
  bool done;
}

class LogicTodoListWidget extends StatefulWidget {
  const LogicTodoListWidget({super.key, required this.title, this.seed = const []});
  final String title;
  final List<String> seed;
  @override
  State<LogicTodoListWidget> createState() => _LogicTodoListWidgetState();
}

class _LogicTodoListWidgetState extends State<LogicTodoListWidget> {
  late final List<TodoItem> _items =
      widget.seed.map((s) => TodoItem(s)).toList();
  final TextEditingController _c = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add() {
    final String t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _items.add(TodoItem(t));
      _c.clear();
    });
  }

  List<TodoItem> get _visible => _items.where((it) {
        if (_filter == 'done') return it.done;
        if (_filter == 'open') return !it.done;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final int doneCount = _items.where((it) => it.done).length;
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
                Text('$doneCount/${_items.length}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    decoration: const InputDecoration(
                        hintText: 'Add a task…', isDense: true),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                IconButton(onPressed: _add, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'open', label: Text('Open')),
                ButtonSegment(value: 'done', label: Text('Done')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            if (_visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: Text('Nothing here.',
                    style: Theme.of(context).textTheme.bodySmall)),
              )
            else
              ..._visible.map((it) => CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: it.done,
                    title: Text(it.text,
                        style: it.done
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey)
                            : null),
                    onChanged: (v) => setState(() => it.done = v ?? false),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => setState(() => _items.remove(it)),
                    ),
                  )),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: doneCount == 0
                      ? null
                      : () => setState(() => _items.removeWhere((it) => it.done)),
                  child: const Text('Clear done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
