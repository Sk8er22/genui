# Review: `packages/genui/lib/src/catalog/usecases/` (logic widgets)

Scope: 44 `Logic*` stateful widget files (tier‑L logic catalog), the shared
`CatalogItem` contract, and how they are registered
(`basic_catalog.dart` / `catalog.dart` exports). All findings below were
confirmed by tracing the code (the sandbox has no usable command backend, so
everything was verified by hand; line numbers refer to the current files).

---

## 1. Concrete logic bugs / edge‑case holes

**#1 — `logic_chess.dart` `_movesFor()` (lines 99–142): missing `return`/`break` in every non‑pawn `case` → package does not compile (and would cross‑contaminate move sets if it did).**
The `switch (type)` clauses for `'k'`, `'q'`, `'r'`, `'b'`, `'n'` each end in a plain loop that falls through into the *next* case. Dart requires non‑empty case bodies to complete with `break`/`continue`/`return`/`throw` (`case_clause_complete_normally`), so `flutter analyze` fails on this file, which is imported by `basic_catalog.dart` and exported by `catalog.dart` — the whole genui package stops building. If the fall‑through were (incorrectly) accepted by a transpiler, a knight would *also* be given rook moves, bishop would get queen moves, etc. (Note: `case 'p'` is last and is fine.)

**#2 — `logic_chess.dart` `_tap()`/`_applyMove()` (lines 225–257): game continues after checkmate/stalemate.**
`_status` is set to 'Checkmate…' / 'Stalemate…' but nothing stops further input; `_tap` happily moves the other side after the game is decided, and the status line then flips to the regular "… to move". A finished game should freeze the board.

**#3 — `logic_2048.dart` `_move()` (lines 73–113): every swipe throws `RangeError` — the game is unplayable.**
The line gatherer starts at every `(i, j)` (both in `[0..3]`) and then walks **4 cells in the `+dr/+dc` direction**: for a left swipe (`dc = -1`) the very first column `j = 0` produces `(i, 0), (i, -1), (i, -2), (i, -3)` → `_g[i][-1]` throws. Up/down/right crash identically on their first iteration (e.g. up starts at `i = 0` → `_g[-1][c]`; down starts at `i = 3` → `_g[4][c]`; right starts at `j = 3` → `_g[r][4]`). The `line.map((p) => _g[p.$1][p.$2])` index immediately throws, so **every swipe in every direction** crashes the app before any tile moves. There is also dead `final List<int?> cells = [];`.

**#4 — `logic_reversi.dart` `_isLegal()` (lines 88–91) + `_applyPlace()` (lines 66–86): legality probing mutates the live board — plain rendering corrupts the game.**
`_isLegal` calls `_applyPlace(r, c, me)` directly on `_board`, which **flips discs as a side effect**, and `_isLegal` is called from `build`'s `itemBuilder` for every empty cell on every frame, plus from `_anyMove` and `_tap`. So merely painting the widget flips the user's and opponent's discs; `_tap` then applies flips a second time (`_applyPlace` again inside `setState`). The board is scrambled on every rebuild → Othello is functionally broken.

**#5 — `logic_sudoku.dart` `_generate()` (lines 56–85): the "solution" grid is not a valid 4×4 Sudoku.**
The formula `((r % 2) * 2 + (c % 2) + r + c) % 4 + 1` yields duplicates inside rows — e.g. row 0 = `[1, 3, 3, 1]` (missing 2 and 4). `_check()` compares the player's board to this invalid pattern, so a genuinely correct solve is always marked "Not yet", and the "solution" the puzzle is derived from is contradictory. Since given cells are copied from this invalid grid, `_check` can never be satisfied correctly.

**#6 — `logic_calculator.dart` `_eval()` (lines 115–121): double operators crash instead of showing "Error".**
The in‑loop reduction `while (ops.isNotEmpty && …) { b = values.removeLast(); a = values.removeLast(); … }` pops twice without a length guard. Input `5 + + 3 =` (or any repeated/degenerate operator sequence such as `5 + × 3`) leaves `values` with fewer than 2 entries → `StateError: No element` escapes from `setState` — an uncaught exception (UI crash) instead of the intended `Error` display.

