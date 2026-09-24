#!/usr/bin/env bash
# gate-check.sh [--pre] UC-### — Definition of Ready, checked mechanically. exit 0 = through the gate.
#
# --pre is the SMALL gate before step ⑦ (folded in from uc-ready.sh at 4.0.0): is there enough content
# for the three adversarial roles to read. Same file, same functions, a different moment and a
# different threshold — two scripts would only let two measurements of one thing drift apart.
PRE=0; ID=""
for a in "$@"; do
  case "$a" in --pre) PRE=1;; UC-[0-9]*) ID="$a";; esac
done
[ -z "$ID" ] && { echo "usage: gate-check.sh [--pre] UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
[ "$PRE" = "1" ] && echo "Ready for adversarial — $ID" || echo "Definition of Ready — $ID"
[ -z "$F" ] && { bad "cannot find ${ID}.md — specs/*/br-*/use-cases/${ID}-*/ (7.0) or specs/contexts/*/use-cases/${ID}-*/ (6.x)"; exit 1; }
# 7.0: OWNER = core | <craft> (6.x: the context name). Every path is looked up through lib.sh (#55).
CTX="$(owner_of "$F")"; DIR="$(dirname "$F")"
RFS="$(rules_files "$ROOT" | tr '\n' ' ')"; EFS="$(entity_cited "$F" "$ROOT" | tr '\n' ' ')"; GFS="$(glossary_files "$CTX" "$ROOT" | tr '\n' ' ')"
EFALL="$(entity_files "$F" "$ROOT" | tr '\n' ' ')"; BRF="$(br_files "$ROOT" | tr '\n' ' ')"
[ "$PRE" = "0" ] && info "file: ${F#$ROOT/}"

# ── #48: the sibling files — a WARNING, not a block ──────────────────────
# Real case at runxops: verify on UC-014, round 1, 14 of 18 findings were MISMATCHES BETWEEN THE UC AND ITS
# SIBLINGS (glossary, entities, sequence, the `Applies to` of a RULE) after three rounds of applying tickets
# that only touched the UC file — `--pre` was green because it only checks the UC + the flow. The sibling
# list is built exactly the way context.sh builds it: the IDs the UC quotes (RULE/CON/ADR) plus the
# context entities/glossary. A warning because this is what verify will catch; catching it early here is
# cheaper than a whole verify round (~10 minutes, ~200 KB), but it is not certain enough to block.
# uc_live — the UC file minus the three evidence-trail sections (the same rule as context.sh #43).
entity_hint() { if [ "$(layout "$ROOT")" = v7 ]; then printf 'specs/core/entities/<Name>.md or specs/%s/entities/<Name>.md' "$CTX"; else printf 'specs/contexts/%s/entities.md' "$CTX"; fi; }
uc_live() { awk -v re="^## ($(kw trace))" '$0 ~ re {t=1;next} /^## /{t=0} !t' "$F"; }
siblings() {
  SIB="$F $DIR/$ID.flow.md $DIR/$ID.sequence.md $RFS $BRF $EFS $GFS"
  LIVE="$(uc_live)"
  for a in $(printf '%s' "$LIVE" | grep -oE 'ADR-[0-9]+' | sort -u); do SIB="$SIB $(adr_file "$a" "$ROOT")"; done
  # 1. pending markers — outside the evidence sections (History · Adversarial pass · Re-read)
  for f in $SIB; do
    [ -f "$f" ] || continue
    HITS="$(awk -v re="^#{1,6} ($(kw trace))" '$0 ~ re {t=1;next} /^#{1,6} /{t=0} !t' "$f" \
            | grep -nE "$(kw hanging)" | grep -vE '^[0-9]+:[[:space:]]*[-*] \[x\]' | head -3)"
    [ -n "$HITS" ] && { warn "${f#$ROOT/} still has pending markers (waiting on a ticket · under review · not open yet):"; printf '%s\n' "$HITS" | cut -c1-110 | sed 's/^/      /'; }
  done
  # 2. an entity the UC names must have a **Name** line in the glossary — the three roles and the code use one name
  if [ -n "$EFALL" ] && [ -n "$GFS" ]; then
    MISS=""
    for e in $(entity_names "$F" "$ROOT"); do
      printf '%s' "$LIVE" | grep -qw "$e" || continue
      # runxops writes `- **Work** (`WorkItem`)`: the code name follows the prose name — only require presence on one glossary line
      cat /dev/null $GFS | grep -qE "^- \*\*(.*[^A-Za-z0-9_])?$e([^A-Za-z0-9_]|$)" || MISS="$MISS $e"
    done
    [ -n "$MISS" ] && warn "an entity the UC names has no '- **Name**' line in glossary.md:$MISS"
  fi
  # 3. a quoted RULE must list this UC under its Applies to — the reverse direction of §4
  for r in $(printf '%s' "$LIVE" | grep -oE 'RULE-[0-9]+' | sort -u); do
    AP="$(awk -v h="## $r" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f' /dev/null $RFS 2>/dev/null | grep -iE "$(kw appliesto)" | head -1)"
    [ -z "$AP" ] && continue
    printf '%s' "$AP" | grep -q "$ID" || warn "$r: its Applies to does not list $ID — the UC quotes the rule but the rule does not claim the UC (#48)"
  done
}

# ── every E# has a row in the Screens table — used by both --pre (7.4, P-30) and the full gate ────
# Only the FIRST CELL of each table row counts, whole word: `**E1**` (bold) and `E1 · E2` (a merged cell) both count (P-38b);
# up to 7.3 the regex demanded `| E1` flush to the edge, so both of those went falsely red with "E1 has no row".
SCR="$(sed -n '/^## Screens/,/^## /p' "$F")"
screens_check() {
  local n
  for n in $(grep -oE '^- +(\*\*)?E[0-9]+' "$F" | grep -oE '[0-9]+' | sort -un); do
    printf '%s\n' "$SCR" | grep -E '^\|' | awk -F'|' '{print $2}' | grep -qwE "E$n" \
      && ok "E$n has a screen" || bad "E$n has no row in the ## Screens table"
  done
}

