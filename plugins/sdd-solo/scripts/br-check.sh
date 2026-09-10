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

# ── Brief nguồn (#34) ─────────────────────────────────────────────────────
# Ba lớp kiểm của plugin đều đo TRONG specs/: gate-check đo trong specs/, verify
# đọc trong specs/, ba vai adversarial cố ý mù với brief. Nên sau intake, brief
# thành file CHỈ-GHI — hai tài liệu cãi nhau nhiều ngày mà không phép kiểm nào
# có nhiệm vụ nhìn tới. Đây là chỗ duy nhất trong cả bộ nhìn ra ngoài specs/.
BP="$(brief_path "$ROOT")"
if [ -n "$BP" ]; then
  if [ ! -f "$ROOT/$BP" ]; then
    bad "brief_path=$BP nhưng file không tồn tại — config khai một nguồn không có thật"
  else
    BS="$(sha "$ROOT/$BP" | cut -c1-12)"
    BREC="$(brief_rec_sha "$ROOT")"
    if [ -z "$BREC" ]; then
      warn "br.md chưa ghi '**Nguồn brief:** $BP · sha256 <12 hex> · nạp <ngày>' — không truy được BR chuyển ra từ bản brief nào"
    elif [ "$BREC" != "$BS" ]; then
      bad "brief đã đổi kể từ lần intake (sha $BREC → $BS) — br.md và brief có thể đang nói ngược nhau"
      info "đối chiếu rồi cập nhật dòng '**Nguồn brief:**', hoặc chạy lại /sdd-solo:intake $BP"
    else
      ok "brief nguồn khớp sha đã ghi ($BS)"
    fi
  fi
fi

sec() { printf '%s' "$B" | awk -v h="$1" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}'; }
# nonempty/filled dùng bản chung ở lib.sh (4.0.1)

# 1. tiêu đề
grep -qE "^# $ID: *[^ <]" "$BF" && ok "có tiêu đề" || bad "dòng '# $ID:' chưa có tên thật"

# 2. Background — khẳng định không nguồn thì thuộc Open Questions, không thuộc đây
BG="$(sec '## Background')"
filled "$BG" && ok "## Background có nội dung" || bad "## Background rỗng hoặc còn placeholder"
# Câu 5 của intake ("có cách nào không xây phần mềm không?") là câu duy nhất chặn
# được việc xây thứ không cần tồn tại — nhưng trả lời "chưa nghĩ tới" chỉ thành một
# Open Question, mà Open Question không chặn gì. BR chưa chứng minh được lý do tồn
# tại đi qua cổng y hệt BR đã chứng minh xong. Cảnh báo, không đỏ. Xem #22.
printf '%s' "$BG" | grep -qE '\*\*Vì sao vẫn xây:\*\*' \
  && ok "Background có dòng 'Vì sao vẫn xây'" \
  || warn "Background chưa có dòng '**Vì sao vẫn xây:**' — chưa ai chứng minh phần mềm này cần tồn tại; đây là chỗ vai hoài nghi sẽ bấu vào"

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

