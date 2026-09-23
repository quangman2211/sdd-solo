#!/usr/bin/env bash
# uc-steps.sh UC-### — list which of the 14 steps this UC has been through.
#
# BLOCKS NOTHING. Always exits 0. This is a LISTING, not a check — the DoR gate is `gate-check.sh`,
# and a second gate measuring the same thing only adds noise.
#
# Why it exists (#29): `UC-009` at runxops went the whole way round, passed the gate, 30 verify
# findings — and only then did it come out that step ② HAD NEVER RUN. The result existed, so
# everybody assumed the step had run; it existed because it was written by hand. The only person
# who knew the truth was the only person who could type the command. No check ever asked, because
# every check measures the PRODUCT and not the STEP.
#
# Three states, and the boundary between the last two is the valuable part:
#   ✓  there is a trace in a file
#   –  deliberately skipped, WITH a reason  (a line `**Skip step <n>:** <reason>` in the UC file)
#   ?  no trace at all — it may have been done, it may not, NOBODY KNOWS
# "Skipped with a reason" and "skipped with nobody knowing it was skipped" leave the same thing on
# disk, but six months later only the first can still be read back.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ID="${1:-}"
case "$ID" in UC-[0-9]*) ;; *) echo "Usage: uc-steps.sh UC-###" >&2; exit 0;; esac
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
[ -z "$F" ] && { echo "  cannot find $ID"; exit 0; }
DIR="$(dirname "$F")"; CTX="$(owner_of "$F")"

yes_() { printf '  \033[32m✓\033[0m %-2s %s\n' "$1" "$2"; }
skip_() { printf '  \033[36m–\033[0m %-2s %s\n' "$1" "$2"; }
unk_() { printf '  \033[33m?\033[0m %-2s %s\n' "$1" "$2"; }
nom_() { printf '    %-2s %s\n' "$1" "$2"; }

# A declared skip: `**Skip step ⑤:** reason` — a digit or a circled symbol are both accepted.
skipped() { grep -qE "^\*\*($(kw skipstep)) $1:\*\* *[^ ]" "$F" 2>/dev/null; }
# st <symbol> <is the condition already true: 0/1> <description> <hint when ?>
st() {
  if [ "$2" = "0" ]; then yes_ "$1" "$3"
  elif skipped "$1"; then skip_ "$1" "$3 — deliberately skipped, with a reason"
  else unk_ "$1" "$3${4:+ · $4}"; fi
}

echo "=== $ID — the steps it has been through ==="

[ -d "$DIR" ]; st "①" $? "the UC skeleton exists"

# ② content: the Main Flow has real numbered steps
grep -qE '^[0-9]+\. +[^ <]' "$F"; st "②" $? "the UC content is written (the Main Flow has steps)"

# ③ RULE + entities + glossary
R3=1
if grep -qE 'RULE-[0-9]+' "$F" \
   && [ -n "$(entity_files "$F" "$ROOT")" ] \
   && ! cat /dev/null $(entity_files "$F" "$ROOT") | grep -qE '<(Tên entity|Entity name|one sentence)' 2>/dev/null \
   && [ -n "$(glossary_files "$CTX" "$ROOT")" ] \
   && ! cat /dev/null $(glossary_files "$CTX" "$ROOT") | grep -qE '<(thuật ngữ|Term)>' 2>/dev/null; then R3=0; fi
st "③" $R3 "RULE + entity + glossary"

# ④ flow mermaid
# 7.5 (P-32): "drawn" means IT CAN BE DRAWN — a block that mermaid cannot parse means step ④ is not done.
R4=1
if grep -qE '^```mermaid' "$DIR/$ID.flow.md" 2>/dev/null; then
  R4=0
  if mmd_ok && [ -n "$(mmd --lint "$DIR/$ID.flow.md")" ]; then R4=1; fi
fi
[ "$R4" = 1 ] && [ -f "$DIR/$ID.bpmn" ] && R4=0
st "④" $R4 "the flow is drawn"

