#!/usr/bin/env bash
# close-check.sh UC-### — Definition of Done. exit 0 = it can be closed.
ID="$1"; [ -z "$ID" ] && { echo "usage: close-check.sh UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
echo "Definition of Done — $ID"
[ -z "$F" ] && { bad "cannot find the UC file"; exit 1; }
CTX="$(owner_of "$F")"; SLUG="$(slug_of "$F")"
[ -f "$ROOT/.sdd/gate/$ID.ok" ] && ok "through the DoR gate" || bad "no .sdd/gate/$ID.ok marker — run /sdd-solo:gate"
# 7.4 (P-10): the gate marker says "the spec WAS re-read at commit X". Editing an AC after X with a docs(UC-###) commit
# leaves the marker in place while what it certifies is gone — up to 7.3 no script compared again. The §9 fingerprint of
# gate-check (lib: fp_changed) compares from the gate-pass commit to HEAD: Main/Alt/Exceptions/Postconditions/AC · flow · the RULE statements · the entities mermaid.
GH="$(git -C "$ROOT" log -1 -E --format=%H --grep="^docs\($ID\): spec reviewed — ($(kw c_dor))" 2>/dev/null)"
if [ -n "$GH" ]; then
  CHG="$(fp_changed "$ROOT" "$ID" "$GH" HEAD "$(entity_cited "$F" "$ROOT" | tr '\n' ' ')")"
  ST="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$F" | head -1 | awk '{print $2}')"
  if [ -z "$CHG" ]; then ok "the behavioural fingerprint is unchanged since the gate commit"
  elif [ "$ST" = implemented ] || [ "$ST" = deprecated ]; then
    # A closed UC: a change after the gate is a historical trace (Phase 5, a rule edited for another UC) — there is nothing
    # left to re-verify. Measured at runxops 7.4: 10 of 12 implemented UCs had a changed area; blocking would make close-check
    # red on something already closed, and a false red gets ignored.
    warn "UC $ST — the spec changed a behaviour area after the gate commit ($CHG ); a historical trace, the gate is not reapplied"
  else
    bad "the spec changed BEHAVIOUR after passing the gate — areas:$CHG (the §9 fingerprint, #49); the gate marker no longer matches the current spec"
    info "/sdd-solo:verify $ID --since $(git -C "$ROOT" log -1 --format=%h "$GH" 2>/dev/null) then /sdd-solo:gate again — gate-pass creates a new mark"
  fi
fi
# The design layer (4.0.0). Closing a UC with no design.md means the code was written from a technical
# decision that lives nowhere — six months later nobody can read back WHY it was built that way, and
# "never discussed" looks exactly like "discussed and forgotten to write down".
DDIR="$(dirname "$F")"
if [ -f "$DDIR/design.md" ]; then
  ok "has a design.md"
  [ -f "$DDIR/tasks.md" ] && ok "has a tasks.md" || warn "missing tasks.md — every AC should have a task and a test"
else
  bad "missing design.md in the UC directory — run /sdd-solo:design $ID (step ⑩)"
fi
# test theo AC
UCT="$(uc_test_dir "$ROOT")"
TD="$ROOT/$UCT/$CTX/$ID"
for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
  ls "$TD"/AC-$n.test.* >/dev/null 2>&1 && ok "AC-$n has a test" || bad "AC-$n has no $UCT/$CTX/$ID/AC-$n.test.*"
