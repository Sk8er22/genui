// E2E test for genui logic widgets, run inside the simple_chat host app on
// Linux (real engine + rendering, headless via xvfb).
//
// Run:
//   xvfb-run -a -s "-screen 0 1280x720x24" \
//     flutter test integration_test/logic_e2e_test.dart -d linux

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Reach into the genui package source for the logic widgets (workspace dep).
// URI is relative to THIS file (integration_test/), so 3 levels up reaches
// the monorepo root, then packages/genui.
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_2048.dart' as g2048;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_reversi.dart' as reversi;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_sudoku.dart' as sudoku;

Future<void> pumpGame(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Center(
              child: SizedBox(width: 400, height: 700, child: child)))));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('e2e: 2048 handles swipes without crashing', (tester) async {
    await pumpGame(tester, g2048.Logic2048Widget(title: 'g'));
    await tester.pumpAndSettle();
    final game = find.byType(g2048.Logic2048Widget);
    for (final dir in [
      const Offset(-250, 0), const Offset(250, 0),
      const Offset(0, -250), const Offset(0, 250),
    ]) {
      await tester.drag(game, dir);
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('e2e: reversi renders a stable board', (tester) async {
    await pumpGame(tester, reversi.LogicReversiWidget(title: 'o'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('e2e: sudoku renders its 4x4 board', (tester) async {
    await pumpGame(tester, sudoku.LogicSudokuWidget(title: 's'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
