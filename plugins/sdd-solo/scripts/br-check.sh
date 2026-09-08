#!/usr/bin/env bash
# br-check.sh BR-### — kiểm cơ học tầng BR (Phase 1). exit 0 = dùng được.
# BR là tầng trên cùng: BR sai thì mọi UC bên dưới đều sai, và bộ 24 kiểm ở cổng
# DoR sẽ giúp người dùng sai một cách rất kỷ luật. Trước 3.2.0 tầng này không có
# một kiểm nào. Xem #18.
ID="$1"; [ -z "$ID" ] && { echo "dùng: br-check.sh BR-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; BF="$ROOT/specs/br.md"
echo "Kiểm BR — $ID"
[ -f "$BF" ] || { bad "không có specs/br.md — chạy /sdd-solo:init"; exit 1; }
if [ "$ID" = "BR-000" ]; then
  info "BR-000 là BR mẫu của template — không kiểm. Viết BR-001 rồi kiểm cái đó."
  exit 0
fi
B="$(br_body "$ID" "$ROOT")"
[ -z "$B" ] && { bad "không tìm thấy '# $ID: ...' trong specs/br.md"; exit 1; }

sec() { printf '%s' "$B" | awk -v h="$1" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}'; }
nonempty() { printf '%s' "$1" | grep -qvE '^[[:space:]]*$'; }
# filled — có nội dung THẬT: không rỗng, không còn <...>, không phải toàn dòng "..."
filled() {
  nonempty "$1" || return 1
  # Placeholder có thể TRẢI NHIỀU DÒNG: '<Vì sao ...' mở ở dòng này, '...>' đóng ở
  # dòng sau. Regex một dòng '<[^>]+>' không khớp cái nào, nên mục rỗng đi qua như
  # có nội dung. Phải bắt cả dòng chỉ mở và dòng chỉ đóng.
  printf '%s' "$1" | grep -qE '<[^>]+>|^[[:space:]]*<|>[[:space:]]*$' && return 1
  printf '%s' "$1" | grep -vE '^[[:space:]]*$' \
    | grep -qvE '^[[:space:]]*([-*][[:space:]]*)?\.\.\.[[:space:]]*$' || return 1
  return 0
}

# 1. tiêu đề
grep -qE "^# $ID: *[^ <]" "$BF" && ok "có tiêu đề" || bad "dòng '# $ID:' chưa có tên thật"

# 2. Background — khẳng định không nguồn thì thuộc Open Questions, không thuộc đây
filled "$(sec '## Background')" && ok "## Background có nội dung" \
  || bad "## Background rỗng hoặc còn placeholder"

# 3. Goal — một câu, và không được mơ hồ khi chưa có số nào để đo
G="$(sec '## Goal')"
SM="$(sec '## Success Metrics')"
if ! filled "$G"; then bad "## Goal rỗng hoặc còn placeholder"
else
  ok "## Goal có nội dung"
  DOTS="$(printf '%s' "$G" | grep -o '\.' | wc -l | tr -d ' ')"
  [ "$DOTS" -gt 1 ] && warn "## Goal có $DOTS dấu chấm — Goal nên gói trong MỘT câu"
  V="$(printf '%s' "$G" | grep -oiE 'tối ưu|cải thiện|nâng cao|tốt hơn|hiệu quả|hiện đại hoá' | head -1)"
  if [ -n "$V" ]; then
    if printf '%s' "$SM" | grep -qE '[0-9]'; then
      ok "Goal có từ mơ hồ '$V' nhưng Success Metrics có số — chấp nhận"
    else
      bad "Goal dùng '$V' mà Success Metrics chưa có số nào — nói rõ tốt hơn ở chỗ nào, đo bằng gì"
    fi
  fi
fi

# 4. Success Metrics — SỐ được phép để ___, CÁCH ĐO thì không.
# Đây là ranh giới của cả tầng: "___" là dốt một cách trung thực; thiếu cách đo
# là một metric không bao giờ kiểm được, tức một câu nói hay.
if ! nonempty "$SM"; then bad "## Success Metrics rỗng"
else
  N=0
  while IFS= read -r ln; do
    printf '%s' "$ln" | grep -qE '^[[:space:]]*[-*] ' || continue
    N=$((N+1))
    M="$(printf '%s' "$ln" | sed -n 's/.*đo qua: *//p' | sed 's/[)·].*//' | tr -d '_ ')"
    if [ -z "$M" ]; then
      bad "metric thiếu cách đo: $(printf '%s' "$ln" | cut -c1-58)"
    fi
  done <<< "$SM"
  [ "$N" = 0 ] && bad "## Success Metrics không có dòng '- ' nào" \
                || ok "$N metric, mỗi cái có cách đo"
fi

# 5. In Scope / Out of Scope — BR không loại trừ gì gần như luôn là BR chưa nghĩ xong
filled "$(sec '## In Scope')" && ok "## In Scope có nội dung" || bad "## In Scope rỗng hoặc còn placeholder"
filled "$(sec '## Out of Scope')" && ok "## Out of Scope có nội dung" \
  || bad "## Out of Scope rỗng — làm một mình thì dòng này là thứ duy nhất cản scope"

# 6. CON — phải có phân loại và một câu phát biểu
CS="$(sec '## Constraints')"
for c in $(printf '%s' "$CS" | grep -oE 'CON-[0-9]+' | sort -u); do
  L="$(printf '%s' "$CS" | grep -E "$c")"
  printf '%s' "$L" | grep -qiE "$c *(Technical|Regulatory|Timing|SLA)" \
    || bad "$c thiếu phân loại (Technical / Regulatory / Timing/SLA)"
  T="$(printf '%s' "$L" | sed -n 's/.*:\*\* *//p' | tr -d ' .')"
  [ -z "$T" ] && bad "$c chưa có câu phát biểu" || ok "$c có phân loại và nội dung"
done

# 7. Impact Map — không có nhánh đứt nghĩa là chưa map gì, chỉ là đường thẳng từ
# Goal xuống danh sách việc đã định làm sẵn.
IM="$(sec '## Impact Map')"
if ! printf '%s' "$IM" | grep -qE '^[[:space:]]*(flowchart|graph)\b'; then
  bad "## Impact Map chưa có khối mermaid flowchart"
else
  printf '%s' "$IM" | grep -qE '\-\.->' && ok "Impact Map có nhánh ngoài scope" \
    || bad "Impact Map không có nhánh '-.->' nào — mọi thứ đều nối về Goal thì chưa map, chỉ là danh sách việc"
fi

# 8. Related Use Cases — hai chiều.
# Chiều xuôi CHỈ cảnh báo: ở Phase 1 thì UC chưa tồn tại là chuyện bình thường,
# BR viết trước UC. Đỏ ở đây thì mọi BR trung thực đều đỏ và không sửa được.
RU="$(sec '## Related Use Cases')"
for u in $(printf '%s' "$RU" | grep -oE 'UC-[0-9]+' | sort -u); do
  [ -n "$(find_uc "$u" "$ROOT")" ] && ok "$u đã có file" \
    || warn "$u chưa tồn tại — bình thường ở Phase 1, tạo bằng /sdd-solo:start $u"
done
# Chiều ngược thì ĐỎ: UC đã khai thuộc BR này mà BR không nhận là trôi thật, và
# luôn sửa được. Cùng bài học hai chiều của #12, #15, #17.
for uf in $(find "$ROOT/specs/contexts" -path '*/use-cases/UC-*/UC-*.md' \
            -not -name '*.sequence.md' -not -name '*.flow.md' 2>/dev/null); do
  grep -qE "Liên quan tới BR:.*$ID([^0-9]|$)" "$uf" || continue
  uid="$(basename "$uf" .md)"
  printf '%s' "$RU" | grep -qE "$uid([^0-9]|$)" \
    || bad "$uid khai thuộc $ID nhưng ## Related Use Cases của $ID không liệt kê nó"
done

# 9. adversarial pass — CẢNH BÁO, không đỏ. Phase 1 mềm hơn Phase 3: BR viết xong
# đã dùng được để mở UC; ba vai là bước làm nó chắc, không phải điều kiện tồn tại.
printf '%s' "$(sec '## Adversarial pass')" | grep -qE 'Ngày chạy: *[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "adversarial pass đã chạy" \
  || warn "chưa chạy /sdd-solo:adversarial $ID — ba vai tầng BR hay bắt ra 'đây là giải pháp viết ngược thành lý do'"

# 10. History
printf '%s' "$(sec '## History')" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "History có dòng ghi ngày" || bad "## History chưa có dòng 'v1 (YYYY-MM-DD)'"

# 11. ___ là hợp lệ ở Phase 1 — cảnh báo, không đỏ. Ép điền sớm đẻ ra đúng loại
# số bịa mà cả bước intake đang cố chặn.
U="$(printf '%s' "$B" | grep -o '___' | wc -l | tr -d ' ')"
[ "$U" -gt 0 ] && warn "còn $U chỗ ___ — hợp lệ ở Phase 1, nhưng là nợ: mỗi chỗ nên có một dòng Open Question"

echo
if [ "$FAIL" -eq 0 ]; then echo "BR DÙNG ĐƯỢC ($WARN cảnh báo)."; exit 0; else echo "BR CHƯA DÙNG ĐƯỢC — $FAIL lỗi, $WARN cảnh báo."; exit 1; fi
