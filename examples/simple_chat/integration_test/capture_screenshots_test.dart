// Capture real rendered screenshots of logic widgets to ~/genui_shots/*.png.
// Run headless on Linux. Output: one PNG per widget, real pixels from the
// Flutter engine (RepaintBoundary.toImage), NOT mockups.
//
//   xvfb-run -a -s "-screen 0 1280x720x24" \
//     flutter test integration_test/capture_screenshots_test.dart -d linux

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_2048.dart' as w2048;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_chess.dart' as wchess;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_login.dart' as wlogin;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_handwriting.dart' as whand;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_piano.dart' as wpiano;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_otp.dart' as wotp;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_wordle.dart' as wwordle;
// ignore: avoid_relative_lib_imports
import '../../../packages/genui/lib/src/catalog/usecases/logic_sudoku.dart' as wsudoku;

Future<void> snap(WidgetTester tester, Widget child, String name) async {
  await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Center(
              child: RepaintBoundary(
                  key: const ValueKey('shot'),
                  child: SizedBox(width: 420, height: 700, child: child))))));
  await tester.pumpAndSettle();
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));

  Future<ByteData> capture() async {
    final ui.Image? image = await boundary.toImage(pixelRatio: 1.5);
    if (image == null) throw StateError('toImage returned null for $name');
    try {
      final ByteData? d = await image.toByteData(format: ui.ImageByteFormat.png);
      if (d == null) throw StateError('toByteData returned null for $name');
      return d;
    } finally {
      image.dispose();
    }
  }

  final ByteData? byteData = await tester.runAsync(capture);
  final String outDir = '${Directory.current.path}/genui_shots';
  await Directory(outDir).create(recursive: true);
  await File('$outDir/$name.png').writeAsBytes(
      byteData!.buffer.asUint8List(byteData!.offsetInBytes, byteData!.lengthInBytes));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture logic widget screenshots', (tester) async {
    await snap(tester, w2048.Logic2048Widget(title: '2048'), '2048');
    await snap(tester, wchess.LogicChessWidget(title: 'Chess'), 'chess');
    await snap(tester,
        wlogin.LogicLoginWidget(title: 'Sign in', demoPassword: 'demo123'),
        'login');
    await snap(tester, whand.LogicHandwritingWidget(
        title: 'Handwriting', items: const ['A', 'B', 'AB']), 'handwriting');
    await snap(tester, wpiano.LogicPianoWidget(title: 'Piano'), 'piano');
    await snap(tester, wotp.LogicOtpWidget(expected: '123456'), 'otp');
    await snap(tester, wwordle.LogicWordleWidget(word: 'ADOBE'), 'wordle');
    await snap(tester, wsudoku.LogicSudokuWidget(title: 'Sudoku'), 'sudoku');
  });
}