# ⑤ screens: a file other than the README in screens/
R5=1; find "$DIR/screens" -type f ! -name 'README.md' 2>/dev/null | grep -q . && R5=0
st "⑤" $R5 "screens (Claude Design)" "there is no file in screens/"

nom_ "⑥" "checking SCR ↔ E# ↔ state — no artifact of its own, /sdd-solo:gate checks it"

# ⑦ adversarial
grep -qE "^- *($(kw rundate)): *[0-9]{4}-" "$(printf '%s' "$F")" 2>/dev/null \
  && awk -v re="$(kwh adversarial)" '$0 ~ re {t=1;next} /^## /{t=0} t' "$F" | grep -qE "($(kw rundate)): *[0-9]{4}-"
st "⑦" $? "adversarial pass (3 vai)"

# ⑧ the re-read: the ## Re-read section has an F# line (or the compressed line after close). 6.0.0 (#38): it no
# longer counts "a docs commit that survived a night" — that door is gone, verify is mandatory.
R8=1
awk -v re="$(kwh reread)" '$0 ~ re {t=1;next} /^## /{t=0} t' "$F" 2>/dev/null | grep -qE "^- F[0-9]+ |^- ($(kw rundate)):.*($(kw findings))" && R8=0
st "⑧" $R8 "re-read with an unanchored mind"

[ -f "$ROOT/.sdd/gate/$ID.ok" ]; st "⑨" $? "through the DoR gate"

# ⑩ the design: design.md + tasks.md in THE UC directory itself (4.0.0).
# Before 4.0.0 this line scanned for plan.md/tasks.md ANYWHERE under specs/ — so another UC plan.md
# made this UC report "designed". Asking by its own directory means it cannot borrow a neighbour trace.
R10=1; [ -f "$DIR/design.md" ] && [ -f "$DIR/tasks.md" ] && R10=0
st "⑩" $R10 "the design (/sdd-solo:design)" "there is no design.md + tasks.md in the UC directory"

# ⑪ product code — asked by FILE SCOPE, not by the wording of the message (#32).
# Before 3.20.0 this line only did `--grep "($ID)"` over ALL paths, so a `feat(UC-009)` commit touching
# exactly `tool_paths` — what 3.19.0 had just declared as belonging to NO UC and unable to — made it
# report "the code is written". The same commit, two scripts of the same plugin, two opposite
# conclusions: `trace-ratio` deliberately excludes it, `uc-steps` took it as evidence. The rule was
# already written at #31: what needs classifying is the FILE, not the wording. At #31 it applied to a
# blocking check; here it applies to a reading one.
CPS="$(code_paths "$ROOT") $(test_paths "$ROOT")"
TLS="$(tool_paths "$ROOT")"
for d in $TLS; do CPS="$(printf '%s\n' $CPS | grep -vxF "$d" | tr '\n' ' ')"; done
R11=1
if [ -n "$(printf '%s' "$CPS" | tr -d ' ')" ]; then
  git -C "$ROOT" log --format='%h %s' --grep="($ID)" -- $CPS 2>/dev/null \
    | grep -qE '^[0-9a-f]+ (feat|fix)' && R11=0
fi
st "⑪" $R11 "product code (a feat/fix commit carrying $ID touching $(printf '%s' "$CPS" | sed 's/ *$//'))"

# ⑫ test theo AC
UCT="$(uc_test_dir "$ROOT")"
R12=1; find "$ROOT/$UCT/$CTX/$ID" -type f 2>/dev/null | grep -q . && R12=0
st "⑫" $R12 "tests per AC" "there is no file in $UCT/$CTX/$ID/"

nom_ "⑬" "the 5-question self-review — leaves no trace, cannot be measured"

R14=1; grep -qE '\*\*Status:\*\* *implemented' "$F" && R14=0
st "⑭" $R14 "closed (Status: implemented)"

echo
echo "  ? = no trace, NOT the same as not done. To skip a step deliberately, write a line"
echo "    '**Skip step <symbol>:** <reason>' in the UC file — it will show as '–'."
exit 0
