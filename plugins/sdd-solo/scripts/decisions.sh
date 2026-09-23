#!/usr/bin/env bash
# decisions.sh [--md] — a ledger of EVERY decision in the project, in time order.
#
# Why this file exists. The document set holds 7 kinds of decision in 6 places with 4 different
# shapes (a CON in br.md · a RULE in rules.md · an ADR in internal/adr/ · a Forbidden line in
# architecture.md · a CHG in changes/ · a one-sentence line in internal/decisions.md).
# Each shape read on its own makes sense; together, nobody can hold what this project has decided.
# That is a question that must be answerable after 5–10 years, not after one sprint.
#
# TIME ORDER is deliberate, not decoration. Real case (runxops): two prohibitions written at two
# different times, the later one stricter and swallowing something In Scope still allowed.
# Read file by file, both read smoothly. Put on one timeline, two lines saying the same thing with
# two different dates end up next to each other — the human eye catches at once what no mechanical
# check can catch.
#
# WRITES NO FILE (unless --md and the user redirects it themselves). A ledger that is generated and
# then committed is a copy that will drift from its source, and drifting is exactly the "falsely
# green" class the whole 3.x line went to fix. This ledger must always be read from the source, at reading time.
#
# 4.2.0: this script is READ-ONLY and always exits 0. It is not a gate. A hard gate
# (decision-check.sh) is for a later release, once you have looked at this table and filled it in —
# turning on a gate while dozens of lines still lack a date only teaches people to ignore it.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
MD=0; [ "${1:-}" = "--md" ] && MD=1
TODAY="$(today)"

REC="$(mktemp)"; trap 'rm -f "$REC"' EXIT

# One record per line, TAB separated:
#   date <TAB> ID <TAB> kind <TAB> statement <TAB> status <TAB> review on
# An empty date → "0000-00-00", so sort pushes it to the top and printing splits it into its own block.
TAB="$(printf '\t')"

FLD='
function fld(s, name,   i, rest, j) {
  i = index(s, name); if (i == 0) return ""
  rest = substr(s, i + length(name))
  j = index(rest, " · ")
  if (j > 0) rest = substr(rest, 1, j - 1)
  sub(/^[ \t]+/, "", rest); sub(/[ \t]+$/, "", rest)
  return rest
}
# fldk(): like fld but taking the alternation BODY from kw() (`Từ|From`) — it tries each side and takes
# whichever is present on the line. Thanks to it, a sub-cell written in English enters the ledger exactly like the Vietnamese one.
function fldk(s, k,   i, n, a, r) {
  n = split(k, a, "|")
  for (i = 1; i <= n; i++) { r = fld(s, a[i] ":"); if (r != "") return r }
  return ""
}
function nodate(d) { return (d ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) ? d : "0000-00-00" }
# ghost(): a line that is still a TEMPLATE, not a decision. Dropping it is mandatory, not tidiness —
# a ledger listing the teaching text of a template as "a decision of the project" is worse than no
# ledger, because it teaches the reader that this ledger cannot be trusted.
# A `<...>` only counts with its closing bracket, so "response < 200ms" is not falsely caught.
function ghost(s) {
  if (s == "") return 1
  if (s ~ /^[ \t]*(\.\.\.|_+)[ \t]*$/) return 1
  if (s ~ /<[^>]*>/) return 1
  return 0
}
'

# strip_markup BEFORE anything else. Every template has a <!-- … --> block teaching how to use it, and
# those blocks mention CON-002 / ADR-001 / BR-001 as examples. Without stripping, the ledger reads the
# teaching text as decisions. (The same trap design-check hit at 4.0.x.)

# ── CON-### : specs/br.md (6.x) · specs/*/br-###/br.md (7.0) ─────────────────
br_text "$ROOT" | strip_markup | awk -v T="$TAB" \
  -v SINCE="$(kw since)" -v STATE="$(kw state)" -v REVIEWON="$(kw reviewon)" "$FLD"'
