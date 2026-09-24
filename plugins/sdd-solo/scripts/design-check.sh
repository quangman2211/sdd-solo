#!/usr/bin/env bash
# design-check.sh UC-### — step ⑩: does the design layer exist and has it been checked back.
# exit 0 = enough to write code.
#
# TWO levels in one script, deliberately: whatever checks `design.md` has to read
# `architecture.md` to know what it is being checked against. Splitting it in two creates two
# scripts reading the same set of files and then drifting apart — exactly what happened to
# `uc-ready` and `gate-check` before 4.0.0.
#
# Why this layer exists (#34, #35): the four layers BR/UC/Entity/AC have no drawer for
# "built with what · runs where · called by whom". So the design fell to a step OUTSIDE the
# process, and there it could contradict the brief for days with no check whose job was to
# look at it.
ID=""
for a in "$@"; do case "$a" in UC-[0-9]*) ID="$a";; esac; done
[ -z "$ID" ] && { echo "usage: design-check.sh UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
echo "Design layer — $ID"
[ -z "$F" ] && { bad "cannot find the UC file"; exit 1; }
DIR="$(dirname "$F")"; CTX="$(owner_of "$F")"
DS="$DIR/design.md"; TK="$DIR/tasks.md"; AR="$(arch_file "$ROOT")"

# 4.2.0: the local `strip_tags()` is gone — everything uses `strip_markup()` from lib.sh.
# The two functions differed in one point, and that point was the bug: strip_tags removed TAGS,
# strip_markup removes the `<!-- … -->` BLOCK as well. Keeping a tags-only function next to it
# invites the next person to reuse exactly the one that just broke.

# ── 0. the DoR gate must have been passed ─────────────────────────────────
# Designing for a UC that has not passed the gate is designing for a spec that is still moving.
step "⑨ /sdd-solo:gate $ID — the DoR gate first, design after"
[ -f "$ROOT/.sdd/gate/$ID.ok" ] && ok "the DoR gate was passed" \
  || bad "there is no .sdd/gate/$ID.ok — run /sdd-solo:gate $ID first"

# ── 1. architecture.md — project level ────────────────────────────────────
step "specs/architecture.md — the project-level sections, by hand"
if [ ! -f "$AR" ]; then
  bad "missing ${AR#$ROOT/} — design.md has nothing to check back against"
else
  MISS=""
  for k in stack runswhere callers boundaries forbidden settledbrief; do
    grep -qE "$(kwh "$k")" "$AR" || MISS="$MISS '## $(kw_w "$k")'"
  done
  if [ -n "$MISS" ]; then bad "architecture.md is missing sections:$MISS"
  else ok "architecture.md has all six sections"; fi
  # 7.0: the design.md of a core UC may not pull a craft into the core — a warning (layer-check.sh)
  if [ "$CTX" = core ] && [ -f "$DS" ] && [ -f "$HERE/layer-check.sh" ]; then
    LCO="$(bash "$HERE/layer-check.sh" --file "$DS" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep '✗' | head -3)"
    [ -n "$LCO" ] && { warn "the design.md of a core UC quotes a craft ID/entity — the core does not know a craft:"; printf '%s\n' "$LCO" | cut -c1-110 | sed 's/^/      /'; }
  fi
  # A <...> placeholder = nobody decided. '___' IS legitimate (not decided, but known to be
  # undecided) — the same rule as the BR layer: '___' is an answer, '<...>' is a spot nobody has
  # touched. Skip the '>' quotation lines of the guidance block at the top of the file.
  #
  # A `<br/>` inside a mermaid block is NOT a placeholder — it is syntax. The first version counted
  # it as one, so a fully filled architecture.md still went red, and a falsely red line gets ignored,
  # taking the genuinely red ones with it.
  # strip_MARKUP, not strip_tags: the old filter only removed lines STARTING with `<!--`, so an
  # `<ID>` on a line in the MIDDLE of a multi-line comment block still counted as a placeholder.
  # The 4.2.0 architecture.md template itself was caught: the block explaining ## Forbidden contains
  # the sentence "replaced by <ID> from YYYY-MM-DD", and design-check falsely accused a freshly
  # scaffolded repo. The third time for the same trap (4.0.1, 4.0.x, now 4.2.0) — a comment is never
  # a placeholder, so the filter must drop THE WHOLE BLOCK, not each opening line.
  # strip_markup keeps the line count (97→97, measured) so `grep -n` still points into the real file.
  # 7.4 (I-8): `<core|craft>` inside code ticks is a path CONVENTION (tests/use-cases/<core|craft>/UC-###/), not an
  # undecided spot — drop the code ticks before searching; the line count is preserved because sed only edits within a line.
  PH="$(strip_markup < "$AR" | sed -E 's/`[^`]*`//g' | grep -nE '<[^>]+>' | grep -vE '^[0-9]+:>' \
        | grep -vE '^[0-9]+:[[:space:]]*(<!--|```)' | head -6)"
  if [ -n "$PH" ]; then
    bad "architecture.md still has a <...> placeholder — nobody decided, which is not the same as deciding there is none:"
    printf '%s\n' "$PH" | sed 's/^/      /'
  else
    ok "architecture.md has no placeholder left"
  fi

  # Every ID architecture.md quotes must be real. Up to 4.0.3 this rule only applied to design.md
  # (§2) — one script, two documents, one checked and one not. And `architecture.md` is the place
  # most likely to quote a CON/ADR/BR, because it is the only place required to name the source of
  # a prohibition.
  #
  # SAY PLAINLY WHAT IT MEASURES: this checks THAT THE ID EXISTS, not THAT IT SAYS WHAT IT IS
  # ATTACHED TO. A line quoting a real `BR-001` while reversing the meaning of BR-001 still passes
  # here. Only a reader catches that — and the ## Forbidden section demanding a VERBATIM quotation
  # is exactly what makes that reading cheap.
  # strip_markup FIRST: the template <!-- … --> block itself mentions CON-002, ADR-001 and BR-001
  # as examples. Scanning the comments means falsely accusing a freshly scaffolded repo — the same
  # kind of false red 4.0.1 had just fixed elsewhere.
  for x in $(printf '%s\n' "$(cat "$AR")" | strip_markup /dev/stdin \
             | grep -oE '(RULE|ADR|BR|CHG|CON)-[0-9]+' | sort -u); do
    id_exists "$x" "$ROOT" && ok "$x is real (architecture.md)" \
      || bad "architecture.md quotes $x but there is no heading/directory for it"
  done

  # ## Forbidden: a line that NAMES A SOURCE must carry the verbatim text. A WARNING only — a
  # missing quotation is a habit not yet formed, not a broken artifact; making it red means
  # reporting red on a file that is correct.
  #
  # Why it is worth saying (a real case at runxops): a line in ## Forbidden read "no automation
  # running INSIDE a Multilogin session — BR-001 Out of Scope", while BR-001 forbade running
  # OUTSIDE the session and In Scope EXPLICITLY ALLOWED running inside. It both reversed the
  # meaning of a prohibition and attached a source that did not say it — and it read smoothly.
  # No check caught it because no check reads two sources at once. What exposes it is the act of
  # QUOTING VERBATIM.
  CAM="$(printf '%s\n' "$(cat "$AR")" | strip_markup /dev/stdin \
         | awk -v re="$(kwh forbidden)" '$0 ~ re {f=1;next} f&&/^## /{exit} f{print}')"
  NOQ="$(printf '%s\n' "$CAM" | grep -nE '(RULE|ADR|BR|CHG|CON)-[0-9]+' \
         | grep -vE "$(kw verbatim)" | head -5)"
  if [ -n "$NOQ" ]; then
    warn "## Forbidden: a line names a source without quoting it verbatim — it cannot be checked back against the source:"
    printf '%s\n' "$NOQ" | sed 's/^/      /'
    info "add 'verbatim: \"<the exact words>\"'. A prohibition copied with the wrong meaning still reads perfectly smoothly."
  fi
fi

# ── 2. the UC design.md ───────────────────────────────────────────────────
step "⑪ /sdd-solo:design $ID — the design.md sections"
if [ ! -f "$DS" ]; then
  bad "missing $ID/design.md — run /sdd-solo:design $ID"
else
  ok "has a design.md"
  DMISS=""
  for k in summary techcontext vsarch vsbrief codestruct risks; do
    grep -qE "$(kwh "$k")" "$DS" || DMISS="$DMISS '## $(kw_w "$k")'"
  done
  if [ -n "$DMISS" ]; then bad "design.md is missing sections:$DMISS"
  else ok "design.md has every required section"; fi

  # The two check-back sections may NOT be empty. An empty heading looks exactly like a check that
  # was carried out and found nothing — and those two are entirely different things.
  for k in vsarch vsbrief; do
    HRE="$(kwh "$k")"; sec="## $(kw_w "$k")"
    if grep -qE "$HRE" "$DS"; then
      BODY="$(awk -v re="$HRE" '$0 ~ re {f=1;next} f&&/^## /{exit} f{print}' "$DS" \
              | grep -vE '^[[:space:]]*$' | grep -vE '^[[:space:]]*<!--')"
      if [ -z "$BODY" ]; then
        bad "$sec is empty — an empty section and 'checked, it matches' look identical"
      elif printf '%s\n' "$BODY" | strip_markup | grep -qE '<[^>]+>'; then
        bad "$sec still has a <...> placeholder"
      else
        ok "$sec has content"
      fi
    fi
  done

  # Every ID design.md quotes must be real. The same rule as §4/§7 of gate-check (#12, #16).
  for x in $(grep -oE '(RULE|ADR|BR|CHG)-[0-9]+' "$DS" | sort -u); do
    id_exists "$x" "$ROOT" && ok "$x is real" \
      || bad "design.md quotes $x but there is no heading/directory for it"
  done
fi

# ── 3. tasks.md — one task per AC ─────────────────────────────────────────
step "⑪ /sdd-solo:design $ID — tasks.md: one task per AC"
if [ ! -f "$TK" ]; then
  bad "missing $ID/tasks.md — every AC must have a task and a test file"
else
  ok "has a tasks.md"
  ACS="$(grep -oE '^### AC-[0-9]+' "$F" | awk '{print $2}' | sort -u)"
  if [ -z "$ACS" ]; then
    warn "the UC has no AC yet — tasks.md has nothing to be checked against"
  else
    LACK=""
    for ac in $ACS; do
      grep -qE "(^|[^A-Za-z0-9-])$ac([^0-9]|$)" "$TK" || LACK="$LACK $ac"
    done
    if [ -n "$LACK" ]; then bad "tasks.md has no task for:$LACK"
    else ok "every AC ($(printf '%s' "$ACS" | wc -w | tr -d ' ')) has a task in tasks.md"; fi
    # The reverse direction: an AC invented in tasks.md. The #12/#15 lesson — a label that is not real
    # passes every gate if nobody checks the other way.
    FAKE=""
    for ac in $(grep -oE 'AC-[0-9]+' "$TK" | sort -u); do
      printf '%s\n' $ACS | grep -qxF "$ac" || FAKE="$FAKE $ac"
    done
    [ -n "$FAKE" ] && bad "tasks.md mentions$FAKE but the UC has no such AC"
  fi
  grep -q "tests/use-cases/$CTX/$ID/" "$TK" \
    || warn "tasks.md does not give a test path following the convention tests/use-cases/$CTX/$ID/"
fi

# ── 4. the UC implementation assumption vs architecture.md — A WARNING ────
# A machine cannot read meaning, so this is only a reminder to compare by eye. Making it red would
# promise a check that cannot be done — the same "falsely green" bug with the sign flipped.
GD="$(grep -E "^$(kwl implassum)" "$F" | head -1)"
if [ -n "$GD" ] && [ -f "$AR" ]; then
  info "compare by eye: $GD"
  info "  against ## Stack / ## Runs where / ## Callers of architecture.md — a machine cannot read meaning"
  info "  everything $ID quotes on one screen: .sdd/scripts/context.sh $ID --why"
fi

echo
if [ "$FAIL" -eq 0 ]; then echo "DESIGN COMPLETE — you can write code ($WARN warnings)."; exit 0; fi
echo "NOT COMPLETE — $FAIL errors, $WARN warnings."; echo; nexts; exit 1
