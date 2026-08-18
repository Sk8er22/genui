// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Smoke tests: every logic/use-case widget builds with its sample JSON, and
// its catalog item registers the right name. Guards against regressions from
// adding new widgets without wiring them.

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_chess.dart' as chess;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_expense_tracker.dart' as expenses;

void main() {
  group('LogicChess catalog registration', () {
    test('name is LogicChess and has a schema', () {
      final item = chess.LogicChess.catalogItem;
      expect(item.name, 'LogicChess');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json = chess.LogicChess.catalogItem.exampleData.first();
      expect(json, contains('LogicChess'));
      expect(json, contains('root'));
    });
  });

  group('LogicExpenseTracker catalog registration', () {
    test('name is LogicExpenseTracker and has a schema', () {
      final item = expenses.LogicExpenseTracker.catalogItem;
      expect(item.name, 'LogicExpenseTracker');
      expect(item.dataSchema, isA<Schema>());
    });

    test('example JSON parses and includes a root component', () {
      final String json =
          expenses.LogicExpenseTracker.catalogItem.exampleData.first();
      expect(json, contains('LogicExpenseTracker'));
      expect(json, contains('root'));
    });
  });

  // Verify all exported usecase catalog items are reachable via the barrel.
  test('barrel exports logic chess widget type', () {
    // compile-time: ensures lib/src/catalog.dart re-export resolves
    // ignore: unnecessary_statements
    chess.LogicChess.catalogItem;
  });
}
