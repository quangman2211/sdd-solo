#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"; ROOT="$(project_root)"
echo "=== STATE.md ==="; cat "$ROOT/STATE.md" 2>/dev/null || echo "(not there yet)"
# Phase 1: what the BR holds, and whether something is being built on unwritten ground
echo; echo "=== BR (Phase 1) ==="
BRS="$(br_ids "$ROOT")"
if [ -z "$BRS" ]; then
  warn "there is no BR yet — run /sdd-solo:intake"
else
  for b in $BRS; do
    [ "$b" = "BR-000" ] && { printf '  %-9s %s\n' "$b" "(the template sample)"; continue; }
    # An untouched skeleton printing "draft" looks exactly like a real BR half written.
    if br_title "$b" "$ROOT" | grep -qE "^# $b: *<"; then
      printf '  %-9s %s\n' "$b" "(empty skeleton — /sdd-solo:intake)"; continue
    fi
    st="$(br_body "$b" "$ROOT" | sed -n 's/.*\*\*Status:\*\* *//p' | head -1 | awk '{print $1}')"
    printf '  %-9s %s\n' "$b" "${st:-?}"
  done
fi
UCN="$(all_uc_files "$ROOT" | wc -l | tr -d ' ')"
if br_untouched "$ROOT"; then
  # (d) of #18 — building on unwritten ground is the most expensive kind of wrong, because it is at the root
  if [ "$UCN" -gt 0 ]; then
    bad "br.md is still the template while $UCN UCs already exist — you are building on unwritten ground. Run /sdd-solo:intake."
  else
    info "br.md is still a template — start with /sdd-solo:intake"
  fi
  # (e) of #19 — AIUP jumps straight to "what the system does", skipping the "why" layer
  [ -f "$ROOT/docs/requirements.md" ] && \
    warn "there is an AIUP docs/requirements.md while the BR is missing — /requirements went around the BR layer. Run /sdd-solo:intake first."
fi

echo; echo "=== UC theo status ==="
# UC files only: skipping .flow.md · .sequence.md · .trace.md (5.0.0 generates a trace after close) — before
# 6.1.0 the lines 'UC-###.flow ?' and 'UC-###.trace ?' were printed in the list like two UCs with no status.
for f in $(all_uc_files "$ROOT"); do
  id="$(basename "$f" .md)"; st="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$f" | head -1 | awk '{print $2}')"
  g=""; [ -f "$ROOT/.sdd/gate/$id.ok" ] && g=" · gate ✓"
  printf '  %-8s %-12s%s\n' "$id" "${st:-?}" "$g"
  # #45: a dropped UC whose marker is still there → the githook still allows feat($id). Real case runxops UC-009/UC-012.
  [ "$st" = "deprecated" ] && [ -f "$ROOT/.sdd/gate/$id.ok" ] && \
    warn "$id is deprecated but .sdd/gate/$id.ok is still there — the githook still allows a code commit tagged $id. Remove it: /sdd-solo:deprecate $id (or git rm .sdd/gate/$id.ok)"
  # #44: the context use-cases.md table must say the same status — /sdd-solo:state suggests the next UC
  # from the table, so a table out of step suggests the wrong thing. No table/row → only a note.
  ts="$(uc_table_status "$id" "$ROOT")"
  if [ -n "$ts" ] && [ "$ts" != "$st" ]; then
    warn "$id: the UC file says '$st' but the UC table ($(uc_table_file "$id" "$ROOT" | sed "s#$ROOT/##")) says '$ts' — fix the table to match (pass.sh gate/close fixes it automatically since 6.1.0)"
  elif [ -z "$ts" ] && [ -f "$(uc_table_file "$id" "$ROOT")" ]; then
    info "$id has no row in the UC table ($(uc_table_file "$id" "$ROOT" | sed "s#$ROOT/##"))"
  fi
done
# Phase 5: which changes are open, and whether they passed the gate
CD="$(ls -d "$ROOT/specs/changes/CHG-"* "$ROOT/changes/CHG-"* 2>/dev/null)"
if [ -n "$CD" ]; then
  echo; echo "=== Open changes (Phase 5) ==="
  for d in $CD; do
    id="$(basename "$d" | grep -oE '^CHG-[0-9]+')"
    st="$(awk 'index($0,"## Status")==1{f=1;next} f&&/^## /{exit} f&&NF{print;exit}' "$d/proposal.md" 2>/dev/null | tr -d "[:space:]")"
    g=""; [ -f "$ROOT/.sdd/gate/$id.ok" ] && g=" · gate ✓"
    printf '  %-9s %-12s%s\n' "$id" "${st:-?}" "$g"
  done
fi
echo; "$HERE/metrics.sh"
# dependencies: only speak when something is missing, stay silent when it is fine
D="$("$HERE/deps-check.sh" 2>&1)" || { echo; echo "$D"; }
# the code/test paths: getting them wrong makes the githook miss silently
UCT_="$(uc_test_dir "$ROOT")"
# TWO DIFFERENT worries, and they must be asked separately. Up to 3.4.2 this was one OR `if` whose body did
# not re-check which side had been true, so `code_paths` was accused of "no directory exists" even when
# has_code_path was TRUE — only because the uc_test_dir side was broken (#26). That is the DEFAULT state of
# every freshly scaffolded repo: `src/README.md` ships, so has_code_path is true from day one, while
# `tests/use-cases/` only appears with the first implemented UC. That false red told people to go and fix a
# file that was correct — and once fixed, the githook really did start missing things, so it created exactly
# what it warned about.
CP_OK=0; has_code_path "$ROOT" || CP_OK=1
UT_OK=0; [ -d "$ROOT/$UCT_" ] || UT_OK=1
# uc_test_dir being absent in Phase 1–2 is NORMAL: with no AC implemented there is no test to put there.
# Only mention it once an implemented UC exists while the directory is still missing.
UT_SAY=0
if [ "$UT_OK" = 1 ] && all_uc_files "$ROOT" | xargs grep -lE '\*\*Status:\*\* *implemented' >/dev/null 2>&1; then
  UT_SAY=1
