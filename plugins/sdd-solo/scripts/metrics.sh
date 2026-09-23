#!/usr/bin/env bash
# metrics.sh — two indicators counted from git: the trace ratio and the AC coverage.
# Folded in from trace-ratio.sh + ac-coverage.sh (4.0.0); only `status.sh` calls it, and it calls both
# one after the other. Each count is unchanged — every line in here stands on a measured case
# (#16 an invented label · #30 a mixed denominator · #31 tool_paths).
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"

# ── Trace ratio ───────────────────────────────────────────────────────────
# tool_paths is out of the denominator: it is code belonging to no UC, so counting it as
# "a commit with a traceable ID" asks a question with no right answer (#31).
TOOLS="$(tool_paths "$ROOT")"
P="$(printf '%s %s' "$(code_paths "$ROOT")" "$(test_paths "$ROOT")" | tr ' ' '\n' | awk 'NF&&!a[$0]++' | tr '\n' ' ' | sed 's/ *$//')"
if [ -n "$TOOLS" ]; then
  P="$(printf '%s\n' $P | grep -vxF -e "$(printf '%s\n' $TOOLS)" | tr '\n' ' ' | sed 's/ *$//')"
fi
total=$(git -C "$ROOT" log --format=%s -- $P 2>/dev/null | grep -vE '^chore\(sdd\)' | wc -l | tr -d ' ')
# Count IDs THAT EXIST, not "things shaped like an ID". Before 2.1.2 this indicator reported 10/10
# on a repo that had just been holed with 4 invented labels — the indicator was lying. See #16.
traced=0; fake=0
while IFS= read -r sj; do
  [ -z "$sj" ] && continue
  id="$(printf '%s' "$sj" | grep -oE '\((UC|BR|RULE|ADR|CHG)-[0-9]+\)' | head -1 | tr -d '()')"
  [ -z "$id" ] && continue
  if id_exists "$id" "$ROOT"; then traced=$((traced+1)); else fake=$((fake+1)); fi
done <<EOF
$(git -C "$ROOT" log --format=%s -- $P 2>/dev/null)
EOF
if [ "$total" = "0" ] && repo_has_code "$ROOT"; then
  # 0/0 reads as "clean" when it really means "blind" — the repo has code, but not in
  # the paths being counted.
  echo "Trace ratio: ? — the repo has source files but no commit touches: $P"
  echo "            → fix code_paths/test_paths in .sdd/config"
else
  echo "Trace ratio (commits in $(printf '%s' "$P" | sed 's/ /, /g') carrying an ID THAT EXISTS): $traced/$total"
  [ "$fake" -gt 0 ] && echo "            ⚠ $fake commits carry an ID that exists nowhere in the repo — a label that got waved through"
fi

# ── AC coverage ───────────────────────────────────────────────────────────
UCT="$(uc_test_dir "$ROOT")"
# TWO lines, each declaring its own DENOMINATOR (#30). Before 3.19.0 there was one line mixing the ACs
# of a UC through the gate with the ACs of a UC still in draft — so the indicator could NEVER reach 100%
# while a single UC sat in draft, and sitting in draft for months is something this process encourages.
# That number was CORRECT, just correct for a question nobody was asking (error class #9): it mixed
# "have I got tests for what I committed to" with "how much of the spec is built".
tot_a=0; tot_g=0; tst_a=0; tst_g=0
for f in $(all_uc_files "$ROOT"); do
  id="$(basename "$f" .md)"; ctx="$(owner_of "$f")"
  n=$(grep -cE '^### AC-[0-9]+' "$f" 2>/dev/null || true); n=${n:-0}
  t=$(find "$ROOT/$UCT/$ctx/$id" -name 'AC-*.test.*' 2>/dev/null | wc -l | tr -d ' ')
  tot_a=$((tot_a+n)); tst_a=$((tst_a+t))
  if [ -f "$ROOT/.sdd/gate/$id.ok" ]; then tot_g=$((tot_g+n)); tst_g=$((tst_g+t)); fi
done
if [ "$tot_a" = "0" ]; then echo "AC coverage: no AC yet"; exit 0; fi
if [ ! -d "$ROOT/$UCT" ]; then
  echo "AC coverage: ? — there is no $UCT directory yet (check uc_test_dir in .sdd/config). Total ACs: $tot_a"
  exit 0
fi
# This line CAN reach 100%, which is what makes it worth tracking.
echo "ACs with a test / ACs of a UC through the gate:   $tst_g/$tot_g"
echo "ACs with a test / ACs of EVERY UC (draft included): $tst_a/$tot_a"
