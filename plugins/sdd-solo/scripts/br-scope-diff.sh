#!/usr/bin/env bash
# br-scope-diff.sh BR-### [<rev>] — "gained and lost": the In Scope · Out of Scope · Dropped from brief of a BR
# in the working tree compared with <rev> (default HEAD). Prints each item added (+) / removed (−), without interpreting.
#
# Why (7.0, plan §1): runxops BR-003 narrowed three times over three adversarial rounds — every round of applied
# tickets was valid, and no round said out loud "the BR narrows from this to that". The adversarial skill calls this
# script before writing History v+1 and then says it in plain words for the owner to agree. The script only counts; the words are the skill job.
ID="$1"; REV="${2:-HEAD}"
[ -z "$ID" ] && { echo "usage: br-scope-diff.sh BR-### [<rev>]"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; BF="$(br_file "$ID" "$ROOT")"
[ -f "$BF" ] || { bad "there is no ${BF#$ROOT/}"; exit 1; }
REL="${BF#$ROOT/}"
OLD="$(git -C "$ROOT" show "$REV:$REL" 2>/dev/null)"
[ -z "$OLD" ] && { info "$REL does not exist at $REV — everything is new, there is nothing to compare"; exit 0; }
sec_of() { printf '%s\n' "$1" | awk -v h="# $ID:" 'index($0,h)==1{f=1;next} f&&/^# BR-/{exit} f{print}' \
           | awk -v re="$2" '$0 ~ re {f=1;next} f&&/^## /{exit} f{print}' | grep -E '^[[:space:]]*[-*] ' | sed -E 's/^[[:space:]]*[-*] +//'; }
CH=0
echo "=== $ID — gained and lost compared with $REV ==="
# 7.8: the section names go through kw — a BR written in English reads the same as one in Vietnamese
for SN in inscope outscope droppedbrief; do
  S="$(kw_w "$SN" "$ROOT")"; RE="$(kwh "$SN")"
  A="$(sec_of "$OLD" "$RE")"; B="$(sec_of "$(cat "$BF")" "$RE")"
  ADD="$(printf '%s\n' "$B" | grep -vxF -f <(printf '%s\n' "$A") | grep -v '^$')"
  DEL="$(printf '%s\n' "$A" | grep -vxF -f <(printf '%s\n' "$B") | grep -v '^$')"
  [ -z "$ADD" ] && [ -z "$DEL" ] && continue
  CH=$((CH+1))
  printf '## %s\n' "$S"
  [ -n "$DEL" ] && printf '%s\n' "$DEL" | sed 's/^/  − /' | cut -c1-140
  [ -n "$ADD" ] && printf '%s\n' "$ADD" | sed 's/^/  + /' | cut -c1-140
done
if [ "$CH" -eq 0 ]; then ok "In Scope · Out of Scope · Dropped are unchanged compared with $REV"
else
  echo
  info "read it to the owner in plain words: what the BR narrows from and to (a − line in In Scope, a + line in Out of Scope), and what it opens up (the other way round); write History v+1 only after they agree"
  info "a + line in Out of Scope matching a ## Do not narrow keyword of specs/vision.md makes br-check go red — unless the owner settled it with 'deliberately narrowed — owner decided YYYY-MM-DD'"
fi