**#7 — `logic_wordle.dart` `_key()` (line 242) + `_submit()`/`initState` (lines 76, 97–134): the Enter key is rendered as a backspace, and a short model word crashes on submit.**
`Text(ch.length > 1 ? '⌫' : ch)` shows the backspace glyph for `'⏎'` (Enter is the only multi‑char key, so the Enter key displays ⌫; the actual ⌫ key shows itself correctly). Separately, the schema accepts any string for `word`, but the code assumes exactly 5 uppercase letters: a target shorter than 5 letters makes `guess[i] == _target[i]` (and the count loop) index `_target` out of range → `RangeError` on the first submit; a lowercase target makes every keystroke mismatch the uppercase keyboard → guaranteed loss. The word should be normalized/validated (uppercase, stripped to 5) at bind time.

**#8 — `logic_handwriting.dart` build Next button (lines 116–117): modulo-by-zero crash on empty `items`.**
`_index = (_index + 1) % widget.items.length` throws `UnsupportedError` when the model supplies `"items": []` (allowed by `required` — the LLM can emit an empty list). The progress label also shows `1/0`. The getter `_current` guards against empty, but the button does not.

**#9 — `logic_clock_reading.dart` build (lines 101–108): answer options are randomized on every build instead of once per round.**
`opts` (distractors + correct‑answer insertion position) is generated with `_rng` directly inside `build`, which re‑runs on *every* `setState`. After the user taps an option, the follow‑up rebuild reshuffles the list, so the correct/highlighted cards (`o == correctOpt`, `o == _chosen`) no longer line up with the option the user actually selected and with the score. `_next()` should generate and store the option list.

**#10 — `logic_trivia.dart` build reveal (line 147): out-of-range answer index crashes at reveal.**
`options[widget.questions[qi].answer]` is indexed with no bounds check; a model answer ≥ `options.length` (or an empty `options`) throws `RangeError` when the user hits "Reveal results". (This is a pure-indexing hole; `LogicQuizCard` avoids it by only *comparing* `i == widget.answer`.)

