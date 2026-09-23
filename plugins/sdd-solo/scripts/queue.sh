#!/usr/bin/env bash
# queue.sh — the coordinator work queue, the file notes/hang-doi.md IN GIT, machine readable (7.3).
#
#   queue.sh add <key> <lane> <role> [--can "k1 k2"] [note]   add a work item, state waiting
#   queue.sh next                                           what CAN GO OUT NOW: every Need is done, the lane has room
#   queue.sh take <key> [who]                               waiting → active, records who holds it + the time (default: the current role/worktree)
#   queue.sh done <key>                                     reads the KETQUA of the key (role.sh --ketqua); ket=xong + an anchor → done
#   queue.sh stop <key> <stop name> [reason]                → STOP-<name>; the name must be declared in notes/uy-quyen.md ## Stop points
#   queue.sh board [--qua-han <minutes>]                    the assignment board: active (who, how long, is there a KETQUA) · ready · waiting · stopped
#   queue.sh list                                           print the table
#
# ONLY THE COORDINATOR WRITES: add|take|done|stop refuse to run in a secondary worktree (git-dir ≠ git-common-dir). An agent
# only writes a KETQUA; `done` reads the KETQUA, checks the anchor, and only then writes the row — a write conflict disappears
# instead of having to be handled. A secondary worktree only READS, and reads the `main` copy (git show) so it does not read
# its own branch stale version. Every write is one commit --only.
# An overdue item only raises a `suspected-dead` flag for the coordinator to look at — it never changes state by itself (the lesson of dropping the overnight door, 6.0.0).
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
CMD="${1:-}"; [ -z "$CMD" ] && { sed -n '3,10p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
Q="$ROOT/notes/hang-doi.md"
# The table state words go BOTH WAYS: reading accepts either language (kw), writing emits one side per doc_lang (kw_w).
# Computed once here — status_of/ready_list call them in a loop, and each kw is another awk run.
K_WAIT="$(kw q_wait)"; K_ACT="$(kw q_active)"; K_DONE="$(kw q_done)"; K_STOP="$(kw stop)"; K_HELD="$(kw held)"
W_WAIT="$(kw_w q_wait "$ROOT")"; W_ACT="$(kw_w q_active "$ROOT")"; W_DONE="$(kw_w q_done "$ROOT")"
W_STOP="$(kw_w stop "$ROOT")"; W_HELD="$(kw_w held "$ROOT")"
is_kw() { printf '%s' "$2" | grep -qxE "$1"; }   # is the table cell $2 one side of the keyword $1?
is_main_wt() { [ "$(cd "$ROOT" && git rev-parse --git-dir)" = "$(cd "$ROOT" && git rev-parse --git-common-dir)" ]; }
main_branch() { git -C "$ROOT" show-ref --verify --quiet refs/heads/main && printf main || printf master; }
# the table content: the main checkout reads the file; a secondary worktree reads the main copy
qtext() { if is_main_wt || [ ! -f "$Q" ]; then cat "$Q" 2>/dev/null; else git -C "$ROOT" show "$(main_branch):notes/hang-doi.md" 2>/dev/null || cat "$Q"; fi; }
need_q() { [ -f "$Q" ] || { bad "there is no notes/hang-doi.md — /sdd-solo:init --update copies the template"; exit 1; }; }
need_main() { is_main_wt || { bad "only the coordinator in the main checkout writes the queue — this is a secondary worktree ($ROOT). An agent writes a KETQUA (role.sh --ketqua), not the table"; exit 1; }; }
valid_key() { printf '%s' "$1" | grep -qE '^[a-z0-9][a-z0-9._-]{1,39}$' || { bad "key '$1' — only [a-z0-9][a-z0-9._-]{1,39}"; exit 2; }; }
commit_q() { git -C "$ROOT" add "$Q" 2>/dev/null; git -C "$ROOT" commit -q --only -m "chore(sdd): queue — $1" -- "$Q" 2>/dev/null || true; }
# rows → one line each: key|lane|role|needs|state|anchor|note
rows() { qtext | awk -F'|' '/^\| *[a-z0-9][a-z0-9._-]* *\|/ && NF>=8 { for(i=2;i<=8;i++){gsub(/^ +| +$/,"",$i)}; print $2"|"$3"|"$4"|"$5"|"$6"|"$7"|"$8 }'; }
lanes() { qtext | awk -F'|' -v re="$(kwh lanes)" '$0 ~ re {f=1;next} /^## /{f=0} f && /^\| *[a-z]/ && NF>=5 { gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3); print $2"|"$3 }'; }
row_of() { rows | awk -F'|' -v k="$1" '$1==k'; }
status_of() { row_of "$1" | cut -d'|' -f5; }
lane_cap() { lanes | awk -F'|' -v l="$1" '$1==l{print $2}'; }
lane_busy() { rows | awk -F'|' -v l="$1" -v re="^($K_ACT)\$" '$2==l && $5 ~ re' | grep -c .; }
set_row() { # set_row <key> <columns 5..7 by name> — node edits the right row (7.6.0)
  node "$HERE/js/table.mjs" setcell "$Q" "$@"
}
ready_list() { # a waiting item whose Needs are all done and whose lane has room
  rows | while IFS='|' read -r k l v c s n g; do
    is_kw "$K_WAIT" "$s" || continue
    okc=1; for d in $c; do [ "$d" = "-" ] && continue; is_kw "$K_DONE" "$(status_of "$d")" || { okc=0; break; }; done
    [ "$okc" = 1 ] || continue
    cap="$(lane_cap "$l")"; [ -n "$cap" ] && [ "$(lane_busy "$l")" -ge "$cap" ] && continue
    printf '%s|%s|%s|%s\n' "$k" "$l" "$v" "$g"
  done
}

case "$CMD" in
add)
  need_q; need_main; K="$2"; L="$3"; V="$4"; shift 4 2>/dev/null || { echo "usage: queue.sh add <key> <lane> <role> [--can \"k1 k2\"] [note]" >&2; exit 2; }
  valid_key "$K"; CAN="-"; NOTE=""
  while [ $# -gt 0 ]; do case "$1" in --can) CAN="$2"; shift 2;; *) NOTE="$NOTE $1"; shift;; esac; done
  NOTE="$(printf '%s' "$NOTE" | sed 's/^ *//')"
  [ -n "$(row_of "$K")" ] && { bad "the key $K already exists"; exit 1; }
  [ -n "$(lane_cap "$L")" ] || warn "the lane '$L' is not declared in ## Lanes — next cannot limit its capacity"
  for d in $CAN; do [ "$d" = "-" ] && continue; [ -n "$(row_of "$d")" ] || warn "the need '$d' is not in the table"; done
  printf '| %s | %s | %s | %s | %s | - | %s |\n' "$K" "$L" "$V" "$CAN" "$W_WAIT" "${NOTE:--}" >> "$Q"
  commit_q "$K waiting"; ok "added $K (lane $L · role $V · needs ${CAN})"
  ;;
next)
  need_q; R="$(ready_list)"
  if [ -z "$R" ]; then info "nothing can go out right now (waiting on a dependency, or the lane is full)"; exit 0; fi
  printf '%s\n' "$R" | while IFS='|' read -r k l v g; do printf '  %-24s lane %-6s role %-3s %s\n' "$k" "$l" "$v" "$g"; done
  ;;
