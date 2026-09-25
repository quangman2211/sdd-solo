#!/usr/bin/env bash
# queue.sh — the coordinator work queue, the file notes/hang-doi.md IN GIT, machine readable (7.3).
#
#   queue.sh add <key> <lane> <role> [--can "k1 k2"] [note]   add a work item, state waiting
#       <lane> is a lane from the ## Lanes table (spec · code · …), the thing that has a CAPACITY.
#       <role> is a role from .sdd/roles (A · B · …). They are not interchangeable and the order matters.
#   queue.sh next                                           what CAN GO OUT NOW: every Need is done, the lane has room
#   queue.sh take <key> [who]                               waiting → active, records who holds it + the time (default: the current role/worktree)
#   queue.sh done <key> [--theo-phieu #n]                                     reads the KETQUA of the key (role.sh --ketqua); ket=xong + an anchor → done
#   queue.sh stop <key> <stop name> [reason]                → STOP-<name>; the name must be declared in notes/uy-quyen.md ## Stop points
#   queue.sh board [--qua-han <minutes>]                    the assignment board: active (who, how long, is there a KETQUA) · ready · waiting · stopped
#   queue.sh list                                           print the table
#   queue.sh giu [role]                                     read-only: the active items that role still holds + the last ket= of each
#
# add · take · done · stop run ONLY in the main checkout (the coordinator). list · next · board · giu read anywhere.
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
is_lane() { lanes | cut -d'|' -f1 | grep -qxF "$1"; }   # is $1 a lane named in the ## Lanes table?
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

# After a job finishes: was it the last open item of its UC? Then the lane of that UC has nothing left in it.
# 8.6.0 (P-57): --worktree got its opposite in 8.2.0 and nobody ran it — measured at runxops, 4 workspaces and 18
# branches of closed UCs were still there and the owner found them, not a check. The state that knows a lane is
# finished lives here, in the queue, so this is where it gets said. It only LOOKS: --dry-run removes nothing, and
# the real command is printed rather than run, because deleting a lane deletes the only copy of somebody work.
lane_done_hint() {
  local u rest
  [ -n "$(roles_file "$ROOT")" ] || return 0
  # The UC can be in the key, in the anchor (`.sdd/gate/UC-012.ok` is the usual one) or in the KETQUA line. Not in
  # the note: `take` overwrites that cell with the held-by stamp, so anything written there at `add` is already gone.
  u="$(printf '%s\n%s\n' "$(row_of "$1")" "$(tail -1 "$(ketqua_dir "$ROOT")/$1.txt" 2>/dev/null)" \
       | grep -oE '([Uu][Cc]|[Cc][Hh][Gg])-[0-9]{3}' | head -1 | tr 'a-z' 'A-Z')"
  [ -n "$u" ] || return 0
  rest="$(rows | awk -F'|' -v re="^($K_ACT|$K_WAIT)\$" '$5 ~ re' | grep -cE "(^|[^A-Za-z0-9])$u([^0-9]|\$)")"
  [ "$rest" = 0 ] || { info "$u still has $rest open item(s) in the queue - its lane stays as it is"; return 0; }
  info "$u has no open item left in the queue. What its lane still holds:"
  bash "$HERE/role.sh" --don "$u" --dry-run 2>&1 | sed 's/^/    /'
  info "clean it for real when you agree:  bash .sdd/scripts/role.sh --don $u"
}

