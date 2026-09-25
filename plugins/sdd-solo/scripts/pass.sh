#!/usr/bin/env bash
# pass.sh <gate|close|change> <ID> — run AFTER the matching check exits 0.
#
# Folded in from gate-pass.sh + close-pass.sh + change-pass.sh (4.0.0). The three old scripts had
# the same shape: change the Status, write the trace, commit separately. KEEP every word of the
# commit messages and every printed line — the githooks and `gate-check` §9 recognise a commit by
# its subject, so changing one character here opens a silent hole somewhere else.
#
# Why the mode is explicit instead of inferred from the ID prefix: `UC-###` goes through TWO different
# passes (⑨ gate and ⑭ close). The prefix cannot tell those apart, and a script guessing wrong between
# "reviewed" and "implemented" breaks silently.
set -e
MODE="${1:-}"; ID="${2:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
case "$MODE" in
  gate|close|change|deprecate|restore) ;;
  *) echo "Usage: pass.sh <gate|close|change|deprecate|restore> <ID>" >&2; exit 2;;
esac
[ -z "$ID" ] && { echo "Usage: pass.sh $MODE <ID>" >&2; exit 2; }
ROOT="$(project_root)"

# 8.4.0 (P-52) - pass.sh VERIFIES. Up to 8.3.0 the header above said "run AFTER the matching check exits 0" and that
# was the whole guarantee: nothing here called gate-check, close-check or change-check, so `pass.sh gate UC-###`
# stamped .sdd/gate/UC-###.ok on a UC with no Acceptance Criteria at all - and the commit-msg hook then trusted that
# marker to let `feat(UC-###)` through. What kept the marker honest was the SKILL TEXT a person read, not the person.
# So the rule "only the owner may type it" bought no check; measured at runxops on 2026-09-24 it bought a 5-hour wait
# (03:30 to 08:50) on a UC that was already green. This is the same reasoning that removed the overnight door at 6.0.0:
# a night measures time passing, a keystroke measures presence, and neither measures whether anything was checked.
#
# There is no flag and no environment escape, exactly as for gate-check itself. `deprecate` is deliberately exempt:
# dropping a UC must not require it to be green - being not-green is often the reason it is being dropped.
CHK=""
case "$MODE" in gate) CHK=gate-check.sh;; close) CHK=close-check.sh;; change) CHK=change-check.sh;; esac
if [ -n "$CHK" ]; then
  CO="$(bash "$HERE/$CHK" "$ID" 2>&1)" && CR=0 || CR=$?
  if [ "$CR" != 0 ]; then
    printf %s\\n "$CO" | grep -E "^ *.\[31m" || printf %s\\n "$CO" | tail -20
    bad "$CHK $ID is not green - pass.sh does not stamp a pass it has not seen happen (8.4.0)"
    info "fix every mark above, then run it in full yourself: bash .sdd/scripts/$CHK $ID"
    exit 1
  fi
  ok "$CHK $ID verified here: green"
fi

# Who may SIGN. Opt-in in both directions (lib: role_sign_declared): a repo with no `<V>.ky` line anywhere behaves
# exactly as before, marker or no marker, so a solo project and every repo running today change by nothing. Once one
# `.ky` line exists, a session whose role CAN be inferred must list this pass. A session with no role inferred is
# still allowed - that is the owner in an unmarked checkout, and the plugin cannot tell a person from an agent.
SIGNED_BY=""
case "$MODE" in
  gate|close)
    if role_sign_declared "$ROOT"; then
      SV="$(role_current "$ROOT")"
      if [ -n "$SV" ]; then
        SOK=0; for m in $(role_sign "$SV" "$ROOT"); do [ "$m" = "$MODE" ] && SOK=1; done
        if [ "$SOK" = 0 ]; then
          bad "role $SV may not sign $MODE: .sdd/roles has no \"$SV.ky\" listing it"
          info "this repo has declared signing authority (a <role>.ky line exists), so a session with a known role signs only what it is given"
          info "the owner grants it in .sdd/roles - never the agent itself; record it in notes/uy-quyen.md and specs/decisions.md too"
          exit 1
        fi
        SIGNED_BY="$SV"
      fi
    fi
    ;;