fi
if [ "$CP_OK" = 1 ] || [ "$UT_SAY" = 1 ]; then
  echo; echo "=== .sdd/config ==="
  if [ "$CP_OK" = 1 ]; then
    if repo_has_code "$ROOT"; then
      bad "code_paths=$(code_paths "$ROOT") — no directory exists, while the repo already has source files."
      info "the githook is missing things. Fix .sdd/config to match the real layout."
    else
      # "no code yet" is no longer true once the repo has declared tool_paths: it HAS code,
      # only tool code belonging to no UC (#33).
      if [ -n "$(tool_paths "$ROOT")" ]; then
        warn "code_paths=$(code_paths "$ROOT") — no directory exists yet (the repo has no product code; the tool code is declared in tool_paths)."
      else
        warn "code_paths=$(code_paths "$ROOT") — no directory exists yet (the repo has no code)."
      fi
    fi
  fi
  # Keep repeating it while it does not match: a `!` at init time is easy to miss from the second --update
  # onwards, when people skim the output.
  if [ "$UT_SAY" = 1 ]; then
    warn "uc_test_dir=$UCT_ — an implemented UC exists while the directory does not, so ac-coverage is blind. Fix it to match this repo convention."
  fi
fi
# The steps a UC in progress has gone through — A LISTING, not a block (#29). Every other check measures the
# PRODUCT; none measures the STEP, so a step skipped entirely still goes the whole way round with nobody
# knowing. The ID comes from the "Working on:" / "Đang làm:" line of STATE.md.
UCNOW="$(grep -oE 'UC-[0-9]+' "$ROOT/STATE.md" 2>/dev/null | head -1)"
if [ -n "$UCNOW" ]; then
  FN="$(find_uc "$UCNOW" "$ROOT")"
  [ -n "$FN" ] && grep -qE '\*\*Status:\*\* *deprecated' "$FN" && \
    warn "STATE.md says $UCNOW is in progress but that UC is deprecated — point STATE at the replacement UC (/sdd-solo:state)"
fi
# An older .sdd/scripts/ copy has no uc-steps.sh — stay quiet, do not break the whole status over one extra section.
if [ -n "$UCNOW" ] && [ -f "$HERE/uc-steps.sh" ]; then echo; bash "$HERE/uc-steps.sh" "$UCNOW"; fi

# 7.3 — the agent team: only speak when the repo has the ledgers. The two delegation checks run here, NOT at the DoR gate
# or in a githook: a gate measures requirement quality, not coordination. (1) every STOP-<name> in the queue must be a name
# declared in ## Stop points; (2) a Ledger row pointing at #n or at decisions means specs/decisions.md must hold a matching
# line — otherwise A decides and the decision is invisible to every later session (measured at runxops: 90 Ledger rows, 81 empty Approve cells).
UY="$ROOT/notes/uy-quyen.md"; HQ="$ROOT/notes/hang-doi.md"
if [ -f "$UY" ] || [ -f "$HQ" ]; then
  echo; echo "=== Agent team (7.3) ==="
  if [ -f "$HQ" ]; then
    for nm in $(grep -oE "\| *($(kw stop))-[^ |]+" "$HQ" | sed -E "s/.*($(kw stop))-//" | sort -u); do
      if [ -f "$UY" ] && grep -qE "^\| *$nm *\|" "$UY"; then ok "STOP-$nm is declared in uy-quyen.md"
      else bad "the queue holds STOP-$nm but notes/uy-quyen.md ## Stop points does not declare that name"; fi
    done
    NX="$(bash "$HERE/queue.sh" board 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'empty Anchor|suspected-dead' | head -5)"
    [ -n "$NX" ] && printf '%s\n' "$NX" | sed 's/^ *//' | while IFS= read -r l; do warn "$l"; done
  fi
  if [ -f "$UY" ]; then
    DEC="$(decisions_file "$ROOT")"
    grep -E '^\| *[0-9]{4}-[0-9]{2}-[0-9]{2} *\|' "$UY" | while IFS= read -r row; do
      ref="$(printf '%s' "$row" | awk -F'|' '{print $6}')"
      for n in $(printf '%s' "$ref" | grep -oE '#[0-9]+'); do
        grep -qF -- "$n" "$DEC" 2>/dev/null || warn "the delegation ledger points at ticket $n but $(basename "$DEC") has no line mentioning $n — the decision is invisible to a later session"
      done
      printf '%s' "$ref" | grep -qi decisions && ! printf '%s' "$ref" | grep -qE '#[0-9]+' && {
        d="$(printf '%s' "$row" | awk -F'|' '{print $2}' | tr -d ' ')"
        grep -qE "^- *$d" "$DEC" 2>/dev/null || warn "the delegation ledger dated $d says 'decisions' but $(basename "$DEC") has no line with that date"; }
    done
    grep -qE "^($(kw ph_owner))" "$UY" && info "uy-quyen.md ## Scope is still the template — the coordinator decides NO L3 question until the owner writes it"
  fi
  for hf in "$ROOT"/notes/hoi-dap/hoi-[A-Z]*.md; do [ -f "$hf" ] && bash "$HERE/hoi-check.sh" "$hf" 2>&1 | grep -E '✗|!' | head -3; done
fi

# version: asks GitHub for at most 3s, remembers for 24h. Only speaks when there is a mismatch.
V="$("$HERE/version-check.sh" --remote 2>&1)" || { echo; echo "$V"; }
