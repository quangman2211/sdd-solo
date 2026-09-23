#!/usr/bin/env bash
# role.sh — vai của đội agent (7.2). Cơ chế ở plugin; chính sách (có vai nào, ghi đâu) ở .sdd/roles của dự án.
#
#   role.sh <vai>                       đặt dấu vai cho WORKTREE này (.git[/worktrees/<tên>]/sdd-role) và in hợp đồng
#   role.sh --xem                       vai hiện tại (SDD_ROLE → dấu worktree → mẫu nhánh) + vùng ghi/cấm
#   role.sh --worktree <vai> [UC-###]   dựng worktree riêng cho vai trên nhánh theo <V>.nhanh, đặt dấu, nhắc merge main
#   role.sh <vai> <file phiếu> [--luot N]   in LỜI GIAO SÁU PHẦN từ một phiếu — không nhận chuỗi tự do
#   role.sh --ketqua <khoá> ket=xong|chan|do neo=<hash|marker|file> [kiem=…] [hoi=…] [con=…]
#                                       ghi một dòng KETQUA vào $(git-common-dir)/sdd-ketqua/<khoá>.txt — chung mọi worktree
#   role.sh --ketqua <khoá>             đọc
#   role.sh --staged                    kiểm file đang stage theo vai hiện tại (githook gọi qua --commit)
#   role.sh --commit <file msg>         như --staged, thêm suy vai từ đuôi `Vai: <V>` và ghi đuôi vào message
#   role.sh --kiem-lich-su <range>      chỉ đọc: chạy luật vùng ghi qua lịch sử, đếm commit không vai nào được ghi đủ
#
# Vì sao dấu vai theo worktree: ba agent spec và ba agent soi chạy song song trên một checkout đã cuốn file của nhau
# hai lần một ngày (P-29) và trùng số phiếu bốn lần (P-21). Nhánh không đủ: vai spec/soi/trọng tài cùng ở main.
# `git rev-parse --git-path sdd-role` trả đường riêng từng worktree, không vào git, không theo nhánh.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
usage() { sed -n '3,14p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
[ $# -eq 0 ] && usage
RF="$(roles_file "$ROOT")"

need_roles() { [ -n "$RF" ] || { bad "chưa có .sdd/roles — chép khuôn: /sdd-solo:init --update (7.2) rồi sửa vai cho đúng repo"; exit 1; }; }
check_role() { role_known "$1" "$ROOT" || { bad "vai '$1' không có trong .sdd/roles (vai=$(role_list "$ROOT"))"; exit 1; }; }
contract() { # in hợp đồng vai
  local v="$1"
  printf 'Vai %s · %s\n' "$v" "$(role_name "$v" "$ROOT")"
  printf '  được ghi: %s\n' "$(role_paths "$v" "$ROOT")"
  printf '  KHÔNG ghi: %s\n' "$(role_deny "$v" "$ROOT")"
  [ -n "$(role_branch "$v" "$ROOT")" ] && printf '  nhánh: %s\n' "$(role_branch "$v" "$ROOT")"
  role_may_commit "$v" "$ROOT" && printf '  commit: có — <type>(ID) kê đích danh file, đuôi Vai: %s\n' "$v" || printf '  commit: KHÔNG — A commit thay\n'
  [ -n "$(role_checks "$v" "$ROOT")" ] && printf '  kiểm trước commit: %s\n' "$(role_checks "$v" "$ROOT")"
}
# kiểm danh sách file theo vai → in ✗ từng file; trả 1 nếu có vi phạm
check_files() { # check_files <vai> <danh sách file, mỗi dòng một>
  local v="$1" f bad=0 who
  role_may_commit "$v" "$ROOT" || { bad "vai $v không được commit (.sdd/roles: $v.commit=khong) — A commit thay"; bad=1; }
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    role_allows "$v" "$f" "$ROOT" && continue
    who="$(role_of_path "$f" "$ROOT")"
    if [ -n "$who" ]; then bad "$f — chỗ này của vai $who, không của $v. Ghi HỎI/phiếu, vai kia sửa lượt kế"
    else bad "$f — không vai nào trong .sdd/roles được ghi chỗ này"; fi
    bad=1
  done
  return $bad
}

case "$1" in
--xem)
  need_roles
  V="$(role_current "$ROOT")"
  if [ -z "$V" ]; then info "chưa suy được vai (không SDD_ROLE, không dấu worktree, nhánh không khớp mẫu nào). Đặt: role.sh <vai>"; exit 0; fi
  contract "$V"
  M="$(role_marker_file "$ROOT")"; [ -f "$M" ] && info "dấu vai: ${M#$ROOT/}"
  ;;
--worktree)
  need_roles; V="$2"; U="$3"; [ -n "$V" ] || usage; check_role "$V"
  P="$(role_branch "$V" "$ROOT")"
  [ -n "$P" ] || { bad "vai $V không có mẫu nhánh ($V.nhanh trống) — vai này làm ở checkout chính (spec giữ main để cái nó viết là sự thật chung, các vai khác đọc được ngay)"; exit 1; }
  case "$P" in
    *\**) [ -n "$U" ] || { bad "mẫu nhánh $P cần UC-###: role.sh --worktree $V UC-###"; exit 1; }
          BR="$(printf '%s' "$P" | sed "s#\*#$(printf '%s' "$U" | tr 'A-Z' 'a-z')#")";;
    *) BR="$P";;
  esac
  D="$(dirname "$ROOT")/$(basename "$ROOT")-$(printf '%s' "$V" | tr 'A-Z' 'a-z')${U:+-$(printf '%s' "$U" | tr 'A-Z' 'a-z')}"
  [ -e "$D" ] && { bad "đã có $D"; exit 1; }
  if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BR"; then git -C "$ROOT" worktree add -q "$D" "$BR" || exit 1
  else git -C "$ROOT" worktree add -q -b "$BR" "$D" || exit 1; fi
  printf '%s\n' "$V" > "$(role_marker_file "$D")"
  ok "worktree $D · nhánh $BR · dấu vai $V"
  info "hook trong worktree là bản của nhánh lúc tách — mở lượt bằng: git -C $D merge main"
  info "commit ở đó: git commit --only -m '<type>(ID): …' -- <file> ; hook thêm đuôi 'Vai: $V'"
  ;;
