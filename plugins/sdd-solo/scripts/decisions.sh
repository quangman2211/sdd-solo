#!/usr/bin/env bash
# decisions.sh [--md] — sổ tra MỌI quyết định của dự án, xếp theo thời gian.
#
# Vì sao có file này. Bộ tài liệu chứa 7 loại quyết định ở 6 chỗ với 4 khuôn khác
# nhau (CON trong br.md · RULE trong rules.md · ADR trong internal/adr/ · Cấm trong
# architecture.md · CHG trong changes/ · dòng một câu trong internal/decisions.md).
# Mỗi khuôn đọc riêng thì hợp lý; hợp lại thì không ai nắm được dự án này đã quyết
# những gì. Đó là câu hỏi phải trả lời được sau 5–10 năm, không phải sau một sprint.
#
# XẾP THEO THỜI GIAN là chủ ý, không phải cho đẹp. Ca thật (runxops): hai điều cấm
# viết ở hai thời điểm, cái sau ngặt hơn và nuốt luôn thứ In Scope đang cho phép.
# Đọc rời từng file thì cả hai đều trôi chảy. Xếp chung một dòng thời gian thì hai
# dòng nói cùng một chuyện với hai ngày khác nhau tự nằm cạnh nhau — mắt người bắt
# được ngay thứ mà không phép kiểm cơ học nào bắt được.
#
# KHÔNG GHI FILE (trừ khi --md và người dùng tự hứng ra). Một sổ tra sinh ra rồi
# commit là một bản sao sẽ trôi khỏi nguồn, và trôi thì lại đúng lớp "báo xanh sai"
# mà cả 3.x đi chữa. Sổ này phải luôn được đọc từ nguồn, tại thời điểm đọc.
#
# 4.2.0: script này CHỈ ĐỌC và luôn exit 0. Nó không phải cổng. Cổng cứng
# (decision-check.sh) để bản sau, sau khi anh đã nhìn bảng này và điền xong — bật
# cổng khi hàng chục dòng còn thiếu ngày thì chỉ dạy được người ta cách phớt lờ nó.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
MD=0; [ "${1:-}" = "--md" ] && MD=1
TODAY="$(today)"

REC="$(mktemp)"; trap 'rm -f "$REC"' EXIT

# Mỗi bản ghi một dòng, ngăn bằng TAB:
#   ngày <TAB> ID <TAB> loại <TAB> phát biểu <TAB> trạng thái <TAB> kiểm lại
# Ngày trống → "0000-00-00", để sort đẩy lên đầu rồi tách ra khối riêng lúc in.
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
function nodate(d) { return (d ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) ? d : "0000-00-00" }
# ghost(): dòng còn là KHUÔN, chưa phải quyết định. Bỏ nó đi là bắt buộc, không
# phải cho gọn — một sổ tra liệt kê chính lời giảng trong khuôn thành "quyết định
# của dự án" thì tệ hơn không có sổ, vì nó dạy người đọc rằng sổ này không đáng tin.
# `<...>` phải có dấu đóng mới tính, nên "response < 200ms" không bị bắt oan.
function ghost(s) {
  if (s == "") return 1
  if (s ~ /^[ \t]*(\.\.\.|_+)[ \t]*$/) return 1
  if (s ~ /<[^>]*>/) return 1
  return 0
}
'

# strip_markup TRƯỚC mọi thứ. Khuôn nào cũng có khối <!-- … --> dạy cách dùng, và
# những khối đó nhắc CON-002 / ADR-001 / BR-001 làm ví dụ. Không lột thì sổ tra
# đọc chính lời giảng thành quyết định. (Cùng bẫy đã dính ở design-check 4.0.x.)