take)
  need_q; need_main; K="$2"; WHO="${3:-$(role_current "$ROOT")}"; valid_key "$K"
  S="$(status_of "$K")"; [ -n "$S" ] || { bad "there is no $K"; exit 1; }
  is_kw "$K_WAIT" "$S" || { bad "$K is '$S', only a 'waiting' item can be taken"; exit 1; }
  printf '%s\n' "$(ready_list)" | grep -q "^$K|" || warn "$K is not ready (a need is unfinished or the lane is full) — taken anyway, as instructed"
  set_row "$K" "trangthai=$W_ACT" "ghichu=$W_HELD:${WHO:-?}@$(date +%Y-%m-%dT%H:%M)"
  commit_q "$K active"; ok "$K → active (held by: ${WHO:-?})"
  ;;
done)
  need_q; need_main; K="$2"; valid_key "$K"
  [ -n "$(row_of "$K")" ] || { bad "there is no $K"; exit 1; }
  KF="$(ketqua_dir "$ROOT")/$K.txt"
  [ -f "$KF" ] || { bad "$K has no KETQUA yet ($KF) — until the agent writes one it is not 'done'; time passing is not evidence"; exit 1; }
  LAST="$(tail -1 "$KF")"; KET="$(printf '%s' "$LAST" | grep -oE 'ket=[a-z]+' | cut -d= -f2)"; NEO="$(printf '%s' "$LAST" | grep -oE 'neo=[^ ]+' | cut -d= -f2)"
  [ "$KET" = xong ] || { bad "the latest KETQUA of $K is ket=$KET, not xong: $LAST"; exit 1; }
  [ -n "$NEO" ] && [ "$NEO" != "-" ] || { bad "a KETQUA of xong with no anchor — done without an anchor is red"; exit 1; }
  set_row "$K" "trangthai=$W_DONE" "neo=$NEO"
  commit_q "$K done ($NEO)"; ok "$K → done · anchor $NEO"
  ;;
