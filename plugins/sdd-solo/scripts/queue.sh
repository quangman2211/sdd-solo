#!/usr/bin/env bash
# queue.sh — hàng đợi việc của điều phối, file notes/hang-doi.md TRONG GIT, máy đọc (7.3).
#
#   queue.sh add <khoá> <làn> <vai> [--can "k1 k2"] [ghi chú]   thêm một việc, trạng thái chờ
#   queue.sh next                                           việc PHÁT ĐƯỢC NGAY: mọi Cần đã xong, làn còn chỗ
#   queue.sh take <khoá> [ai]                               chờ → đang, ghi ai giữ + giờ (mặc định: vai/worktree hiện tại)
#   queue.sh done <khoá>                                    đọc KETQUA của khoá (role.sh --ketqua); ket=xong + neo → xong
#   queue.sh stop <khoá> <tên dừng> [lý do]                 → DỪNG-<tên>; tên phải khai ở notes/uy-quyen.md ## Điểm dừng
#   queue.sh board [--qua-han <phút>]                       bảng giao việc: đang (ai, bao lâu, có KETQUA chưa) · sẵn sàng · chờ · dừng
#   queue.sh list                                           in bảng
#
# CHỈ ĐIỀU PHỐI GHI: add|take|done|stop từ chối chạy ở worktree phụ (git-dir ≠ git-common-dir). Agent chỉ ghi KETQUA;
# `done` đọc KETQUA, kiểm neo, rồi mới ghi dòng — xung đột ghi biến mất thay vì phải xử lý. Worktree phụ chỉ ĐỌC, và đọc
# bản của `main` (git show) để không đọc bản cũ của nhánh mình. Mỗi lần ghi là một commit --only.
# Việc quá hạn chỉ được cắm cờ `nghi-chết` để điều phối đi nhìn — không tự đổi trạng thái (bài học bỏ cửa qua đêm, 6.0.0).
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
CMD="${1:-}"; [ -z "$CMD" ] && { sed -n '3,10p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
Q="$ROOT/notes/hang-doi.md"
# Từ trạng thái của bảng đi CẢ HAI CHIỀU: đọc nhận cả hai thứ tiếng (kw), ghi ra một vế theo doc_lang (kw_w).
# Tính một lần ở đây — status_of/ready_list gọi trong vòng lặp, mỗi kw là một lượt awk.
K_WAIT="$(kw q_wait)"; K_ACT="$(kw q_active)"; K_DONE="$(kw q_done)"; K_STOP="$(kw stop)"; K_HELD="$(kw held)"
W_WAIT="$(kw_w q_wait "$ROOT")"; W_ACT="$(kw_w q_active "$ROOT")"; W_DONE="$(kw_w q_done "$ROOT")"
W_STOP="$(kw_w stop "$ROOT")"; W_HELD="$(kw_w held "$ROOT")"
is_kw() { printf '%s' "$2" | grep -qxE "$1"; }   # ô bảng $2 là một vế của từ khoá $1?
is_main_wt() { [ "$(cd "$ROOT" && git rev-parse --git-dir)" = "$(cd "$ROOT" && git rev-parse --git-common-dir)" ]; }
main_branch() { git -C "$ROOT" show-ref --verify --quiet refs/heads/main && printf main || printf master; }
# nội dung bảng: checkout chính đọc file; worktree phụ đọc bản của main
qtext() { if is_main_wt || [ ! -f "$Q" ]; then cat "$Q" 2>/dev/null; else git -C "$ROOT" show "$(main_branch):notes/hang-doi.md" 2>/dev/null || cat "$Q"; fi; }
need_q() { [ -f "$Q" ] || { bad "chưa có notes/hang-doi.md — /sdd-solo:init --update chép khuôn"; exit 1; }; }
need_main() { is_main_wt || { bad "chỉ điều phối ở checkout chính ghi hàng đợi — đang ở worktree phụ ($ROOT). Agent ghi KETQUA (role.sh --ketqua), không ghi bảng"; exit 1; }; }
valid_key() { printf '%s' "$1" | grep -qE '^[a-z0-9][a-z0-9._-]{1,39}$' || { bad "khoá '$1' — chỉ [a-z0-9][a-z0-9._-]{1,39}"; exit 2; }; }
commit_q() { git -C "$ROOT" add "$Q" 2>/dev/null; git -C "$ROOT" commit -q --only -m "chore(sdd): hàng đợi — $1" -- "$Q" 2>/dev/null || true; }
# rows → mỗi dòng: khoá|làn|vai|cần|trạng thái|neo|ghi chú
rows() { qtext | awk -F'|' '/^\| *[a-z0-9][a-z0-9._-]* *\|/ && NF>=8 { for(i=2;i<=8;i++){gsub(/^ +| +$/,"",$i)}; print $2"|"$3"|"$4"|"$5"|"$6"|"$7"|"$8 }'; }
lanes() { qtext | awk -F'|' -v re="$(kwh lanes)" '$0 ~ re {f=1;next} /^## /{f=0} f && /^\| *[a-z]/ && NF>=5 { gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3); print $2"|"$3 }'; }
row_of() { rows | awk -F'|' -v k="$1" '$1==k'; }
status_of() { row_of "$1" | cut -d'|' -f5; }
lane_cap() { lanes | awk -F'|' -v l="$1" '$1==l{print $2}'; }
lane_busy() { rows | awk -F'|' -v l="$1" -v re="^($K_ACT)\$" '$2==l && $5 ~ re' | grep -c .; }
set_row() { # set_row <khoá> <cột 5..7 theo tên> — node sửa đúng dòng (7.6.0)
  node "$HERE/js/table.mjs" setcell "$Q" "$@"
}
ready_list() { # việc chờ mà mọi Cần đã xong và làn còn chỗ
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
  need_q; need_main; K="$2"; L="$3"; V="$4"; shift 4 2>/dev/null || { echo "dùng: queue.sh add <khoá> <làn> <vai> [--can \"k1 k2\"] [ghi chú]" >&2; exit 2; }
  valid_key "$K"; CAN="-"; NOTE=""
  while [ $# -gt 0 ]; do case "$1" in --can) CAN="$2"; shift 2;; *) NOTE="$NOTE $1"; shift;; esac; done
  NOTE="$(printf '%s' "$NOTE" | sed 's/^ *//')"
  [ -n "$(row_of "$K")" ] && { bad "khoá $K đã có"; exit 1; }
  [ -n "$(lane_cap "$L")" ] || warn "làn '$L' chưa khai ở ## Làn — next không giới hạn được sức chứa"
  for d in $CAN; do [ "$d" = "-" ] && continue; [ -n "$(row_of "$d")" ] || warn "cần '$d' chưa có trong bảng"; done
  printf '| %s | %s | %s | %s | %s | - | %s |\n' "$K" "$L" "$V" "$CAN" "$W_WAIT" "${NOTE:--}" >> "$Q"
  commit_q "$K chờ"; ok "thêm $K (làn $L · vai $V · cần ${CAN})"
  ;;
next)
  need_q; R="$(ready_list)"
  if [ -z "$R" ]; then info "không việc nào phát được ngay (chờ phụ thuộc hoặc làn đầy)"; exit 0; fi
  printf '%s\n' "$R" | while IFS='|' read -r k l v g; do printf '  %-24s làn %-6s vai %-3s %s\n' "$k" "$l" "$v" "$g"; done
  ;;
take)
  need_q; need_main; K="$2"; WHO="${3:-$(role_current "$ROOT")}"; valid_key "$K"
  S="$(status_of "$K")"; [ -n "$S" ] || { bad "không có $K"; exit 1; }
  is_kw "$K_WAIT" "$S" || { bad "$K đang '$S', chỉ nhận việc 'chờ'"; exit 1; }
  printf '%s\n' "$(ready_list)" | grep -q "^$K|" || warn "$K chưa sẵn sàng (cần chưa xong hoặc làn đầy) — vẫn nhận theo lệnh"
  set_row "$K" "trangthai=$W_ACT" "ghichu=$W_HELD:${WHO:-?}@$(date +%Y-%m-%dT%H:%M)"
  commit_q "$K đang"; ok "$K → đang (giữ: ${WHO:-?})"
  ;;
done)
  need_q; need_main; K="$2"; valid_key "$K"
  [ -n "$(row_of "$K")" ] || { bad "không có $K"; exit 1; }
  KF="$(ketqua_dir "$ROOT")/$K.txt"
  [ -f "$KF" ] || { bad "$K chưa có KETQUA ($KF) — agent chưa ghi thì không 'xong'; thời gian trôi không phải bằng chứng"; exit 1; }
  LAST="$(tail -1 "$KF")"; KET="$(printf '%s' "$LAST" | grep -oE 'ket=[a-z]+' | cut -d= -f2)"; NEO="$(printf '%s' "$LAST" | grep -oE 'neo=[^ ]+' | cut -d= -f2)"
  [ "$KET" = xong ] || { bad "KETQUA mới nhất của $K là ket=$KET, không phải xong: $LAST"; exit 1; }
  [ -n "$NEO" ] && [ "$NEO" != "-" ] || { bad "KETQUA xong mà không có neo — xong không neo là đỏ"; exit 1; }
  set_row "$K" "trangthai=$W_DONE" "neo=$NEO"
  commit_q "$K xong ($NEO)"; ok "$K → xong · neo $NEO"
  ;;
