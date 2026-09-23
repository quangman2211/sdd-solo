#!/usr/bin/env bash
# br-check.sh BR-### — the mechanical check of the BR layer (Phase 1). exit 0 = usable.
# The BR is the top layer: a wrong BR makes every UC under it wrong, and the 24 checks at the
# DoR gate will then help the user be wrong with great discipline. Before 3.2.0 this layer had
# no check at all. See #18.
ID="$1"; [ -z "$ID" ] && { echo "usage: br-check.sh BR-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; BF="$(br_file "$ID" "$ROOT")"
echo "BR check — $ID"
[ -f "$BF" ] || { bad "no ${BF#$ROOT/} — run /sdd-solo:init (6.x) or /sdd-solo:intake (7.0 creates the br-###/ slice)"; exit 1; }
if [ "$ID" = "BR-000" ]; then
  info "BR-000 is the template sample BR — not checked. Write BR-001 and check that one."
  exit 0
fi

# ── BR-000 must DISAPPEAR once a real BR exists ───────────────────────────
# Up to 4.2.0 the rule was "keep the BR-000 sample" — and that is where it broke, measured at
# runxops: BR-000 carried CON-001/002/003, and the real BR-001 also carried CON-001/002/003.
# `id_exists()` looks a CON up by grepping THE FIRST MATCHING LINE, so it always hit the BR-000
# set. The real consequences, not hypotheticals:
#   · UC-009 quoting CON-002 → the DoR gate matched "payment records kept for 10 years";
#   · architecture.md ## Forbidden saying "No eBay API calls. CON-001 — a personal
#     account…" → design-check reported GREEN by pointing at "shared hosting".
# UC-009 went through the gate with quotations pointing at the wrong item.
#
# A sample BR is useful exactly while there is nothing else to read. After that it is a run of
# fake IDs standing in front of every real ID in the same file — and with a fake ID in front,
# every "first matching line" lookup lands on it. Renumbering the real BR CONs treats the
# symptom; the real fix is that the sample BR must leave when its job is done.
# "A REAL BR" = a title with no `<...>` left. Counting by the PRESENCE of an ID is wrong: the
# template ships `# BR-001: <Business requirement name>`, so a freshly scaffolded repo also has
# a "BR-001" and this check would go red on the first install — a false red on a repo nobody has
# touched is the fastest way to teach people to ignore red lines.
REAL=""
for b in $(br_ids "$ROOT" | grep -v '^BR-000$'); do
  grep -qE "^# $b:.*<[^>]+>" "$BF" && continue
  REAL="$b"; break
done
if [ -n "$REAL" ] && grep -qE '^# BR-000\b' "$BF"; then
  bad "br.md already has a real $REAL while BR-000 (the sample BR) is still there — delete the whole BR-000 section"
  info "  BR-000 carries its own CON-001/002/003. While it is there, every CON-### lookup"
  info "  by 'the first matching line' hits the teaching example, not the real CON."
  info "  If you need to read the sample BR again: it is in the plugin templates, it is not lost."
fi
B="$(br_body "$ID" "$ROOT")"
[ -z "$B" ] && { bad "cannot find '# $ID: ...' in ${BF#$ROOT/}"; exit 1; }

# ── The source brief (#34) ────────────────────────────────────────────────
# All three checking layers of the plugin measure INSIDE specs/: gate-check measures inside
# specs/, verify reads inside specs/, the three adversarial roles are deliberately blind to the
# brief. So after intake the brief becomes a WRITE-ONLY file — two documents contradicting each
# other for days with no check whose job is to look. This is the only place in the whole set that looks outside specs/.
BP="$(brief_path "$ROOT")"
if [ -n "$BP" ]; then
  if [ ! -f "$ROOT/$BP" ]; then
    bad "brief_path=$BP but the file does not exist — the config declares a source that is not there"
  else
    BS="$(sha "$ROOT/$BP" | cut -c1-12)"
    BREC="$(brief_rec_sha "$ROOT")"
    if [ -z "$BREC" ]; then
      warn "br.md does not record '**Brief source:** $BP · sha256 <12 hex> · loaded <date>' — there is no way to trace which brief the BR was converted from"
    elif [ "$BREC" != "$BS" ]; then
      bad "the brief changed since intake (sha $BREC → $BS) — br.md and the brief may now contradict each other"
      info "compare them and update the '**Brief source:**' line, or run /sdd-solo:intake $BP again"
    else
      ok "the source brief matches the recorded sha ($BS)"
    fi
  fi
fi

sec() { printf '%s' "$B" | awk -v h="$1" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}'; }
# secre — like sec but taking a PATTERN (kwh <name>), for a section heading in either language
secre() { printf '%s' "$B" | awk -v re="$1" '$0 ~ re {f=1;next} f&&/^## /{exit} f{print}'; }
# nonempty/filled use the shared version in lib.sh (4.0.1)

# ── 7.0: layer 0 — a BR claims to be a slice, and does not narrow what vision.md forbids narrowing ──
# Real case (plan 7.0 §1): runxops BR-003 was narrowed three times over three adversarial rounds — each time
# correctly by the rule "no number, no Background entry" — until "the write direction" sat in Out of Scope
# with nobody noticing, because no layer held the intent. The three checks below only run on the 7.0 layout
# (an unmigrated 6.x repo has no vision.md).
V7=0; [ "$(layout "$ROOT")" = v7 ] && V7=1
if [ "$V7" = 1 ]; then
  VF="$(find_vision "$ROOT")"
  if [ -z "$VF" ]; then
    warn "there is no specs/vision.md yet — layer 0 is unwritten; a BR has nothing to claim a slice against (/sdd-solo:intake step 0)"
  else
    # (a) **Slice:** <craft> · <slice name> — the craft must be the directory holding the BR, and the slice name must be in the ## Crafts and slices table
    LAT="$(printf '%s' "$B" | grep -oE "^- $(kwl slice) *.*" | head -1 | sed -E "s/^- $(kwl slice) *//")"
    LN="$(printf '%s' "$LAT" | awk -F' · ' '{print $1}' | sed 's/[[:space:]]*$//')"
    # The slice name is everything after the FIRST craft prefix. Up to 7.0.0 this was built with awk -F' · ' '{$1=""…}' —
    # awk rejoins the fields with OFS (a space), so a slice name containing ' · ' lost the middle separator and went falsely
    # red (runxops: 'core · sign in · admin app (console)' → 'sign in admin app (console)'). Cut exactly one prefix, do not split fields.
    LT=""; case "$LAT" in *" · "*) LT="${LAT#* · }";; esac
    LT="$(printf '%s' "$LT" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/ — .*//')"
    OWN="$(owner_of_br "$ID" "$ROOT")"
    VT="$(awk -v re="$(kwh craftslice)" '$0 ~ re {f=1;next} f&&/^## /{exit} f' "$VF" | grep -E '^\|' | grep -vE '^\|[- |]*\|$')"
    if [ -z "$LAT" ]; then
      bad "missing the line '- **Slice:** <craft> · <slice name>' in ## Metadata — every BR must claim to be a slice in specs/vision.md"
    elif ! nonempty "$LT" || printf '%s' "$LT" | grep -qE '^___$|<'; then
      bad "**Slice:** has no slice name yet (still ___ or <...>) — pick a row from the ## Crafts and slices table of specs/vision.md"
    elif [ -n "$OWN" ] && [ "$LN" != "$OWN" ]; then
      bad "**Slice:** names the craft '$LN' but the BR lives in specs/$OWN/ — the two places must name the same craft"
    elif ! printf '%s\n' "$VT" | grep -F -- "$LT" | grep -qE "^\| *$LN *\|"; then
      bad "**Slice:** '$LN · $LT' is not in the ## Crafts and slices table of specs/vision.md — add the row there (the owner does that) or fix the name to match"
    else
      ok "slice: $LN · $LT — present in specs/vision.md"
    fi
    # (b) Out of Scope may not contain a keyword of ## Do not narrow — unless the owner settled it with a date
    OOS="$(sec '## Out of Scope' | grep -E '^[[:space:]]*[-*] ')"
    KEYS="$(awk -v re="$(kwh nonarrow)" '$0 ~ re {f=1;next} f&&/^## /{exit} f' "$VF" | grep -E '^[[:space:]]*[-*] ' | sed -E 's/^[[:space:]]*[-*] *//' \
           | awk '{ if (match($0, /\*\*[^*]+\*\*/)) print substr($0, RSTART+2, RLENGTH-4); else print }' | grep -vE '^<|^___$' | awk 'NF')"
    if [ -n "$KEYS" ] && [ -n "$OOS" ]; then
      HITN=0
      while IFS= read -r k; do
        [ -n "$k" ] || continue
        H="$(printf '%s\n' "$OOS" | grep -iF -- "$k")"
        [ -n "$H" ] || continue
        while IFS= read -r ln; do
          [ -n "$ln" ] || continue
          if printf '%s' "$ln" | grep -qE "($(kw narrowed)) [0-9]{4}-[0-9]{2}-[0-9]{2}"; then
            info "Out of Scope narrows '$k' deliberately (settled by the owner): $(printf '%s' "$ln" | cut -c1-90)"
          else
            HITN=$((HITN+1))
            bad "Out of Scope narrows something vision.md forbids narrowing — '$k': $(printf '%s' "$ln" | cut -c1-100)"
          fi
        done <<EOF_H
