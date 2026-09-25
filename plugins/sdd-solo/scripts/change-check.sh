#!/usr/bin/env bash
# change-check.sh CHG-### — the Phase 5 gate, checked mechanically. exit 0 = the code may be changed.
# Phase 3 has 22 checks in gate-check.sh; before 3.0.0 Phase 5 had none, so a change touching
# behaviour ALREADY delivered to a customer could enter the repo with an empty description, naming
# no UC and no AC it overturned. See #16.
ID="$1"; [ -z "$ID" ] && { echo "usage: change-check.sh CHG-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; D="$(find_chg "$ID" "$ROOT")"
echo "Phase 5 gate — $ID"
[ -z "$D" ] && { bad "cannot find specs/changes/${ID}-*/"; exit 1; }
info "directory: ${D#$ROOT/}"

# sect <file> <heading> — the body of one section, without the heading line itself
sect() { awk -v h="$2" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}' "$1" 2>/dev/null; }
# sectk <file> <ERE pattern for the heading> — like sect but taking a `kwh` pattern, so a section
# written in English reads exactly like the Vietnamese one (7.7.0).
sectk() { awk -v re="$2" '$0 ~ re {f=1;next} f&&/^## /{exit} f{print}' "$1" 2>/dev/null; }
# nonempty/filled use the shared version in lib.sh (4.0.1)

P="$D/proposal.md"; G="$D/design.md"; T="$D/tasks.md"
for f in proposal.md design.md tasks.md; do
  [ -f "$D/$f" ] && ok "has $f" || bad "missing ${D#$ROOT/}/$f"
done
[ -d "$D/delta" ] && ok "has delta/" || bad "missing ${D#$ROOT/}/delta/"
[ -f "$P" ] || { echo; echo "NOT THROUGH — $FAIL errors."; exit 1; }

# 1. the title and the status
grep -qE "^# $ID: *<" "$P" && bad "the title still has the placeholder <Change name>"
grep -qE "^# $ID: *[^ <]" "$P" && ok "has a title" || bad "the first line of proposal.md must be '# $ID: <a real name>'"
grep -qE 'CHG-000' "$P" "$G" "$T" 2>/dev/null && bad "the template string CHG-000 is still there — change it to $ID"
STL="$(sect "$P" "## Status" | grep -vE '^[[:space:]]*$' | head -1)"
printf '%s' "$STL" | grep -q '|' && bad "Status is still a list of choices — pick one value"
ST="$(printf '%s' "$STL" | tr -d '[:space:]')"
case "$ST" in
  proposed|specified|designed) ok "status: $ST";;
  applying)  bad "status is already applying — this change has passed the gate";;
  verified|archived) bad "status $ST — the change is closed and is not reopened; create a new CHG";;
  dropped)   bad "status dropped — the change was abandoned";;
  *)         bad "invalid status: '$ST'";;
esac

# 2. Why · Impact — the two sections most often left as the template
for h in "## Why" "## Impact on customers"; do
  S="$(sect "$P" "$h")"
  if ! nonempty "$S"; then bad "$h is empty"
  elif ! filled "$S"; then bad "$h still holds the template placeholder"
  else ok "$h has content"; fi
done

# 3. Scope — an affected UC must BE REAL, be implemented, and have passed the DoR gate.
# A UC still in draft has not been delivered to anyone; editing it in Phase 3 is far cheaper.
SC="$(sect "$P" "## Scope")"
UCS="$(printf '%s' "$SC" | grep -oE 'UC-[0-9]+' | sort -u)"
if [ -z "$UCS" ]; then bad "## Scope names no affected UC"; fi
for u in $UCS; do
  UF="$(find_uc "$u" "$ROOT")"
  if [ -z "$UF" ]; then bad "Scope names $u but there is no UC file — an invented ID"; continue; fi
  UST="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$UF" | head -1 | awk '{print $2}')"
  if [ "$UST" != "implemented" ]; then
    bad "$u is '$UST', not implemented — edit it directly in Phase 3 (History v+1), do not open a change"
  elif [ ! -f "$ROOT/.sdd/gate/$u.ok" ]; then
    bad "$u is implemented but there is no .sdd/gate/$u.ok — the baseline cannot be trusted"
    info "if $u was brought back from deprecated, the marker is still in git: bash .sdd/scripts/pass.sh restore $u (8.7.0)"
  else ok "$u is implemented and passed the gate"; fi
done
for r in $(printf '%s' "$SC" | grep -oE 'RULE-[0-9]+' | sort -u); do
  [ -n "$(rule_file "$r" "$ROOT")" ] && ok "$r exists in rules.md" \
    || bad "Scope names $r but rules.md has no such heading"
