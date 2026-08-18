// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// An expense tracker: add/remove spending entries and see the running total.
final class LogicExpenseTracker {
  static final catalogItem = CatalogItem(
    name: 'LogicExpenseTracker',
    dataSchema: S.object(
      description: 'Track personal expenses as a running ledger.',
      properties: {
        'title': S.string(),
        'currency': S.string(description: r'Currency symbol or code, e.g. $'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      final Object? currency = (ctx.data as Map)['currency'];
      return LogicExpenseTrackerWidget(
        title: title is String ? title : 'Expenses',
        currency: currency is String ? currency : r'$',
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicExpenseTracker","title":"Groceries","currency":"USD"}
]''',
    ],
  );
}

class _ExpenseEntry {
  _ExpenseEntry(this.name, this.amount);
  final String name;
  final double amount;
}

class LogicExpenseTrackerWidget extends StatefulWidget {
  const LogicExpenseTrackerWidget(
      {super.key, this.title = 'Expenses', this.currency = r'$'});
  final String title;
  final String currency;
  @override
  State<LogicExpenseTrackerWidget> createState() =>
      _LogicExpenseTrackerWidgetState();
}

class _LogicExpenseTrackerWidgetState extends State<LogicExpenseTrackerWidget> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final List<_ExpenseEntry> _items = [];
  String? _error;

  String get _sym {
    final String c = widget.currency.toUpperCase();
    return switch (c) {
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'JPY' => '¥',
      _ => widget.currency,
    };
  }

  double get _total => _items.fold<double>(
      0, (sum, e) => sum + e.amount);

  void _add() {
    final String name = _name.text.trim();
    final String raw = _amount.text.trim().replaceAll(',', '.');
    final double? amount = double.tryParse(raw);
    if (name.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a description and a positive amount.');
      return;
    }
    setState(() {
      _items.add(_ExpenseEntry(name, amount));
      _name.clear();
      _amount.clear();
      _error = null;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleMedium)),
                Text('${_items.length} item${_items.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                        hintText: 'Description', isDense: true),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: '$_sym Amount', isDense: true),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                IconButton(
                    onPressed: _add, icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12)),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text('No entries yet.',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              )
            else
              ..._items.asMap().entries.map((entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long, size: 20),
                    title: Text(entry.value.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_sym${entry.value.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () =>
                              setState(() => _items.removeAt(entry.key)),
                        ),
                      ],
                    ),
                  )),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Total',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(
                  '$_sym${_total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (_items.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(_items.clear),
                  child: const Text('Clear all'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
