#!/usr/bin/env bash
# phieu.sh — question tickets with a NUMBER LOCK (7.2). One file per ticket, notes/hoi-dap/phieu/NNN-<slug>.md + one index row
# trong notes/hoi-dap/hoi-dap.md (6.x: specs/internal/hoi-dap.md).
#
#   phieu.sh new "<task>" <from-role> [slug]  take the next number (an mkdir lock in git-common-dir, shared by every worktree; the
#                                          number = max of the index ∪ the file names ∪ `git log --all` "ticket #n"), create the file
#                                          from the template, add the index row, COMMIT THE PLACEHOLDER ROW (--only) and only then return. Write the body afterwards.
#   phieu.sh close <n>                     recount F#/K# ON THE FILE and compare with the total the ticket declares; every role in For: must
#                                          have a KETQUA ket=xong (role.sh --ketqua); when it all holds, the index → "applied", and commit
#   phieu.sh muc-luc                       audit: duplicate numbers · gaps · a file with no row · a row with no file. exit 1 if there is any
#   phieu.sh list [--mo]                   print the index; --mo: tickets not yet "applied"/"closed"
#   phieu.sh hoi <role> "<one-line question>"  (7.3) open an ASK-<V>n entry in notes/hoi-dap/hoi-<V>.md using the four-box addressed template
#                                          (copying templates/skel/hoi-vai.md when there is no log yet); the number = max + 1. Check it with: hoi-check.sh <V>
#
# Why: runxops collided on ticket numbers FOUR times in one day (P-21) — the number was chosen when writing started and the file
# created when writing finished, and the gap was enough for another role to take the number. Closing a ticket copied R TOTAL instead of counting on the file → ticket tails were lost (P-33).
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
CMD="${1:-}"; [ -z "$CMD" ] && { sed -n '3,14p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
HD="$(hoi_dap_file "$ROOT")"; PD="$(dirname "$HD")/phieu"
rel() { printf '%s' "${1#$ROOT/}"; }

ensure_hd() {
  [ -f "$HD" ] && return 0
  local sk; sk="$(plugin_file templates/skel/hoi-dap.md "$(dirname "$HERE")")"
  mkdir -p "$(dirname "$HD")"
  if [ -n "$sk" ]; then cp "$sk" "$HD"; else printf '# Questions and answers between agents\n\n## %s\n' "$(kw_w ticket "$ROOT")" > "$HD"; fi
  grep -qE "^\\| # \\| ($(kw work)) \\|" "$HD" \
    || printf '\n| # | %s | %s | %s | %s | %s |\n|---|---|---|---|---|---|\n' \
         "$(kw_w work "$ROOT")" "$(kw_w since "$ROOT")" "$(kw_w date "$ROOT")" \
         "$(kw_w state "$ROOT")" "$(kw_w file "$ROOT")" >> "$HD"
  ok "created $(rel "$HD") from the template"
}
# the highest number in use — three sources, to stay safe across worktrees that have not merged
max_n() {
  { grep -oE '^\| *#[0-9]+' "$HD" 2>/dev/null | grep -oE '[0-9]+'
    ls "$PD" 2>/dev/null | grep -oE '^[0-9]+'
    git -C "$ROOT" log --all --format=%s 2>/dev/null | grep -oiE "($(kw c_ticket))[0-9]+" | grep -oE '[0-9]+'
  } | sort -n | tail -1
}
slugify() { node "$HERE/js/util.mjs" slug "$1" 2>/dev/null; }
find_pf() { ls "$PD"/"$(printf '%03d' "$1")"-*.md 2>/dev/null | head -1; }

case "$CMD" in
new)
  VIEC="$2"; TU="$3"; SL="$4"
  [ -n "$VIEC" ] && [ -n "$TU" ] || { echo "usage: phieu.sh new \"<task>\" <from-role> [slug]" >&2; exit 2; }
  ensure_hd; mkdir -p "$PD"
  lock_take phieu "$ROOT" || { bad "could not take the lock $(lock_dir "$ROOT")/phieu after 10 s — somebody is allocating a number; try again"; exit 1; }
  N=$(( $(max_n | awk '{print $1+0}') + 1 )); NNN="$(printf '%03d' "$N")"
  [ -z "$SL" ] && SL="$(slugify "$VIEC")"; [ -z "$SL" ] && SL="phieu"
  F="$PD/$NNN-$SL.md"; TD="$(today)"
  { printf '### #%s · %s: %s · %s: %s · %s\n' "$N" "$(kw_w from_ "$ROOT")" "$TU" "$(kw_w task "$ROOT")" "$VIEC" "$TD"
    printf '%s: <one sentence>\n%s: <file:line, …>\n%s: <the consequence>\n%s: <the choice + why>\n\n' "$(kw_w p_q "$ROOT")" "$(kw_w p_look "$ROOT")" "$(kw_w p_wrong "$ROOT")" "$(kw_w p_lean "$ROOT")"
    printf '**%s:** <level L0–L3> · <the answer>\n%s: <file:line or the reason>\n%s: <one line per role: - **B:** … · - **D:** … · - **T:** …>\n%s:\n' "$(kw_w p_ans "$ROOT")" "$(kw_w p_src "$ROOT")" "$(kw_w forwhom "$ROOT")" "$(kw_w approve "$ROOT")"; } > "$F"
  ROW="| #$N | $VIEC | $TU | $TD | $(kw_w q_open "$ROOT") | [$NNN-$SL.md](phieu/$NNN-$SL.md) |"
  node "$HERE/js/table.mjs" addrow "$HD" "$ROW"
  git -C "$ROOT" add "$F" "$HD" 2>/dev/null
  git -C "$ROOT" commit -q --only -m "chore(sdd): $(kw_w c_ticket_w "$ROOT")$N placeholder — $VIEC" -- "$F" "$HD" 2>/dev/null \
    || warn "could not commit the placeholder row (a hook blocking, or no git in this repo?) — the number $N is written into the file and the index either way"
  lock_drop phieu "$ROOT"
  printf '#%s %s\n' "$N" "$(rel "$F")"
  info "the number is taken and committed. Write the ticket body, then commit separately: git commit --only -m 'chore(sdd): $(kw_w c_ticket_w "$ROOT")$N — <task>' -- $(rel "$F")"
  ;;