done

# 4. History
# 8.0.0: proposal.trace.md holds it once migrate --trace has run; before that it is still in proposal.md.
ev_body history "$P" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "History has a dated line" || bad "## History has no 'YYYY-MM-DD: ...' line"

# 5. design.md
if [ -f "$G" ]; then
  filled "$(sectk "$G" "$(kwh techdir)")" && ok "design.md has a technical direction" \
    || bad "design.md ## Technical direction is empty or still a placeholder"
  for a in $(grep -oE 'ADR-[0-9]+' "$G" | sort -u); do
    if [ -n "$(adr_file "$a" "$ROOT")" ]; then
      ok "$a has a file"
    else bad "design.md names $a but there is no ADR file ($(adr_dirs "$ROOT" | sed "s#$ROOT/##" | tr '\n' ' '))"; fi
  done
  grep -qE 'SCR-[0-9]+-[0-9]+' "$G" || warn "design.md names no SCR-###-# — does this change really touch no screen?"
  filled "$(sectk "$G" "$(kwh risksback)")" && ok "has risks and a rollback" \
    || bad "design.md ## Risks and rollback is empty or still '...' — changing delivered behaviour means stating the way back"
fi

# 6. tasks.md
if [ -f "$T" ]; then
  TC="$(grep -cE '^- \[[ x]\]' "$T")"; [ -z "$TC" ] && TC=0
  [ "$TC" -ge 1 ] && ok "tasks.md has $TC tasks" || bad "tasks.md has no '- [ ] ...' line yet"
  grep -qE '^- \[[ x]\].*(Archive|archive)' "$T" && ok "has an archive task at the end of the round" \
    || warn "tasks.md has no archive task — the baseline will never be merged back"
fi

# 7. delta — the most expensive part. Every UC in Scope must have a delta, and the delta must speak
# correctly about the baseline: no removing an AC that does not exist, no adding an AC with a used number.
MODS=0
[ -f "$D/delta/UC-000.delta.md" ] && [ -z "$(find_uc UC-000 "$ROOT")" ] \
  && bad "the template delta/UC-000.delta.md is still there — delete it or rename it after a real UC"
for u in $UCS; do
  DF="$D/delta/$u.delta.md"
  if [ ! -f "$DF" ]; then bad "Scope names $u but delta/$u.delta.md is missing"; continue; fi
  UF="$(find_uc "$u" "$ROOT")"; [ -z "$UF" ] && continue
  HAS=0
  for h in ADDED MODIFIED REMOVED; do
    S="$(awk -v h="## $h" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}' "$DF")"
    nonempty "$S" || continue
    printf '%s' "$S" | grep -qE '^\.\.\.$|<[^>]+>' && bad "delta/$u ## $h still has a placeholder"
    HAS=1
    case "$h" in
      ADDED)
        for a in $(printf '%s' "$S" | grep -oE '^### AC-[0-9]+' | grep -oE 'AC-[0-9]+'); do
          grep -qE "^### $a\b" "$UF" && bad "delta/$u ADDED $a but the baseline already has $a — number collision, take the next number" \
            || ok "delta/$u adds $a"
        done
        printf '%s' "$S" | grep -qE '^Given:' && printf '%s' "$S" | grep -qE '^Then:' \
          || bad "delta/$u ADDED has no Given/When/Then";;
      MODIFIED)
        MODS=$((MODS+1))
        for x in $(printf '%s' "$S" | grep -oE '^### (AC-[0-9]+|E[0-9]+)' | awk '{print $2}'); do
          case "$x" in
            AC-*) grep -qE "^### $x\b" "$UF" && ok "delta/$u modifies $x" || bad "delta/$u MODIFIED $x but the baseline has no $x";;
            E*)   grep -qE "^- +(\*\*)?$x[.:]" "$UF" && ok "delta/$u modifies $x" || bad "delta/$u MODIFIED $x but the baseline has no $x";;
          esac
        done
        printf '%s' "$S" | grep -qE "^($(kw oldval)):" && printf '%s' "$S" | grep -qE "^($(kw newval)):" \
          || bad "delta/$u MODIFIED must record both 'Old:' and 'New:' — without them nobody can review it";;
      REMOVED)
        MODS=$((MODS+1))
        while IFS= read -r ln; do
          printf '%s' "$ln" | grep -qE '^### ' || continue
          x="$(printf '%s' "$ln" | grep -oE '(AC-[0-9]+|E[0-9]+)' | head -1)"
          [ -z "$x" ] && { bad "delta/$u REMOVED has no ID: $(printf '%s' "$ln" | cut -c1-50)"; continue; }
          grep -qE "^### $x\b|^- +(\*\*)?$x[.:]" "$UF" || bad "delta/$u REMOVED $x but the baseline has no $x"
          printf '%s' "$ln" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
            || bad "delta/$u REMOVED $x records no deprecation date"
          printf '%s' "$ln" | grep -qiE "$(kw reason)" \
            || bad "delta/$u REMOVED $x records no reason"
        done <<< "$S";;
    esac
  done
  [ "$HAS" = 0 ] && bad "delta/$u has no ADDED/MODIFIED/REMOVED section with content"