case "$CMD" in
add)
  need_q; need_main; K="$2"; L="$3"; V="$4"; shift 4 2>/dev/null || { echo "usage: queue.sh add <key> <lane> <role> [--can \"k1 k2\"] [note]" >&2; exit 2; }
  valid_key "$K"
  # 8.9.0 (P-66): <lane> and <role> are two different vocabularies and swapping them was never caught. Measured on
  # the runxops queue on 2026-09-25: 20 malformed rows - 5 where the arguments were plainly swapped
  # (`lane=C role=UC-034`), 1 with a UC in the lane cell, 14 on a lane nobody ever declared. The existing warning
  # about an undeclared lane had been printed and ignored 14 times, so what can be PROVEN wrong now blocks; what is
  # merely undeclared still warns, because blocking that would make a running repo edit its table before it could
  # queue anything, and a lane may simply not be written down yet.
  if role_known "$L" "$ROOT" && ! is_lane "$L"; then
    bad "'$L' is a ROLE, not a lane - the arguments are the other way round"
    info "you meant:  queue.sh add $K <lane> $L${V:+   (and '$V' goes where a role goes, not where a lane goes)}"
    info "lanes declared in ## Lanes: $(lanes | cut -d'|' -f1 | tr '\n' ' ')"
    exit 2
  fi
  case "$L" in [Uu][Cc]-[0-9]*|[Cc][Hh][Gg]-[0-9]*|[Bb][Rr]-[0-9]*)
    bad "'$L' is an ID, not a lane - the lane is the thing with a capacity (## Lanes), the ID belongs in the key or the note"
    info "lanes declared in ## Lanes: $(lanes | cut -d'|' -f1 | tr '\n' ' ')"
    exit 2;; esac
  if [ -n "$V" ]; then
    # Same line as for the lane, drawn in the same place: an ID in the role slot, or a LANE in the role slot, is
    # provably wrong and blocks; a role that is merely not declared yet only warns. Blocking that one would stop a
    # repo from queueing work until it had finished writing its own policy file - and it is not what went wrong at
    # runxops, where every bad row carried a UC-### in the role cell.
    case "$V" in [Uu][Cc]-[0-9]*|[Cc][Hh][Gg]-[0-9]*|[Bb][Rr]-[0-9]*)
      bad "'$V' is an ID, not a role - a role is a name from .sdd/roles; the ID belongs in the key or the note"
      info "you meant:  queue.sh add $K $L <role>   (and put $V in the note)"
      exit 2;; esac
    if is_lane "$V" && ! role_known "$V" "$ROOT"; then
      bad "'$V' is a LANE, not a role - the arguments are the other way round"
      info "you meant:  queue.sh add $K $V <role>"
      exit 2
    fi
    if [ -n "$(roles_file "$ROOT")" ] && ! role_known "$V" "$ROOT"; then
      warn "'$V' is not a role in .sdd/roles (vai=$(role_list "$ROOT")) — nobody can be handed this row until it is declared there"
    fi
  fi
  CAN="-"; NOTE=""
  while [ $# -gt 0 ]; do case "$1" in --can) CAN="$2"; shift 2;; *) NOTE="$NOTE $1"; shift;; esac; done
  NOTE="$(printf '%s' "$NOTE" | sed 's/^ *//')"
  [ -n "$(row_of "$K")" ] && { bad "the key $K already exists"; exit 1; }
  [ -n "$(lane_cap "$L")" ] || warn "the lane '$L' is not declared in ## Lanes — it has no capacity, so 'next' will never hold a job back on it. Add a row to ## Lanes"
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
  # 8.4.0 (P-50): a job that ended `ket=chan hoi=#n` and was then settled BY THE TICKET had no way to close. `done`
  # wanted a fresh `ket=xong` (so the agent had to be sent round again to produce one) and `stop` wanted a declared
  # stop name (it is not stopped, it is finished). --theo-phieu is the second SHAPE of evidence, not an exemption:
  # the ticket must carry the `Applied:` stamp that `phieu.sh close` writes onto the file (8.3.0) — and that stamp is
  # only written after close has counted F#/K# on the file and demanded a KETQUA from every role in For:. The ticket
  # file then becomes the anchor. Time passing is still not evidence; a closed ticket is.
  if [ "$3" = --theo-phieu ]; then
    PN="${4#\#}"; [ -n "$PN" ] || { echo "usage: queue.sh done <key> --theo-phieu #n" >&2; exit 2; }
    HD="$(hoi_dap_file "$ROOT")"; PF="$(ls "$(dirname "$HD")/phieu/$(printf '%03d' "$PN")"-*.md 2>/dev/null | head -1)"
    [ -n "$PF" ] || { bad "there is no file for ticket #$PN"; exit 1; }
    grep -qE "^($(kw p_applied)):[[:space:]]*[^[:space:]<]" "$PF" \
      || { bad "ticket #$PN is not closed — it carries no $(kw_w p_applied "$ROOT"): stamp. Run phieu.sh close $PN first; an unclosed ticket does not finish a job"; exit 1; }
    set_row "$K" "trangthai=$W_DONE" "neo=${PF#$ROOT/}" "ghichu=$(kw_w c_ticket_w "$ROOT")$PN"
    commit_q "$K done (ticket #$PN)"; ok "$K → done · anchor ${PF#$ROOT/} (settled by ticket #$PN, not by redoing the work)"
    lane_done_hint "$K"
    exit 0
  fi
  KF="$(ketqua_dir "$ROOT")/$K.txt"
  [ -f "$KF" ] || { bad "$K has no KETQUA yet ($KF) — until the agent writes one it is not 'done'; time passing is not evidence"; exit 1; }
  LAST="$(tail -1 "$KF")"; KET="$(kq_field ket "$LAST")"; NEO="$(kq_field neo "$LAST")"
  [ "$KET" = xong ] || { bad "the latest KETQUA of $K is ket=$KET, not xong: $LAST"; exit 1; }
  [ -n "$NEO" ] && [ "$NEO" != "-" ] || { bad "a KETQUA of xong with no anchor — done without an anchor is red"; exit 1; }
  set_row "$K" "trangthai=$W_DONE" "neo=$NEO"
  DT="$(kq_field dat "$LAST")"; [ "$DT" = "-" ] && DT=""
  commit_q "$K done ($NEO)"; ok "$K → done · anchor $NEO${DT:+ · measured $DT}"
  # A job that reported a shortfall is still done: the measurement ran, and what it found is a finding to file,
  # not a gate to fail. Saying the number out loud is the whole job here (8.9.0, P-65).
  if [ -n "$DT" ] && [ "${DT%%/*}" != "${DT##*/}" ]; then
    warn "$K reported $DT - the measurement did not pass in full; file what it found before the result is forgotten"
  fi
  lane_done_hint "$K"
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
giu)
  # Read-only and worktree-safe (qtext reads the main copy from a secondary worktree). One line per item the role
  # still holds: `<key>|<last ket=>`, empty after the bar when there is no KETQUA at all. The Stop hook asks exactly
  # this question, and so does an agent wondering what it is still carrying.
  need_q; V="${2:-$(role_current "$ROOT")}"; [ -n "$V" ] || exit 0
  KD="$(ketqua_dir "$ROOT")"
  rows | awk -F'|' -v re="^($K_ACT)\$" '$5 ~ re' | while IFS='|' read -r k l v c s n g; do
    [ "$v" = "$V" ] || printf '%s' "$g" | grep -qE "($K_HELD): *$V([^A-Za-z0-9_-]|\$)" || continue
    if [ -f "$KD/$k.txt" ]; then kt="$(kq_field ket "$(tail -1 "$KD/$k.txt")")"; else kt=""; fi
    printf '%s|%s\n' "$k" "$kt"
  done
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
      KL="$(tail -1 "$KD/$k.txt")"
      DT="$(kq_field dat "$KL")"; [ "$DT" = "-" ] && DT=""
      case "$(kq_field ket "$KL")" in xong) flag="✓ KETQUA says xong${DT:+ ($DT)} — queue.sh done $k";; chan) flag="✗ KETQUA blocked: hoi=$(kq_field hoi "$KL")";; *) flag="KETQUA: ket=$(kq_field ket "$KL")";; esac
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
