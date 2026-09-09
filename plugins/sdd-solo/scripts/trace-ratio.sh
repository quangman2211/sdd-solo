#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
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
