#!/usr/bin/env bash
# genui self-improvement loop, driven by the DeepSeek harness (dsh).
#
# One cycle:
#   1. Ask dsh (headless) what to improve / which new logic widget to add.
#   2. dsh implements it in packages/genui (source write only, no build).
#   3. Parent verifies: dart analyze (0 errors) + full genui test suite.
#   4. If green -> commit + push to Sk8er22/genui linux-support; write summary.
#   5. If red  -> capture the error, hand back to dsh once to fix; else abort.
#
# Env: DEEPSEEK_API_KEY=local-ondevice  DSH_TELEMETRY_MODE=DISABLED
#      DSHBIN=/tmp/dsh/apps/cli/lib/bin.js   GENUI=/tmp/genui
set -uo pipefail

DSHBIN="${DSHBIN:-/tmp/dsh/apps/cli/lib/bin.js}"
GENUI="${GENUI:-/tmp/genui}"
export DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-local-ondevice}"
export DSH_TELEMETRY_MODE=DISABLED

TASK="${1:-}"
if [ -z "$TASK" ]; then
  echo "usage: $0 '<self-improvement task for dsh>'"
  exit 2
fi

echo "[loop] task: $TASK"

# --- 1+2: dsh reviews + implements (source only) ---
(
  cd "$GENUI" || exit 1
  node "$DSHBIN" --profile headless "$TASK"
) | tee /tmp/genui_loop_cycle.log
DS_RC=${PIPESTATUS[0]}
echo "[loop] dsh exit=$DS_RC"

# --- 3: verify ---
export PATH="$HOME/flutter_sdk/bin:$PATH"
echo "[loop] analyzing..."
( cd "$GENUI/packages/genui" && dart analyze > /tmp/genui_loop_analyze.out 2>&1 )
AN_ERR=$(grep -cE "error - |error •" /tmp/genui_loop_analyze.out || true)
echo "[loop] analyze errors: $AN_ERR"

echo "[loop] running tests..."
( cd "$GENUI/packages/genui" && flutter test > /tmp/genui_loop_test.out 2>&1 )
TEST_RC=$?
pass_line=$(grep -E "All tests passed|Some tests failed" /tmp/genui_loop_test.out | tail -1)

if [ "$AN_ERR" -ne 0 ] || [ "$TEST_RC" -ne 0 ]; then
  echo "[loop] VERIFY FAILED (analyze_errs=$AN_ERR test_rc=$TEST_RC) -> abort"
  echo "analyze tail:"; tail -5 /tmp/genui_loop_analyze.out
  echo "test tail:"; tail -8 /tmp/genui_loop_test.out
  exit 1
fi

# --- 4: commit + push ---
cd "$GENUI" || exit 1
MSG=$(git status --porcelain | wc -l)
if [ "$MSG" -eq 0 ]; then
  echo "[loop] no changes; nothing to commit"
else
  git add -A
  git -c user.name="Sk8er22" -c user.email="sk8er22@users.noreply.github.com" \
      commit -q -m "feat(genui): self-improvement loop — $TASK

Cycle verify: dart analyze 0 errors; genui tests pass ($pass_line)." 
  git push origin linux-support 2>&1 | tail -1
fi

echo "[loop] completed: $pass_line"
echo "[loop] full cycle log: /tmp/genui_loop_cycle.log"