done
# Phase 5 exists to overturn delivered ACs. Only adding new ACs makes it Phase 3.
if [ "$MODS" = 0 ] && [ -n "$UCS" ]; then
  bad "no delta MODIFIED/REMOVED anything — the change only adds ACs and breaks no old one → this is Phase 3 (History v+1), do not open a change"
else
  [ "$MODS" -gt 0 ] && ok "$MODS sections overturn an old AC — the right scope for Phase 5"
fi

# 8. a re-read with an unanchored mind + the commit — the same rule as the DoR gate (6.0.0, #38: verify
# is mandatory, there is no overnight door left). Before 6.0.0 this section had ONLY the overnight door
# although the comment said "the same rule as the DoR gate" — DoR had had the verify door since 3.5.0;
# real case runxops CHG-001: every line green, red only on "written today". Changing behaviour already
# delivered to a customer needs a reading to have happened all the more: /sdd-solo:verify CHG-### writes
# ## Re-read into proposal.md, commits separately, and that must be the latest docs(CHG) commit in the change directory.
RR="$(rr_lines "$P")"; RRN=0; RRU=0
[ -n "$RR" ] && { RRN="$(printf '%s\n' "$RR" | rr_count)"; RRU="$(printf '%s\n' "$RR" | rr_undecided)"; }
[ -z "$RRU" ] && RRU=0
# 8.0.0: the same ceiling as the DoR gate (gate-check §8). A change proposal loops for the same reason a UC does.
RMAX="$(rr_max "$ROOT")"; RND="$(rr_rounds "$P")"
if [ "$RMAX" -gt 0 ] && [ "$RND" -ge "$RMAX" ] && [ "$RRU" -gt 0 ]; then
  bad "round $RND of the re-read has reached the ceiling (rr_max=$RMAX) and $RRU finding(s) are still Undecided — turn each into an Open Question or a ticket; a further round is not an answer"
fi
LAST="$(git -C "$ROOT" log -1 -E --format=%cs --grep="^docs\($ID\)" -- "$D" 2>/dev/null)"
LASTS="$(git -C "$ROOT" log -1 -E --format=%s --grep="^docs\($ID\)" -- "$D" 2>/dev/null)"
RRC=0; printf '%s' "$LASTS" | grep -qE "^docs\($ID\): ($(kw c_reread))" && RRC=1
if [ -z "$LAST" ]; then bad "there is no docs($ID) commit yet — commit the change first"
elif printf '%s' "$LASTS" | grep -qE "^docs\($ID\): change reviewed — ($(kw c_p5))$"; then
  ok "the latest docs($ID) is the change-pass commit — the gate was passed before"
elif [ "$RRN" -gt 0 ] && [ "$RRC" = 1 ]; then
  ok "re-read with an unanchored mind: $RRN findings with an anchor + an outcome, and the separate commit is the latest commit of $ID"
  # 7.4 (P-20, original case CHG-002): say how many lines still read "→ Undecided" — if the gate is equally green in
  # both states, the reader has to change 11 tails by hand to find out which ones were decided.
  [ "$RRU" -gt 0 ] && warn "$RRU of $RRN findings still read '→ Undecided (waiting on the owner …)' — opening the gate is a debt you take on (#53); once answered, change the tail to '→ Decided: …'"
elif [ "$RRN" -eq 0 ]; then
  bad "not re-read with an unanchored mind — proposal.md has no ## Re-read with an F# line carrying [anchor: ...] + an outcome other than ___"
  info "/sdd-solo:verify $ID (a subagent reads the proposal + delta + the baseline UC, writes the F# lines, commits separately)"
else
  bad "the change was edited after the re-read — the latest docs($ID) commit is '$LASTS' ($LAST), not the re-read commit"
  info "run /sdd-solo:verify $ID again"
fi
git -C "$ROOT" status --porcelain -- "$D" 2>/dev/null | grep -q . && bad "there are uncommitted changes in $ID"

echo
if [ "$FAIL" -eq 0 ]; then echo "THROUGH THE PHASE 5 GATE ($WARN warnings)."; exit 0; else echo "NOT THROUGH — $FAIL errors, $WARN warnings."; exit 1; fi
