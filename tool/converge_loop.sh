#!/usr/bin/env bash
# genui CONVERGENCE loop — self-chaining improvement cycles with stop hooks.
#
# Unlike the fixed-interval cron (one shot every 30m), this runs continuous
# cycles back-to-back: when a cycle finishes it immediately starts the next one
# of the same kind, UNTIL the DeepSeek Harness judges no more useful work
# remains (writes CONVERGED), or the cycle budget is exhausted, or a cycle
# produces no code change (nothing left to do).
#
# Each cycle = a "hook" decision point: dsh reviews current state, picks ONE
# concrete improvement (new logic widget OR real bug fix), implements it, then
# writes a verdict file:
#    CONTINUE:<what to do next>   -> loop chains the next cycle immediately
#    CONVERGED:<reason>           -> loop stops (believes it's enough)
#
# Usage:
#   tool/converge_loop.sh [max_cycles]           # default 8
#   tool/converge_loop.sh --forever              # ignore the cycle cap
set -uo pipefail

DSHBIN="${DSHBIN:-/tmp/dsh/apps/cli/lib/bin.js}"
GENUI="${GENUI:-/tmp/genui}"
VERDICT="/tmp/genui_loop_verdict.txt"
export DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-local-ondevice}"
export DSH_TELEMETRY_MODE=DISABLED
export PATH="$HOME/flutter_sdk/bin:$PATH"

MAX="${1:-8}"
if [ "$MAX" = "--forever" ]; then MAX=1000000; echo "[loop] mode: --forever (no cycle cap)"; fi

echo "[loop] convergence loop start (max_cycles=$MAX)"
echo "[loop] harness: $DSHBIN | repo: $GENUI"

cycle=0
FAILS=0
while true; do
  cycle=$((cycle+1))
  if [ "$cycle" -gt "$MAX" ]; then
    echo "[loop] STOP — reached max_cycles=$MAX"
    break
  fi
  echo
  echo "═══════════ CYCLE $cycle ═══════════"

  # --- HOOK: clear verdict, ask harness to improve + judge convergence ---
  : > "$VERDICT"
  _PROMPT="/tmp/genui_loop_prompt_${cycle}.txt"
  cat > "$_PROMPT" <<'PROMPTEOF'
CONVERGENCE LOOP CYCLE for the genui logic-widget catalog (__GENUI__).

STEP 1 — Pick ONE concrete improvement that does NOT already exist:
  * a NEW logic widget: create libraries/stubs/logic_<name>.dart
    (CatalogItem named Logic<Name>, schema via S.object, a StatefulWidget),
    then export it in packages/genui/lib/src/catalog.dart and register it in
    packages/genui/lib/src/catalog/basic_catalog.dart logicCatalogItems; OR
  * a REAL bug fix: read a widget + its gameplay to confirm the bug, then fix.
List current widgets first so you don't add a duplicate.

STEP 2 — Implement it (source only). Then CHECK: is there still more genuinely
useful improvement left? Write EXACTLY one line to __VERDICT__:
  CONTINUE:<one-line note on what remains>
  — if you still see useful new widgets or known bugs to fix, OR
  CONVERGED:<reason>
  — only if the catalog is in good shape and no more high-value work remains.
If you made NO code change this cycle, write CONVERGED:no-change.

Reply 'done'.
PROMPTEOF
  sed -i "s|__GENUI__|$GENUI|g; s|__VERDICT__|$VERDICT|g" "$_PROMPT"

  (
    cd "$GENUI" || exit 1
    node "$DSHBIN" --profile headless "$(cat "$_PROMPT")"
  ) | tail -5
  rm -f "$_PROMPT"

  # --- verify (analyze + unit tests) ---
  echo "[loop] verifying..."
  ( cd "$GENUI/packages/genui" && dart analyze >/tmp/genui_a.out 2>&1 )
  AN_ERR=$(grep -cE "error - |error •" /tmp/genui_a.out || true)
  ( cd "$GENUI/packages/genui" && flutter test >/tmp/genui_t.out 2>&1 )
  TEST_RC=$?
  PASS_LINE=$(grep -E "All tests passed|Some tests failed" /tmp/genui_t.out | tail -1)

  # --- E2E hook (if any source changed, also run the logic E2E on Linux) ---
  CHANGED=$(git -C "$GENUI" status --porcelain 2>/dev/null | wc -l)
  E2E_RESULT="skip(no change)"
  if [ "$AN_ERR" -eq 0 ] && [ "$TEST_RC" -eq 0 ] && [ "$CHANGED" -gt 0 ]; then
    echo "[loop] running E2E (Linux headless)..."
    ( cd "$GENUI/examples/simple_chat" && \
      xvfb-run -a -s "-screen 0 1280x720x24" \
        flutter test integration_test/logic_e2e_test.dart -d linux >/tmp/genui_e2e.out 2>&1 )
    E2E_RC=$?
    E2E_RESULT=$([ "$E2E_RC" -eq 0 ] && echo "pass" || echo "FAIL")
  fi

  # --- gate: red on analyze/test -> revert this cycle's work, mark a failure ---
  if [ "$AN_ERR" -ne 0 ] || [ "$TEST_RC" -ne 0 ]; then
    echo "[loop] VERIFY FAILED (analyze=$AN_ERR test_rc=$TEST_RC) -> revert this cycle"
    git -C "$GENUI" checkout -- . 2>/dev/null
    git -C "$GENUI" clean -fd \
      packages/genui/lib/src/catalog/usecases \
      packages/genui/test/usecases 2>/dev/null
    FAILS=$((FAILS+1))
    if [ "$FAILS" -ge "${MAX_FAILS:-3}" ]; then
      echo "[loop] STOP — $FAILS consecutive verification failures (model can't land green code)"
      break
    fi
    echo "[loop] reverted (failure $FAILS/$MAX_FAILS trying again next cycle)..."
    # skip the hooks below; go straight to the next cycle
    continue
  fi

  # --- commit + push if changes ---
  if [ "$CHANGED" -gt 0 ]; then
    git -C "$GENUI" add -A
    git -C "$GENUI" -c user.name="Sk8er22" -c user.email="sk8er22@users.noreply.github.com" \
      commit -q -m "feat(genui): convergence cycle $cycle — $(head -c 60 "$VERDICT")

verify: analyze 0 errs, $PASS_LINE, e2e=$E2E_RESULT."
    git -C "$GENUI" push origin linux-support 2>&1 | tail -1
    echo "[loop] committed + pushed (e2e=$E2E_RESULT)"
  else
    echo "[loop] no code change this cycle"
  fi

  # --- HOOK: read verdict -> decide to chain or stop ---
  VERDICT_TEXT="$(head -c 200 "$VERDICT" 2>/dev/null)"
  case "$VERDICT_TEXT" in
    CONVERGED:*)
      echo "[loop] CONVERGED — harness believes it's enough."
      echo "[loop] verdict: $VERDICT_TEXT"
      break
      ;;
    CONTINUE:*)
      echo "[loop] chaining next cycle -> $VERDICT_TEXT"
      # loop continues (while true) => start another of the same
      ;;
    *)
      echo "[loop] no clear verdict ('$VERDICT_TEXT'); stopping to avoid a runaway loop"
      break
      ;;
  esac
done

echo
echo "[loop] convergence loop finished after $cycle cycle(s)."
echo "[loop] last verdict: $(head -c 200 "$VERDICT" 2>/dev/null)"
