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

# ── BR-000 phải BIẾN MẤT khi đã có BR thật ────────────────────────────────
# Tới 4.2.0 luật là "giữ nguyên BR-000 mẫu" — và đó là chỗ hỏng, đo được ở
# runxops: BR-000 mang CON-001/002/003, BR-001 thật cũng mang CON-001/002/003.
# `id_exists()` tra CON bằng grep DÒNG ĐẦU TIÊN khớp, nên nó luôn trúng bộ của
# BR-000. Hệ quả thật, không phải giả định:
#   · UC-009 trích CON-002 → cổng DoR khớp vào "bản ghi thanh toán giữ 10 năm";
#   · architecture.md ## Cấm viết "Không gọi API eBay. CON-001 — tài khoản cá
#     nhân…" → design-check báo XANH bằng cách trỏ vào "hosting chia sẻ".
# UC-009 đã qua cổng với những trích dẫn trỏ nhầm mục đó.
#
# Một BR mẫu có ích đúng lúc chưa có gì để đọc. Sau đó nó là một dãy ID giả
# đứng trước mọi ID thật trong cùng một file — và ID giả đứng trước thì mọi phép
# tra "dòng đầu tiên khớp" đều rơi vào nó. Chữa bằng cách đánh lại số CON của BR
# thật là chữa triệu chứng; chữa đúng chỗ là BR mẫu phải đi khi hết việc.
# "BR THẬT" = tiêu đề không còn `<...>`. Đếm bằng SỰ CÓ MẶT của một ID là sai:
# khuôn phát ra sẵn `# BR-001: <Tên business requirement>`, nên repo vừa scaffold
# cũng có "BR-001" và phép kiểm này báo đỏ ngay lần cài đầu — đỏ oan trên một repo
# chưa ai đụng vào là cách nhanh nhất dạy người ta phớt lờ dòng đỏ.
REAL=""
for b in $(br_ids "$ROOT" | grep -v '^BR-000$'); do
  grep -qE "^# $b:.*<[^>]+>" "$BF" && continue
  REAL="$b"; break
done
if [ -n "$REAL" ] && grep -qE '^# BR-000\b' "$BF"; then
  bad "br.md đã có $REAL thật mà BR-000 (BR mẫu) vẫn còn — xoá cả mục BR-000 đi"
  info "  BR-000 mang CON-001/002/003 của riêng nó. Còn nó thì mọi phép tra CON-###"
  info "  bằng 'dòng đầu tiên khớp' đều trúng ví dụ dạy việc, không trúng CON thật."
  info "  Cần đọc lại BR mẫu: nó nằm trong template của plugin, không mất đi đâu."
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

# 6b. CON trùng số giữa HAI BR — quét CẢ FILE, không chỉ BR đang kiểm.
# Số CON đánh riêng trong từng BR, nhưng ID thì dùng chung cả repo: UC trích
# `CON-002` trống trơn, không kèm BR nào. Hai BR cùng có CON-002 thì mọi phép
# tra đều trúng cái đứng trước, và cái đứng sau trở thành vô hình — không dòng
# đỏ nào, vì ID vẫn "có tồn tại".
# Kiểm này KHÔNG thừa sau khi BR-000 đi: hai BR THẬT cũng đụng nhau y hệt, và
# đó là ca sẽ tới, vì mỗi BR viết ở một thời điểm khác nhau và không ai nhớ số
# BR trước đã dùng tới đâu.
DUP="$(strip_markup < "$BF" | awk '
  # Bỏ qua BR còn là khuôn (tiêu đề còn `<...>`) — CON của nó cũng là khuôn, và
  # `CON-001 ...` của khuôn đụng `CON-001` của BR-000 ngay trên repo vừa scaffold.
  /^# BR-/ { match($0, /BR-[0-9]+/); br = substr($0, RSTART, RLENGTH)
             skip = ($0 ~ /<[^>]+>/) ? 1 : 0; next }
  skip { next }
  /^-? *\*\*CON-[0-9]+/ {
    match($0, /CON-[0-9]+/); c = substr($0, RSTART, RLENGTH)
    if (!(c in owner))      { owner[c] = br }
    else if (owner[c] != br) { print c "  (" owner[c] " và " br ")" }
  }' | sort -u)"
if [ -n "$DUP" ]; then
  bad "CON trùng số giữa hai BR — mọi phép tra chỉ thấy cái đứng trước:"
  printf '%s\n' "$DUP" | sed 's/^/      /'
  info "  đánh lại số cho bộ đứng sau, rồi sửa mọi chỗ trích nó."
fi

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
AP="$(sec '## Adversarial pass')"
printf '%s' "$AP" | grep -qE 'Ngày chạy: *[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "adversarial pass đã chạy" \
  || warn "chưa chạy /sdd-solo:adversarial $ID — ba vai tầng BR hay bắt ra 'đây là giải pháp viết ngược thành lý do'"