$H
EOF_H
      done <<EOF_K
$KEYS
EOF_K
      [ "$HITN" -gt 0 ] && info "to really narrow it, that line must read 'deliberately narrowed — owner decided YYYY-MM-DD' (an owner decision, with a date); otherwise take it out of Out of Scope"
      [ "$HITN" -eq 0 ] && ok "Out of Scope narrows nothing from ## Do not narrow ($(printf '%s\n' "$KEYS" | grep -c .) keywords)"
    elif [ -z "$KEYS" ]; then
      warn "specs/vision.md ## Do not narrow has no item yet (in the form '- **keyword** — explanation') — nothing is holding the BR against narrowing"
    fi
    # Every Out of Scope line says where it went — a warning (the 7.0 template says so; not enough real cases to block)
    NOD_OOS="$(printf '%s\n' "$OOS" | grep -vE "→|$(kw narrow)" | grep -vE '<[^>]+>' | grep -c .)"
    [ "$NOD_OOS" -gt 0 ] && warn "$NOD_OOS Out of Scope lines do not say where they went — add '→ slice ___' or '→ reopen when ___' (or 'deliberately narrowed — owner decided YYYY-MM-DD')"
  fi
fi

# 1. the title
grep -qE "^# $ID: *[^ <]" "$BF" && ok "has a title" || bad "the line '# $ID:' has no real name yet"

