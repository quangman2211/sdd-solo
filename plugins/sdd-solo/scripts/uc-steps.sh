#!/usr/bin/env bash
# uc-steps.sh UC-### — liệt kê UC này đã đi qua những bước nào của vòng 14 bước.
#
# KHÔNG CHẶN GÌ. Luôn exit 0. Đây là phép LIỆT KÊ, không phải phép kiểm — cổng
# DoR là `gate-check.sh`, và thêm một cổng thứ hai đo cùng thứ chỉ tạo nhiễu.
#
# Vì sao nó tồn tại (#29): `UC-009` ở runxops đi trọn một vòng, qua cổng, 30 phát
# hiện verify — rồi mới lộ ra bước ② CHƯA TỪNG CHẠY. Kết quả có thật nên ai cũng
# tưởng bước đã chạy; nó có thật vì được viết tay. Người duy nhất biết sự thật là
# người duy nhất gõ được lệnh. Không phép kiểm nào hỏi tới, vì mọi phép kiểm đều
# đo SẢN PHẨM chứ không đo BƯỚC.
#
# Ba trạng thái, và ranh giới giữa hai cái sau mới là chỗ đáng giá:
#   ✓  có dấu vết trong file
#   –  cố ý bỏ, CÓ ghi lý do  (dòng `**Bỏ bước <n>:** <lý do>` trong file UC)
#   ?  không có dấu vết nào — có thể đã làm, có thể chưa, KHÔNG AI BIẾT
# "Bỏ có ghi lý do" và "bỏ mà không ai biết là bỏ" cho cùng một kết quả trên đĩa,
# nhưng sáu tháng sau chỉ cái đầu còn đọc lại được.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ID="${1:-}"
case "$ID" in UC-[0-9]*) ;; *) echo "Dùng: uc-steps.sh UC-###" >&2; exit 0;; esac
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
[ -z "$F" ] && { echo "  không tìm thấy $ID"; exit 0; }
DIR="$(dirname "$F")"; CTX="$(ctx_of "$F")"

yes_() { printf '  \033[32m✓\033[0m %-2s %s\n' "$1" "$2"; }
skip_() { printf '  \033[36m–\033[0m %-2s %s\n' "$1" "$2"; }
unk_() { printf '  \033[33m?\033[0m %-2s %s\n' "$1" "$2"; }
nom_() { printf '    %-2s %s\n' "$1" "$2"; }

# Bỏ có khai: `**Bỏ bước ⑤:** lý do` — số hoặc ký hiệu vòng tròn đều nhận.
skipped() { grep -qE "^\*\*Bỏ bước $1:\*\* *[^ ]" "$F" 2>/dev/null; }
# st <ký hiệu> <điều kiện đã đúng chưa: 0/1> <mô tả> <gợi ý khi ?>
st() {
  if [ "$2" = "0" ]; then yes_ "$1" "$3"
  elif skipped "$1"; then skip_ "$1" "$3 — cố ý bỏ, đã ghi lý do"
  else unk_ "$1" "$3${4:+ · $4}"; fi
}

echo "=== $ID — đã đi qua những bước nào ==="

[ -d "$DIR" ]; st "①" $? "khung UC đã tạo"

# ② nội dung: Main Flow có bước đánh số thật
grep -qE '^[0-9]+\. +[^ <]' "$F"; st "②" $? "nội dung UC đã viết (Main Flow có bước)"

# ③ RULE + entities + glossary
R3=1
if grep -qE 'RULE-[0-9]+' "$F" \
   && [ -f "$ROOT/specs/contexts/$CTX/entities.md" ] \
   && ! grep -q '<Tên entity' "$ROOT/specs/contexts/$CTX/entities.md" 2>/dev/null \
   && [ -f "$ROOT/specs/glossary.md" ] \
   && ! grep -q '<thuật ngữ' "$ROOT/specs/glossary.md" 2>/dev/null; then R3=0; fi
st "③" $R3 "RULE + entities.md + glossary.md"

# ④ flow mermaid
R4=1; grep -qE '^```mermaid' "$DIR/$ID.flow.md" 2>/dev/null && R4=0
[ "$R4" = 1 ] && [ -f "$DIR/$ID.bpmn" ] && R4=0
st "④" $R4 "flow đã vẽ"

