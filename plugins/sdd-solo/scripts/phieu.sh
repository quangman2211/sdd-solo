#!/usr/bin/env bash
# phieu.sh — phiếu hỏi đáp có KHOÁ SỐ (7.2). Mỗi phiếu một file notes/hoi-dap/phieu/NNN-<slug>.md + một dòng mục lục
# trong notes/hoi-dap/hoi-dap.md (6.x: specs/internal/hoi-dap.md).
#
#   phieu.sh new "<việc>" <từ-vai> [slug]   giữ số kế tiếp (khoá mkdir ở git-common-dir, chung mọi worktree; số = max của
#                                          mục lục ∪ tên file ∪ `git log --all` "phiếu #n"), tạo file theo khuôn, thêm dòng
#                                          mục lục, COMMIT NGAY dòng giữ chỗ (--only) rồi mới trả về. Viết thân sau.
#   phieu.sh close <n>                     đếm lại F#/K# TRÊN FILE, so với số phiếu tự khai; mỗi vai trong Cho: phải có
#                                          KETQUA ket=xong (role.sh --ketqua); đủ thì mục lục → "đã áp", commit
#   phieu.sh muc-luc                       soát: số trùng · số nhảy · file không có dòng · dòng không có file. exit 1 nếu có
#   phieu.sh list [--mo]                   in mục lục; --mo: phiếu chưa "đã áp"/"đóng"
#
# Vì sao: runxops trùng số phiếu BỐN lần trong một ngày (P-21) — chọn số lúc bắt đầu viết, tạo file lúc viết xong, khoảng
# giữa đủ cho vai khác lấy mất số. Đóng phiếu chép TỔNG của R thay vì đếm trên file → đuôi phiếu rơi (P-33).
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
CMD="${1:-}"; [ -z "$CMD" ] && { sed -n '3,12p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
HD="$(hoi_dap_file "$ROOT")"; PD="$(dirname "$HD")/phieu"
rel() { printf '%s' "${1#$ROOT/}"; }

ensure_hd() {
  [ -f "$HD" ] && return 0
  local sk; sk="$(plugin_file templates/skel/hoi-dap.md "$(dirname "$HERE")")"
  mkdir -p "$(dirname "$HD")"
  if [ -n "$sk" ]; then cp "$sk" "$HD"; else printf '# Hỏi đáp giữa các agent\n\n## Phiếu\n' > "$HD"; fi
  grep -q '^| # | Việc |' "$HD" || printf '\n| # | Việc | Từ | Ngày | Trạng thái | File |\n|---|---|---|---|---|---|\n' >> "$HD"
  ok "tạo $(rel "$HD") từ khuôn"
}
# số lớn nhất đang có — ba nguồn, để an toàn giữa các worktree chưa merge
max_n() {
  { grep -oE '^\| *#[0-9]+' "$HD" 2>/dev/null | grep -oE '[0-9]+'
    ls "$PD" 2>/dev/null | grep -oE '^[0-9]+'
    git -C "$ROOT" log --all --format=%s 2>/dev/null | grep -oiE 'phi[eế]u #[0-9]+' | grep -oE '[0-9]+'
  } | sort -n | tail -1
}
slugify() { python3 -c 'import sys,unicodedata,re
s=sys.argv[1].replace("đ","d").replace("Đ","D")
s=unicodedata.normalize("NFD",s); s="".join(c for c in s if not unicodedata.combining(c))
print(re.sub(r"-+","-",re.sub(r"[^a-z0-9]","-",s.lower())).strip("-")[:40])' "$1"; }
find_pf() { ls "$PD"/"$(printf '%03d' "$1")"-*.md 2>/dev/null | head -1; }

case "$CMD" in
new)
  VIEC="$2"; TU="$3"; SL="$4"
  [ -n "$VIEC" ] && [ -n "$TU" ] || { echo "dùng: phieu.sh new \"<việc>\" <từ-vai> [slug]" >&2; exit 2; }
  ensure_hd; mkdir -p "$PD"
  lock_take phieu "$ROOT" || { bad "không lấy được khoá $(lock_dir "$ROOT")/phieu sau 10 s — ai đó đang cấp số; thử lại"; exit 1; }
  N=$(( $(max_n | awk '{print $1+0}') + 1 )); NNN="$(printf '%03d' "$N")"
  [ -z "$SL" ] && SL="$(slugify "$VIEC")"; [ -z "$SL" ] && SL="phieu"
  F="$PD/$NNN-$SL.md"; TD="$(today)"
  { printf '### #%s · từ: %s · việc: %s · %s\n' "$N" "$TU" "$VIEC" "$TD"
    printf 'Câu: <một câu>\nĐã tra: <file:dòng, …>\nNếu chọn sai thì: <hậu quả>\nAgent nghiêng về: <lựa chọn + vì sao>\n\n'
    printf '**Trả lời (R):** <mức L0–L3> · <câu trả lời>\nNguồn / lý do: <file:dòng hoặc lý do>\nCho: <mỗi vai một dòng: - **B:** … · - **D:** … · - **T:** …>\nDuyệt:\n'; } > "$F"
  ROW="| #$N | $VIEC | $TU | $TD | mở | [$NNN-$SL.md](phieu/$NNN-$SL.md) |"
  python3 - "$HD" "$ROW" <<'PY'
import sys, io, re
p, row = sys.argv[1:3]; s = io.open(p, encoding='utf-8').read()
rows = list(re.finditer(r'(?m)^\| *#\d+ \|.*$', s))
if rows: i = rows[-1].end(); s = s[:i] + '\n' + row + s[i:]
elif '| # | Việc |' in s:
    m = re.search(r'(?m)^\|---\|.*$', s[s.index('| # | Việc |'):]); i = s.index('| # | Việc |') + m.end(); s = s[:i] + '\n' + row + s[i:]
else: s = s.rstrip('\n') + '\n\n| # | Việc | Từ | Ngày | Trạng thái | File |\n|---|---|---|---|---|---|\n' + row + '\n'
io.open(p, 'w', encoding='utf-8').write(s)
PY
  git -C "$ROOT" add "$F" "$HD" 2>/dev/null
  git -C "$ROOT" commit -q --only -m "chore(sdd): phiếu #$N giữ chỗ — $VIEC" -- "$F" "$HD" 2>/dev/null \
    || warn "chưa commit được dòng giữ chỗ (hook chặn hay repo không có git?) — số $N vẫn đã ghi vào file và mục lục"
  lock_drop phieu "$ROOT"
  printf '#%s %s\n' "$N" "$(rel "$F")"
  info "số đã giữ và đã commit. Viết thân phiếu, rồi commit riêng: git commit --only -m 'chore(sdd): phiếu #$N — <việc>' -- $(rel "$F")"
  ;;
close)
  N="$2"; [ -n "$N" ] || { echo "dùng: phieu.sh close <n>" >&2; exit 2; }
  N="${N#\#}"; F="$(find_pf "$N")"; [ -f "$F" ] || { bad "không có file phiếu #$N trong $(rel "$PD")/"; exit 1; }
  echo "Đóng phiếu #$N — $(rel "$F")"
  NF="$(grep -cE '^(- |\| *)F[0-9]+\b' "$F")"; NK="$(grep -cE '^(- |\| *)K[0-9]+\b' "$F")"
  info "trên file: $NF dòng F# · $NK dòng K#"
  ROW="$(grep -E "^\| *#$N \|" "$HD" | head -1)"
  CLAIM="$(printf '%s\n%s' "$ROW" "$(head -5 "$F")" | grep -oE '[0-9]+ (phát hiện|K\b|câu)' | head -1 | grep -oE '^[0-9]+')"
  if [ -n "$CLAIM" ]; then
    GOT="$NF"; [ "$NK" -gt "$NF" ] && GOT="$NK"
    if [ "$CLAIM" = "$GOT" ]; then ok "số tự khai $CLAIM khớp số đếm trên file"
    else
      bad "phiếu tự khai $CLAIM mục nhưng trên file đếm được $GOT — đếm trên FILE mới là sự thật (P-33)"
      printf '%s\n' "$(grep -oE '^(- |\| *)[FK][0-9]+' "$F" | grep -oE '[0-9]+' | sort -n | awk 'NR>1 && $1!=p+1 {for(i=p+1;i<$1;i++) printf "      thiếu #%d\n", i} {p=$1}')"
    fi
  fi
  # mỗi vai có việc trong Cho: → cần KETQUA ket=xong
  ID="$(grep -m1 -E '^###? *#' "$F" | grep -oE '\b(UC|BR|CHG)-[0-9]+\b' | head -1 | tr 'A-Z' 'a-z')"
  MISS=0
  for v in $(sed -n '/^Cho:/,/^Duyệt:/p' "$F" | grep -oE '^- \*\*[A-Z]( ?[·,] ?[A-Z])*' | sed 's/^- \*\*//' | tr '·,' '  '); do
    sed -n '/^Cho:/,/^Duyệt:/p' "$F" | grep -E "^- \*\*([^*]*[ ·,/])?$v([ ·,/:(]|$)" | grep -qi 'không có việc' && continue
    role_known "$v" "$ROOT" 2>/dev/null || [ -z "$(roles_file "$ROOT")" ] || continue
    k="$(ls "$(ketqua_dir "$ROOT")"/"$(printf '%s' "$v" | tr 'A-Z' 'a-z')-${ID:-*}-p$N"*.txt 2>/dev/null | head -1)"
    if [ -n "$k" ] && grep -q 'ket=xong' "$k"; then ok "vai $v có KETQUA xong ($(basename "$k"))"
    else bad "vai $v có việc trong Cho: nhưng chưa có KETQUA ket=xong (role.sh --ketqua $(printf '%s' "$v" | tr 'A-Z' 'a-z')-${ID:-<id>}-p$N …)"; MISS=1; fi
  done
  if [ "$FAIL" -eq 0 ]; then
    python3 - "$HD" "$N" <<'PY'