# 2. Background — an assertion with no source belongs in Open Questions, not here
BG="$(sec '## Background')"
filled "$BG" && ok "## Background has content" || bad "## Background is empty or still a placeholder"
# Question 5 of intake ("is there a way not to build software at all?") is the only question that can
# stop something that need not exist from being built — but answering "have not thought about it" only
# produces an Open Question, and an Open Question blocks nothing. A BR that has not proved its reason to
# exist goes through the gate exactly like one that has. A warning, not red. See #22.
printf '%s' "$BG" | grep -qE "$(kwl whybuild)" \
  && ok "Background has a 'Why still build' line" \
  || warn "Background has no '**Why still build:**' line — nobody has shown this software needs to exist; this is where the sceptic role will push"
# #46: a BR converted from a brief must carry the words of whoever pays, not only the words of the agent who wrote the brief.
if printf '%s' "$(sec '## Metadata')" | grep -qiE "($(kw source)):\*\* *brief"; then
  printf '%s' "$BG" | grep -qE "$(kwl pain)" \
    && ok "Background has a 'What hurts, why it lands here' line (asked in words, #46)" \
    || warn "a BR converted from a brief whose Background has no '**What hurts, why it lands here:**' line — intake from a brief must ask the user in words before filling Goal/In Scope (#46); a brief cannot stand in for that answer"
fi

# 3. Goal — one sentence, and not vague while there is no number to measure it by
G="$(sec '## Goal')"
SM="$(sec '## Success Metrics')"
if ! filled "$G"; then bad "## Goal is empty or still a placeholder"
else
  ok "## Goal has content"
  # 7.4 (P-25): only count the full stops of the GOAL SENTENCE — a source line (*Source: …*, italics, a blockquote,
  # a footnote) under the Goal sentence is a note, not a second sentence.
  DOTS="$(printf '%s' "$G" | grep -vE "^[[:space:]]*(\*|_|>|<!--|$(kw source))" | grep -o '\.' | wc -l | tr -d ' ')"
  [ "$DOTS" -gt 1 ] && warn "## Goal has $DOTS full stops — a Goal should fit in ONE sentence"
  V="$(printf '%s' "$G" | grep -oiE "$(kw vague)" | head -1)"
  if [ -n "$V" ]; then
    if printf '%s' "$SM" | grep -qE '[0-9]'; then
      ok "the Goal uses the vague word '$V' but Success Metrics has numbers — accepted"
    else
      bad "the Goal uses '$V' while Success Metrics has no number — say what gets better where, and what measures it"
    fi
  fi