# ── --pre: the gate before step ⑦ ────────────────────────────────────────
# The four old preconditions in skills/adversarial measured STRUCTURE, so an empty template passed
# them all: 4 numbered Main Flow lines, 2 ACs, 2 E#, 3 Screens rows — while the whole file still had
# 23 placeholders. And /sdd-solo:start copies that very template. See #11.
if [ "$PRE" = "1" ]; then
  grep -qE '^[0-9]+\.' "$F" && ok "Main Flow has numbered steps" || bad "Main Flow has no step yet"
  A="$(grep -cE '^### AC-[0-9]+' "$F")"; [ "$A" -ge 1 ] && ok "$A AC" || bad "no AC yet"
  E="$(grep -cE '^- +(\*\*)?E[0-9]+[.:]' "$F")"; [ "$E" -ge 1 ] && ok "$E exception" || bad "no E# yet"
  grep -qE 'SCR-[0-9]+-[0-9]+' "$F" && ok "the Screens table has a SCR-###-#" || bad "the Screens table has no SCR yet"
  screens_check

  # This is the real latch: a placeholder left means nobody has written the content.
  # EXCEPTION: a '___' inside ## Open Questions is legitimate. The previous version counted it as a
  # placeholder, so an honest writer of '- [ ] <question> (interim decision: ___)' was blocked, and the
  # only way out was to INVENT a value — exactly what the whole BR layer exists to prevent. §8 below
  # lets it through and br-check only warns; this branch is the only one that blocks.
  # '<...>' still goes red everywhere, Open Questions included. See #23.
  PHALL="$(awk -v TRACE="$(kwh trace)" -v SKIPPH="$(kw rundate)|$(kw output)" '
    /^## Open Questions/ { oq=1; dl=0; next }
    # ## Re-read belongs to step ⑧, and this branch runs at step ⑦ — it being STILL a template is on
    # schedule, not unfilled. Without skipping it --pre goes red, adversarial refuses to run, and there
    # is no way out: passing step ⑦ would require filling in a section that only exists after step ⑦.
    # 7.0.1 (#52): ## Adversarial pass is the same kind — it is the OUTPUT of the very step ⑦ that --pre
    # guards; from the second round on (old questions still with an ___ outcome, the new role not yet run)
    # --pre would go red over the very section it is about to fill.
    # 7.4 (P-18): ## History is an append-only log recording warning text with an `E<number>` in it — not an unfilled spot.
    $0 ~ TRACE { dl=1; oq=0; next }
    /^## / { oq=0; dl=0 }
    {
      if (dl) next
      # 7.4 (P-38): text inside code ticks is real text (`<tr>` is an HTML tag name), not a placeholder.
      t = $0; gsub(/`[^`]*`/, "", t)
      ang = (t ~ /<[^>]+>/); us = (t ~ /___/)
      if (!ang && !us) next
      if ($0 ~ /^[[:space:]]*<!--/) next
      if ($0 ~ SKIPPH) next
      if (oq && !ang) next
      printf "%d:%s\n", NR, $0
    }' "$F")"
  # 7.4 (P-43): a '___' in the UC body on a line quoting a RULE whose parameter is still ___ in rules.md is HONEST —
  # the undecided number lives in the rule and the UC merely copies that blank. Blocking here leaves inventing a number
  # in the UC before the rule has one as the only way out (runxops case: an AC quoting RULE-### `minutes` = ___). '<...>' still goes red.
  RULE_BLANK=""
  for r in $(cat /dev/null $RFS 2>/dev/null | grep -oE '^## RULE-[0-9]+' | awk '{print $2}' | sort -u); do
    awk -v h="## $r" 'index($0,h)==1{f=1;print;next} f&&/^## /{f=0} f' /dev/null $RFS 2>/dev/null | grep -q '___' && RULE_BLANK="$RULE_BLANK $r "
  done
  PHK=""; PHX=""
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    if printf '%s' "$l" | grep -q '___' && ! printf '%s' "$l" | grep -qE '<[^>]+>'; then
      rid="$(printf '%s' "$l" | grep -oE 'RULE-[0-9]+' | head -1)"
      if [ -n "$rid" ] && printf '%s' "$RULE_BLANK" | grep -q " $rid "; then PHX="$PHX
$l"; continue; fi
    fi
    PHK="$PHK
$l"
  done <<< "$PHALL"
  PHALL="$PHK"
  PXN="$(printf '%s\n' "$PHX" | awk 'NF' | wc -l | tr -d ' ')"
  [ "$PXN" -gt 0 ] && info "$PXN of the ___ spots quote a RULE parameter that is still blank ($(printf '%s' "$RULE_BLANK" | tr -s ' ' | sed 's/^ //; s/ $//')) — legitimate; fill them in rules.md and the UC follows"
  PN="$(printf '%s\n' "$PHALL" | awk 'NF' | wc -l | tr -d ' ')"
  if [ "$PN" -gt 0 ]; then
    bad "$PN spots still unfilled — an adversarial pass over an empty spec is pointless:"
    printf '%s\n' "$PHALL" | head -8 | sed 's/^/      /'
  else
    ok "no placeholder left"
  fi
  OQU="$(sed -n '/^## Open Questions/,/^## /p' "$F" | grep -c '___')"; [ -z "$OQU" ] && OQU=0
  [ "$OQU" -gt 0 ] && info "$OQU of the ___ spots are in Open Questions — legitimate, not counted as unfilled"

  # The context entities.md and glossary.md: a WARNING, not a block.
  # The three roles read those two files as input. Running while they are still templates means the model
  # changes afterwards and the ACs have to be reworded — a real cost, but not large enough to lock the user
  # out of step ⑦. Blocking here would repeat exactly the shape of #23. See #24.
  if [ -z "$EFALL" ]; then
    warn "$CTX has no entity yet ($(entity_hint)) — the three roles will ask without a model to check against"
  elif cat /dev/null $EFALL | grep -qE '(class|## )Entity[AB]([^A-Za-z0-9]|$)' 2>/dev/null; then
    warn "the entities of $CTX are still the template EntityA/EntityB — a model that changes after adversarial means rewording the ACs"
  fi
  [ -n "$GFS" ] && cat /dev/null $GFS | grep -qE "$(kw ph_term)|<Context A>" && \
    warn "the glossary is still a template — the three roles and the code will call one thing by different names"
  siblings

  echo
  if [ "$FAIL" -eq 0 ]; then echo "READY — the three roles can run ($WARN warnings)."; exit 0; fi
  echo "NOT READY — $FAIL errors, $WARN warnings. Finish writing the content and run again."; exit 1
fi

# 0. status
STL="$(grep -E '\*\*Status:\*\*' "$F" | head -1)"; echo "$STL" | grep -q '|' && bad "Status is still a list of choices — pick one value"
ST="$(echo "$STL" | grep -oE '\*\*Status:\*\* *[a-z]+' | awk '{print $2}')"
case "$ST" in draft|reviewed) ok "status: $ST";; implemented) bad "status is already implemented — use Phase 5 (specs/changes/) to change behaviour";; deprecated) bad "status deprecated — the UC was dropped (#45); open a replacement UC recorded in ## History, not through this gate";; *) bad "invalid status: '$ST'";; esac

# 1. the required sections
# 8.0.0: ## History left this list. It is the one required section that is EVIDENCE, and evidence now lives in
# UC-###.trace.md — demanding it in the body would make every migrated repo red for having done the migration.
# It is not unchecked: ev_history below asks for it wherever it is, which is the same question asked correctly.
for sec in "## Actor" "## Trigger" "## Preconditions" "## Main Flow" "## Exceptions" "## Postconditions" "## Acceptance Criteria" "## Screens"; do
  grep -q "^$sec" "$F" && ok "has $sec" || bad "missing $sec"
done
if [ -n "$(ev_body history "$F" | tr -d '[:space:]')" ]; then ok "has ## History"
else bad "missing ## History — it belongs in $(basename "$(trace_of "$F")") (8.0.0), or still in the UC body on a repo that has not run migrate.sh --trace"; fi
grep -qE '<[^>]*>' <(sed -n '/^## Actor/,/^## Alternative/p' "$F" | grep -vE '^\s*$|^##') && warn "a <...> placeholder is left in Actor/Trigger/Flow"

# 2. AC vs E#
EN="$(grep -cE '^- +(\*\*)?E[0-9]+[.:]' "$F")"; AN="$(grep -cE '^### AC-[0-9]+' "$F")"
if [ "$AN" -ge 1 ] && [ "$AN" -ge $((EN+1)) ]; then ok "AC: $AN · Exceptions: $EN (≥ E# + 1)"; else bad "AC: $AN · Exceptions: $EN — need ≥ 1 AC for Main + 1 per E#"; fi
grep -qE '^Given:' "$F" && grep -qE '^When:' "$F" && grep -qE '^Then:' "$F" && ok "ACs in Given/When/Then form" || bad "the ACs have no Given/When/Then"

# 3. every E# has a row in the Screens table (the screens_check function at the top — shared with --pre)
screens_check
echo "$SCR" | grep -qE 'SCR-[0-9]+-[0-9]+' || bad "no SCR-###-# in ## Screens yet"

# 4. a quoted RULE must exist in rules.md
for r in $(uc_text "$F" | grep -oE 'RULE-[0-9]+' | sort -u); do
  # grep -c prints "0" AND THEN exits 1, so a "|| echo 0" builds a two-line string and breaks
  # both comparisons below. Do not add a fallback here.
  C="$(cat /dev/null $RFS 2>/dev/null | grep -cE "^## $r\b")"; [ -z "$C" ] && C=0
  H="$(cat /dev/null $RFS 2>/dev/null | grep -E "^## $r\b" | head -1)"
  if [ "$C" = "0" ]; then bad "$r is quoted but has no heading in any rules.md ($(printf '%s' "$RFS" | sed "s#$ROOT/##g"))"
  elif [ "$C" -gt 1 ]; then bad "$r has $C headings across the rules.md files — duplicate ID, fix it (#13)"
  elif echo "$H" | grep -q '<'; then bad "$r is still the template placeholder: $H — write the real rule or stop quoting it (#13)"
  else ok "$r exists in rules.md"; fi
done

# 5. Flow — mermaid (the default since 3.1.0) or .bpmn (the old path, still accepted)
# .bpmn is compressed XML, so a script can only check that the file exists. The count the DoR
# checklist asked for from the start — "number of error boundary events = number of E#" — was
# never machine-checkable. .flow.md is text, so it can be counted for real, in both directions.
# 2.0.0: the diagram lives INSIDE the UC directory, no longer in a context-level diagrams/.
FL="$DIR/$ID.flow.md"
BP="$DIR/$ID.bpmn"
OLD="$ROOT/specs/contexts/$CTX/diagrams/$ID.bpmn"
if [ -f "$FL" ]; then
  ok "$ID.flow.md (mermaid, inside the UC directory)"
  grep -qE '^```mermaid' "$FL" && grep -qE '^[[:space:]]*(flowchart|graph)\b' "$FL" \
    || warn "$ID.flow.md has no mermaid block with flowchart/graph yet — nothing can be drawn"
  grep -qE '\(\[' "$FL" || warn "$ID.flow.md has no terminal node of the form ([...]) — the Postcondition has no path to it"
  # ONLY EDGE LABELS count: the part between two | characters on a line carrying an arrow. A node id
  # is never there. Version 3.1.0 matched E<number> ANYWHERE in the file, so a terminal node named
  # E1([Logged in]) — that is, a SUCCESSFUL ending — convinced the gate that the error path E1 had
  # been drawn, while the real exception branch had no label at all. A fake ✓, and wrong on the
  # dangerous side. See #17.
  # 7.5 (P-32): edge labels come from the PARSER (js/mermaid.mjs --edges) — it knows a label from a node name from
  # text inside double quotes. Without node it falls back to the previous release grep (a fallback, never a false red).
  if mmd_ok; then LBL="$(mmd --edges "$FL")"
  else LBL="$(grep -E '(-->|==>|-\.->|--x|--o)' "$FL" 2>/dev/null | grep -oE '\|[^|]*\|')"; fi
  # forward direction: an E# declared in the UC must have an arrow carrying that label
  for e in $(grep -oE '^- +(\*\*)?E[0-9]+' "$F" | grep -oE 'E[0-9]+' | sort -u); do
    printf '%s' "$LBL" | grep -qE "(^|[^A-Za-z0-9])$e([^0-9]|$)" && ok "$e has a branch in the flow" \
      || bad "$e is in ## Exceptions but no arrow in $ID.flow.md carries the label |$e ...| — a label sits between two | characters, a node name does not count"
  done
  # reverse direction: a label in the diagram must be a real E#. An invented label passes every gate
  # if nobody checks the other way — the lesson of #12 and #15.
  for e in $(printf '%s' "$LBL" | grep -oE 'E[0-9]+' | sort -u); do
    grep -qE "^- +(\*\*)?$e[.:]" "$F" \
      || bad "$ID.flow.md has the label $e but ## Exceptions of the UC has no $e"
  done
  # A node id of the form E<number> can no longer impersonate a label, but it is still hard to read.
  # Do not catch X#([E1: ...]) — there E1 comes before a colon and is not an id.
  # 7.4 (P-17): only look INSIDE a ```mermaid block — a prose note under the diagram saying "E1 (…)" is not a node id.
  # 7.5 (P-32): the parser returns the id column directly, no longer guessing by the regex "the id before the opening shape".
  if mmd_ok; then
    ENID="$(mmd --nodes "$FL" | awk -F'\t' '$1 ~ /^E[0-9]+$/ {print $1}' | sort -u | tr '\n' ' ')"
  else
    ENID="$(awk '/^```/{c=!c;next} c' "$FL" | grep -oE '(^|[[:space:]])E[0-9]+ *[[({]' | grep -oE 'E[0-9]+' | sort -u | tr '\n' ' ')"
  fi
  [ -n "$ENID" ] \
    && warn "$ID.flow.md uses node ids of the form E<number> ($ENID) — easy to misread as exceptions; use P# for an ordinary terminal node, X# for an exception terminal"
  # A diagram that DOES NOT RENDER cannot be re-read by anyone, and every count above counts on something that does not exist.
  # Measured: 17 of runxops 88 mermaid blocks were broken while the gate stayed green (P-32). Lints flow · sequence · UC · screens/README.
  mmd_lint "$FL" "$DIR/$ID.sequence.md" "$F" "$DIR/screens/README.md" \
    || bad "the mermaid diagram above does not render (js/mermaid.mjs --lint) — fix it and run again; a broken diagram is one nobody reads"
elif [ -f "$BP" ]; then
  ok "$ID.bpmn (the old path — a mermaid .flow.md lets E# be counted, consider moving)"
  [ -f "$BP.svg" ] || warn "$ID.bpmn.svg has not been exported"
elif [ -f "$OLD" ]; then bad "$ID.bpmn is still in the old place specs/contexts/$CTX/diagrams/ — move it into the UC directory (see the README section on the 1.x layout)"
else bad "missing ${DIR#$ROOT/}/$ID.flow.md (mermaid) — or $ID.bpmn if you still use BPMN"; fi

# 6. entities + glossary — measuring CONTENT, not shape.
# The previous version checked `grep -q stateDiagram`, and the context template ships with a sample
# stateDiagram-v2 block — so the check matched itself. An entities.md still holding class EntityA/EntityB
# printed ✓ and did not warn a word. A check that reports green WRONGLY is worse than no check: without
# one, people still remember to look. The same shape of bug as #11 (preconditions measuring structure)
# and #13 (a placeholder RULE). See #24.
# 7.0 (T2): one file per entity in specs/core/entities/ + specs/<craft>/entities/; whichever entity the UC
# uses is "the UC entities" (entity_cited). 6.x: the context entities.md, one file for all of them.
EF="$EFALL"
if [ -z "$EF" ]; then bad "missing entity — $(entity_hint)"
else
  case "$EF" in */specs/contexts/*) ok "context $CTX has an entities.md";; *) ok "$CTX has $(printf '%s\n' $EF | wc -l | tr -d ' ') entities ($(printf '%s\n' $EF | xargs -n1 basename | sed 's/\.md$//' | tr '\n' ' ' | sed 's/ $//'))";; esac
  cat /dev/null $EF | grep -qE '(class|## )Entity[AB]([^A-Za-z0-9]|$)' && bad "the entity is still the template EntityA/EntityB — no real entity name yet"
  cat /dev/null $EF | grep -q '<Context>' && bad "the entity still carries the template title '# Entity Model — <Context>'"
  if cat /dev/null $EF | grep -q 'stateDiagram'; then
    # DELIBERATELY scanning the whole file instead of each arrow: ONE arrow carrying a real UC is
    # enough to pass. Do not tighten this to "every arrow must carry a UC" — some states change
    # because THE OUTSIDE WORLD changed, not because a UC pulled them. Real case at runxops:
    # `alive --> suspended` happens because the exchange locks the account, no UC causes it.
    # A per-arrow rule would push people to stick a fake UC-### on it — that is, to invent, exactly
    # what this whole process exists to prevent.
    # 7.5 (P-32): read the LABELS mermaid itself understands, do not grep lines. One ; inside a label makes mermaid lose
    # EVERY label of the WHOLE diagram (measured on runxops core/entities/Account.md: 4 of 4 relations came back empty,
    # 5 junk states) — grep still saw "UC-016" and still printed ✓, while the diagram a reader sees had no text left.
    if mmd_ok; then
      STUC="$(for _e in $EF; do mmd --states "$_e"; done | awk -F'\t' '$3 ~ /UC-[0-9]+/' | head -1)"
      if [ -n "$STUC" ]; then ok "the state diagram has an arrow carrying a real UC (the label parses)"
      elif cat /dev/null $EF | grep -qE '\-\->.*UC-[0-9]+'; then
        bad "the state diagram contains the text UC-### but mermaid reads NO label carrying a UC — the labels are lost on render:"
        mmd_lint $EF || true
      else bad "the state diagram still holds the template '<UC-### ...>' — at least one arrow must name a real UC pulling that state"; fi
    else
      cat /dev/null $EF | grep -qE '\-\->.*UC-[0-9]+' && ok "the state diagram has an arrow carrying a real UC" \
        || bad "the state diagram still holds the template '<UC-### ...>' — at least one arrow must name a real UC pulling that state"
    fi
    mmd_lint $EF || bad "the entity mermaid diagram does not render — fix it and run again"
  else
    warn "the entity has no state diagram yet"
  fi
fi
# glossary: before 3.3.0 NO script mentioned it — grep -ric glossar scripts/ returned 0.
# So it drifted in silence, while the project CLAUDE.md told the AI to use exactly the names in it.
GF="$GFS"
if [ -z "$GF" ]; then warn "there is no specs/glossary.md yet"
elif cat /dev/null $GF | grep -qE "$(kw ph_term)|<Context A>"; then
  bad "specs/glossary.md is still the untouched template — CLAUDE.md says to use the names in it, and there are none"
  # Saying what is wrong and why is not enough: "go write a glossary" is a blank page. Whoever is at
  # this step has almost always finished entities.md already, and the entity names are the first batch
  # of terms — turning a blank page into copying. Compare the P#/X# warning of §5, which says what to
  # type. See #24.
  ENTN="$(entity_names "$F" "$ROOT" | tr '\n' ' ')"
  if [ -n "$ENTN" ]; then
    info "the first batch is at hand — the entity names already written: $ENTN"
  else
    info "the first batch comes from the entity names ($(entity_hint))"
  fi
  if [ "$(layout "$ROOT")" = v7 ]; then
    info "one term per line:  - **Name** — a one-sentence meaning. A project-wide term goes in specs/glossary.md, a craft term in specs/$CTX/glossary.md. Do not confuse it with **a near synonym**."
  else
    info "one term per line, under the heading '## $CTX':  - **Name** — a one-sentence meaning. Do not confuse it with **a near synonym**."
  fi
else
  GN="$(cat /dev/null $GF | grep -cE '^- \*\*[^<]')"; [ -z "$GN" ] && GN=0
  [ "$GN" -ge 1 ] && ok "the glossary has $GN terms" || bad "specs/glossary.md has no '- **term** — meaning' line yet"
fi

siblings
# 7.0: a core UC may not know a craft — layer-check only WARNS here (a freshly migrated repo still carries old debt;
# the pre-commit.d/20-layer-boundary githook blocks new debt once enabled).
if [ "$CTX" = core ] && [ -f "$HERE/layer-check.sh" ]; then
  LCO="$(bash "$HERE/layer-check.sh" --file "$F" "$DIR/$ID.flow.md" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep '✗' | head -3)"
  [ -n "$LCO" ] && { warn "a core UC quotes a craft ID — the core does not know a craft (layer-check.sh):"; printf '%s\n' "$LCO" | cut -c1-110 | sed 's/^/      /'; }
fi

# 7. the adversarial pass has content
AP="$(ev_body adversarial "$F")"
if echo "$AP" | grep -qE "($(kw rundate)): *[0-9]{4}-[0-9]{2}-[0-9]{2}"; then ok "the adversarial pass has run"; else bad "the ## Adversarial pass section has no 'Run date: YYYY-MM-DD'"; fi
echo "$AP" | grep -qE "$(kw ph_advq)" && bad "the adversarial pass still has a placeholder"
# A claim of "→ spec" must carry a real ID, otherwise nobody can check whether it was actually
# carried out — which is exactly what the adversarial pass catches. See #12.
SO="$(echo "$AP" | grep -E '→ *spec' || true)"
if [ -n "$SO" ]; then
  while IFS= read -r ln; do
    [ -z "$ln" ] && continue
    IDS="$(printf '%s' "$ln" | sed 's/.*→ *spec//' | grep -oE '(RULE-[0-9]+|AC-[0-9]+|E[0-9]+)' | sort -u)"
    if [ -z "$IDS" ]; then
      bad "adversarial: a '→ spec' with no ID, so it cannot be checked: $(printf '%s' "$ln" | cut -c1-60)"
      continue
    fi
    for id in $IDS; do
      case "$id" in
        RULE-*) [ -n "$(rule_file "$id" "$ROOT")" ] && ok "adversarial → $id is real" || bad "adversarial claims → $id but rules.md has no such rule";;
        AC-*)   grep -qE "^### $id\b" "$F" && ok "adversarial → $id is real" || bad "adversarial claims → $id but the UC has no such AC";;
        E*)     grep -qE "^- +(\*\*)?$id[.:]" "$F" && ok "adversarial → $id is real" || bad "adversarial claims → $id but the UC has no such E#";;
      esac
    done
  done <<< "$SO"
fi

# 7b. If the three roles ran but most questions still have no outcome, the adversarial pass is only
# half done: it ASKED but did not DECIDE. It is measurable (#25 measured 21 of 24 on a real case), so say it.
AQ="$(printf '%s' "$AP" | grep -cE '^[[:space:]]*- Q[0-9]+')"; [ -z "$AQ" ] && AQ=0
AE="$(printf '%s' "$AP" | grep -cE "($(kw output)): *_{2,}")"; [ -z "$AE" ] && AE=0
if [ "$AQ" -ge 3 ] && [ "$AE" -gt $((AQ/2)) ]; then
  warn "$AE of $AQ adversarial questions still read 'outcome: ___' — asked but not decided. Run /sdd-solo:adversarial $ID again to have each one presented with its context and choices."
fi

# 7c. The implementation assumption — a WARNING, not a block (#35).
# The four requirement layers (BR/UC/Entity/AC) have no drawer for "built with what, runs where,
# called by whom". So the design fell to /speckit-plan, which sits AFTER this gate. Real case: a UC
# passed the gate with a Main Flow assuming a CLI on the local machine; the next day the plan revealed
# the product was a remote server, three sentences of the Main Flow could not be carried out, and the
# gate had to be reopened. A gate cannot decide the architecture for you — but making the assumption
# BE SAID is cheap, and it would have caught exactly that case.
if grep -qE "^$(kwl implassum) *[^ <]" "$F"; then
  ok "has **Implementation assumption:** — the stack / where it runs / who calls it are stated"
else
  warn "the UC does not state '**Implementation assumption:** <where it runs · who calls it · the stack>' — the Main Flow is standing on an assumption nobody wrote down"
  info "one line is enough. Without it, step ⑩ /sdd-solo:design has nothing to check against specs/architecture.md."
fi

# 8. an open question must carry an interim decision
# 8.4.2 (P-55): FOLD each item onto one line before looking. Up to 8.4.1 this grepped `^- [ ]`, i.e. the opening
# line only, so an item wrapped at 120 columns - the shape the plugin templates themselves produce - hid its
# `(interim decision: ...)` on line 2 to 4 and the gate went red on a UC that had one. Measured at runxops on
# UC-015 (the `maxConcurrentProfiles` and Windows/macOS items) and UC-032. A FALSELY RED GATE is the one failure
# this repo cannot have: the fix is to re-word a spec that was already right, and after doing that twice nobody
# believes the next red either. Same root as P-54 in context.mjs - a list item is a BLOCK, not a line.
# Folded with awk, not node: the DoR gate must run where node does not (CI, a fresh clone) and this check may
# never become one that cannot run.
OQ="$(sed -n '/^## Open Questions/,/^## /p' "$F" | awk '
  /^- \[/                { if (cur != "") print cur; cur = $0; next }
  /^[ \t]+[^ \t]/        { if (cur != "") { l = $0; sub(/^[ \t]+/, "", l); cur = cur " " l } next }
                         { if (cur != "") print cur; cur = "" }
  END                    { if (cur != "") print cur }' | grep -E '^- \[ \]')"
if [ -n "$OQ" ]; then
  OQM="$(printf '%s\n' "$OQ" | grep -viE "$(kw interim)")"
  if [ -n "$OQM" ]; then
    bad "an Open Question has no ($(kw_w interim "$ROOT"): ...)"
    # Name the offending items. Without this the reader re-reads the whole section to find which one - measured
    # at runxops as part of the same report.
    printf '%s\n' "$OQM" | cut -c1-120 | sed 's/^/      /'
  else ok "the Open Questions carry interim decisions"; fi
fi

# 9. the docs commit + a re-read with an unanchored mind
#
# ONE DOOR (6.0.0, #38): verify is mandatory. What step ⑧ needs is a reader NOT ANCHORED by the
# writer assumptions. The original rule bought that with a night on the calendar; 3.5.0 (#27) opened a
# second door (verify) because a night measures TIME PASSING, not WHETHER THE READING HAPPENED: the same
# person, the same anchor, a 30-second skim in the morning still passed the gate.
# Keeping door 1 for two more major releases showed it was still the cheapest path and therefore still
# the path taken — the owner settled on removing it (runxops 2026-09-13, CHG-001 stood at change-check
# only because it was "written today").
#
# The remaining door measures the right thing: a reading happened and produced a result. The anti-faking
# latch is that an F# line must CARRY AN ANCHOR and CARRY AN OUTCOME — inventing such a line costs exactly
# as much as really reading. And the re-read commit must be the LATEST spec commit: editing the spec after
# the re-read means reading again, whatever the date. A reading that found nothing does not open the gate —
# deliberately: an unanchored reading of a UC-sized spec that produces not one finding (not even one
# rejected with "not a bug because") had too narrow a scope.
RR="$(rr_lines "$F")"; RRN=0; RRU=0
[ -n "$RR" ] && { RRN="$(printf '%s\n' "$RR" | rr_count)"; RRU="$(printf '%s\n' "$RR" | rr_undecided)"; }
[ -z "$RRU" ] && RRU=0
# 8.0.0 — the ceiling on re-read rounds. An Undecided outcome is a legitimate one (7.0.1 #53: verify does not
# ask, and opening the gate with an open question is a debt the owner takes on knowingly), so the gate has only
# ever counted them. Measured on runxops, that turns out to be the loophole: rounds and leftovers rise together —
# UC-024 13 rounds / 105 Undecided, UC-029 13 / 74, UC-026 12 / 71, UC-025 9 / 37 — while every UC that stopped
# at one round carries none. Another round is not an answer to the previous round; it is the cheapest way to look
# busy, and it is what grew one UC file to 455 KB.
# So: under the ceiling nothing changes. AT the ceiling, an Undecided may no longer be carried forward — it
# becomes an Open Question (the owner owes an answer) or a ticket (someone else does). This is a STOP, not a
# door: there is no flag, and doing one more round does not clear it — the number only goes down by deciding.
RMAX="$(rr_max "$ROOT")"; RND="$(rr_rounds "$F")"
if [ "$RMAX" -gt 0 ] && [ "$RND" -ge "$RMAX" ] && [ "$RRU" -gt 0 ]; then
  bad "round $RND of the re-read has reached the ceiling (rr_max=$RMAX) and $RRU finding(s) are still Undecided — turn each into an Open Question or a ticket; a further round is not an answer"
  info "the ceiling lives in .sdd/config (rr_max=0 switches it off, and then nothing counts the rounds)"
elif [ "$RMAX" -gt 0 ] && [ "$RND" -ge "$RMAX" ]; then
  ok "$RND re-read rounds, at the ceiling (rr_max=$RMAX), nothing left Undecided"
fi
# A claim inside ## Re-read must carry a REAL ID — exactly the §7 rule for adversarial (#12). Real case
# (runxops): an F# line claimed '→ fixed RULE-007' after the person fixing it had reverted the code; the
# body was fixed but THE RECORD OF THE FIX was not — that is, the ## Re-read section is itself a place that
# can drift, and it drifted during the very re-read round. Unchecked, door 2 opens on a claim pointing at
# something that does not exist.
if [ -n "$RR" ]; then
  while IFS= read -r ln; do
    [ -z "$ln" ] && continue
    # 7.0.1 (#53): `→ Undecided (… · proposal: add AC-9)` is a PROPOSAL awaiting the owner, not a claim of a fix —
    # the ID inside it is allowed not to exist yet. Verify no longer asks, so every line not rejected has this shape.
    # 7.4 (P-37): only the LIVE TAIL counts — the text after the last arrow, minus (…) and `…` (rr_tail). Up to 7.3
    # `case *"→ Undecided"*` exempted the whole line, so a live tail "→ fix AC-9" hiding behind a quoted "(→ Undecided …)"
    # escaped the check; conversely an arrow inside the quote "`✗ … → E4 …`" is not an outcome. A tail reading
    tl="$(printf '%s\n' "$ln" | rr_tail)"
    [ -z "$tl" ] && continue
    case "$tl" in *"$(kw_w undecided)"*) continue;; esac
    for id in $(printf '%s' "$tl" | grep -oE '(RULE-[0-9]+|AC-[0-9]+|E[0-9]+)' | sort -u); do
      case "$id" in
        RULE-*) [ -n "$(rule_file "$id" "$ROOT")" ] || bad "the re-read claims → $id but rules.md has no such rule";;
        AC-*)   grep -qE "^### $id\b" "$F" || bad "the re-read claims → $id but the UC has no such AC";;
        E*)     grep -qE "^- +(\*\*)?$id[.:]" "$F" || bad "the re-read claims → $id but the UC has no such E#";;
      esac
    done
  done <<< "$RR"
fi
# 5.2.0: only a docs($ID) commit that TOUCHED THE SPEC counts — the UC file, flow, screens/, rules.md,
# entities.md. Grepping the subject used to be enough, so the step ⑩ commit `docs(UC-###): design —
# design.md + tasks.md` (skill design §6 says to name it that) held the gate red until the next day even
# though UC-###.md had not changed a byte. "Right rule, wrong scope" — and a false red teaches people to
# ignore it. Real case: runxops UC-009 went red right after committing design.md (runxops-ea).
# The remaining hole, known and not yet handled: editing rules.md under the subject docs(UC-010) or
# docs(RULE-###) is invisible to UC-009 — dropping the subject grep would be more correct but would turn
# every UC of the same context red when someone edits rules.md; there is no real case yet to weigh it.
# 7.0: the pathspec includes the 6.x paths — a docs($ID) commit from before the migration lives in
# specs/contexts/…; git log is not --follow, so the old names must be listed or a UC moved to the new tree loses its whole re-read history (#55).
# 7.4 (P-31): the UC path in the pathspec is the PATTERN `specs/*/br-*/use-cases/ID-*/…`, not the current path — git log
# is not --follow, so a UC just `git mv`-ed to another slice loses every re-read commit at the old path and the gate goes
# red with "BEHAVIOUR changed (unclear)". The pattern must reach git intact: glog turns off shell globbing (with the repo as
# cwd the shell would expand the pattern into the current path, exactly the trap being avoided).
if [ "$(layout "$ROOT")" = v7 ]; then
  SPECP="specs/*/br-*/use-cases/$ID-*/$ID.md specs/*/br-*/use-cases/$ID-*/$ID.trace.md specs/*/br-*/use-cases/$ID-*/$ID.flow.md specs/*/br-*/use-cases/$ID-*/screens $RFS $EFS specs/contexts/*/use-cases/$ID-*/$ID.md specs/contexts/*/use-cases/$ID-*/$ID.trace.md specs/contexts/*/use-cases/$ID-*/$ID.flow.md specs/contexts/*/use-cases/$ID-*/screens specs/contexts/*/entities.md specs/rules.md"
else
  SPECP="$F $(trace_of "$F") $DIR/$ID.flow.md $DIR/screens $RFS $EFS"
fi
# 8.0.1: $ID.trace.md IS a spec path. From 8.0.0 the re-read is written there and nowhere else, so a verify commit
# on a migrated repo touches only that file — and with it missing from the pathspec `glog` returns nothing, §9 reads
# "there is no docs(UC-###) commit yet", and THE GATE CAN NEVER OPEN. It is invisible to a before/after comparison
# of an existing repo (no such commit exists yet in one), which is exactly why it needed its own test: case 50 writes
# a re-read into the trail, commits only that file, and demands the gate see it.
glog() { set -f; git -C "$ROOT" log "$@" -- $SPECP 2>/dev/null; set +f; }
LAST="$(glog -1 --format=%cs --grep="^docs($ID)")"
LASTS="$(glog -1 --format=%s --grep="^docs($ID)")"
# #49: the latest re-read commit, and the "behavioural fingerprint" of the spec at a revision. Real case at
# runxops UC-014: six re-reads (19 → 23 → 11 → 7 → 7 → 10) because each round of applying wording/label fixes
# in a sibling file also dragged in a full verify round (~200 KB, ~10 minutes). The owner settled it: only a
# CONTRADICTION BETWEEN TWO PLACES or an AC THAT CANNOT BE TESTED blocks; wording debt needs no re-verify.
# So the gate lets a commit after the re-read through IF the behavioural fingerprint is unchanged:
# Main/Alternative/Exceptions/Postconditions/AC of the UC · flow.md · the quoted RULE statements (minus the
# Applies to line) · the mermaid of entities.md. Changing any of those areas is changing behaviour → read again (full or --since).
# 7.4: the fingerprint functions (spec_fp · fp_changed) moved to lib.sh — close-check shares them (P-10).
RH="$(glog -1 -E --format=%H --grep="^docs\($ID\): ($(kw c_reread))")"
FP_CHANGED=""; FP_SKIP=""
[ -n "$RH" ] && FP_CHANGED="$(fp_changed "$ROOT" "$ID" "$RH" HEAD "$EFS")"
# the latest commit touching the spec, WHATEVER its subject — so the "BEHAVIOUR changed" message names the right commit
# (a docs(RULE-###) commit editing a rule statement does not carry the UC name, P-35).
LASTANY="$(glog -1 --format='%s (%cs)')"
# This must use `case`, NOT ${LASTS#docs($ID): ...}: the parentheses in a prefix-strip pattern
# make it match nothing at all, silently — measured: the string comes back exactly as it went in,
# so the condition is always false and the door never opens. The same family as the `ls a b` trap
# (#16): it breaks quietly, with no error.
RRC=0; printf '%s' "$LASTS" | grep -qE "^docs\($ID\): ($(kw c_reread))" && RRC=1
# 7.4 (P-20): say how many findings are still "→ Undecided" — a valid outcome (7.0.1 #53), but opening the gate with them
# is a debt the owner takes on; a ✓ must not look identical at "all decided" and at "nothing decided".
rr_warn() { [ "$RRU" -gt 0 ] && warn "$RRU of $RRN findings still read '→ Undecided (waiting on the owner …)' — opening the gate is a debt you take on (#53); once answered, change the tail to '→ Decided: …' or fix the spec + verify --since"; return 0; }
if [ "$ST" = implemented ]; then
  # 7.4 (P-16): the UC is closed — the mark to compare against is the CLOSING COMMIT, not the re-read (## Re-read has been
  # compressed to one line, and comparing against it makes every docs commit after closing falsely red with "not re-read" /
  # "BEHAVIOUR changed"). §0 already went red over the status; here we only add whether the spec changed behaviour after
  CH="$(glog -1 -E --format=%H --grep="^docs\($ID\): implemented — traceability")"
  if [ -n "$CH" ]; then
    CHG="$(fp_changed "$ROOT" "$ID" "$CH" HEAD "$EFS")"
    if [ -z "$CHG" ]; then ok "after the closing commit the spec only changed outside the behaviour areas — §9 does not apply to an implemented UC"
    else bad "the spec changed BEHAVIOUR after the UC was closed — areas:$CHG; an implemented UC changes behaviour through Phase 5 (/sdd-solo:change), not by direct editing"; fi
  else info "an implemented UC with no closing commit from pass.sh close — §9 does not apply"; fi
elif [ "$ST" = deprecated ]; then info "the UC is deprecated — §9 does not apply"
elif [ -z "$LAST" ]; then bad "there is no docs($ID) commit yet — /sdd-solo:adversarial ends with that commit"
elif printf '%s' "$LASTS" | grep -qE "^docs\($ID\): spec reviewed — ($(kw c_dor))$"; then
  # The latest spec commit was made by gate-pass itself, not by someone editing the spec. Without this
  # branch, the act of passing the gate destroys the condition for passing the gate (#7). A REAL spec edit
  # after the gate produces a commit with a different subject → it falls to the last branch and must be re-read.
  ok "the latest docs($ID) is the gate-pass commit — the gate was passed before"
elif [ "$RRN" -eq 0 ]; then
  bad "not re-read with an unanchored mind — ## Re-read / ## Đọc lại has no F# line carrying both [anchor: ...] and an outcome other than ___"
  info "/sdd-solo:verify $ID (a subagent re-reads, writes the F# lines, commits separately). Since 6.0.0 there is no overnight door."
elif [ -n "$RH" ] && [ -n "$FP_CHANGED" ]; then
  # 7.4 (P-35): compare the fingerprint BEFORE believing "the re-read commit is the latest spec commit" — a docs(RULE-###)
  # commit editing a rule statement does not carry the UC name, so LASTS is still the re-read while behaviour has changed.
  bad "the spec changed BEHAVIOUR after the re-read — the latest commit touching the spec is '$LASTANY'; areas changed:$FP_CHANGED"
  info "run /sdd-solo:verify $ID --since $(git -C "$ROOT" log -1 --format=%h "$RH" 2>/dev/null) — reading only what changed since the previous re-read; the new re-read commit becomes the new mark"
  # #41: "enough to fix, not enough to understand" — say the order too, so next time the tickets are applied BEFORE verify.
  info "the order: apply every ⑦ finding (wording/labels and sibling files included) → ⑧ verify → ⑨ gate, back to back; editing the spec after ⑧ means accepting another re-read"
elif [ "$RRC" = 1 ]; then
  ok "re-read with an unanchored mind: $RRN findings with an anchor + an outcome, and the separate commit is the latest spec commit (#27, #38)"
  rr_warn
elif [ -n "$RH" ]; then
  NCH="$(glog --format=%h "$RH..HEAD" --grep="^docs($ID)" | wc -l | tr -d ' ')"
  ok "re-read: $RRN findings with an anchor + an outcome; the $NCH spec commits since only applied wording/labels — Main/Alt/Exceptions/Postconditions/AC · flow · the RULE statements · the entities mermaid are unchanged (#49)"
  [ -n "$FP_SKIP" ] && info "the re-read happened before the v7 migration — the entities mermaid area cannot be compared across that mark (one file per context → one per entity); check by hand if an entity changed"
  rr_warn
else
  bad "the spec changed BEHAVIOUR after the re-read — the latest docs($ID) is '$LASTS' ($LAST); no 'docs($ID): re-read' commit was found to compare the fingerprint against"
  info "run /sdd-solo:verify $ID — the new re-read commit becomes the mark"
fi
git -C "$ROOT" status --porcelain -- "$DIR" $RFS 2>/dev/null | grep -q . && bad "there are uncommitted spec changes — commit docs($ID) first"

echo
if [ "$FAIL" -eq 0 ]; then echo "THROUGH THE GATE ($WARN warnings)."; exit 0; else echo "NOT THROUGH — $FAIL errors, $WARN warnings. Fix them and run again."; exit 1; fi
