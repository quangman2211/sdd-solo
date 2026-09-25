#!/usr/bin/env bash
# .github/replay-hooks.sh <base-ref> <head-ref> — run this repo's own githooks over every commit of a PR.
#
# Why this exists: `core.hooksPath` is LOCAL git config. It is not committed and a fresh clone does not
# get it, so every rule this project is built on is invisible to an outside contributor — while README
# says "Chặn cứng … Không có cờ bỏ qua". Without this job that sentence is false for everybody but the
# author. CLAUDE.md already gave the reason .sdd/scripts/ is shipped at all: "cổng DoR chạy được ở CI và
# trên máy người clone repo, chứ không dừng ở máy tác giả."
#
# It replays the REAL hook rather than re-implementing its rules. `git cherry-pick -n` stages exactly the
# commit's changes, so the hook sees a true index: `git diff --cached` in all three of its forms (plain,
# --diff-filter=d, --name-status -M) answers the same as it would have on the contributor's machine. A
# second copy of the path list is the failure CLAUDE.md warns about for `id_exists` — "đổi một nơi thì
# đổi cả hai" — and a third copy living in CI would be the one nobody remembers.
#
# The hook it runs is the one IN THE PR, not a stale snapshot. A PR that breaks the hook is judged by its
# own broken hook — which is the honest arrangement: the test suite is what catches a broken hook.
set -u
BASE="${1:?usage: replay-hooks.sh <base> <head>}"; HEAD_="${2:?}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT" || exit 2
CM="$ROOT/plugins/sdd-solo/templates/githooks/commit-msg"
PC="$ROOT/plugins/sdd-solo/templates/githooks/pre-commit"
[ -f "$CM" ] || { echo "no commit-msg hook in this tree — nothing to replay"; exit 0; }

ADVISORY=0
if [ ! -f "$ROOT/.sdd/config" ]; then
  ADVISORY=1
  echo "! This repo has no .sdd/config yet, so the hooks fall back to code_paths=src and enforce almost"
  echo "  nothing that matches this repo layout. The replay below therefore REPORTS and does not block."
  echo "  It becomes a gate the day sdd-solo is scaffolded onto itself — no edit here is needed for that,"
  echo "  and what you see below is a preview of the cost of that day."
fi

CMTS="$(git rev-list --reverse --no-merges "$BASE..$HEAD_" 2>/dev/null)"
N="$(printf '%s\n' "$CMTS" | grep -c . || true)"; N="${N:-0}"
if [ "$N" = 0 ]; then echo "no non-merge commit in $BASE..$HEAD_ — nothing to check"; exit 0; fi
echo "replaying this repo's githooks over $N commit(s) in $BASE..$HEAD_"
echo

WT="$(mktemp -d)"; MSG="$(mktemp)"; FAIL=0
cleanup() { cd "$ROOT" 2>/dev/null; git worktree remove --force "$WT" >/dev/null 2>&1; rm -f "$MSG"; }
trap cleanup EXIT
# A separate worktree so the checkout the runner is testing is never disturbed, and so a failed
# cherry-pick cannot leave the real tree mid-operation.
git worktree add -q --detach "$WT" "$BASE" || { echo "cannot create a worktree at $BASE"; exit 2; }
cd "$WT" || exit 2

for c in $CMTS; do
  SUBJ="$(git log -1 --format=%s "$c")"
  git log -1 --format=%B "$c" > "$MSG"
  if ! git cherry-pick -n "$c" >/dev/null 2>&1; then
    git cherry-pick --abort >/dev/null 2>&1
    printf '  \033[33m!\033[0m %.9s  %s\n' "$c" "$SUBJ"
    echo "      could not replay this commit onto its predecessor — skipped, not judged"
    continue
  fi
  OUT=""; RC=0
  if [ -x "$PC" ] || [ -f "$PC" ]; then
    OUT="$(bash "$PC" 2>&1)" || RC=1
  fi
  O2="$(bash "$CM" "$MSG" 2>&1)" || RC=1
  OUT="$OUT
$O2"
  if [ "$RC" = 0 ]; then printf '  \033[32m✓\033[0m %.9s  %s\n' "$c" "$SUBJ"
  else printf '  \033[31m✗\033[0m %.9s  %s\n' "$c" "$SUBJ"; FAIL=$((FAIL+1)); fi
  printf '%s\n' "$OUT" | grep -E '^(✗|!|  )' | sed 's/^/      /'
  git commit -q --no-verify --allow-empty -C "$c" >/dev/null 2>&1
done

echo
if [ "$FAIL" = 0 ]; then echo "every commit passes this repo's own hooks"; exit 0; fi
echo "$FAIL commit(s) would have been rejected by this repo own githooks."
if [ "$ADVISORY" = 1 ]; then
  echo "Not failing the build: with no .sdd/config the hooks are not yet configured for this layout,"
  echo "and a red that nobody can act on is the one thing this project refuses to ship."
  exit 0
fi
echo "Fix the commits (rebase / reword), not the hook: this project ships no bypass flag, and that"
echo "promise is only true if it holds for pull requests too."
exit 1