# 10b (5.1.0). Tới 5.0.0 phép kiểm trên là toàn bộ: có chữ "Ngày chạy:" là xanh. Không đếm
# `→ ___`, không kiểm "→ Open Question" có dòng `- [ ]` nào khớp. Cùng lỗi #12 ("lời khai
# `→ spec` trống không kiểm được") đã sửa ở gate-check cho UC năm bản trước — chưa bao giờ
# lan sang BR. Đo ở runxops (peer báo, đo lại đúng): 30 câu, 10 còn `___`, 4 "→ Open
# Question", và luật "không có để đó" ở skills/adversarial dòng 149 không script nào đọc.
# Phase 1 ĐƯỢC PHÉP còn `___` (quyết định 3.x, vẫn đúng) — nên ĐẾM RA, không chặn.
# Sau migrate --evidence thân nằm ở br.evidence.md, mặt tiền là một dòng đếm; đọc cả hai.
APB="$AP"
if printf '%s' "$AP" | grep -q '→ specs/br.evidence.md' && [ -f "$ROOT/specs/br.evidence.md" ]; then
  APB="$APB
$(awk -v h="## $ID — ## Adversarial pass" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}' "$ROOT/specs/br.evidence.md")"
fi
NQ="$(printf '%s\n' "$APB" | grep -cE '^[[:space:]]*-[[:space:]]*Q[0-9]+\b')"
NB="$(printf '%s\n' "$APB" | grep -E '^[[:space:]]*-[[:space:]]*Q[0-9]+\b' | grep -cE '→[[:space:]]*`?___|^[^→]*$')"
if [ "$NQ" -gt 0 ] && [ "$NB" -gt 0 ]; then
  warn "adversarial: $NB/$NQ câu chưa có đầu ra (→ ___) — treo được ở Phase 1, nhưng đây là số nợ, đừng để nó chìm"
fi
# "→ Open Question" là lời khai: phải có một dòng `- [ ]` cùng BR nói về nó. Khớp bằng từ
# khoá (3 từ dài nhất của câu, cần ≥ 2 trùng) — thưa có chủ ý: chắc chắn mồ côi (không có
# dòng `- [ ]` nào cả) thì ĐỎ; khớp không ra thì CẢNH BÁO kèm câu, vì diễn đạt lại thì máy
# chịu và đỏ oan dạy người ta phớt lờ.
OQB="$(sec '## Open Questions' | grep -E '^[[:space:]]*- \[ \]')"
NOQC="$(printf '%s\n' "$APB" | grep -cE '→[[:space:]]*Open Question')"
if [ "$NOQC" -gt 0 ]; then
  if [ -z "$OQB" ]; then
    bad "adversarial khai $NOQC lần '→ Open Question' mà ## Open Questions không có dòng '- [ ]' nào — lời khai trỏ vào chỗ trống"
  else
    printf '%s\n' "$APB" | grep -E '→[[:space:]]*Open Question' | while IFS= read -r q; do
      KW="$(printf '%s' "$q" | sed 's/→.*//' | tr -c '[:alnum:]àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ' '\n' \
            | awk 'length($0)>=5' | awk '{print length($0), $0}' | sort -rn | head -3 | awk '{print $2}')"
      HIT=0
      for w in $KW; do printf '%s\n' "$OQB" | grep -qiF "$w" && HIT=$((HIT+1)); done
      [ "$HIT" -lt 2 ] && warn "adversarial '→ Open Question' chưa thấy dòng '- [ ]' nào khớp: $(printf '%s' "$q" | cut -c1-70)…"
    done
  fi
fi
# 10c (5.1.0). Ba vai đọc BẢN NÀO? Adversarial ghi "trên vN" hoặc chỉ có ngày; History
# ghi vN mới nhất. Ba vai chạy trên v1 mà BR đã sang v3 thì câu đắt nhất của tầng này
# ("đây có thật là BR không") được hỏi trên một văn bản không còn tồn tại. Chỉ nói ra.
HV="$(sec '## History' | grep -oE '^- v[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)"
AV="$(printf '%s' "$AP" | grep -oE 'trên v[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)"
if [ -n "$HV" ] && [ -n "$AV" ] && [ "$AV" -lt "$HV" ]; then
  warn "ba vai chạy trên v$AV, BR đã là v$HV — hai vai kia chưa đọc bản hiện tại; chạy lại hay ghi rõ vì sao không"
elif [ -n "$HV" ] && [ -z "$AV" ]; then
  AD="$(printf '%s' "$AP" | grep -oE 'Ngày chạy: *[0-9-]+' | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
  HD="$(sec '## History' | grep -oE '\(20[0-9]{2}-[0-9]{2}-[0-9]{2}\)' | tr -d '()' | sort | tail -1)"
  [ -n "$AD" ] && [ -n "$HD" ] && [ "$AD" \< "$HD" ] && warn "adversarial chạy $AD, History sửa tới $HD — ba vai chưa đọc bản sau; ghi 'trên vN' vào Ngày chạy để đo được"
fi

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
