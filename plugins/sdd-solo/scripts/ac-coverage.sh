#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; UCT="$(uc_test_dir "$ROOT")"
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