--ketqua)
  K="$2"; shift 2
  printf '%s' "$K" | grep -qE '^[a-z0-9][a-z0-9._-]{1,39}$' || { bad "khoá '$K' — chỉ [a-z0-9][a-z0-9._-]{1,39}, không dấu cách, không |"; exit 2; }
  KD="$(ketqua_dir "$ROOT")"; KF="$KD/$K.txt"
  if [ $# -eq 0 ]; then [ -f "$KF" ] && cat "$KF" || { info "chưa có KETQUA cho $K ($KF)"; exit 1; }; exit 0; fi
  KET=""; NEO=""; KIEM="-"; HOI="-"; CON="-"
  for a in "$@"; do case "$a" in ket=*) KET="${a#ket=}";; neo=*) NEO="${a#neo=}";; kiem=*) KIEM="${a#kiem=}";; hoi=*) HOI="${a#hoi=}";; con=*) CON="${a#con=}";; *) bad "không hiểu '$a' (ket= neo= kiem= hoi= con=)"; exit 2;; esac; done
  case "$KET" in xong|chan|do) ;; *) bad "ket= phải là xong · chan · do (được '$KET')"; exit 1;; esac
  if [ "$KET" = xong ]; then
    [ -n "$NEO" ] && [ "$NEO" != "-" ] || { bad "ket=xong bắt buộc có neo= (hash commit · marker .sdd/gate/… · đường dẫn file) — thời gian trôi không phải bằng chứng"; exit 1; }
    if printf '%s' "$NEO" | grep -qE '^[0-9a-f]{7,40}$'; then
      git -C "$ROOT" cat-file -e "$NEO^{commit}" 2>/dev/null || { bad "neo=$NEO không phải commit có thật trong repo"; exit 1; }
    elif [ ! -e "$ROOT/$NEO" ]; then bad "neo=$NEO — không phải hash và không có file/marker đó ở $ROOT"; exit 1; fi
  fi
  [ "$KET" = chan ] && { [ -n "$HOI" ] && [ "$HOI" != "-" ] || { bad "ket=chan bắt buộc có hoi=<số phiếu | HỎI-X#> — chặn mà không có câu hỏi thì không ai gỡ được"; exit 1; }; }
  mkdir -p "$KD"
  L="KETQUA key=$K ket=$KET neo=${NEO:--} kiem=$KIEM hoi=$HOI con=$CON vai=$(role_current "$ROOT" | tr -d ' ') luc=$(date +%Y-%m-%dT%H:%M)"
  printf '%s\n' "$L" >> "$KF"
  printf '%s\n' "$L"
  info "đã ghi ${KF} — gửi đúng dòng trên về điều phối (dòng đầu tin nhắn)"
  ;;