close)
  N="$2"; [ -n "$N" ] || { echo "usage: phieu.sh close <n>" >&2; exit 2; }
  N="${N#\#}"; F="$(find_pf "$N")"; [ -f "$F" ] || { bad "there is no file for ticket #$N in $(rel "$PD")/"; exit 1; }
  echo "Closing ticket #$N — $(rel "$F")"
  NF="$(grep -cE '^(- |\| *)F[0-9]+\b' "$F")"; NK="$(grep -cE '^(- |\| *)K[0-9]+\b' "$F")"
  info "on the file: $NF F# lines · $NK K# lines"
  ROW="$(grep -E "^\| *#$N \|" "$HD" | head -1)"
  CLAIM="$(printf '%s\n%s' "$ROW" "$(head -5 "$F")" | grep -oE "[0-9]+ ($(kw findings)|K\b|$(kw questions))" | head -1 | grep -oE '^[0-9]+')"
  if [ -n "$CLAIM" ]; then
    GOT="$NF"; [ "$NK" -gt "$NF" ] && GOT="$NK"
    if [ "$CLAIM" = "$GOT" ]; then ok "the declared total $CLAIM matches the count on the file"
    else
      bad "the ticket declares $CLAIM entries but the file counts $GOT — the count ON THE FILE is the truth (P-33)"
      printf '%s\n' "$(grep -oE '^(- |\| *)[FK][0-9]+' "$F" | grep -oE '[0-9]+' | sort -n | awk 'NR>1 && $1!=p+1 {for(i=p+1;i<$1;i++) printf "      missing #%d\n", i} {p=$1}')"
    fi
  fi
  # every role with work in For: → a KETQUA ket=xong is required
  ID="$(grep -m1 -E '^###? *#' "$F" | grep -oE '\b(UC|BR|CHG)-[0-9]+\b' | head -1 | tr 'A-Z' 'a-z')"
  MISS=0
  CHO="/^($(kw forwhom)):/,/^($(kw approve)):/p"
  for v in $(sed -nE "$CHO" "$F" | grep -oE '^- \*\*[A-Z]( ?[·,] ?[A-Z])*' | sed 's/^- \*\*//' | tr '·,' '  '); do
    sed -nE "$CHO" "$F" | grep -E "^- \*\*([^*]*[ ·,/])?$v([ ·,/:(]|$)" | grep -qiE "$(kw nowork)" && continue
    role_known "$v" "$ROOT" 2>/dev/null || [ -z "$(roles_file "$ROOT")" ] || continue
    k="$(ls "$(ketqua_dir "$ROOT")"/"$(printf '%s' "$v" | tr 'A-Z' 'a-z')-${ID:-*}-p$N"*.txt 2>/dev/null | head -1)"
    if [ -n "$k" ] && grep -q 'ket=xong' "$k"; then ok "role $v has a KETQUA xong ($(basename "$k"))"
    else bad "role $v has work in For: but no KETQUA ket=xong yet (role.sh --ketqua $(printf '%s' "$v" | tr 'A-Z' 'a-z')-${ID:-<id>}-p$N …)"; MISS=1; fi
  done
  if [ "$FAIL" -eq 0 ]; then
    node "$HERE/js/table.mjs" mark "$HD" "$N" "$(kw_w applied "$ROOT")"
    git -C "$ROOT" commit -q --only -m "chore(sdd): $(kw_w c_ticket_w "$ROOT")$N $(kw_w applied "$ROOT") — $NF F# · $NK K# counted on the file" -- "$HD" 2>/dev/null || true
    echo "CLOSED #$N — the index now says applied."
  else
    echo "NOT CLOSED — $FAIL errors."; exit 1
  fi
  ;;