fi

# 4. Success Metrics — the NUMBER may be ___, HOW IT IS MEASURED may not.
# This is the boundary of the whole layer: "___" is honest ignorance; a missing measurement method
# is a metric that can never be checked, that is, a nice-sounding sentence.
if ! nonempty "$SM"; then bad "## Success Metrics is empty"
else
  N=0
  while IFS= read -r ln; do
    printf '%s' "$ln" | grep -qE '^[[:space:]]*[-*] ' || continue
    N=$((N+1))
    M="$(printf '%s' "$ln" | sed -nE "s/.*($(kw measuredby)): *//p" | sed 's/[)·].*//' | tr -d '_ ')"
    if [ -z "$M" ]; then
      bad "a metric with no measurement method: $(printf '%s' "$ln" | cut -c1-58)"
    fi
  done <<< "$SM"
  [ "$N" = 0 ] && bad "## Success Metrics has no '- ' line" \
                || ok "$N metrics, each with a measurement method"
fi

# 5. In Scope / Out of Scope — a BR that excludes nothing is almost always a BR not thought through
filled "$(sec '## In Scope')" && ok "## In Scope has content" || bad "## In Scope is empty or still a placeholder"
filled "$(sec '## Out of Scope')" && ok "## Out of Scope has content" \
  || bad "## Out of Scope is empty — working alone, this line is the only thing holding the scope back"

# 6. CON — must carry a classification and one statement
CS="$(sec '## Constraints')"
for c in $(printf '%s' "$CS" | grep -oE 'CON-[0-9]+' | sort -u); do
  L="$(printf '%s' "$CS" | grep -E "$c")"
  printf '%s' "$L" | grep -qiE "$c *(Technical|Regulatory|Timing|SLA)" \
    || bad "$c has no classification (Technical / Regulatory / Timing/SLA)"
  T="$(printf '%s' "$L" | sed -n 's/.*:\*\* *//p' | tr -d ' .')"
  [ -z "$T" ] && bad "$c has no statement yet" || ok "$c has a classification and content"
done

# 6b. A CON number reused across TWO BRs — scan THE WHOLE FILE, not only the BR being checked.
# CON numbers are allocated per BR, but the ID is used repo-wide: a UC quotes `CON-002` bare, with
# no BR attached. If two BRs both have a CON-002 then every lookup hits the earlier one and the
# later one becomes invisible — with no red line, because the ID still "exists".
# This check is NOT redundant once BR-000 is gone: two REAL BRs collide exactly the same way, and
# that case is coming, because each BR is written at a different time and nobody remembers how far
# the previous BR numbered.
DUP="$(strip_markup < "$BF" | awk '
  # Skip a BR that is still a template (its title still has `<...>`) — its CONs are templates too, and
  # the template `CON-001 ...` collides with BR-000 CON-001 on a freshly scaffolded repo.
  /^# BR-/ { match($0, /BR-[0-9]+/); br = substr($0, RSTART, RLENGTH)
             skip = ($0 ~ /<[^>]+>/) ? 1 : 0; next }
  skip { next }
  /^-? *\*\*CON-[0-9]+/ {
    match($0, /CON-[0-9]+/); c = substr($0, RSTART, RLENGTH)
    if (!(c in owner))      { owner[c] = br }
    else if (owner[c] != br) { print c "  (" owner[c] " and " br ")" }
  }' | sort -u)"
if [ -n "$DUP" ]; then
  bad "a CON number is reused across two BRs — every lookup only sees the earlier one:"
  printf '%s\n' "$DUP" | sed 's/^/      /'
  info "  renumber the later set, then fix every place quoting it."
fi

# 7. Impact Map — without a broken-off branch nothing was mapped, it is just a straight line from
# the Goal down to a list of work already decided on.
IM="$(sec '## Impact Map')"
if ! printf '%s' "$IM" | grep -qE '^[[:space:]]*(flowchart|graph)\b'; then
  bad "## Impact Map has no mermaid flowchart block"