# 9. BR chuyển từ brief phải giữ lại dấu vết của thứ đã loại.
# Luật 4 của intake trước 3.2.2 chỉ bảo "in danh sách" nên sản phẩm của nó sống
# trong lời nói: đóng terminal là mất. Luật không để lại dấu vết trong file thì
# không kiểm được, và cái gì không kiểm được thì cuối cùng sẽ trôi. Xem #21.
if printf '%s' "$B" | grep -qiE '\*\*Nguồn:\*\*.*brief'; then
  DR="$(sec '## Đã loại khỏi brief')"
  if filled "$DR" && printf '%s' "$DR" | grep -qE '^[[:space:]]*[-*] .*—'; then
    ok "có ## Đã loại khỏi brief"
    # ĐỊA CHỈ CHUYỂN TIẾP MÀ KHÔNG CÓ GÌ ĐI GIAO (#34). Một dòng ghi "thuộc
    # tầng thiết kế" đọc như đã xử lý xong, nhưng không cơ chế nào mang nó đi.
    # Ca thật: 'toàn bộ kiến trúc ba lớp' hoãn sang tầng thiết kế, hai ngày sau
    # bản thiết kế viết ra kiến trúc NGƯỢC HẲN brief mà không ai đối chiếu.
    # Từ 4.0.0 đích của loại dòng này là specs/internal/architecture.md, mục
    # ## Đã chốt từ brief — một chỗ CÓ THẬT và design-check đọc tới.
    FWD="$(printf '%s' "$DR" | grep -iE 'speckit-plan|/plan|design\.md|architecture|kiến trúc|ADR|Phase 5|sau này|để sau|tầng thiết kế')"
    if [ -n "$FWD" ]; then
      NOD="$(printf '%s\n' "$FWD" | grep -vE '→ *(chuyển|đích)' | grep -c .)"
      if [ "$NOD" -gt 0 ]; then
        warn "$NOD mục hoãn sang bước sau mà không ghi ĐÍCH — không cơ chế nào tự chuyển chúng đi"
        info "mỗi dòng như vậy thêm '→ chuyển: <đích có thật>' (ADR-###, CHG-###, Open Question, hoặc một dòng trong plan.md)"
        printf '%s\n' "$FWD" | grep -vE '→ *(chuyển|đích)' | head -3 | sed 's/^/      /'
      else
        ok "mọi mục hoãn đều ghi đích chuyển tiếp"
      fi
    fi
  else
    warn "Nguồn là brief mà không có ## Đã loại khỏi brief (mỗi dòng '- <mục> — <lý do>') — thứ bị bỏ đang không có chỗ nào ghi lại"
  fi
fi

# 10. adversarial pass — CẢNH BÁO, không đỏ. Phase 1 mềm hơn Phase 3: BR viết xong
# đã dùng được để mở UC; ba vai là bước làm nó chắc, không phải điều kiện tồn tại.
printf '%s' "$(sec '## Adversarial pass')" | grep -qE 'Ngày chạy: *[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "adversarial pass đã chạy" \
  || warn "chưa chạy /sdd-solo:adversarial $ID — ba vai tầng BR hay bắt ra 'đây là giải pháp viết ngược thành lý do'"

# 11. Bao nhiêu câu treo là treo THẬT, bao nhiêu là chỗ trống.
# '___' là đầu ra hợp lệ và không được biến mất. Nhưng khi nó chiếm đa số áp đảo
# thì đó không còn là "đã cân nhắc và chưa quyết được" — đó là "không có gì để
# cân". Đo được thì nói ra, đừng im lặng. Xem #25.
OQL="$(sec '## Open Questions' | grep -cE '^[[:space:]]*- \[ \]')"; [ -z "$OQL" ] && OQL=0
OQE="$(sec '## Open Questions' | grep -cE 'quyết định tạm: *_{2,}')"; [ -z "$OQE" ] && OQE=0
if [ "$OQL" -ge 3 ] && [ "$OQE" -gt $((OQL/2)) ]; then
  warn "$OQE/$OQL câu treo có 'quyết định tạm' rỗng — quá nửa. Câu nào chưa có gì để cân thì nó chưa phải câu hỏi đã chín; /sdd-solo:adversarial $ID sẽ trình từng câu kèm ngữ cảnh."
elif [ "$OQL" -gt 0 ]; then
  ok "$OQL câu treo, $OQE câu chưa có quyết định tạm"
fi

# 12. History
printf '%s' "$(sec '## History')" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "History có dòng ghi ngày" || bad "## History chưa có dòng 'v1 (YYYY-MM-DD)'"

# 13. ___ là hợp lệ ở Phase 1 — cảnh báo, không đỏ. Ép điền sớm đẻ ra đúng loại
# số bịa mà cả bước intake đang cố chặn.
U="$(printf '%s' "$B" | grep -o '___' | wc -l | tr -d ' ')"
[ "$U" -gt 0 ] && warn "còn $U chỗ ___ — hợp lệ ở Phase 1, nhưng là nợ: mỗi chỗ nên có một dòng Open Question"

echo
if [ "$FAIL" -eq 0 ]; then echo "BR DÙNG ĐƯỢC ($WARN cảnh báo)."; exit 0; else echo "BR CHƯA DÙNG ĐƯỢC — $FAIL lỗi, $WARN cảnh báo."; exit 1; fi