--staged|--commit)
  [ -n "$RF" ] || exit 0
  [ -f "$(cd "$ROOT" && git rev-parse --git-path MERGE_HEAD)" ] && exit 0
  V="$SDD_ROLE"
  if [ -z "$V" ] && [ "$1" = --commit ] && [ -f "$2" ]; then V="$(grep -E "^($(kw c_role)): *[A-Za-z0-9_-]+ *\$" "$2" | head -1 | sed -E "s/^($(kw c_role)): *//; s/ *\$//")"; fi
  [ -z "$V" ] && V="$(role_current "$ROOT")"
  REQ="$(role_required "$ROOT")"
  if [ -z "$V" ]; then
    [ "$REQ" = moi ] && { bad "không suy được vai (vai_bat_buoc=moi): đặt SDD_ROLE, đuôi 'Vai: <V>' trong message, dấu worktree (role.sh <vai>) hay nhánh theo mẫu"; exit 1; }
    exit 0
  fi
  role_known "$V" "$ROOT" || { bad "vai '$V' không có trong .sdd/roles (vai=$(role_list "$ROOT"))"; [ "$REQ" != khong ] && exit 1; exit 0; }
  ST="${SDD_STAGED:-$(cd "$ROOT" && git diff --cached --name-only)}"
  if ! check_files "$V" <<EOS
$ST
EOS
  then
    if [ "$REQ" != khong ]; then bad "vai $V: commit chạm ngoài vùng ghi — chặn (vai_bat_buoc=$REQ)"; exit 1
    else warn "vai $V: commit chạm ngoài vùng ghi — chỉ nhắc (vai_bat_buoc=khong; bật chặn: vai_bat_buoc=nhanh-vai trong .sdd/roles)"; fi
  fi
  # đuôi Vai: — kênh duy nhất git ghi lại được; `git log --grep '^Vai: '` đo mức tuân thủ
  if [ "$1" = --commit ] && [ -f "$2" ] && ! grep -qE "^($(kw c_role)): " "$2"; then printf '\n%s: %s\n' "$(kw_w c_role "$ROOT")" "$V" >> "$2"; fi
  exit 0
  ;;
--kiem-lich-su)
  need_roles; RANGE="${2:-HEAD~300..HEAD}"
  N=0; NONE=0; VIO=0; LIST=""
  # đuôi vai đọc CẢ HAI vế (kw c_role) — git chỉ nhận một khoá mỗi %(trailers:key=…), nên một atom mỗi vế,
  # và giá trị ra sau tiền tố ASCII '##' để phân biệt với dòng tên file của --name-only
  TFMT=""; for k in $(kw c_role | tr '|' ' '); do TFMT="$TFMT%(trailers:key=$k,valueonly=true)"; done
  # mỗi commit không-merge: file chạm + đuôi Vai nếu có → vai nào được ghi ĐỦ mọi file
  while IFS= read -r line; do
    case "$line" in
      @@*) 
        if [ -n "$H" ]; then
          N=$((N+1)); OKR=""
          for v in $(role_list "$ROOT"); do
            allok=1; for f in $FILES; do role_allows "$v" "$f" "$ROOT" || { allok=0; break; }; done
            [ "$allok" = 1 ] && OKR="$OKR $v"
          done
          [ -z "$OKR" ] && { NONE=$((NONE+1)); LIST="$LIST
  $H $S"; }
          if [ -n "$TV" ]; then case " $OKR " in *" $TV "*) ;; *) VIO=$((VIO+1)); LIST="$LIST
  $H $S — khai Vai: $TV nhưng vai đó không được ghi đủ";; esac; fi
        fi
        H="$(printf '%s' "$line" | cut -c3-9)"; S="$(printf '%s' "$line" | cut -c11- | cut -c1-70)"; TV=""; FILES="";;
      "##"*) TV="${line#\#\#}";;
      "") ;;
      *) FILES="$FILES $line";;
    esac
  done <<EOS
