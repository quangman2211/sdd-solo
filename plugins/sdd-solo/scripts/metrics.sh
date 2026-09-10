#!/usr/bin/env bash
# metrics.sh — hai chỉ số đếm bằng git: trace ratio và AC coverage.
# Gộp từ trace-ratio.sh + ac-coverage.sh (4.0.0); chỉ `status.sh` gọi, và nó gọi
# hai cái liền nhau. Nội dung từng phép đếm giữ nguyên — mỗi dòng trong đây đứng
# trên một ca đã đo (#16 nhãn bịa · #30 mẫu số trộn · #31 tool_paths).
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"

# ── Trace ratio ───────────────────────────────────────────────────────────
# tool_paths ra khỏi mẫu số: nó là code không thuộc UC nào, nên đếm nó vào
# "commit có ID truy vết được" là hỏi một câu không có câu trả lời đúng (#31).
TOOLS="$(tool_paths "$ROOT")"
P="$(printf '%s %s' "$(code_paths "$ROOT")" "$(test_paths "$ROOT")" | tr ' ' '\n' | awk 'NF&&!a[$0]++' | tr '\n' ' ' | sed 's/ *$//')"
if [ -n "$TOOLS" ]; then
  P="$(printf '%s\n' $P | grep -vxF -e "$(printf '%s\n' $TOOLS)" | tr '\n' ' ' | sed 's/ *$//')"
fi
total=$(git -C "$ROOT" log --format=%s -- $P 2>/dev/null | grep -vE '^chore\(sdd\)' | wc -l | tr -d ' ')
# Đếm ID CÓ THẬT, không đếm "khớp dạng ID". Trước 2.1.2 chỉ số này báo 10/10
# trên repo vừa bị chọc thủng bằng 4 nhãn bịa — chỉ số nói dối. Xem #16.
traced=0; fake=0
while IFS= read -r sj; do
  [ -z "$sj" ] && continue
  id="$(printf '%s' "$sj" | grep -oE '\((UC|BR|RULE|ADR|CHG)-[0-9]+\)' | head -1 | tr -d '()')"
  [ -z "$id" ] && continue
  if id_exists "$id" "$ROOT"; then traced=$((traced+1)); else fake=$((fake+1)); fi
done <<EOF
$(git -C "$ROOT" log --format=%s -- $P 2>/dev/null)
EOF
if [ "$total" = "0" ] && repo_has_code "$ROOT"; then
  # 0/0 đọc như "sạch" trong khi thật ra là "mù" — repo có code mà không nằm
  # trong đường dẫn đang đếm.
  echo "Trace ratio: ? — repo có file nguồn nhưng không commit nào đụng: $P"
  echo "            → sửa code_paths/test_paths trong .sdd/config"
else
  echo "Trace ratio (commit trong $(printf '%s' "$P" | sed 's/ /, /g') có ID CÓ THẬT): $traced/$total"
  [ "$fake" -gt 0 ] && echo "            ⚠ $fake commit mang ID không tồn tại ở đâu trong repo — nhãn dán cho qua"
fi

# ── AC coverage ───────────────────────────────────────────────────────────
UCT="$(uc_test_dir "$ROOT")"
# HAI dòng, mỗi dòng khai rõ MẪU SỐ của nó (#30). Trước 3.19.0 chỉ có một dòng
# trộn AC của UC đã qua cổng với AC của UC còn draft — nên chỉ số KHÔNG BAO GIỜ
# lên 100% được chừng nào còn một UC nằm draft, mà nằm draft nhiều tháng là
# chuyện quy trình này khuyến khích. Con số đó ĐÚNG, chỉ là đúng cho một câu hỏi
# không ai đang hỏi (loại sai #9): nó trộn "cái tôi đã cam kết có test chưa" với
# "spec xây được bao nhiêu".
tot_a=0; tot_g=0; tst_a=0; tst_g=0
for f in $(find "$ROOT/specs/contexts" -path '*/use-cases/UC-*/UC-*.md' -not -name '*.sequence.md' -not -name '*.flow.md' 2>/dev/null | sort); do
  id="$(basename "$f" .md)"; ctx="$(ctx_of "$f")"
  n=$(grep -cE '^### AC-[0-9]+' "$f" 2>/dev/null || true); n=${n:-0}
  t=$(find "$ROOT/$UCT/$ctx/$id" -name 'AC-*.test.*' 2>/dev/null | wc -l | tr -d ' ')
  tot_a=$((tot_a+n)); tst_a=$((tst_a+t))
  if [ -f "$ROOT/.sdd/gate/$id.ok" ]; then tot_g=$((tot_g+n)); tst_g=$((tst_g+t)); fi
done
if [ "$tot_a" = "0" ]; then echo "AC coverage: chưa có AC nào"; exit 0; fi
if [ ! -d "$ROOT/$UCT" ]; then
  echo "AC coverage: ? — chưa có thư mục $UCT (kiểm uc_test_dir trong .sdd/config). Tổng AC: $tot_a"
  exit 0
fi
# Dòng này ĐẠT được 100%, nên mới có nghĩa để theo dõi.
echo "AC có test / AC của UC đã qua cổng:   $tst_g/$tot_g"
echo "AC có test / AC của MỌI UC (kể cả draft): $tst_a/$tot_a"