stop)
  need_q; need_main; K="$2"; NAME="$3"; shift 3 2>/dev/null; valid_key "$K"
  [ -n "$NAME" ] || { echo "dùng: queue.sh stop <khoá> <tên dừng> [lý do]" >&2; exit 2; }
  [ -n "$(row_of "$K")" ] || { bad "không có $K"; exit 1; }
  UY="$ROOT/notes/uy-quyen.md"
  if [ -f "$UY" ]; then grep -qE "^\| *$NAME *\|" "$UY" || warn "tên dừng '$NAME' chưa khai ở notes/uy-quyen.md ## Điểm dừng — status.sh sẽ đỏ"
  else warn "chưa có notes/uy-quyen.md — không kiểm được tên dừng"; fi
  set_row "$K" "trangthai=$W_STOP-$NAME" "ghichu=$*"
  commit_q "$K DỪNG-$NAME"; ok "$K → DỪNG-$NAME"
  ;;
list) need_q; qtext | sed -nE "/$(kwh work)/,\$p";;
board)
  need_q; QH="${3:-90}"; [ "$2" = --qua-han ] || QH=90
  NOW="$(date +%s)"; KD="$(ketqua_dir "$ROOT")"
  echo "Bảng giao việc — $(date +%Y-%m-%d\ %H:%M) · $(rows | grep -c .) việc"
  for l in $(lanes | cut -d'|' -f1); do printf '  làn %-6s %s/%s đang\n' "$l" "$(lane_busy "$l")" "$(lane_cap "$l")"; done
  echo "── đang"
  rows | awk -F'|' -v re="^($K_ACT)\$" '$5 ~ re' | while IFS='|' read -r k l v c s n g; do
    who="$(printf '%s' "$g" | grep -oE "($K_HELD):[^@ ]*" | cut -d: -f2)"; t="$(printf '%s' "$g" | grep -oE '@[0-9T:-]+' | tr -d '@')"
    age=""; if [ -n "$t" ]; then ts="$(date -j -f '%Y-%m-%dT%H:%M' "$t" +%s 2>/dev/null || date -d "$t" +%s 2>/dev/null)"; [ -n "$ts" ] && age=$(( (NOW - ts) / 60 )); fi
    flag=""; if [ -f "$KD/$k.txt" ]; then
      case "$(tail -1 "$KD/$k.txt")" in *ket=xong*) flag="✓ có KETQUA xong — queue.sh done $k";; *ket=chan*) flag="✗ KETQUA chặn: $(tail -1 "$KD/$k.txt" | grep -oE 'hoi=[^ ]+')";; *) flag="KETQUA: $(tail -1 "$KD/$k.txt" | grep -oE 'ket=[^ ]+')";; esac
    elif [ -n "$age" ] && [ "$age" -gt "$QH" ]; then flag="nghi-chết (${age} phút, chưa KETQUA) — đi nhìn, không tự đổi trạng thái"; fi
    printf '  %-24s vai %-3s giữ %-10s %6s phút  %s\n' "$k" "$v" "${who:-?}" "${age:--}" "$flag"
  done
  echo "── sẵn sàng (next)"; ready_list | while IFS='|' read -r k l v g; do printf '  %-24s làn %-6s vai %s\n' "$k" "$l" "$v"; done
  echo "── chờ phụ thuộc / làn đầy"
  rows | awk -F'|' -v re="^($K_WAIT)\$" '$5 ~ re' | while IFS='|' read -r k l v c s n g; do printf '%s\n' "$(ready_list)" | grep -q "^$k|" || printf '  %-24s cần %s\n' "$k" "$c"; done
  echo "── dừng"; rows | awk -F'|' -v re="^($K_STOP)-" '$5 ~ re' | while IFS='|' read -r k l v c s n g; do printf '  %-24s %s — %s\n' "$k" "$s" "$g"; done
  # xong không neo là đỏ — không dùng pipe | while: bad trong subshell không đếm được FAIL
  NX="$(rows | awk -F'|' -v re="^($K_DONE)\$" '$5 ~ re && ($6=="" || $6=="-") {print $1}')"
  for k in $NX; do bad "$k xong mà Neo trống — xong không neo là đỏ"; done
  [ "$FAIL" -gt 0 ] && exit 1; exit 0
  ;;
*) sed -n '3,10p' "$0" | sed 's/^# \{0,3\}//'; exit 2;;
esac