# ⑤ màn hình: file ngoài README trong screens/
R5=1; find "$DIR/screens" -type f ! -name 'README.md' 2>/dev/null | grep -q . && R5=0
st "⑤" $R5 "màn hình (Claude Design)" "không có file nào trong screens/"

nom_ "⑥" "đối chiếu SCR ↔ E# ↔ state — không có artifact riêng, /sdd-solo:gate kiểm"

# ⑦ adversarial
grep -qE '^- *Ngày chạy: *[0-9]{4}-' "$(printf '%s' "$F")" 2>/dev/null \
  && sed -n '/^## Adversarial pass/,/^## /p' "$F" | grep -qE 'Ngày chạy: *[0-9]{4}-'
st "⑦" $? "adversarial pass (3 vai)"

# ⑧ đọc lại: mục ## Đọc lại có dòng F#, HOẶC commit docs đã qua một đêm
R8=1
sed -n '/^## Đọc lại/,/^## /p' "$F" 2>/dev/null | grep -qE '^- F[0-9]+ ' && R8=0
if [ "$R8" = 1 ]; then
  L="$(git -C "$ROOT" log -1 --format=%cs --grep="^docs($ID)" 2>/dev/null)"
  [ -n "$L" ] && [ "$L" != "$(today)" ] && R8=0
fi
st "⑧" $R8 "đọc lại bằng đầu chưa neo"

[ -f "$ROOT/.sdd/gate/$ID.ok" ]; st "⑨" $? "qua cổng DoR"

# ⑩ thiết kế: design.md + tasks.md trong CHÍNH thư mục UC (4.0.0).
# Trước 4.0.0 dòng này quét plan.md/tasks.md ở BẤT KỲ đâu dưới specs/ — nên một
# plan.md của UC khác làm UC này báo "đã thiết kế". Hỏi theo thư mục của chính
# nó thì không mượn được dấu vết của hàng xóm.
R10=1; [ -f "$DIR/design.md" ] && [ -f "$DIR/tasks.md" ] && R10=0
st "⑩" $R10 "thiết kế (/sdd-solo:design)" "chưa có design.md + tasks.md trong thư mục UC"

# ⑪ code sản phẩm — hỏi theo PHẠM VI FILE, không theo câu chữ trong message (#32).
# Trước 3.20.0 dòng này chỉ `--grep "($ID)"` trên MỌI đường dẫn, nên một commit
# `feat(UC-009)` đụng đúng `tool_paths` — thứ 3.19.0 vừa khai là KHÔNG thuộc UC
# nào và không thể thuộc — làm nó báo "code đã viết xong". Cùng một commit, hai
# script của plugin, hai kết luận ngược nhau: `trace-ratio` cố ý loại nó ra,
# `uc-steps` lấy nó làm bằng chứng. Luật đã ghi ở #31: thứ cần phân loại là
# FILE, không phải câu chữ. Ở #31 nó áp cho phép chặn; ở đây cho phép đọc.
CPS="$(code_paths "$ROOT") $(test_paths "$ROOT")"
TLS="$(tool_paths "$ROOT")"
for d in $TLS; do CPS="$(printf '%s\n' $CPS | grep -vxF "$d" | tr '\n' ' ')"; done
R11=1
if [ -n "$(printf '%s' "$CPS" | tr -d ' ')" ]; then
  git -C "$ROOT" log --format='%h %s' --grep="($ID)" -- $CPS 2>/dev/null \
    | grep -qE '^[0-9a-f]+ (feat|fix)' && R11=0
fi
st "⑪" $R11 "code sản phẩm (commit feat/fix mang $ID đụng $(printf '%s' "$CPS" | sed 's/ *$//'))"

# ⑫ test theo AC
UCT="$(uc_test_dir "$ROOT")"
R12=1; find "$ROOT/$UCT/$CTX/$ID" -type f 2>/dev/null | grep -q . && R12=0
st "⑫" $R12 "test theo AC" "chưa có file nào trong $UCT/$CTX/$ID/"

nom_ "⑬" "self-review 5 câu — không để lại dấu vết, không đo được"

R14=1; grep -qE '\*\*Status:\*\* *implemented' "$F" && R14=0
st "⑭" $R14 "đã đóng (Status: implemented)"

echo
echo "  ? = không có dấu vết, KHÔNG phải = chưa làm. Cố ý bỏ một bước thì ghi vào"
echo "    file UC một dòng '**Bỏ bước <ký hiệu>:** <lý do>' — nó sẽ hiện thành '–'."
exit 0
