# Integration tests

Renders canned A2UI samples through `ChatScreen` with a `FakeAiClient` — no API key.

From `examples/simple_chat`:

```bash
flutter pub get
flutter test integration_test/app_test.dart -d macos
```

Swap `macos` for any device from `flutter devices`. `flutter pub get` is
required first; without it you'll see a misleading `'../pubspec.yaml'` error
from the pub-workspace lookup.

## E2E — logic widgets (Linux headless)

Runs the genui logic widgets (2048, Reversi, Sudoku) inside the real host app
with the real Flutter engine + rendering, driving actual swipes/taps:

```sh
export PATH="$HOME/flutter_sdk/bin:$PATH"
cd examples/simple_chat
xvfb-run -a -s "-screen 0 1280x720x24" \
  flutter test integration_test/logic_e2e_test.dart -d linux
```

The test deliberately plays game gestures (drag/swipe on 2048) that pure
widget-build tests cannot, catching game-breaking crashes the unit suite misses.
