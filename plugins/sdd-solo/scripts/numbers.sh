#!/usr/bin/env bash
# numbers.sh [--uc UC-###] [--rules-only] — gather every blank the owner still owes a number for (8.0.0).
#
# Why this exists. The rule "never invent a figure" (5.0.0) makes every template leave `___` where a number
# is not known yet, and the gate blocks on a `___` in the UC body. Both are right. What they produce together,
# measured on the runxops copy, is 588 blanks spread over 34 files — and the owner meets them ONE AT A TIME,
# each in the middle of a gate run, each as an interruption to something else. At that moment the cheapest
# way forward is always the same: put a plausible number in. That is exactly the failure the no-inventing
# rule exists to prevent, arrived at by obeying it.
#
# So this prints all of them at once, grouped, with the thing that turns a list into a work order: WHO IS
# BLOCKED. A `___` in a RULE parameter is not one blank, it is every UC that quotes that RULE — and the owner
# deciding in that knowledge decides differently from the owner squinting at one table cell.
#
# It classifies by STRUCTURE, never by heading text, so it reads a Vietnamese and an English spec alike:
#   · a table row with a `___`                → a parameter; the name is the first backticked cell
#   · a `- [ ]` / `- [x]` line with a `___`   → an open question with no interim decision
#   · anything else                           → a prose blank
# The evidence trail (## Adversarial pass · ## Re-read · ## History · ## Evidence) and every *.trace.md are
# skipped: a `___` in a finding is the record of a question asked, not a number anyone owes.
#
# READ-ONLY. It changes nothing and commits nothing. Exit 0 always — this is a worklist, not a gate.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
ONLY=""; RULES=0
PREV=""
for a in "$@"; do
  case "$PREV" in --uc) ONLY="$a"; PREV=""; continue;; esac
  case "$a" in --uc) PREV="$a";; --rules-only) RULES=1;; UC-[0-9]*) ONLY="$a";; esac
done

# ── the files to sweep ───────────────────────────────────────────────────
if [ -n "$ONLY" ]; then
  UF="$(find_uc "$ONLY" "$ROOT")"
  [ -n "$UF" ] || { bad "no $ONLY in specs/"; exit 0; }
  # a UC is blocked by its own blanks AND by the blanks of every rule/ADR it quotes
  LIST="$UF $(rules_files "$ROOT") $(ls "$ROOT"/specs/adr/*.md "$ROOT"/specs/*/adr/*.md 2>/dev/null)"
else
  LIST="$(find "$ROOT/specs" -name '*.md' -not -name '*.trace.md' 2>/dev/null | sort)"
fi

# ── which UC quotes which RULE/ADR — computed once, this is the expensive part ──
UCF="$(all_uc_files "$ROOT")"
blocked_by() { # blocked_by <ID> → the UC IDs whose file mentions that ID
  _b=""
  for u in $UCF; do
    grep -qw "$1" "$u" 2>/dev/null && _b="$_b $(basename "${u%.md}")"
  done
  printf '%s' "${_b# }"
}

TOTAL=0; NPAR=0; NQ=0; NP=0; OUT=""
for f in $LIST; do
  [ -f "$f" ] || continue
  # drop the trail and the fenced blocks; keep the line numbers by printing a blank in their place
  B="$(awk -v TR="$(kwh trace)" '
    $0 ~ TR { t=1; print ""; next }
    /^## / { t=0 }
    /^```/ { c=!c; print ""; next }
    (t || c) { print ""; next }
    { print }' "$f")"
  printf '%s' "$B" | grep -q '___' || continue
  FOUT=""; SEC=""
  N=0
  while IFS= read -r ln; do
    N=$((N+1))
    case "$ln" in "## "*) SEC="$(printf '%s' "$ln" | grep -oE '(RULE|ADR)-[0-9]+' | head -1)";; esac
    case "$ln" in *___*) : ;; *) continue;; esac
    TOTAL=$((TOTAL+1))
    # a `param` is not "a blank in a table" — it is a blank standing ALONE IN ITS OWN CELL, which is what a
    # parameter table looks like (`| \`Extension.minGapBetweenRuns\` | \`___\` | how long … |`). A table whose
    # prose merely contains a `___` is prose; calling it a parameter buried the 94 real ones among 300 rows on
    # the first run of this script. Test it by cell, not by line.
    KIND=prose; NAME=""
    case "$ln" in
      \|*\|*)
        printf '%s' "$ln" | awk -F'|' '{for(i=2;i<=NF;i++){c=$i; gsub(/[`*_ \t]/,"",c); if(c==""&&$i ~ /_/) {print "y"; exit}}}' | grep -q y \
          && { KIND=param; NAME="$(printf '%s' "$ln" | awk -F'|' '{print $2}' | grep -oE '`[^`]+`' | head -1 | tr -d '`')"; }
        [ "$KIND" = param ] && [ -z "$NAME" ] && NAME="$(printf '%s' "$ln" | awk -F'|' '{print $2}' | sed 's/^[ *]*//;s/[ *]*$//' | cut -c1-24)";;
      -\ \[*) KIND=question;;
    esac
    case "$KIND" in param) NPAR=$((NPAR+1));; question) NQ=$((NQ+1));; *) NP=$((NP+1));; esac
    # who is waiting: the enclosing RULE/ADR section, or failing that an ID named on the line itself.
    WHO=""; REF="$SEC"
    [ -z "$REF" ] && REF="$(printf '%s' "$ln" | grep -oE '(RULE|ADR)-[0-9]+' | head -1)"
    [ -n "$REF" ] && WHO="$(blocked_by "$REF")"
    [ "$RULES" = 1 ] && [ "$KIND" != param ] && continue
    TXT="$(printf '%s' "$ln" | sed 's/^[-|# ]*//' | cut -c1-96)"
    FOUT="$FOUT$(printf '  %-5s %-8s %-28s %s\n' "$N" "$KIND" "${REF:+$REF }${NAME}" "$TXT")
"
    [ -n "$WHO" ] && FOUT="$FOUT$(printf '        %s\n' "blocks: $WHO")
"
  done <<EOF
$B
EOF
  [ -n "$FOUT" ] && OUT="$OUT
${f#$ROOT/}
$FOUT"
done

printf '=== Numbers still owed%s — %s blank(s): %s in tables, %s in open questions, %s in prose ===\n' \
  "${ONLY:+ for $ONLY}" "$TOTAL" "$NPAR" "$NQ" "$NP"
if [ "$TOTAL" = 0 ]; then ok "nothing is blank — every figure in the spec has been decided"; exit 0; fi
printf '%s\n' "$OUT"
info "answer them in one sitting: a table blank is a parameter the rule cannot be enforced without, and the"
info "'blocks:' line says which UCs are waiting on it. A blank nobody blocks is a candidate for deletion."
info "What you must NOT do is fill one in to get past a gate — that is the one thing the blank is here to stop."
exit 0