stop)
  need_q; need_main; K="$2"; NAME="$3"; shift 3 2>/dev/null; valid_key "$K"
  [ -n "$NAME" ] || { echo "usage: queue.sh stop <key> <stop name> [reason]" >&2; exit 2; }
  [ -n "$(row_of "$K")" ] || { bad "there is no $K"; exit 1; }
  UY="$ROOT/notes/uy-quyen.md"
  if [ -f "$UY" ]; then grep -qE "^\| *$NAME *\|" "$UY" || warn "the stop name '$NAME' is not declared in notes/uy-quyen.md ## Stop points — status.sh will go red"; fi
  if [ ! -f "$UY" ]; then warn "there is no notes/uy-quyen.md — the stop name cannot be checked"; fi
  set_row "$K" "trangthai=$W_STOP-$NAME" "ghichu=$*"
  commit_q "$K $W_STOP-$NAME"; ok "$K → $W_STOP-$NAME"
  ;;
list) need_q; qtext | sed -nE "/$(kwh work)/,\$p";;
board)
  need_q; QH="${3:-90}"; [ "$2" = --qua-han ] || QH=90
  NOW="$(date +%s)"; KD="$(ketqua_dir "$ROOT")"
  echo "Assignment board — $(date +%Y-%m-%d\ %H:%M) · $(rows | grep -c .) items"
  for l in $(lanes | cut -d'|' -f1); do printf '  lane %-6s %s/%s active\n' "$l" "$(lane_busy "$l")" "$(lane_cap "$l")"; done
  echo "── active"
  rows | awk -F'|' -v re="^($K_ACT)\$" '$5 ~ re' | while IFS='|' read -r k l v c s n g; do
    who="$(printf '%s' "$g" | grep -oE "($K_HELD):[^@ ]*" | cut -d: -f2)"; t="$(printf '%s' "$g" | grep -oE '@[0-9T:-]+' | tr -d '@')"
    age=""; if [ -n "$t" ]; then ts="$(date -j -f '%Y-%m-%dT%H:%M' "$t" +%s 2>/dev/null || date -d "$t" +%s 2>/dev/null)"; [ -n "$ts" ] && age=$(( (NOW - ts) / 60 )); fi
    flag=""; if [ -f "$KD/$k.txt" ]; then
      case "$(tail -1 "$KD/$k.txt")" in *ket=xong*) flag="✓ KETQUA says xong — queue.sh done $k";; *ket=chan*) flag="✗ KETQUA blocked: $(tail -1 "$KD/$k.txt" | grep -oE 'hoi=[^ ]+')";; *) flag="KETQUA: $(tail -1 "$KD/$k.txt" | grep -oE 'ket=[^ ]+')";; esac
    elif [ -n "$age" ] && [ "$age" -gt "$QH" ]; then flag="suspected-dead (${age} minutes, no KETQUA) — go and look, do not change the state by itself"; fi
    printf '  %-24s role %-3s held %-10s %6s min  %s\n' "$k" "$v" "${who:-?}" "${age:--}" "$flag"
  done
  echo "── ready (next)"; ready_list | while IFS='|' read -r k l v g; do printf '  %-24s lane %-6s role %s\n' "$k" "$l" "$v"; done
  echo "── waiting on a dependency / lane full"
  rows | awk -F'|' -v re="^($K_WAIT)\$" '$5 ~ re' | while IFS='|' read -r k l v c s n g; do printf '%s\n' "$(ready_list)" | grep -q "^$k|" || printf '  %-24s needs %s\n' "$k" "$c"; done
  echo "── stopped"; rows | awk -F'|' -v re="^($K_STOP)-" '$5 ~ re' | while IFS='|' read -r k l v c s n g; do printf '  %-24s %s — %s\n' "$k" "$s" "$g"; done
  # done without an anchor is red — do not use a pipe | while: bad inside a subshell cannot increment FAIL
  NX="$(rows | awk -F'|' -v re="^($K_DONE)\$" '$5 ~ re && ($6=="" || $6=="-") {print $1}')"
  for k in $NX; do bad "$k is done with an empty Anchor — done without an anchor is red"; done
  [ "$FAIL" -gt 0 ] && exit 1; exit 0
  ;;
*) sed -n '3,10p' "$0" | sed 's/^# \{0,3\}//'; exit 2;;
esac