# ── CON-### : specs/br.md ───────────────────────────────────────────────────
[ -f "$ROOT/specs/br.md" ] && strip_markup < "$ROOT/specs/br.md" | awk -v T="$TAB" "$FLD"'
function flush() { if (cur != "" && !ghost(stmt)) print d T cur T "ràng buộc" T stmt T stt T rc; cur = "" }
# BR-000 là BR MẪU của template và nó Ở LẠI VĨNH VIỄN: `/sdd-solo:intake` dặn thẳng
# "Giữ nguyên BR-000 mẫu", `br-check.sh:11` bỏ qua nó vì cùng lý do. Không bỏ ở đây
# thì ba CON dạy-việc của nó nằm trong sổ tra của MỌI dự án, mãi mãi — và chúng
# không phải placeholder, chúng đọc y như quyết định thật (hosting, luật kế toán).
# Đó đúng là "sổ tra có mục ma", thứ tệ hơn không có sổ. Cùng một luật với br-check,
# giữ ở hai nơi vì hai script không dùng chung vòng quét br.md.
/^# BR-/ { flush(); inbr0 = ($0 ~ /^# BR-000([^0-9]|$)/) ? 1 : 0; next }
/^- \*\*CON-[0-9]+/ {
  flush()
  if (inbr0) next
  match($0, /CON-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
  stmt = $0; sub(/^-[ ]*\*\*CON-[0-9]+[^:]*:\*\*[ ]*/, "", stmt)
  d = "0000-00-00"; stt = ""; rc = ""
  next
}
cur != "" && /^[ \t]+- Từ:/ {
  d = nodate(fld($0, "Từ:")); stt = fld($0, "Trạng thái:"); rc = fld($0, "Kiểm lại:"); next
}
END { flush() }
' >> "$REC"

# ── RULE-### : specs/rules.md ───────────────────────────────────────────────
[ -f "$ROOT/specs/rules.md" ] && strip_markup < "$ROOT/specs/rules.md" | awk -v T="$TAB" "$FLD"'
function flush() { if (cur != "" && !ghost(stmt)) print d T cur T "luật" T stmt T stt T ""; cur = "" }
/^## RULE-/ {
  flush()
  match($0, /RULE-[0-9a-z]+/); cur = substr($0, RSTART, RLENGTH)
  stmt = $0; sub(/^## RULE-[0-9a-z]+:[ ]*/, "", stmt)
  d = "0000-00-00"; stt = ""
  next
}
/^## / { flush(); next }
cur != "" && /\*\*Phát biểu:\*\*/ { s = $0; sub(/^.*\*\*Phát biểu:\*\*[ ]*/, "", s); if (!ghost(s)) stmt = s; next }
cur != "" && /\*\*Từ:\*\*/        { s = $0; sub(/^.*\*\*Từ:\*\*[ ]*/, "", s);        d = nodate(s); next }
cur != "" && /\*\*Status:\*\*/    { s = $0; sub(/^.*\*\*Status:\*\*[ ]*/, "", s);    if (!ghost(s)) stt = s; next }
END { flush() }
' >> "$REC"

# ── ADR-### : specs/internal/adr/*.md ───────────────────────────────────────
# Bỏ file bắt đầu bằng "_" — đó là khuôn, không phải quyết định. Chính vì khuôn
# từng mang tên ADR-000-template.md mà `id_exists ADR-000` báo XANH SAI trong mọi
# repo vừa scaffold, không cần ai viết sai gì cả. Đổi tên ở 4.2.0.
for f in "$ROOT/specs/internal/adr/"*.md "$ROOT/docs/adr/"*.md; do
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

# ── Cấm : specs/internal/architecture.md, mục ## Cấm ────────────────────────
# ID hiển thị là `CAM-N`, đánh theo THỨ TỰ XUẤT HIỆN — cố ý không phải danh tính.
# "Số không phải danh tính, nó là vị trí, và vị trí thì đổi": chèn một điều cấm ở
# giữa là mọi số sau nó chạy. Nên đừng trích `CAM-N` từ bất cứ đâu; cần trích được
# thì nâng điều cấm đó thành RULE-### hoặc ADR-###, hai thứ có ID thật.
# (Chữ ASCII vì đây là ID, và vì cột căn theo ký tự chỉ đúng khi bash đếm — awk
#  length() ở macOS đếm BYTE, "Cấm-1" 5 ký tự nhưng 6 byte, đủ lệch cả bảng.)
[ -f "$ROOT/specs/internal/architecture.md" ] && strip_markup < "$ROOT/specs/internal/architecture.md" \
| awk -v T="$TAB" "$FLD"'
function flush() { if (cur != "" && !ghost(stmt)) printf "%s%s%s%s%s%s%s%s%s%s%s\n", d,T,("CAM-" n),T,"cấm",T,stmt,T,stt,T,""; cur = "" }
/^## / { flush(); insec = ($0 ~ /^## Cấm/) ? 1 : 0; next }
insec && /^-[ ]/ {
  flush(); n++; cur = "y"
  stmt = $0; sub(/^-[ ]*/, "", stmt)
  d = "0000-00-00"; stt = ""
  next
}
cur != "" && /^[ \t]+- Từ:/ { d = nodate(fld($0, "Từ:")); stt = fld($0, "Trạng thái:"); next }
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
  END { if (id != "" && !ghost(stmt)) print nodate(d) T id T "thay đổi" T stmt T stt T "" }
  ' >> "$REC"
done

# ── dòng một câu : specs/internal/decisions.md ──────────────────────────────
[ -f "$ROOT/specs/internal/decisions.md" ] && strip_markup < "$ROOT/specs/internal/decisions.md" \
| awk -v T="$TAB" "$FLD"'
/^-[ ]+[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][ ]/ {
  match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/); d = substr($0, RSTART, RLENGTH)
  s = substr($0, RSTART + RLENGTH); sub(/^[ ]*(—|-)[ ]*/, "", s)
  if (ghost(s)) next
  n++
  print d T ("note-" n) T "ghi chú" T s T "" T ""
}
' >> "$REC"