esac

# the marker + the marker commit — shared by gate and change
mark() {
  mkdir -p "$ROOT/.sdd/gate"
  # LINE 1 STAYS EXACTLY THE COMMIT HASH - and since 8.8.0 it is READ: `gate_commit` in lib.sh takes the anchor
  # from here, so a line 1 that is not a bare hash silently sends every "has the spec moved since the gate" check
  # back to grepping commit subjects. A second line is a record, not a field: six months on,
  # "who signed this" is the question nobody can answer from a bare hash.
  git -C "$ROOT" rev-parse HEAD > "$ROOT/.sdd/gate/$1.ok"
  [ -n "$SIGNED_BY" ] && printf 'signed-by: %s (.sdd/roles %s.ky) %s\n' "$SIGNED_BY" "$SIGNED_BY" "$(today)" >> "$ROOT/.sdd/gate/$1.ok"
  git -C "$ROOT" add ".sdd/gate/$1.ok" \
    && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $1" -- ".sdd/gate/$1.ok" || true
}

case "$MODE" in

restore)
  # 8.7.0 (P-61): a UC that was dropped and then brought back. `pass.sh deprecate` removes .sdd/gate/<UC>.ok -
  # correctly, a dropped UC holds no gate - but nothing ever put it back, and both doors that need it are shut:
  # gate-check calls an `implemented` status red, so `pass.sh gate` can never run, and change-check goes red with
  # "implemented but there is no .sdd/gate/<UC>.ok". Measured at runxops on 2026-09-25 (UC-012 back from
  # deprecated at v14, CHG-007): the only way out was digging the old blob out of git by hand (37978d72).
  #
  # This does NOT write a new pass, and that is the whole design. It RECOVERS one git still has and refuses when
  # git has none - the same rule as everywhere else here (8.4.0: no stamping a pass it has not seen happen), just
  # pointed at the history instead of at a check. Line 1 stays the ORIGINAL gate commit hash, so every reader that
  # follows the marker back still lands on the commit where the gate actually happened, not on today.
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  MK="$ROOT/.sdd/gate/$ID.ok"
  [ -f "$MK" ] && { bad "$ID already has .sdd/gate/$ID.ok - there is nothing to restore"; exit 1; }
  ST="$(sed -n 's/.*\*\*Status:\*\* *//p' "$F" | head -1 | awk '{print $1}')"
  case "$ST" in
    implemented|applying) ;;
    draft|reviewed) bad "$ID is '$ST' - a UC that has not been through the gate gets its marker FROM the gate, not from here"
                    info "bash .sdd/scripts/pass.sh gate $ID"; exit 1;;
    deprecated) bad "$ID is deprecated - a dropped UC holds no gate marker. Bring it back first (Status + a ## History entry saying why), then run this"; exit 1;;
    *) bad "$ID has an unreadable status: '$ST'"; exit 1;;
  esac
  C="$(git -C "$ROOT" rev-list -1 HEAD -- ".sdd/gate/$ID.ok" 2>/dev/null)"
  OLD=""; SRC=""
  if [ -n "$C" ]; then
    if OLD="$(git -C "$ROOT" show "$C:.sdd/gate/$ID.ok" 2>/dev/null)" && [ -n "$OLD" ]; then SRC="$C"
    elif OLD="$(git -C "$ROOT" show "$C^:.sdd/gate/$ID.ok" 2>/dev/null)" && [ -n "$OLD" ]; then SRC="$(git -C "$ROOT" rev-parse "$C^")"; fi
  fi
  if [ -z "$OLD" ]; then
    bad "this branch history holds no .sdd/gate/$ID.ok - there is no pass to recover, and this does not invent one"
    info "if $ID really did go through the gate, that commit is on another branch: fetch or merge it, then run this again"
    info "if it never did, then it is not implemented either - fix the Status and take it through /sdd-solo:gate"
    exit 1
  fi
  GH="$(printf '%s' "$OLD" | head -1)"
  RV=""; if role_sign_declared "$ROOT"; then RV="$(role_current "$ROOT")"; fi
  mkdir -p "$ROOT/.sdd/gate"
  printf '%s\n' "$OLD" > "$MK"
  printf 'restored: %s from %s%s\n' "$(today)" "$SRC" "${RV:+ by $RV}" >> "$MK"
  git -C "$ROOT" add ".sdd/gate/$ID.ok" \
    && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $ID restored from $SRC" -- ".sdd/gate/$ID.ok" || true
  ok "marker .sdd/gate/$ID.ok recovered from $SRC - gate commit $GH"
  # A recovered marker says a gate happened, not that it still fits. How far the spec has moved since is a fact
  # worth putting on the screen; it is NOT a new rule, so nothing here blocks on it.
  N="$(git -C "$ROOT" rev-list --count "$GH..HEAD" -- "$F" 2>/dev/null || printf 0)"
  case "$N" in ''|*[!0-9]*) N=0;; esac
  if [ "$N" -gt 0 ]; then
    warn "$N commit(s) have touched ${F#$ROOT/} since that gate - the marker is back, the baseline is as old as it says"
    info "if the spec has really moved, the honest route is Phase 5 (/sdd-solo:change $ID), not this marker"
  fi
  printf 'RESTORED %s. Marker back, status untouched (%s).\n' "$ID" "$ST"
  ;;

