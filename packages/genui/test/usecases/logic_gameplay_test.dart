// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regression tests for logic-widget bugs found by the DeepSeek Harness review.
// These exercise gameplay paths (swipe/move/render) that pure-build tests can't.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_2048.dart' as g2048;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_reversi.dart' as reversi;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_expense_tracker.dart' as expenses;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_snake.dart' as snake;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_pathfinding.dart' as pathfinding;

Future<void> pumpSized(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Center(
              child: SizedBox(width: 320, height: 620, child: child)))));
}

void main() {
  testWidgets('2048 swipe does not crash', (tester) async {
    await pumpSized(tester, g2048.Logic2048Widget(title: 't'));
    await tester.pumpAndSettle();
    final finder = find.byType(g2048.Logic2048Widget);
    await tester.drag(finder, const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.drag(finder, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reversi renders without board corruption', (tester) async {
    await pumpSized(tester, reversi.LogicReversiWidget(title: 'o'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('expense tracker adds entries and updates the total',
      (tester) async {
    await pumpSized(tester, expenses.LogicExpenseTrackerWidget(
        title: 'Trip', currency: 'USD'));
    await tester.pumpAndSettle();

    // Rejects empty/invalid input without crashing.
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Add two entries: $12.50 + $7.00 = $19.50.
    await tester.enterText(find.byType(TextField).first, 'Lunch');
    await tester.enterText(find.byType(TextField).last, '12.50');
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Taxi');
    await tester.enterText(find.byType(TextField).last, '7');
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text(r'$19.50'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Taxi'), findsOneWidget);

    // Deleting the first entry leaves $7.00 (once as the entry, once as total).
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text(r'$7.00'), findsNWidgets(2));

    // Clearing resets the ledger.
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text('No entries yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snake ticks, steers, pauses and restarts without crashing',
      (tester) async {
    await pumpSized(tester, snake.LogicSnakeWidget(title: 's', gridSize: 10));
    await tester.pump();

    // Step the game loop with explicit durations — never pumpAndSettle, the
    // periodic timer would keep it from ever settling.
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    // Keyboard steering via the autofocused board.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 250));

    // Pause / resume, then restart.
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.tap(find.text('Restart'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
  });

  testWidgets('pathfinding BFS run animates and draws a route',
      (tester) async {
    await pumpSized(tester, pathfinding.LogicPathfindingWidget(title: 'pf'));
    await tester.pump();

    // Pick BFS (deterministic) and start the search. The seeded grid has a
    // start, an end and a wall pattern, so a route must exist.
    await tester.tap(find.text('BFS'));
    await tester.pump();
    await tester.tap(find.text('Run'));

    // Step the periodic timer explicitly — never pumpAndSettle while running.
    for (var i = 0; i < 120 &&
        find.textContaining('Shortest path').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Shortest path'), findsOneWidget);
  });
}