# ── in ra ───────────────────────────────────────────────────────────────────
TOT="$(grep -c . "$REC" 2>/dev/null)"; [ -n "$TOT" ] || TOT=0
if [ "$TOT" = "0" ]; then
  printf 'Chưa có quyết định nào ghi lại.\n'
  printf 'Bắt đầu ở specs/br.md (## Constraints) và specs/rules.md — hoặc chạy /sdd-solo:intake.\n'
  exit 0
fi

DATED="$(grep -v "^0000-00-00$TAB" "$REC" | sort)"
UNDATED="$(grep "^0000-00-00$TAB" "$REC")"
ND="$(printf '%s' "$DATED"   | grep -c . || true)"
NU="$(printf '%s' "$UNDATED" | grep -c . || true)"

if [ "$MD" = "1" ]; then
  printf '# Sổ quyết định — sinh bởi decisions.sh ngày %s\n\n' "$TODAY"
  printf '<!-- SINH RA, ĐỪNG SỬA TAY. Chạy lại: bash .sdd/scripts/decisions.sh --md -->\n\n'
  printf '| Ngày | ID | Loại | Phát biểu | Trạng thái | Kiểm lại |\n|---|---|---|---|---|---|\n'
  printf '%s\n%s\n' "$DATED" "$UNDATED" | grep . | while IFS="$TAB" read -r d i k s t r; do
    [ "$d" = "0000-00-00" ] && d="—"
    printf '| %s | %s | %s | %s | %s | %s |\n' "$d" "$i" "$k" "$s" "${t:-—}" "${r:-—}"
  done
  exit 0
fi

# Căn cột ở BASH, không ở awk: ${#v} của bash đếm ký tự, length() của awk đếm byte.
# Mọi nhãn tiếng Việt đi qua đây, nên nhầm chỗ này là lệch cả bảng mà vẫn "chạy".
padc() { _s="$1"; _w="$2"; while [ "${#_s}" -lt "$_w" ]; do _s="$_s "; done; printf '%s' "$_s"; }

# br.md còn nguyên khuôn thì BR-000 là VÍ DỤ DẠY VIỆC, không phải quyết định của
# dự án. Không nói ra thì sổ tra trông như dự án đã quyết ba ràng buộc về hosting
# và luật kế toán — đúng loại "báo xanh sai" mà nó sinh ra để chống.
UNTOUCHED=0; br_untouched "$ROOT" && UNTOUCHED=1

printf '=== Sổ quyết định — %s mục ===\n' "$TOT"
[ "$UNTOUCHED" = "1" ] && printf '!  specs/br.md còn nguyên khuôn — dòng BR-000 dưới đây là VÍ DỤ dạy việc,\n   chưa phải quyết định của dự án. Chạy /sdd-solo:intake trước.\n'
printf '\n'

printf '%s\n' "$DATED" | grep . | while IFS="$TAB" read -r d i k s t r; do
  printf '%s  %s%s\n' "$d" "$(padc "$i" 9)" "$s"
  L="$t"
  [ -n "$r" ] && { [ -n "$L" ] && L="$L · kiểm lại: $r" || L="kiểm lại: $r"; }
  [ -n "$L" ] && printf '            %s%s\n' "$(padc '' 9)" "$L"
done

# Quá hạn kiểm lại — chỉ bắt được khi `Kiểm lại:` là một NGÀY. Mốc dạng "khi đổi
# gói hosting" thì máy chịu, và đó thường lại là mốc ĐÚNG HƠN. Nên đây là lưới
# thưa có chủ ý: bắt được cái nào hay cái đó, và nói thẳng là nó không bắt hết —
# một phép kiểm nhận mình thưa thì dùng được, một phép kiểm giả vờ kín thì không.
OVER="$(printf '%s\n' "$DATED" | awk -F"$TAB" -v today="$TODAY" '
  $6 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && $6 < today { printf "  %s  %s (hẹn %s)\n", $2, $4, $6 }')"
if [ -n "$OVER" ]; then
  printf '\n--- Quá hạn kiểm lại ---\n%s\n' "$OVER"
  printf '  ^ ràng buộc hết đúng khi THẾ GIỚI đổi, mà thế giới đổi thì repo không động đậy gì.\n'
fi

if [ "$NU" -gt 0 ]; then
  printf '\n--- Chưa có ngày (%s mục — không xếp được vào dòng thời gian) ---\n' "$NU"
  printf '%s\n' "$UNDATED" | grep . | while IFS="$TAB" read -r d i k s t r; do
    printf '  %s%s\n' "$(padc "$i" 9)" "$s"
  done
  printf '  ^ ngày là thứ DUY NHẤT ở đây không tái tạo được. Bố cục file lúc nào cũng sắp\n'
  printf '    lại được; hai quyết định mất ngày thì không ai dựng lại được cái nào ra trước.\n'
fi

printf '\n%s mục có ngày · %s mục chưa có ngày.\n' "$ND" "$NU"
exit 0