function flush() { if (cur != "" && !ghost(stmt)) print d T cur T "constraint" T stmt T stt T rc; cur = "" }
# BR-000 is the template SAMPLE BR and it STAYS FOREVER: `/sdd-solo:intake` says outright "keep the
# BR-000 sample", and `br-check.sh:11` skips it for the same reason. Not skipping it here would put its
# three teaching CONs in the ledger of EVERY project, forever — and they are not placeholders, they
# read exactly like real decisions (hosting, accounting law).
# That is precisely "a ledger with ghost entries", the thing worse than no ledger. The same rule as in
# br-check, kept in two places because the two scripts do not share the br.md scanning loop.
/^# BR-/ { flush(); inbr0 = ($0 ~ /^# BR-000([^0-9]|$)/) ? 1 : 0; next }
/^- \*\*CON-[0-9]+/ {
  flush()
  if (inbr0) next
  match($0, /CON-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
  stmt = $0; sub(/^-[ ]*\*\*CON-[0-9]+[^:]*:\*\*[ ]*/, "", stmt)
  d = "0000-00-00"; stt = ""; rc = ""
  next
}
cur != "" && $0 ~ ("^[ \t]+- (" SINCE "):") {
  d = nodate(fldk($0, SINCE)); stt = fldk($0, STATE); rc = fldk($0, REVIEWON); next
}
END { flush() }
' >> "$REC"

# ── RULE-### : specs/rules.md + specs/<craft>/rules.md ───────────────────────
rules_text "$ROOT" | strip_markup | awk -v T="$TAB" \
  -v STMT="$(kw statement)" -v SINCE="$(kw since)" "$FLD"'
function flush() { if (cur != "" && !ghost(stmt)) print d T cur T "rule" T stmt T stt T ""; cur = "" }
/^## RULE-/ {
  flush()
  match($0, /RULE-[0-9a-z]+/); cur = substr($0, RSTART, RLENGTH)
  stmt = $0; sub(/^## RULE-[0-9a-z]+:[ ]*/, "", stmt)
  d = "0000-00-00"; stt = ""
  next
}
/^## / { flush(); next }
cur != "" && $0 ~ ("\\*\\*(" STMT "):\\*\\*")  { s = $0; sub("^.*\\*\\*(" STMT "):\\*\\*[ ]*", "", s);  if (!ghost(s)) stmt = s; next }
cur != "" && $0 ~ ("\\*\\*(" SINCE "):\\*\\*") { s = $0; sub("^.*\\*\\*(" SINCE "):\\*\\*[ ]*", "", s); d = nodate(s); next }
cur != "" && /\*\*Status:\*\*/    { s = $0; sub(/^.*\*\*Status:\*\*[ ]*/, "", s);    if (!ghost(s)) stt = s; next }
END { flush() }
' >> "$REC"

# ── ADR-### : specs/internal/adr/*.md ───────────────────────────────────────
# Skip a file starting with "_" — that is a template, not a decision. It was exactly because the
# template was once named ADR-000-template.md that `id_exists ADR-000` reported FALSELY GREEN in every
# freshly scaffolded repo, with nobody writing anything wrong. Renamed at 4.2.0.
for f in $(for d in $(adr_dirs "$ROOT"); do ls "$d"/*.md 2>/dev/null; done); do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in _*) continue;; esac
  strip_markup < "$f" | awk -v T="$TAB" "$FLD"'
  /^# ADR-/ && id == "" { match($0, /ADR-[0-9]+/); id = substr($0, RSTART, RLENGTH)
                          stmt = $0; sub(/^# ADR-[0-9]+:[ ]*/, "", stmt); next }
  /^## Status/ { inst = 1; next }
  inst && NF   { inst = 0; if (!ghost($0)) stt = $0
                 if (match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) d = substr($0, RSTART, RLENGTH)
                 next }
  END { if (id != "" && !ghost(stmt)) print nodate(d) T id T "ADR" T stmt T stt T "" }
  ' >> "$REC"