else
  printf '%s' "$IM" | grep -qE '\-\.->' && ok "the Impact Map has an out-of-scope branch" \
    || bad "the Impact Map has no '-.->' branch — if everything connects back to the Goal nothing was mapped, it is just a work list"
fi
# 7.5 (P-32): every mermaid block of br.md must render — a broken Impact Map turns the whole section into red
# text, while br-check up to 7.4 only counted arrows and still printed ✓.
mmd_lint "$(br_file "$ID" "$ROOT")" || bad "a mermaid diagram in br.md does not render — fix it and run again"

# 8. Related Use Cases — both directions.
# The forward direction only WARNS: in Phase 1 a UC that does not exist yet is normal, the BR is
# written before the UC. Going red here would make every honest BR red with no way to fix it.
RU="$(sec '## Related Use Cases')"
for u in $(printf '%s' "$RU" | grep -oE 'UC-[0-9]+' | sort -u); do
  [ -n "$(find_uc "$u" "$ROOT")" ] && ok "$u has a file" \
    || warn "$u does not exist yet — normal in Phase 1, create it with /sdd-solo:start $u"
  # 7.4 (P-22): one UC in the Related Use Cases table of TWO slices — which slice owns it? Up to 7.3 no check went red;
  # real case at runxops: a UC in two tables, and /sdd-solo:state suggested two slices for one piece of work. The other slice points with Upstream UC, it does not list it in the table.
  OTH=""
  for b in $(br_ids "$ROOT" | grep -vx "$ID" | grep -v '^BR-000$'); do
    br_body "$b" "$ROOT" | sed -n '/^## Related Use Cases/,/^## /p' | grep -qE "$u([^0-9]|$)" && OTH="$OTH $b"
  done
  [ -n "$OTH" ] && bad "$u appears in the ## Related Use Cases of 2 or more BR tables ($ID$OTH) — a UC belongs to one slice; the other slice points with the UC '**Upstream UC:**', it does not list it in the table"
done
# The reverse direction IS red: a UC that declares it belongs to this BR while the BR does not claim
# it is real drift, and it is always fixable. The same both-directions lesson as #12, #15, #17.
for uf in $(all_uc_files "$ROOT"); do
  # 7.0: a UC inside the slice br-###/use-cases/ declares itself part of that slice — no Metadata line needed
  { [ "$(br_of "$uf")" = "$ID" ] || grep -qE "($(kw relbr)):.*$ID([^0-9]|$)" "$uf"; } || continue
  uid="$(basename "$uf" .md)"
  printf '%s' "$RU" | grep -qE "$uid([^0-9]|$)" \
    || bad "$uid declares it belongs to $ID but the ## Related Use Cases of $ID does not list it"
done