**#11 — `logic_rps.dart` build (lines 69–83): dead/nonsense "verdict" line.**
The `verdict` expression only produces `'Tie'` when the total game count is exactly 1 *and* the first round was a tie; otherwise it's `null` and the `Text` renders a tautology (`'$verdict${verdict == null ? "" : ""}'`). The actual verdict is already rendered below (`You win! / AI wins / It's a tie`). Additionally the file documents a "previous-move counter AI" but `_play` uses `_rng.nextInt(3)` and `_aiPrev` is dead.

**#12 — `logic_simon.dart` `_press()` (lines 93–108): game hard-locks after a wrong guess.**
On a wrong press the state sets `_playing = true` and shows "Wrong!" but nothing ever replays the sequence or returns to the player's turn — every pad press is ignored afterwards (`if (_playing) return;`). Only "Restart" recovers.

**#13 — `logic_wheel_picker.dart` `_spin()` (lines 59–66) + `_WheelPainter`: the wheel rotation has no relation to the picked result.**
`_start` (rotation) and `_result` are two independent `_rng` draws, and the painter draws **no pointer/indicator** — so the wheel is a cosmetic animation that contradicts its own outcome: the announced result does not correspond to any wedge the wheel "landed" on. There is also no spin animation (the rotation teleports).

**#14 — `logic_memory_game.dart` `_cols` (lines 66–69) + `_deal` (lines 77–88): non-square/ragged and ambiguous grids for non-8 pair counts.**
`math.sqrt(pairs * 2).round()` produces a ragged grid for, e.g., `pairs = 7` (14 cards in a 4‑col grid), and `pairs` is only clamped at the low end (≥ 4): for `pairs > 12` the deck uses `_emojis[i % 12]`, so two different pairs display the same face emoji — matches become visually ambiguous even though internal ids differ.

**#15 — `logic_gravity.dart` build (lines 125–129): build-time state mutation + floor plane mismatch.**
`_area` is assigned as a side effect of `build` (inside `LayoutBuilder`), and the collision floor derives from parent constraints with a 360px fallback while the visible container is a fixed 330px tall — balls quoted between 330 and ~360 are drawn outside/clipped at the bottom of the visible pit. Cosmetic, but it's an impure build and the physics pit doesn't match the rendered box.

**#16 — Lesser defects (recorded for completeness).**
- `logic_password_gen.dart` `_strength` (lines 79–83): scale mismatch — strength can reach `12.0` while the label claims `/6` (bar clamps, text doesn't); also `math.Random` is used for a widget advertised as producing "secure" passwords.
- `logic_currency.dart` line 48: `r'C\$'` in a raw string is a literal `C\$` (backslash visible) for the CAD symbol; `rate == 0` (model input) makes the flipped display `1/0` → `Infinity`, and `Infinity.toStringAsFixed(4)` throws.
- `logic_battleship.dart` `_tryPlace` (lines 94–118): silently gives up after 20 attempts, so a generated game can contain fewer than the intended 3 ships.
- `logic_codebreaker.dart`: `_tries = 10` only shows a message; `_submit` keeps accepting guesses past 10.
- `logic_hangman.dart` (lines 64–97): a model word with lowercase letters (or spaces/hyphens) is unwinnable / miscounted — every letter never matches `_guessed` (keyboard is uppercase A–Z).
- `logic_poll_vote.dart` `_vote` (lines 78–86): the `_myVote != null` re‑vote branch is dead (guarded by `_voted`), harmless but misleading; negative `votes` from the model render bogus bars.
- `logic_tip_calculator.dart`/`logic_bmi.dart`: no guard for zero/negative inputs (BMI with `weight=0` → category "Underweight"; no crash).

---

## 2. Exact fixes for the 3 most important

### Fix A — `logic_2048.dart` `_move()` (bug #3; game-crashing)
Gather each lane starting from the **destination edge** and step inward; the lane is a fixed row (for horizontal moves) or column (for vertical moves). Replace the whole `_move` body:

```dart
bool _move(int dr, int dc) {
  bool moved = false;
  // Index of the edge tiles slide toward, and the step direction from it.
  final int edge = dr != 0 ? (dr > 0 ? 3 : 0) : (dc > 0 ? 3 : 0);
  final int step = dr != 0 ? (dr > 0 ? -1 : 1) : (dc > 0 ? -1 : 1);

  for (var lane = 0; lane < 4; lane++) {
    // Read the 4 cells of this lane in travel order (destination first).
    final List<int> line = [];
    var k = edge;
    for (var t = 0; t < 4; t++) {
      line.add(dr != 0 ? _g[k][lane] : _g[lane][k]);
      k += step;
    }
    final List<int> vals = line.where((v) => v != 0).toList();
    if (vals.isEmpty) continue;

    final List<int> merged = [];
    for (var t = 0; t < vals.length; t++) {
      if (t + 1 < vals.length && vals[t] == vals[t + 1]) {
        final int nv = vals[t] * 2;
        merged.add(nv);
        _score += nv;
        if (nv == 2048) _won = true;
        t++; // consume the pair
      } else {
        merged.add(vals[t]);
      }
    }

    // Write back in travel order, zero-filling the rest of the lane.
    k = edge;
    for (var t = 0; t < 4; t++) {
      final int value = t < merged.length ? merged[t] : 0;
      if (dr != 0) {
        if (_g[k][lane] != value) moved = true;
        _g[k][lane] = value;
      } else {
        if (_g[lane][k] != value) moved = true;
        _g[lane][k] = value;
      }
      k += step;
    }
  }
  return moved;
}
```

### Fix B — `logic_reversi.dart` `_isLegal()` / `_applyPlace()` (bug #4; board corruption)
Make `_applyPlace` take an explicit board and make `_isLegal` probe on a **copy**, then apply flips exactly once per move:

```dart
int _applyPlace(int r, int c, int me, List<List<int?>> board) {
  final int opp = me == 1 ? 2 : 1;
  int flips = 0;
  for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0),
      (1, 1), (1, -1), (-1, 1), (-1, -1)]) {
    var rr = r + d.$1, cc = c + d.$2;
    final List<(int, int)> toFlip = [];
    while (_in(rr, cc) && board[rr][cc] == opp) {
      toFlip.add((rr, cc));
      rr += d.$1;
      cc += d.$2;
    }
    if (_in(rr, cc) && board[rr][cc] == me) {
      for (final (x, y) in toFlip) {
        board[x][y] = me;
      }
      flips += toFlip.length;
    }
  }
  return flips;
}