done

# ── Forbidden : specs/internal/architecture.md, section ## Forbidden ─────────
# The displayed ID is `CAM-N`, numbered BY ORDER OF APPEARANCE — deliberately not an identity.
# "A number is not an identity, it is a position, and positions move": inserting a prohibition in the
# middle shifts every number after it. So never quote `CAM-N` from anywhere; if it must be quotable,
# promote that prohibition to a RULE-### or an ADR-###, which have real IDs.
# (ASCII letters because this is an ID, and because a column aligned by character only works when bash
#  does the counting — awk length() on macOS counts BYTES.)
[ -f "$(arch_file "$ROOT")" ] && strip_markup < "$(arch_file "$ROOT")" \
| awk -v T="$TAB" -v FORB="$(kwh forbidden)" \
  -v SINCE="$(kw since)" -v STATE="$(kw state)" "$FLD"'
function flush() { if (cur != "" && !ghost(stmt)) printf "%s%s%s%s%s%s%s%s%s%s%s\n", d,T,("CAM-" n),T,"forbidden",T,stmt,T,stt,T,""; cur = "" }
/^## / { flush(); insec = ($0 ~ FORB) ? 1 : 0; next }
insec && /^-[ ]/ {
  flush(); n++; cur = "y"
  stmt = $0; sub(/^-[ ]*/, "", stmt)
  d = "0000-00-00"; stt = ""
  next
}
cur != "" && $0 ~ ("^[ \t]+- (" SINCE "):") { d = nodate(fldk($0, SINCE)); stt = fldk($0, STATE); next }
END { flush() }
' >> "$REC"

# ── CHG-### : specs/changes/*/proposal.md ───────────────────────────────────
for cd in "$ROOT/specs/changes/"CHG-*/ "$ROOT/changes/"CHG-*/; do
  [ -d "$cd" ] || continue
  P="$cd/proposal.md"; [ -f "$P" ] || continue
  strip_markup < "$P" | awk -v T="$TAB" "$FLD"'
  /^# CHG-/ && id == "" { match($0, /CHG-[0-9]+/); id = substr($0, RSTART, RLENGTH)
                          stmt = $0; sub(/^# CHG-[0-9]+:[ ]*/, "", stmt); next }
  /^## Status/  { inst = 1; next }
  inst && NF    { inst = 0; if (!ghost($0)) stt = $0; next }
  /^## History/ { inhis = 1; next }
  inhis && d == "" && /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ {
                  match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/); d = substr($0, RSTART, RLENGTH); next }
  END { if (id != "" && !ghost(stmt)) print nodate(d) T id T "change" T stmt T stt T "" }
  ' >> "$REC"
done

# ── one-sentence lines : specs/internal/decisions.md ─────────────────────────
[ -f "$(decisions_file "$ROOT")" ] && strip_markup < "$(decisions_file "$ROOT")" \
| awk -v T="$TAB" "$FLD"'
/^-[ ]+[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][ ]/ {
  match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/); d = substr($0, RSTART, RLENGTH)
  s = substr($0, RSTART + RLENGTH); sub(/^[ ]*(—|-)[ ]*/, "", s)
  if (ghost(s)) next
  n++
  print d T ("note-" n) T "note" T s T "" T ""
}
' >> "$REC"

# ── in ra ───────────────────────────────────────────────────────────────────
TOT="$(grep -c . "$REC" 2>/dev/null)"; [ -n "$TOT" ] || TOT=0
if [ "$TOT" = "0" ]; then
  printf 'No decision has been recorded yet.\n'
  printf 'Start at the BR (## Constraints) and rules.md — or run /sdd-solo:intake.\n'
  exit 0
fi

