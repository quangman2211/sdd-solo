#!/usr/bin/env bash
# design-check.sh UC-### — bước ⑩: tầng thiết kế đã có và đã đối chiếu chưa.
# exit 0 = đủ để viết code.
#
# Kiểm HAI mức trong một script, cố ý: thứ kiểm `design.md` bắt buộc phải đọc
# `architecture.md` để biết nó đối chiếu với cái gì. Tách đôi là tạo hai script
# đọc cùng một bộ file rồi trôi khỏi nhau — đúng cái đã xảy ra với `uc-ready` và
# `gate-check` trước 4.0.0.
#
# Vì sao tầng này tồn tại (#34, #35): bốn tầng BR/UC/Entity/AC không có ngăn nào
# cho "dựng bằng gì · chạy ở đâu · ai gọi". Nên thiết kế rơi vào một bước NGOÀI
# quy trình, và ở đó nó có thể nói ngược lại brief nhiều ngày mà không phép kiểm
# nào có nhiệm vụ nhìn tới.
ID=""
for a in "$@"; do case "$a" in UC-[0-9]*) ID="$a";; esac; done
[ -z "$ID" ] && { echo "dùng: design-check.sh UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
echo "Tầng thiết kế — $ID"
[ -z "$F" ] && { bad "không tìm thấy file UC"; exit 1; }
DIR="$(dirname "$F")"; CTX="$(ctx_of "$F")"
DS="$DIR/design.md"; TK="$DIR/tasks.md"; AR="$ROOT/specs/internal/architecture.md"

# strip_tags <file|-> — bỏ thẻ HTML hợp lệ trước khi đi tìm placeholder <...>.
# Danh sách này là những thẻ CÓ THẬT trong template của plugin; thêm thẻ mới vào
# template thì thêm vào đây, đừng nới regex thành "bỏ mọi <...> ngắn".
strip_tags() { sed -E 's#</?(br|b|i|u|em|strong|code|sub|sup)[[:space:]]*/?>##g' "$1"; }

# ── 0. cổng DoR phải qua trước ────────────────────────────────────────────
# Thiết kế cho một UC chưa qua cổng là thiết kế cho một spec còn đang đổi.
[ -f "$ROOT/.sdd/gate/$ID.ok" ] && ok "đã qua cổng DoR" \
  || bad "chưa có .sdd/gate/$ID.ok — chạy /sdd-solo:gate $ID trước"

# ── 1. architecture.md — cấp dự án ────────────────────────────────────────
if [ ! -f "$AR" ]; then
  bad "thiếu specs/internal/architecture.md — không có gì để design.md đối chiếu ngược lên"
else
  MISS=""
  for sec in "## Ngăn xếp" "## Nơi chạy" "## Ai gọi" "## Ranh giới" "## Cấm" "## Đã chốt từ brief"; do
    grep -q "^$sec" "$AR" || MISS="$MISS '$sec'"
  done
  if [ -n "$MISS" ]; then bad "architecture.md thiếu mục:$MISS"
  else ok "architecture.md có đủ sáu mục"; fi
  # Placeholder <...> = chưa ai quyết. '___' thì HỢP LỆ (chưa quyết được, nhưng đã
  # biết là mình chưa quyết) — cùng luật với tầng BR: '___' là câu trả lời, '<...>'
  # là chỗ chưa ai đụng tới. Bỏ dòng trích dẫn '>' của phần hướng dẫn đầu file.
  #
  # `<br/>` trong khối mermaid KHÔNG phải placeholder — nó là cú pháp. Bản đầu
  # tính nó là placeholder, nên một architecture.md đã điền xong vẫn đỏ, và dòng
  # đỏ oan thì bị học cách phớt lờ, rồi kéo theo cả những dòng đỏ thật.
  PH="$(strip_tags "$AR" | grep -nE '<[^>]+>' | grep -vE '^[0-9]+:>' \
        | grep -vE '^[0-9]+:[[:space:]]*(<!--|```)' | head -6)"
  if [ -n "$PH" ]; then
    bad "architecture.md còn placeholder <...> — chưa ai quyết, không phải đã quyết là không có:"
    printf '%s\n' "$PH" | sed 's/^/      /'
  else
    ok "architecture.md không còn placeholder"
  fi

  # Mọi ID architecture.md trích phải có thật. Tới 4.0.3 luật này chỉ áp cho
  # design.md (§2) — cùng một script, hai văn bản, một cái được kiểm một cái
  # không. `architecture.md` mới là chỗ hay trích CON/ADR/BR nhất, vì nó là chỗ
  # duy nhất buộc phải nêu nguồn cho một điều cấm.
  #
  # NÓI RÕ NÓ ĐO GÌ: đây là phép kiểm ID CÓ TỒN TẠI, không phải ID CÓ NÓI ĐÚNG
  # THỨ ĐANG GẮN NÓ. Một dòng trích `BR-001` có thật mà chép ngược nghĩa của
  # BR-001 vẫn đi qua đây. Chỗ đó chỉ người đọc bắt được — và mục ## Cấm đòi
  # trích NGUYÊN VĂN chính là để việc đọc đó rẻ đi.
  # strip_markup TRƯỚC: khối <!-- … --> của template chính nó có nhắc CON-002,
  # ADR-001, BR-001 làm ví dụ. Quét cả chú thích là tự tố oan một repo vừa
  # scaffold — đúng loại đỏ oan mà 4.0.1 vừa đi chữa ở chỗ khác.
  for x in $(printf '%s\n' "$(cat "$AR")" | strip_markup /dev/stdin \
             | grep -oE '(RULE|ADR|BR|CHG|CON)-[0-9]+' | sort -u); do
    id_exists "$x" "$ROOT" && ok "$x có thật (architecture.md)" \
      || bad "architecture.md trích $x nhưng không có heading/thư mục nào cho nó"
  done

  # ## Cấm: dòng nào NÊU NGUỒN thì phải kèm nguyên văn. Chỉ CẢNH BÁO — thiếu
  # trích dẫn là một thói quen chưa có, không phải một artifact hỏng; cho nó đỏ
  # là báo đỏ trên một file đang đúng.
  #
  # Vì sao đáng nhắc (ca thật, runxops): một dòng trong ## Cấm viết "không tự
  # động hoá chạy TRONG phiên Multilogin — BR-001 Out of Scope", trong khi
  # BR-001 cấm chạy NGOÀI phiên và In Scope thì CHO PHÉP chạy trong. Vừa đảo
  # nghĩa một điều cấm, vừa dán nguồn cho câu mà nguồn không nói — và nó đọc
  # trôi chảy. Không phép kiểm nào bắt được vì không phép kiểm nào đọc hai
  # nguồn cùng lúc. Thứ làm nó lộ ra là động tác CHÉP NGUYÊN VĂN.
  CAM="$(printf '%s\n' "$(cat "$AR")" | strip_markup /dev/stdin \
         | awk 'index($0,"## Cấm")==1{f=1;next} f&&/^## /{exit} f{print}')"
  NOQ="$(printf '%s\n' "$CAM" | grep -nE '(RULE|ADR|BR|CHG|CON)-[0-9]+' \
         | grep -vE 'nguyên văn' | head -5)"
  if [ -n "$NOQ" ]; then
    warn "## Cấm: có dòng nêu nguồn mà không trích nguyên văn — không đối chiếu ngược lên nguồn được:"
    printf '%s\n' "$NOQ" | sed 's/^/      /'
    info "thêm 'nguyên văn: \"<trích đúng chữ>\"'. Một điều cấm chép sai nghĩa vẫn đọc rất trôi chảy."
  fi
fi

# ── 2. design.md của UC ───────────────────────────────────────────────────
if [ ! -f "$DS" ]; then
  bad "thiếu $ID/design.md — chạy /sdd-solo:design $ID"
else
  ok "có design.md"
  DMISS=""
  for sec in "## Tóm tắt" "## Bối cảnh kỹ thuật" "## Đối chiếu architecture.md" "## Đối chiếu brief" "## Cấu trúc code" "## Rủi ro"; do
    grep -q "^$sec" "$DS" || DMISS="$DMISS '$sec'"
  done
  if [ -n "$DMISS" ]; then bad "design.md thiếu mục:$DMISS"
  else ok "design.md có đủ mục bắt buộc"; fi

  # Hai mục đối chiếu KHÔNG được rỗng. Một tiêu đề trống trông y hệt một lượt
  # đối chiếu đã làm và không thấy gì — mà hai thứ đó khác nhau hoàn toàn.
  for sec in "## Đối chiếu architecture.md" "## Đối chiếu brief"; do
    if grep -q "^$sec" "$DS"; then
      BODY="$(awk -v h="$sec" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}' "$DS" \
              | grep -vE '^[[:space:]]*$' | grep -vE '^[[:space:]]*<!--')"
      if [ -z "$BODY" ]; then
        bad "$sec rỗng — mục trống và 'đã đối chiếu, khớp' trông giống hệt nhau"
      elif printf '%s\n' "$BODY" | strip_tags /dev/stdin | grep -qE '<[^>]+>'; then
        bad "$sec còn placeholder <...>"
      else
        ok "$sec có nội dung"
      fi
    fi
  done

  # Mọi ID design.md trích phải có thật. Cùng luật §4/§7 của gate-check (#12, #16).
  for x in $(grep -oE '(RULE|ADR|BR|CHG)-[0-9]+' "$DS" | sort -u); do
    id_exists "$x" "$ROOT" && ok "$x có thật" \
      || bad "design.md trích $x nhưng không có heading/thư mục nào cho nó"
  done
fi

# ── 3. tasks.md — mỗi AC một việc ─────────────────────────────────────────
if [ ! -f "$TK" ]; then
  bad "thiếu $ID/tasks.md — mỗi AC phải có một việc và một file test"
else
  ok "có tasks.md"
  ACS="$(grep -oE '^### AC-[0-9]+' "$F" | awk '{print $2}' | sort -u)"
  if [ -z "$ACS" ]; then
    warn "UC chưa có AC nào — tasks.md không có gì để đối chiếu"
  else
    LACK=""
    for ac in $ACS; do
      grep -qE "(^|[^A-Za-z0-9-])$ac([^0-9]|$)" "$TK" || LACK="$LACK $ac"
    done
    if [ -n "$LACK" ]; then bad "tasks.md thiếu việc cho:$LACK"
    else ok "mọi AC ($(printf '%s' "$ACS" | wc -w | tr -d ' ')) đều có việc trong tasks.md"; fi
    # Chiều ngược: AC bịa trong tasks.md. Bài học #12/#15 — nhãn không có thật đi
    # qua mọi cổng nếu không ai đối chiếu ngược lại.
    FAKE=""
    for ac in $(grep -oE 'AC-[0-9]+' "$TK" | sort -u); do
      printf '%s\n' $ACS | grep -qxF "$ac" || FAKE="$FAKE $ac"
    done
    [ -n "$FAKE" ] && bad "tasks.md nhắc$FAKE nhưng UC không có AC đó"
  fi
  grep -q "tests/use-cases/$CTX/$ID/" "$TK" \
    || warn "tasks.md chưa nêu đường dẫn test đúng quy ước tests/use-cases/$CTX/$ID/"
fi

# ── 4. giả định triển khai của UC vs architecture.md — CẢNH BÁO ───────────
# Máy không đọc được nghĩa, nên đây chỉ là lời nhắc đối chiếu bằng mắt. Cho nó
# đỏ là hứa một phép kiểm không làm được — đúng loại "báo xanh sai" ngược dấu.
GD="$(grep -E '^\*\*Giả định triển khai:\*\*' "$F" | head -1)"
if [ -n "$GD" ] && [ -f "$AR" ]; then
  info "đối chiếu bằng mắt: $GD"
  info "  với ## Ngăn xếp / ## Nơi chạy / ## Ai gọi của architecture.md — máy không đọc được nghĩa"
fi

echo
if [ "$FAIL" -eq 0 ]; then echo "ĐỦ THIẾT KẾ — viết code được ($WARN cảnh báo)."; exit 0; fi
echo "CHƯA ĐỦ — $FAIL lỗi, $WARN cảnh báo."; exit 1