# 9. A BR converted from a brief must keep a trace of what was dropped.
# Rule 4 of intake before 3.2.2 only said "print the list", so its product lived in speech: closing
# the terminal lost it. A rule that leaves no trace in a file cannot be checked, and whatever cannot
# be checked eventually drifts. See #21.
if printf '%s' "$B" | grep -qiE "$(kwl source).*brief"; then
  DR="$(secre "$(kwh droppedbrief)")"
  if filled "$DR" && printf '%s' "$DR" | grep -qE '^[[:space:]]*[-*] .*—'; then
    ok "has a ## Dropped from brief"
    # A FORWARDING ADDRESS WITH NOTHING BEING DELIVERED (#34). A line saying "belongs to the design
    # layer" reads as handled, but no mechanism carries it there.
    # Real case: "the whole three-layer architecture" was deferred to the design layer, and two days
    # later the design wrote an architecture DIRECTLY OPPOSED to the brief with nobody comparing.
    # Since 4.0.0 the destination of this kind of line is specs/architecture.md, section
    # ## Settled from brief — a place that EXISTS and that design-check reads.
    # 7.0 (c): EVERY dropped line must have a destination — `→ slice ___` (which slice in vision.md takes it) ·
    # `→ reopen when ___` · `→ moved to: <destination>` (an architecture section). No destination means deferring into
    # thin air — plan 7.0 §1: three things dropped from BR-003 and nobody knew which slice they belonged to. On 6.x it still only warns (the block below).
    if [ "$V7" = 1 ]; then
      NOD7="$(printf '%s' "$DR" | grep -E '^[[:space:]]*[-*] ' | grep -vE "→ *($(kw dest))" | grep -vE '^[[:space:]]*[-*] *<' | grep -c .)"
      if [ "$NOD7" -gt 0 ]; then
        bad "$NOD7 lines of ## Dropped from brief have no destination — add '→ slice <slice name>' or '→ reopen when <condition>' to each (or '→ moved to: <destination>' for an architecture item)"
        printf '%s' "$DR" | grep -E '^[[:space:]]*[-*] ' | grep -vE "→ *($(kw dest))" | head -3 | cut -c1-110 | sed 's/^/      /'
      else
        ok "every ## Dropped from brief line has a destination (slice · reopen when · moved to)"
      fi
    fi
    FWD="$(printf '%s' "$DR" | grep -iE "speckit-plan|/plan|design\.md|ADR|Phase 5|$(kw deferarch)")"
    if [ "$V7" = 0 ] && [ -n "$FWD" ]; then
      NOD="$(printf '%s\n' "$FWD" | grep -vE "→ *($(kw fwddest))" | grep -c .)"
      if [ "$NOD" -gt 0 ]; then
        warn "$NOD items deferred to a later step with no DESTINATION — no mechanism moves them along"
        info "add '→ moved to: <a real destination>' to each such line (ADR-###, CHG-###, an Open Question, or a line in plan.md)"
        printf '%s\n' "$FWD" | grep -vE "→ *($(kw fwddest))" | head -3 | sed 's/^/      /'
      else
        ok "every deferred item records where it was moved to"
      fi
    fi
  else
    warn "the source is a brief but there is no ## Dropped from brief (one line each, '- <item> — <reason>') — what was dropped is recorded nowhere"
  fi
fi

# 10. the adversarial pass — a WARNING, not red. Phase 1 is softer than Phase 3: a finished BR is
# already usable to open UCs; the three roles are the step that makes it solid, not a condition of existence.
AP="$(sec '## Adversarial pass')"
printf '%s' "$AP" | grep -qE "($(kw rundate)): *[0-9]{4}-[0-9]{2}-[0-9]{2}" \
  && ok "the adversarial pass has run" \
  || warn "/sdd-solo:adversarial $ID has not been run — the three BR-layer roles often catch 'this is a solution written backwards into a reason'"

# 10b (5.1.0). Up to 5.0.0 the check above was the whole thing: the words "Run date:" made it green. It did not
# count `→ ___`, and did not check that a "→ Open Question" had a matching `- [ ]` line. The same bug as #12 ("an
# empty `→ spec` claim cannot be checked"), fixed in gate-check for UCs five releases earlier — it never spread
# to the BR. Measured at runxops (reported by a peer, re-measured and correct): 30 questions, 10 still `___`,
# 4 "→ Open Question", and the rule "nothing is left hanging" at skills/adversarial line 149 that no script read.
# Phase 1 IS ALLOWED to still hold `___` (a 3.x decision, still right) — so COUNT it, do not block.
# After migrate --evidence the body lives in br.evidence.md and the front is one counting line; read both.
APB="$AP"
EVF="$(evidence_file "$ID" "$ROOT")"
if printf '%s' "$AP" | grep -qE '→ .*evidence\.md' && [ -f "$EVF" ]; then
  APB="$APB
$(awk -v h="## $ID — ## Adversarial pass" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}' "$EVF")"
fi
NQ="$(printf '%s\n' "$APB" | grep -cE '^[[:space:]]*-[[:space:]]*Q[0-9]+\b')"
NB="$(printf '%s\n' "$APB" | grep -E '^[[:space:]]*-[[:space:]]*Q[0-9]+\b' | grep -cE '→[[:space:]]*`?___|^[^→]*$')"
if [ "$NQ" -gt 0 ] && [ "$NB" -gt 0 ]; then
  warn "adversarial: $NB of $NQ questions have no outcome yet (→ ___) — they may hang in Phase 1, but this is a debt, do not let it sink"
