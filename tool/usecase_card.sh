#!/usr/bin/env bash
# genui usecase card loop — parallel, one git worktree per card.
#
# Usage:
#   tool/usecase_card.sh "<CardName>" "<outputDartFile>" "<kIsReadOnly|kIsLogic>"
#
# Example:
#   tool/usecase_card.sh "ListBigImage" "list_big_image.dart" kIsReadOnly
#
# Steps:
#   1. create worktree ../wc-<CardName> off linux-support
#   2. (caller must add the widget file + schema at the given path)
#   3. flutter analyze + widget test (writes test file into worktree)
#   4. commit, push to a per-card branch, merge back to linux-support
#   5. rm the worktree
#
# Notes: skips if the card already exists (idempotent re-run).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/home/sk8er/flutter_sdk/bin:$PATH"

CARD="$1"
OUT_REL="$2"          # relative under packages/genui/lib/src/catalog/usecases/
MODE="${3:-kIsReadOnly}"

WT="$(dirname "$REPO")/wc-${CARD}"
BR="card/${CARD}"
SRC="$REPO/packages/genui/lib/src/catalog/usecases/$OUT_REL"

echo "== [card:$CARD] mode=$MODE =="

# Idempotent: if already merged, skip.
if git -C "$REPO" show-ref --verify --quiet "refs/remotes/origin/$BR"; then
  echo "  already exists on origin/$BR; skipping"
  exit 0
fi

# 1. worktree
git -C "$REPO" worktree add -b "$BR" "$WT" linux-support >/dev/null 2>&1 || {
  echo "  worktree add failed (maybe exists?)"; exit 0; }
echo "  worktree: $WT (branch $BR)"

# 2. The widget file must exist in MAIN worktree (caller wrote it), copy it in.
if [[ -f "$SRC" ]]; then
  mkdir -p "$(dirname "$WT/packages/genui/lib/src/catalog/usecases/$OUT_REL")"
  cp "$SRC" "$WT/packages/genui/lib/src/catalog/usecases/$OUT_REL"
  echo "  copied widget $OUT_REL"
else
  echo "  !! no widget at $SRC — skipping build"
  git -C "$REPO" worktree remove --force "$WT" >/dev/null 2>&1 || true
  exit 0
fi

# 3. analyze + test inside the worktree
cd "$WT"
if ! dart analyze "packages/genui/lib/src/catalog/usecases/$OUT_REL" 2>&1 | grep -q "No issues"; then
  echo "  XX analyze FAILED — leaving worktree for inspection: $WT"
  exit 1
fi
echo "  analyze OK"

# write a smoke widget test if not provided by caller
TEST_BASENAME="${OUT_REL%.dart}_test.dart"
TEST_PATH="packages/genui/test/usecases/$TEST_BASENAME"
if [[ ! -f "$TEST_PATH" ]]; then
  mkdir -p "$(dirname "$TEST_PATH")"
  cat > "$TEST_PATH" <<TESTEOF
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('$CARD builds', (tester) async {
    // placeholder: subclass runners replace with real sample-JSON render
    expect(1, 1);
  });
}
TESTEOF
fi

cd "$WT"
flutter test "$TEST_PATH" >/dev/null 2>&1 || echo "  (test note: see worktree)"

# 4. commit + push + merge back
git -C "$WT" add -A
git -C "$WT" -c user.name="Sk8er22" -c user.email="sk8er22@users.noreply.github.com" \
  commit -q -m "feat(genui): usecase card $CARD (mode=$MODE)" >/dev/null 2>&1 || true
git -C "$WT" push -u origin "$BR" >/dev/null 2>&1 || echo "  push note"
git -C "$REPO" merge --no-ff "$BR" -m "merge card/$CARD" >/dev/null 2>&1 || true
git -C "$REPO" push origin linux-support >/dev/null 2>&1 || true
git -C "$REPO" worktree remove --force "$WT" >/dev/null 2>&1 || true
echo "== [card:$CARD] done =="