gate)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  sed -i.bak -E 's/(\*\*Status:\*\* *)draft/\1reviewed/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  # #44: the context use-cases.md table says the same status, in the same commit.
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" reviewed "$ROOT"; then TF="$T"; else
    printf '  ! the table %s has no row for %s — add one so /sdd-solo:state suggests the right next UC\n' "${T#$ROOT/}" "$ID"; fi
  # The SUBJECT is untouched on purpose: gate-check §9 and close-check find this commit by matching it.
  GC=1
  git -C "$ROOT" commit -q --only -m "docs($ID): spec reviewed — $(kw_w c_dor "$ROOT")" \
    ${SIGNED_BY:+-m "$(kw_w c_role "$ROOT"): $SIGNED_BY"} -- "$F" $TF >/dev/null 2>&1 || GC=0
  mark "$ID"
  if [ "$GC" = 1 ]; then
    printf 'THROUGH THE GATE. Status -> reviewed · marker .sdd/gate/%s.ok · committed.\n' "$ID"
  else
    # 8.8.0 (P-64): re-gating a UC that is already `reviewed` and dated today changes nothing in the file, so there
    # is nothing to commit. Up to 8.7.0 git's own "nothing to commit, working tree clean" leaked out here and the
    # script then printed "committed." anyway - a line that was simply false. What moves is the MARKER, and since
    # 8.8.0 that is the anchor gate_commit reads, so saying which commit it now points at is the whole record.
    printf 'THROUGH THE GATE AGAIN. The UC file was already reviewed and dated today: nothing to commit.\n'
    printf 'The marker moved - .sdd/gate/%s.ok now points at %s, and that is the anchor close-check compares against.\n' \
      "$ID" "$(head -1 "$ROOT/.sdd/gate/$ID.ok")"
  fi
  printf 'Next: /sdd-solo:design %s — design before the first line of code.\n' "$ID"
  ;;