muc-luc)
  [ -f "$HD" ] || { info "there is no $(rel "$HD") yet"; exit 0; }
  echo "Ticket index — $(rel "$HD") · $(rel "$PD")/"
  IDX="$(grep -oE '^\| *#[0-9]+' "$HD" | grep -oE '[0-9]+' | sort -n)"
  FIL="$(ls "$PD" 2>/dev/null | grep -oE '^[0-9]+' | sed 's/^0*//' | sort -n)"
  D1="$(printf '%s\n' "$IDX" | uniq -d | tr '\n' ' ')"; [ -n "$D1" ] && bad "duplicate numbers in the index: $D1"
  D2="$(printf '%s\n' "$FIL" | uniq -d | tr '\n' ' ')"; [ -n "$D2" ] && bad "two files with the same number: $D2"
  G="$(printf '%s\n' "$IDX" | awk 'NR>1 && $1!=p+1 {for(i=p+1;i<$1;i++) printf "%d ", i} {p=$1}')"; [ -n "$G" ] && warn "gaps in the index numbering: $G"
  NOF="$(comm -23 <(printf '%s\n' "$IDX" | sort -u) <(printf '%s\n' "$FIL" | sort -u) | tr '\n' ' ')"; [ -n "$NOF" ] && bad "index rows with no file: #$(printf '%s' "$NOF" | sed 's/ /  #/g')"
  NOR="$(comm -13 <(printf '%s\n' "$IDX" | sort -u) <(printf '%s\n' "$FIL" | sort -u) | tr '\n' ' ')"; [ -n "$NOR" ] && bad "files with no index row: $NOR"
  printf '  %s index rows · %s files · highest number %s\n' "$(printf '%s\n' "$IDX" | grep -c .)" "$(printf '%s\n' "$FIL" | grep -c .)" "$(max_n)"
  [ "$FAIL" -eq 0 ] && { ok "the index and the files match"; exit 0; } || exit 1
  ;;
list)
  [ -f "$HD" ] || { info "there is no $(rel "$HD") yet"; exit 0; }
  if [ "$2" = --mo ]; then grep -E '^\| *#[0-9]+ \|' "$HD" | grep -vE "\\| *($(kw applied)|$(kw closed)) *\\|[^|]*\\| *\$"
  else grep -E '^\| *#[0-9]+ \|' "$HD"; fi | cut -c1-160
  ;;
hoi)
  V="$2"; CAU="$3"; [ -n "$V" ] && [ -n "$CAU" ] || { echo "usage: phieu.sh hoi <role> \"<one-line question>\"" >&2; exit 2; }
  HF="$(dirname "$HD")/hoi-$V.md"; mkdir -p "$(dirname "$HF")"
  if [ ! -f "$HF" ]; then
    sk="$(plugin_file templates/skel/hoi-vai.md "$(dirname "$HERE")")"
    if [ -n "$sk" ]; then sed "s/<V>/$V/g; s/<role name>/$(role_name "$V" "$ROOT")/" "$sk" | sed -E "/^### ($(kw ask))-/,\$d" > "$HF"
    else printf '# %s from role %s\n\n' "$(kw_w ask "$ROOT")" "$V" > "$HF"; fi
    ok "created $(rel "$HF") from the template"
  fi
  N=$(( $(grep -oE "^### ($(kw ask))-$V[0-9]+" "$HF" | grep -oE '[0-9]+$' | sort -n | tail -1 | awk '{print $1+0}') + 1 ))
  A="$(kw_w ask "$ROOT")"
  { printf '\n### %s-%s%s · %s — %s\n' "$A" "$V" "$N" "$CAU" "$(today)"
    printf -- '- **%s:** <file:section already looked up>\n- **%s:** <%s> — <why>\n- **%s:** <…>\n- **%s:** <…>\n- **%s:** · **%s:**\n' "$(kw_w source "$ROOT")" "$(kw_w blocking "$ROOT")" "$(kw_w blockvals "$ROOT" | tr '|' '/')" "$(kw_w waiting "$ROOT")" "$(kw_w specwork "$ROOT")" "$(kw_w answer "$ROOT" | tr -d '\\\\')" "$(kw_w target "$ROOT")"; } >> "$HF"
  printf '%s-%s%s %s\n' "$A" "$V" "$N" "$(rel "$HF")"
  info "fill the four boxes, then commit: git commit --only -m 'docs(<ID>): $A-$V$N — <question>' -- $(rel "$HF") ; check it with: hoi-check.sh $V"
  ;;
*) sed -n '3,14p' "$0" | sed 's/^# \{0,3\}//'; exit 2;;
esac
