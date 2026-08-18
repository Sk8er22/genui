// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regression tests for logic-widget bugs found by the DeepSeek Harness review.
// These exercise gameplay paths (swipe/move/render) that pure-build tests can't.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_2048.dart' as g2048;
// ignore: avoid_relative_lib_imports
import '../../lib/src/catalog/usecases/logic_reversi.dart' as reversi;

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
}
