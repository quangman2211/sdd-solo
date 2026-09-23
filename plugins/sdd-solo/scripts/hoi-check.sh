#!/usr/bin/env bash
# hoi-check.sh <role | file> [--lich-su] — check the addressed question log notes/hoi-dap/hoi-<V>.md (7.3). exit 1 if there is a ✗.
#   1. every ASK-<V>n entry has all four boxes (Source · Blocking · Doing while waiting · Spec work when answered), with no <…> left
#   2. `Blocking:` is blocking | not blocking
#   3. an answered entry must carry a `target:`; if the gate of its UC-### is open (.sdd/gate/UC-###.ok) and the target points into the
#      UC BODY (not design.md / decisions.md, and it does not say "AC") → ✗ — the rule: after the gate, a D/T question is answered in
#      design.md or decisions.md, and the UC body only reopens when an AC changes (runxops _chung.md rule 6; the 25 ASK entries of UC-025 each dragged a verify round)
#   4. the ASK-<V>n numbers do not repeat; a gap is a warning
#   --lich-su: look at `git log -p` — which commit EDITED an existing `### ASK-` line (the log is append-only); run at status, not in a githook
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; A="${1:-}"; [ -z "$A" ] && { sed -n '2,9p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
if [ -f "$A" ]; then F="$A"; V="$(basename "$A" .md | sed 's/^hoi-//')"; else V="$A"; F="$ROOT/notes/hoi-dap/hoi-$V.md"; fi
[ -f "$F" ] || { info "there is no ${F#$ROOT/} yet"; exit 0; }
echo "Question log of role $V — ${F#$ROOT/}"
if [ "$2" = --lich-su ] || [ "$3" = --lich-su ]; then
  N=0
  for h in $(git -C "$ROOT" log --format=%h --diff-filter=M -- "${F#$ROOT/}" 2>/dev/null); do
    if git -C "$ROOT" show "$h" -- "${F#$ROOT/}" | grep -qE "^-### ($(kw ask))-"; then N=$((N+1)); bad "$h edited an existing '### ASK-' line — the log is append-only: $(git -C "$ROOT" log -1 --format=%s "$h" | cut -c1-60)"; fi
  done
  [ "$N" = 0 ] && ok "no commit edited an existing ASK line"
fi
node "$HERE/js/hoi.mjs" "$F" "$V" "$ROOT"
R=$?; [ "$R" != 0 ] && FAIL=$((FAIL+1))
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