bool _isLegal(int r, int c, int me) {
  if (_board[r][c] != null) return false;
  final List<List<int?>> probe =
      [for (final row in _board) List<int?>.from(row)]; // dry run only
  return _applyPlace(r, c, me, probe) > 0;
}
```

…and in `_tap` apply flips to the real board once (the duplicate `_applyPlace` call in the `setState` block goes away; the stone placement stays):

```dart
void _tap(int r, int c) {
  if (_gameOver || !_isLegal(r, c, _black ? 1 : 2)) return;
  setState(() {
    _board[r][c] = _black ? 1 : 2;
    _applyPlace(r, c, _black ? 1 : 2, _board); // single, real application
    ...
  });
}
```

### Fix C — `logic_chess.dart` `_movesFor()` switch fall-through (bug #1; build breaker)
Add a `return out;` (or `break;`) after each non-pawn case so every piece gets its own move set. The `'p'` case can stay last:

```dart
switch (type) {
  case 'n':
    for (final (dr, dc) in const [(2, 1), (2, -1), (-2, 1), (-2, -1),
        (1, 2), (1, -2), (-1, 2), (-1, -2)]) {
      final rr = r + dr, cc = c + dc;
      if (_inBounds(rr, cc) && _board[rr][cc] == null) out.add((rr, cc));
      if (_inBounds(rr, cc) && _isEnemy(rr, cc)) out.add((rr, cc));
    }
    return out;
  case 'r': /* ... */ return out;
  case 'b': /* ... */ return out;
  case 'q': /* ... */ return out;
  case 'k': /* ... */ return out;
  case 'p':
    /* ... */
}
return out;
```

While here, also block further play once the game is decided — at the top of `_tap`:

```dart
void _tap(int r, int c) {
  if (_status != null) return; // freezes the board at mate/stalemate
  ...
}
```

---

## 3. Five new logic-widget ideas

- `LogicSortingVisualizer`: Animate bubble/quick sort on a model-supplied list with play/pause/step and a swap counter.
- `LogicIntervalTimer`: Multi-interval round timer (work/rest) with chime, auto-advance and a progress ring.
- `LogicBudgetSplitter`: Enter a bill and participants to split items, then compute who owes whom in simplified IOU form.
- `LogicTypingSpeed`: Timed typing drill on a model-supplied passage with live WPM, accuracy and best-round history.
- `LogicDailyStreakTracker`: Tap-to-check habits on a mini month calendar with current streak and a heat strip.

---

### Quick reference (file → most severe issue)
| File | Issue |
|---|---|
| logic_chess.dart | switch fall-through (won't compile) + play-after-game-over |
| logic_2048.dart | `_move` out-of-bounds crash on every swipe |
| logic_reversi.dart | `_isLegal` mutates live board during build/tap |
| logic_sudoku.dart | invalid generated solution → `_check` can never pass |
| logic_calculator.dart | `_eval` StateError on double operators |
| logic_wordle.dart | Enter shows ⌫; short/odd-model-word crashes submit |
| logic_handwriting.dart | `% items.length` → UnsupportedError on empty items |
| logic_clock_reading.dart | options re-rolled every build (wrong highlight/order) |
| logic_trivia.dart | reveal indexes `options[answer]` unguarded |
| logic_rps.dart | dead "verdict" line; "counter AI" is random |
| logic_simon.dart | hard-lock after a wrong guess |
| logic_wheel_picker.dart | rotation unrelated to result; no pointer |
| logic_memory_game.dart | ragged/ambiguous grids for non-8 pair counts |
| logic_gravity.dart | build-time `_area` side effect; floor ≠ visible box |