done
# the order docs → feat
D0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^docs($ID)" 2>/dev/null | head -1)"
F0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^feat($ID)" 2>/dev/null | head -1)"
if [ -z "$F0" ]; then warn "there is no feat($ID) commit yet — commit the code before closing"
elif [ -n "$D0" ] && [ "$D0" -lt "$F0" ]; then ok "docs($ID) comes before feat($ID)"; else bad "feat($ID) has no docs($ID) before it"; fi
# implicit rules: a literal number in the UC code.
# THE SET OF CODE FILES OF THE UC — two sources added together (7.0.1, P-15):
#  ① files under code_paths touched by a non-merge commit with `(UC-###)` in its subject, still existing, not a test.
#     The 7.0 layout places code by CONCEPT (src/core/domain/session/, web/, deploy/) and not by the UC slug; up to
#     7.0.0 only source ② existed, so runxops UC-024 went red with "there is a feat but no code file can be read"
#     although 17 of 17 ACs had tests. The commit already carries the ID because the githook demands it — that is the
#     only UC → code link a machine can trust.
#  ② by slug: a directory (src/domain/<slug>/) or a file (src/domain/<slug>.js). Union of EVERY matching path, not
#     head -1 — an empty directory next to the real file (left by a git mv) once beat the real file and turned the DoD "clean".
CP="$(code_paths "$ROOT")"; TPS="$(test_paths "$ROOT") $UCT"
in_paths() { local x; for x in $2; do x="${x%/}"; [ "$x" = . ] && return 0; case "$1" in "$x"/*|"$x") return 0;; esac; done; return 1; }
CFILES="$(git -C "$ROOT" log --no-merges --format='@@%s' --name-only 2>/dev/null \
  | awk -v t="($ID)" '/^@@/ { k = index($0, t) > 0; next } k && NF && !a[$0]++' \
  | while IFS= read -r f; do
      [ -f "$ROOT/$f" ] || continue
      in_paths "$f" "$CP" || continue
      in_paths "$f" "$TPS" && continue
      printf '%s\n' "$f"
    done | grep -vE '\.(test|spec)\.')"   # no `case` here: bash 3.2 does not parse `pat)` inside $( )
NC1="$(printf '%s\n' "$CFILES" | grep -c .)"
for d in $CP; do
  [ -d "$ROOT/$d" ] || continue
  CFILES="$CFILES
$(cd "$ROOT" && { find "$d" -type d -name "$SLUG" -exec find {} -type f \; ; find "$d" -type f -name "$SLUG.*"; } 2>/dev/null | grep -vE '\.(test|spec)\.')"
done
CFILES="$(printf '%s\n' "$CFILES" | awk 'NF&&!a[$0]++')"
# Count the files that can REALLY be read. 0 files = "unknown", not "clean".
NF_="$(printf '%s\n' "$CFILES" | grep -c .)"
if [ "$NF_" -gt 0 ]; then
  info "the code of $ID: $NF_ files — $NC1 touched by a ($ID) commit, $((NF_-NC1)) added by the slug $SLUG"
  L="$(cd "$ROOT" && printf '%s\n' "$CFILES" | tr '\n' '\0' | xargs -0 grep -HnE '([=<>!]=?|:|,|\() *[0-9]+\b|[0-9]+ *\* *[0-9]+' 2>/dev/null \
       | grep -vE '\.(test|spec)\.[a-z]+:|RULE-|CON-|ADR-' \
       | grep -vE '\[[0-9]+\]' \
       | grep -vE '\b(i|j|k|n|idx|index)\b *[=<>!]=? *[0-9]+' \
       | awk '{ if ($0 ~ /[0-9]+ *\* *[0-9]+/) { print; next }
                if ($0 ~ /[-+*\/]= *[0-9]+/) next
                if ($0 ~ /(substring|substr|slice|splice|padStart|padEnd|charAt|repeat|toFixed)\(/) next
                print }' \
       | grep -vE 'v?[0-9]+\.[0-9]+\.[0-9]+' \
       | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|/\*|\*|#|--)')"   # a comment-only line: the commit-based set drags in .sh/.sql, and a comment is not a rule
  if [ -n "$L" ]; then
    # Do not truncate silently (P-15): up to 7.0.0 it printed head -8 and did not say how many were left. A large set → the count + the full file.
    LN_="$(printf '%s\n' "$L" | grep -c .)"
    LOUT="$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null)/sdd/literal-$ID.txt"
    mkdir -p "$(dirname "$LOUT")" 2>/dev/null && printf '%s\n' "$L" > "$LOUT" || LOUT=""
    warn "$LN_ lines with a literal number to look at (each must quote a RULE/CON or explain itself)$( [ "$LN_" -gt 8 ] && printf ' — the first 8 below')${LOUT:+; all of them in $LOUT}:"
    printf '%s\n' "$L" | head -8 | sed 's/^/      /'
    # The spec marked a blank and the code filled in a number — the most expensive kind of implicit rule.
    if grep -qiE "($(kw openq_any))" "$F" 2>/dev/null && grep -qE '^[[:space:]]*[-*] \[ \]' "$F" 2>/dev/null; then
      warn "$ID still has an open Open Question while the code already has a number — look at those two together"
    fi
  else
    ok "no stray literal number found in the $NF_ code files of $ID"
  fi
elif [ -n "$F0" ]; then
  bad "there is a feat($ID) but no code file can be read: no ($ID) commit touched a file under $CP, and there is no directory/file named $SLUG — fix code_paths in .sdd/config"
else
  warn "the code of $ID was not found in: $CP — the implicit rules could not be looked at"
fi
grep -qE '^- v[0-9]+ ' "$F" && ok "History has rows" || bad "History is empty"
git -C "$ROOT" status --porcelain 2>/dev/null | grep -q . && warn "there are uncommitted changes"
echo
if [ "$FAIL" -eq 0 ]; then echo "CAN BE CLOSED ($WARN warnings)."; exit 0; else echo "NOT CLOSABLE — $FAIL errors."; exit 1; fi