fi
# "→ Open Question" is a claim: there must be a `- [ ]` line in the same BR about it. Matched by keyword
# (the 3 longest words of the question, needing ≥ 2 hits) — deliberately sparse: a certain orphan (no `- [ ]`
# line at all) is RED; a failed match is a WARNING with the question quoted, because rewording defeats a
# machine and a false red teaches people to ignore it.
OQB="$(sec '## Open Questions' | grep -E '^[[:space:]]*- \[ \]')"
NOQC="$(printf '%s\n' "$APB" | grep -cE '→[[:space:]]*Open Question')"
if [ "$NOQC" -gt 0 ]; then
  if [ -z "$OQB" ]; then
    bad "adversarial claims '→ Open Question' $NOQC times but ## Open Questions has no '- [ ]' line — the claim points at empty space"
  else
    printf '%s\n' "$APB" | grep -E '→[[:space:]]*Open Question' | while IFS= read -r q; do
      KW="$(printf '%s' "$q" | sed 's/→.*//' | tr -c '[:alnum:]àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ' '\n' \
            | awk 'length($0)>=5' | awk '{print length($0), $0}' | sort -rn | head -3 | awk '{print $2}')"
      HIT=0
      for w in $KW; do printf '%s\n' "$OQB" | grep -qiF "$w" && HIT=$((HIT+1)); done
      [ "$HIT" -lt 2 ] && warn "adversarial '→ Open Question' with no matching '- [ ]' line found: $(printf '%s' "$q" | cut -c1-70)…"
    done
  fi
fi
# 10c (5.1.0). WHICH VERSION did the three roles read? Adversarial records "on vN" or only a date; History
# records the latest vN. If the three roles ran on v1 while the BR is already v3, then the most expensive
# question of this layer ("is this really a BR") was asked about a document that no longer exists. Just say it.
HV="$(sec '## History' | grep -oE '^- v[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)"
AV="$(printf '%s' "$AP" | grep -oE "($(kw onv))[0-9]+" | grep -oE '[0-9]+' | sort -n | tail -1)"
if [ -n "$HV" ] && [ -n "$AV" ] && [ "$AV" -lt "$HV" ]; then
  warn "the three roles ran on v$AV, the BR is already v$HV — the other two roles have not read the current version; run again or record why not"
elif [ -n "$HV" ] && [ -z "$AV" ]; then
  AD="$(printf '%s' "$AP" | grep -oE "($(kw rundate)): *[0-9-]+" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
  HD="$(sec '## History' | grep -oE '\(20[0-9]{2}-[0-9]{2}-[0-9]{2}\)' | tr -d '()' | sort | tail -1)"
  [ -n "$AD" ] && [ -n "$HD" ] && [ "$AD" \< "$HD" ] && warn "adversarial ran $AD, History was edited up to $HD — the three roles have not read the later version; write 'on vN' into the Run date so it can be measured"
fi

# 11. How many hanging questions really hang, and how many are just blank spots.
# '___' is a valid outcome and must not disappear. But when it is the overwhelming majority it is no
# longer "weighed and not yet decided" — it is "there was nothing to weigh". If it can be measured,
# say it, do not stay silent. See #25.
OQL="$(sec '## Open Questions' | grep -cE '^[[:space:]]*- \[ \]')"; [ -z "$OQL" ] && OQL=0
OQE="$(sec '## Open Questions' | grep -cE "($(kw interim)): *_{2,}")"; [ -z "$OQE" ] && OQE=0
if [ "$OQL" -ge 3 ] && [ "$OQE" -gt $((OQL/2)) ]; then
  warn "$OQE of $OQL hanging questions have an empty 'interim decision' — more than half. A question with nothing to weigh is not a ripe question yet; /sdd-solo:adversarial $ID will present each one with its context."
elif [ "$OQL" -gt 0 ]; then
  ok "$OQL hanging questions, $OQE of them with no interim decision"
fi

# 12. History
printf '%s' "$(sec '## History')" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "History has a dated line" || bad "## History has no 'v1 (YYYY-MM-DD)' line"

# 13. ___ is legitimate in Phase 1 — a warning, not red. Forcing it filled in early produces exactly the
# kind of invented number the whole intake step is trying to prevent.
U="$(printf '%s' "$B" | grep -o '___' | wc -l | tr -d ' ')"
[ "$U" -gt 0 ] && warn "$U ___ spots left — legitimate in Phase 1, but a debt: each one should have an Open Question line"

echo
if [ "$FAIL" -eq 0 ]; then echo "BR USABLE ($WARN warnings)."; exit 0; else echo "BR NOT USABLE — $FAIL errors, $WARN warnings."; exit 1; fi