close)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  CTX="$(owner_of "$F")"
  sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed)/\1implemented/' "$F" && rm -f "$F.bak"
  # 5.0.0 — the evidence trail leaves the file that is still in force. Measured at runxops: of the 56 KB of
  # UC-009.md, ## Adversarial pass was 11.0 + ## Re-read 11.3 + ## History 6.3 = 28.6 KB, and nobody reads
  # those three sections after the UC closes — they are the scratch paper of a solved problem.
  # In a team, a review record is evidence for a second person; working alone there is no second person.
  # But NOTHING IS DELETED: the body moves to UC-###.trace.md in the same directory (git keeps it, a dispute
  # reopens it), leaving ONE line in place with a machine-countable number.
  # Compressed at ⑭ and not at ⑨: while the UC is open, the F# lines are a work list and the gate reads them
  # by machine. Idempotent — a summary line already ending in "→ UC-###.trace.md" is not compressed again.
  TRACE="$(dirname "$F")/$ID.trace.md"
  need_node "pass.sh"
  node "$HERE/js/pass.mjs" trace "$F" "$TRACE" "$ID" "$(today)"
  BR="$(grep -oE 'BR-[0-9]+' "$F" | head -1)"
  RULES="$(grep -oE 'RULE-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  ADRS="$(grep -oE 'ADR-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  TR="$ROOT/specs/traceability.md"
  for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
    SCRS="$(sed -n '/^## Screens/,/^## /p' "$F" | grep -oE 'SCR-[0-9]+-[0-9]+' | sort -u | tr '\n' ' ')"
    echo "| $BR | $ID | AC-$n | $RULES | $SCRS | tests/use-cases/$CTX/$ID/AC-$n.test.* | $ADRS | implemented |" >> "$TR"
  done
  # #44: the use-cases.md table — real case runxops UC-014: the UC file said implemented, the table still said
  # draft, /sdd-solo:state suggested the wrong next UC and it had to be fixed by hand in its own commit (cfbead4).
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" implemented "$ROOT"; then TF="$T"; else
    printf '  ! the table %s has no row for %s — add one so /sdd-solo:state suggests the right next UC\n' "${T#$ROOT/}" "$ID"; fi
  [ -f "$TRACE" ] && git -C "$ROOT" add "$TRACE"
  git -C "$ROOT" commit -q --only -m "docs($ID): implemented — traceability" \
    ${SIGNED_BY:+-m "$(kw_w c_role "$ROOT"): $SIGNED_BY"} -- "$F" "$TR" $TF $( [ -f "$TRACE" ] && printf '%s' "$TRACE" ) || true
  echo "CLOSED $ID. Status → implemented${TF:+ (the UC file + the UC table)} · traceability +$(grep -cE '^### AC-' "$F") rows · committed."
  echo "Remember: update STATE.md (/sdd-solo:state) before you stop."
  ;;

deprecate)
  # #45: dropping a UC properly — five separate jobs (Status · History · the marker · the table · decisions) means
  # one of them always gets missed. Real case runxops: UC-009/UC-012 were deprecated by hand, the gate marker stayed
  # (so the githook still allowed feat(UC-009)), History/decisions were written by hand, STATE carried the debt for days.
  # 7.0.1 (#51): a UC with only a table row (planned then dropped, never a file) — the table + decisions still must be
  # fixed; up to 7.0.0 this branch exited 1 silently and the table kept saying draft forever.
  F="$(find_uc "$ID" "$ROOT")"
  if [ -z "$F" ] && [ -z "$(uc_table_file "$ID" "$ROOT")" ]; then
    printf '✗ %s has neither a UC file nor a row in any UC table — wrong ID?\n' "$ID" >&2; exit 1
  fi
  shift 2; BY="-"; REASON=""
  while [ $# -gt 0 ]; do case "$1" in --by) BY="${2:--}"; shift 2;; *) REASON="$REASON $1"; shift;; esac; done
  REASON="$(printf '%s' "$REASON" | sed 's/^ *//')"
  [ -z "$REASON" ] && { echo "Usage: pass.sh deprecate UC-### [--by UC-###] <reason>" >&2; exit 2; }
  case "$BY" in UC-[0-9]*|-) ;; *) echo "--by must be a UC-### or -" >&2; exit 2;; esac
  if [ -n "$F" ]; then
  sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed|implemented)/\1deprecated/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  need_node "pass.sh"
  node "$HERE/js/pass.mjs" deprecate "$F" "$(today)" "$REASON" "$BY"
  fi
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" deprecated "$ROOT"; then TF="$T"; else
    printf '  ! the table %s has no row for %s\n' "${T#$ROOT/}" "$ID"; fi
  MK="$ROOT/.sdd/gate/$ID.ok"; MKF=""
  if [ -f "$MK" ]; then
    git -C "$ROOT" rm -q --cached ".sdd/gate/$ID.ok" 2>/dev/null || true
    rm -f "$MK"; MKF=".sdd/gate/$ID.ok"
  fi
  DEC="$(decisions_file "$ROOT")"; DF=""
  # If a "Dropped UC-###" line already exists (a second deprecate, or an earlier hand-written one), do not add a duplicate.
  if [ -f "$DEC" ] && ! grep -qE -- "($(kw dropped)) $ID \(" "$DEC"; then
    printf -- '- %s — %s %s (%s). Kind: keep %s. Details: %s\n' "$(today)" "$(kw_w dropped "$ROOT")" "$ID" "$REASON" "$ID" "$( [ "$BY" = "-" ] && kw_w noreplacement "$ROOT" || printf '%s' "$BY" )" >> "$DEC"
    DF="$DEC"
  fi
  git -C "$ROOT" commit -q --only -m "docs($ID): deprecated — $REASON" -- $F $TF $DF $MKF || true
  [ -z "$F" ] && printf '%s has no UC file — only the UC table and decisions.md were edited, there is no History/Status to write.\n' "$ID"
  printf 'DROPPED %s. Status -> deprecated · History v+1 · gate marker %s · UC table %s · decisions.md %s · committed.\n' \
    "$ID" "$( [ -n "$MKF" ] && printf 'removed' || printf 'none' )" "$( [ -n "$TF" ] && printf 'fixed' || printf 'no row' )" "$( [ -n "$DF" ] && printf '+1 row' || printf 'no file' )"
  [ "$BY" != "-" ] && printf 'Replaced by %s — if its directory does not exist yet, /sdd-solo:start %s.\n' "$BY" "$BY"
  BRP="$(grep -oE 'BR-[0-9]+' ${F:-/dev/null} | head -1)"; [ -z "$BRP" ] && [ -n "$TF" ] && BRP="$(grep -oE '^# BR-[0-9]+' "$TF" | head -1 | tr -d '# ')"; BRST="$(br_body "$BRP" "$ROOT" | sed -n 's/.*\*\*Status:\*\* *//p' | head -1 | awk '{print $1}')"
  if [ -n "$BRP" ] && [ "$BRST" != "deprecated" ]; then
    echo "Remember: if the ## Related Use Cases of $BRP and STATE.md still point at $ID, fix them by hand (/sdd-solo:state)."
  else
    echo "Remember: if STATE.md still points at $ID, update it (/sdd-solo:state)."
  fi
  ;;

change)
  D="$(find_chg "$ID" "$ROOT")"; [ -z "$D" ] && exit 1
  P="$D/proposal.md"
  need_node "pass.sh"
  node "$HERE/js/pass.mjs" change "$P" "$(today)"
  git -C "$ROOT" commit -q --only -m "docs($ID): change reviewed — $(kw_w c_p5 "$ROOT")" -- "$P" || true
  mark "$ID"
  printf 'THROUGH THE PHASE 5 GATE. Status -> applying · marker .sdd/gate/%s.ok · committed.\n' "$ID"
  echo "Next: write the tests for the new ACs (red first), then change the code. Commit the code tagged ($ID)."
  echo "When it is all done, merge the delta into specs/, History UC v+1, and chore($ID): archive."
  ;;

esac