DATED="$(grep -v "^0000-00-00$TAB" "$REC" | sort)"
UNDATED="$(grep "^0000-00-00$TAB" "$REC")"
ND="$(printf '%s' "$DATED"   | grep -c . || true)"
NU="$(printf '%s' "$UNDATED" | grep -c . || true)"

if [ "$MD" = "1" ]; then
  printf '# Decision ledger — generated by decisions.sh on %s\n\n' "$TODAY"
  printf '<!-- GENERATED, DO NOT EDIT BY HAND. Regenerate: bash .sdd/scripts/decisions.sh --md -->\n\n'
  printf '| Date | ID | Kind | Statement | Status | Review on |\n|---|---|---|---|---|---|\n'
  printf '%s\n%s\n' "$DATED" "$UNDATED" | grep . | while IFS="$TAB" read -r d i k s t r; do
    [ "$d" = "0000-00-00" ] && d="—"
    printf '| %s | %s | %s | %s | %s | %s |\n' "$d" "$i" "$k" "$s" "${t:-—}" "${r:-—}"
  done
  exit 0
fi

# Columns are aligned in BASH, not in awk: bash ${#v} counts characters, awk length() counts bytes.
# Every Vietnamese label goes through here, so getting this wrong shifts the whole table while still "running".
padc() { _s="$1"; _w="$2"; while [ "${#_s}" -lt "$_w" ]; do _s="$_s "; done; printf '%s' "$_s"; }

# While br.md is still the untouched template, BR-000 is a TEACHING EXAMPLE, not a decision of the
# project. Without saying so, the ledger looks as if the project had decided three constraints about
# hosting and accounting law — exactly the "falsely green" class it was built to fight.
UNTOUCHED=0; br_untouched "$ROOT" && UNTOUCHED=1

printf '=== Decision ledger — %s entries ===\n' "$TOT"
[ "$UNTOUCHED" = "1" ] && printf '!  the BR is still the untouched template — the BR-000 lines below are a TEACHING EXAMPLE,\n   not decisions of this project. Run /sdd-solo:intake first.\n'
printf '\n'

printf '%s\n' "$DATED" | grep . | while IFS="$TAB" read -r d i k s t r; do
  printf '%s  %s%s\n' "$d" "$(padc "$i" 9)" "$s"
  L="$t"
  [ -n "$r" ] && { [ -n "$L" ] && L="$L · review on: $r" || L="review on: $r"; }
  [ -n "$L" ] && printf '            %s%s\n' "$(padc '' 9)" "$L"
done

# Past the review date — only catchable when `Review on:` is a DATE. A mark like "when the hosting plan
# changes" defeats a machine, and that is often the MORE CORRECT mark. So this is a deliberately sparse
# net: it catches what it can, and says plainly that it does not catch everything — a check that admits
# it is sparse is usable, a check pretending to be complete is not.
OVER="$(printf '%s\n' "$DATED" | awk -F"$TAB" -v today="$TODAY" '
  $6 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && $6 < today { printf "  %s  %s (due %s)\n", $2, $4, $6 }')"
if [ -n "$OVER" ]; then
  printf '\n--- Past the review date ---\n%s\n' "$OVER"
  printf '  ^ a constraint stops being right when THE WORLD changes, and when the world changes the repo does not stir.\n'
fi

if [ "$NU" -gt 0 ]; then
  printf '\n--- No date (%s entries — cannot be placed on the timeline) ---\n' "$NU"
  printf '%s\n' "$UNDATED" | grep . | while IFS="$TAB" read -r d i k s t r; do
    printf '  %s%s\n' "$(padc "$i" 9)" "$s"
  done
  printf '  ^ the date is the ONE thing here that cannot be reconstructed. A file layout can always be\n'
  printf '    rearranged; two decisions that lost their dates can never be put back in order.\n'
fi

printf '\n%s entries with a date · %s without.\n' "$ND" "$NU"
exit 0