$(git -C "$ROOT" log --no-merges --format="@@%h %s%n##$TFMT" --name-only $RANGE 2>/dev/null)
@@
EOS
  echo "Luật vùng ghi của .sdd/roles chạy qua $N commit ($RANGE)"
  printf '  %s commit không vai nào được ghi đủ mọi file (lẽ ra bị chặn nếu vai_bat_buoc bật)\n' "$NONE"
  printf '  %s commit khai đuôi Vai: mà vai đó không được ghi đủ\n' "$VIO"
  [ -n "$LIST" ] && printf '%s\n' "$LIST" | head -40
  exit 0
  ;;
--*) usage;;
*)
  need_roles; V="$1"; check_role "$V"
  if [ -z "$2" ]; then
    M="$(role_marker_file "$ROOT")"; printf '%s\n' "$V" > "$M"
    ok "dấu vai $V cho worktree $ROOT (${M#$ROOT/} — không vào git)"
    contract "$V"; exit 0
  fi
  # ── lời giao sáu phần từ một phiếu ────────────────────────────────────────────────────────────
  PF="$2"; LUOT="1"; shift 2
  while [ $# -gt 0 ]; do case "$1" in --luot) LUOT="$2"; shift 2;; *) shift;; esac; done
  [ -f "$PF" ] || { bad "role.sh <vai> nhận MỘT FILE PHIẾU, không nhận chuỗi tự do — phần đắt của lời giao là neo, mà neo chỉ có trong phiếu ('$PF' không phải file)"; exit 1; }
  export SDD_V="$V" SDD_VN="$(role_name "$V" "$ROOT")" SDD_DENY="$(role_deny "$V" "$ROOT")" SDD_CHECKS="$(role_checks "$V" "$ROOT")" SDD_BRANCH="$(role_branch "$V" "$ROOT")" SDD_LUOT="$LUOT" SDD_ROOT="$ROOT"
  # gói đọc: mọi ID trong dòng đầu phiếu → đường dẫn qua lib (không find/grep thẳng specs/)
  HDR="$(grep -m1 -E '^###? *#[0-9]+' "$PF")"
  PK=""
  for id in $(printf '%s' "$HDR" | grep -oE '\b(UC|BR|CHG|RULE|ADR)-[0-9]+\b' | sort -u); do
    case "$id" in
      UC-*)  f="$(find_uc "$id" "$ROOT")"; [ -n "$f" ] && { PK="$PK ${f#$ROOT/}"; [ -f "$(dirname "$f")/design.md" ] && PK="$PK $(dirname "${f#$ROOT/}")/design.md"; };;
      BR-*)  f="$(br_file "$id" "$ROOT")"; [ -f "$f" ] && PK="$PK ${f#$ROOT/}";;
      CHG-*) d="$(find_chg "$id" "$ROOT")"; [ -n "$d" ] && PK="$PK ${d#$ROOT/}/proposal.md";;
      RULE-*) f="$(rule_file "$id" "$ROOT")"; [ -n "$f" ] && PK="$PK ${f#$ROOT/}:## $id";;
      ADR-*) f="$(adr_file "$id" "$ROOT")"; [ -n "$f" ] && PK="$PK ${f#$ROOT/}";;
    esac
  done
  export SDD_PK="$PK"
  node "$HERE/js/brief.mjs" "$PF"
  ;;
esac
