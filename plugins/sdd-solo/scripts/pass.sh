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
  gate|close|change|deprecate) ;;
  *) echo "Usage: pass.sh <gate|close|change|deprecate> <ID>" >&2; exit 2;;
esac
[ -z "$ID" ] && { echo "Usage: pass.sh $MODE <ID>" >&2; exit 2; }
ROOT="$(project_root)"

# the marker + the marker commit — shared by gate and change
mark() {
  mkdir -p "$ROOT/.sdd/gate"
  git -C "$ROOT" rev-parse HEAD > "$ROOT/.sdd/gate/$1.ok"
  git -C "$ROOT" add ".sdd/gate/$1.ok" \
    && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $1" -- ".sdd/gate/$1.ok" || true
}

case "$MODE" in

gate)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  sed -i.bak -E 's/(\*\*Status:\*\* *)draft/\1reviewed/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  # #44: the context use-cases.md table says the same status, in the same commit.
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" reviewed "$ROOT"; then TF="$T"; else
    printf '  ! the table %s has no row for %s — add one so /sdd-solo:state suggests the right next UC\n' "${T#$ROOT/}" "$ID"; fi
  git -C "$ROOT" commit -q --only -m "docs($ID): spec reviewed — $(kw_w c_dor "$ROOT")" -- "$F" $TF || true
  mark "$ID"
  printf 'THROUGH THE GATE. Status -> reviewed · marker .sdd/gate/%s.ok · committed.\n' "$ID"
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
  git -C "$ROOT" commit -q --only -m "docs($ID): implemented — traceability" -- "$F" "$TR" $TF $( [ -f "$TRACE" ] && printf '%s' "$TRACE" ) || true
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