import sys, io, re
p, n = sys.argv[1:3]; s = io.open(p, encoding='utf-8').read()
s2 = re.sub(r'(?m)^(\| *#' + n + r' \|(?:[^|]*\|){3}) *[^|]* *(\|)', r'\1 đã áp \2', s, count=1)
io.open(p, 'w', encoding='utf-8').write(s2)
PY
    git -C "$ROOT" commit -q --only -m "chore(sdd): phiếu #$N đã áp — $NF F# · $NK K# đếm trên file" -- "$HD" 2>/dev/null || true
    echo "ĐÃ ĐÓNG #$N — mục lục → đã áp."
  else
    echo "CHƯA ĐÓNG — $FAIL lỗi."; exit 1
  fi
  ;;
muc-luc)
  [ -f "$HD" ] || { info "chưa có $(rel "$HD")"; exit 0; }
  echo "Mục lục phiếu — $(rel "$HD") · $(rel "$PD")/"
  IDX="$(grep -oE '^\| *#[0-9]+' "$HD" | grep -oE '[0-9]+' | sort -n)"
  FIL="$(ls "$PD" 2>/dev/null | grep -oE '^[0-9]+' | sed 's/^0*//' | sort -n)"
  D1="$(printf '%s\n' "$IDX" | uniq -d | tr '\n' ' ')"; [ -n "$D1" ] && bad "số trùng trong mục lục: $D1"
  D2="$(printf '%s\n' "$FIL" | uniq -d | tr '\n' ' ')"; [ -n "$D2" ] && bad "hai file cùng số: $D2"
  G="$(printf '%s\n' "$IDX" | awk 'NR>1 && $1!=p+1 {for(i=p+1;i<$1;i++) printf "%d ", i} {p=$1}')"; [ -n "$G" ] && warn "số nhảy trong mục lục: $G"
  NOF="$(comm -23 <(printf '%s\n' "$IDX" | sort -u) <(printf '%s\n' "$FIL" | sort -u) | tr '\n' ' ')"; [ -n "$NOF" ] && bad "dòng mục lục không có file: #$(printf '%s' "$NOF" | sed 's/ /  #/g')"
  NOR="$(comm -13 <(printf '%s\n' "$IDX" | sort -u) <(printf '%s\n' "$FIL" | sort -u) | tr '\n' ' ')"; [ -n "$NOR" ] && bad "file không có dòng mục lục: $NOR"
  printf '  %s dòng mục lục · %s file · số lớn nhất %s\n' "$(printf '%s\n' "$IDX" | grep -c .)" "$(printf '%s\n' "$FIL" | grep -c .)" "$(max_n)"
  [ "$FAIL" -eq 0 ] && { ok "mục lục và file khớp"; exit 0; } || exit 1
  ;;
list)
  [ -f "$HD" ] || { info "chưa có $(rel "$HD")"; exit 0; }
  if [ "$2" = --mo ]; then grep -E '^\| *#[0-9]+ \|' "$HD" | grep -vE '\| *(đã áp|đóng) *\|[^|]*\| *$'
  else grep -E '^\| *#[0-9]+ \|' "$HD"; fi | cut -c1-160
  ;;
*) sed -n '3,12p' "$0" | sed 's/^# \{0,3\}//'; exit 2;;
esac
