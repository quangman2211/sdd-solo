#!/usr/bin/env bash
# gate-check.sh [--pre] UC-### — Definition of Ready, kiểm cơ học. exit 0 = qua cổng.
#
# --pre là cổng NHỎ trước bước ⑦ (gộp từ uc-ready.sh ở 4.0.0): đủ nội dung để ba
# vai adversarial có gì mà đọc chưa. Cùng file, cùng bộ hàm, khác thời điểm và
# khác ngưỡng — tách hai script là để hai phép đo cùng một thứ trôi khỏi nhau.
PRE=0; ID=""
for a in "$@"; do
  case "$a" in --pre) PRE=1;; UC-[0-9]*) ID="$a";; esac
done
[ -z "$ID" ] && { echo "dùng: gate-check.sh [--pre] UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
[ "$PRE" = "1" ] && echo "Sẵn sàng adversarial — $ID" || echo "Definition of Ready — $ID"
[ -z "$F" ] && { bad "không tìm thấy ${ID}.md — specs/*/br-*/use-cases/${ID}-*/ (7.0) hay specs/contexts/*/use-cases/${ID}-*/ (6.x)"; exit 1; }
# 7.0: OWNER = core | <nghề> (6.x: tên context). Đường dẫn anh em đều tra qua lib.sh (#55).
CTX="$(owner_of "$F")"; DIR="$(dirname "$F")"
RFS="$(rules_files "$ROOT" | tr '\n' ' ')"; EFS="$(entity_cited "$F" "$ROOT" | tr '\n' ' ')"; GFS="$(glossary_files "$CTX" "$ROOT" | tr '\n' ' ')"
EFALL="$(entity_files "$F" "$ROOT" | tr '\n' ' ')"; BRF="$(br_files "$ROOT" | tr '\n' ' ')"
[ "$PRE" = "0" ] && info "file: ${F#$ROOT/}"

# ── #48: file anh em — CẢNH BÁO, không chặn ──────────────────────────────
# Ca thật runxops: verify UC-014 lần 1, 14/18 phát hiện là LỆCH GIỮA UC VÀ FILE ANH EM
# (glossary, entities, sequence, `Áp dụng cho` của RULE) sau ba đợt áp phiếu chỉ sửa file UC —
# `--pre` xanh vì chỉ kiểm UC + flow. Danh sách anh em lấy đúng cách context.sh lấy: ID UC
# trích (RULE/CON/ADR) + entities/glossary của context. Cảnh báo vì đây là thứ verify sẽ bắt;
# bắt sớm ở đây rẻ hơn một lượt verify (~10 phút, ~200 KB), nhưng chưa đủ chắc để chặn.
# uc_live — file UC bỏ ba mục dấu vết (cùng luật context.sh #43). Ca thật runxops: "dải rule
# 001–011" trong ## Đọc lại làm siblings tưởng UC trích RULE-001 → cảnh báo oan.
entity_hint() { if [ "$(layout "$ROOT")" = v7 ]; then printf 'specs/core/entities/<Tên>.md hoặc specs/%s/entities/<Tên>.md' "$CTX"; else printf 'specs/contexts/%s/entities.md' "$CTX"; fi; }
uc_live() { awk '/^## (Adversarial pass|Đọc lại|History)/{t=1;next} /^## /{t=0} !t' "$F"; }
siblings() {
  SIB="$F $DIR/$ID.flow.md $DIR/$ID.sequence.md $RFS $BRF $EFS $GFS"
  LIVE="$(uc_live)"
  for a in $(printf '%s' "$LIVE" | grep -oE 'ADR-[0-9]+' | sort -u); do SIB="$SIB $(adr_file "$a" "$ROOT")"; done
  # 1. cụm đánh dấu treo — ngoài mục dấu vết (History · Adversarial pass · Đọc lại)
  for f in $SIB; do
    [ -f "$f" ] || continue
    HITS="$(awk '/^#{1,6} (History|Adversarial pass|Đọc lại)/{t=1;next} /^#{1,6} /{t=0} !t' "$f" \
            | grep -nE 'chờ phiếu|đang xét lại|\(chưa mở\)' | grep -vE '^[0-9]+:[[:space:]]*[-*] \[x\]' | head -3)"
    [ -n "$HITS" ] && { warn "${f#$ROOT/} còn cụm treo (chờ phiếu · đang xét lại · chưa mở):"; printf '%s\n' "$HITS" | cut -c1-110 | sed 's/^/      /'; }
  done
  # 2. entity UC nhắc tên phải có dòng **Tên** trong glossary — ba vai và code gọi cùng một tên
  if [ -n "$EFALL" ] && [ -n "$GFS" ]; then
    MISS=""
    for e in $(entity_names "$F" "$ROOT"); do
      printf '%s' "$LIVE" | grep -qw "$e" || continue
      # runxops viết `- **Việc** (`WorkItem`)`: tên code đứng sau tên tiếng Việt — chỉ đòi có mặt trên một dòng thuật ngữ
      cat /dev/null $GFS | grep -qE "^- \*\*(.*[^A-Za-z0-9_])?$e([^A-Za-z0-9_]|$)" || MISS="$MISS $e"
    done
    [ -n "$MISS" ] && warn "entity UC nhắc tên chưa có dòng '- **Tên**' trong glossary.md:$MISS"
  fi
  # 3. RULE được trích phải ghi UC này ở 'Áp dụng cho' — chiều ngược của §4
  for r in $(printf '%s' "$LIVE" | grep -oE 'RULE-[0-9]+' | sort -u); do
    AP="$(awk -v h="## $r" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f' /dev/null $RFS 2>/dev/null | grep -i 'Áp dụng cho' | head -1)"
    [ -z "$AP" ] && continue
    printf '%s' "$AP" | grep -q "$ID" || warn "$r: 'Áp dụng cho' không có $ID — UC trích rule mà rule không nhận UC (#48)"
  done
}

# ── mỗi E# có dòng trong bảng Screens — dùng ở cả --pre (7.4, P-30) lẫn cổng đầy đủ ────
# Chỉ xét Ô ĐẦU của mỗi dòng bảng, so nguyên từ: `**E1**` (in đậm) và `E1 · E2` (ô gộp) đều tính (P-38b);
# tới 7.3 regex đòi `| E1` sát mép nên hai dạng đó đỏ oan "E1 chưa có dòng".
SCR="$(sed -n '/^## Screens/,/^## /p' "$F")"
screens_check() {
  local n
  for n in $(grep -oE '^- +(\*\*)?E[0-9]+' "$F" | grep -oE '[0-9]+' | sort -un); do
    printf '%s\n' "$SCR" | grep -E '^\|' | awk -F'|' '{print $2}' | grep -qwE "E$n" \
      && ok "E$n có màn hình" || bad "E$n chưa có dòng trong bảng ## Screens"
  done
}

# ── --pre: cổng trước bước ⑦ ──────────────────────────────────────────────
# Bốn tiền điều kiện cũ ở skills/adversarial đo CẤU TRÚC nên template rỗng qua
# hết: 4 dòng Main Flow đánh số, 2 AC, 2 E#, 3 dòng Screens — mà cả file còn 23
# placeholder. Và /sdd-solo:start copy chính template đó. Xem #11.
if [ "$PRE" = "1" ]; then
  grep -qE '^[0-9]+\.' "$F" && ok "Main Flow có bước đánh số" || bad "Main Flow chưa có bước nào"
  A="$(grep -cE '^### AC-[0-9]+' "$F")"; [ "$A" -ge 1 ] && ok "$A AC" || bad "chưa có AC nào"
  E="$(grep -cE '^- +(\*\*)?E[0-9]+[.:]' "$F")"; [ "$E" -ge 1 ] && ok "$E exception" || bad "chưa có E# nào"
  grep -qE 'SCR-[0-9]+-[0-9]+' "$F" && ok "bảng Screens có SCR-###-#" || bad "bảng Screens chưa có SCR nào"
  screens_check

  # Đây mới là chốt thật: còn placeholder nghĩa là chưa ai viết nội dung.
  # NGOẠI LỆ: '___' nằm trong ## Open Questions là hợp lệ. Bản trước tính nó là
  # placeholder, nên người viết trung thực '- [ ] <câu hỏi> (quyết định tạm: ___)'
  # bị chặn, và lối thoát duy nhất là BỊA một giá trị — đúng thứ cả tầng BR sinh ra
  # để chặn. §8 dưới cho qua, br-check chỉ cảnh báo; chỉ nhánh này chặn.
  # '<...>' thì vẫn đỏ ở mọi chỗ, kể cả trong Open Questions. Xem #23.
  PHALL="$(awk '
    /^## Open Questions/ { oq=1; dl=0; next }
    # ## Đọc lại là mục của bước ⑧, mà nhánh này chạy ở bước ⑦ — nó CÒN NGUYÊN
    # template là đúng lịch, không phải chưa điền. Không bỏ qua thì --pre đỏ,
    # adversarial từ chối chạy, và không có đường nào ra: muốn qua bước ⑦ phải
    # điền trước một mục chỉ tồn tại sau bước ⑦.
    # 7.0.1 (#52): ## Adversarial pass cùng loại — nó là ĐẦU RA của chính bước ⑦ mà --pre canh cửa; lượt thứ
    # hai trở đi (câu cũ còn đầu ra ___, vai mới chưa chạy) thì --pre đỏ vì chính mục nó sắp điền.
    # 7.4 (P-18): ## History là sổ chỉ-thêm, ghi cả lời cảnh báo có `E<số>` — không phải chỗ chưa điền.
    /^## (Đọc lại|Adversarial pass|History)/ { dl=1; oq=0; next }
    /^## / { oq=0; dl=0 }
    {
      if (dl) next
      # 7.4 (P-38): chữ trong nháy mã là chữ thật (`<tr>` tên thẻ HTML), không phải placeholder.
      t = $0; gsub(/`[^`]*`/, "", t)
      ang = (t ~ /<[^>]+>/); us = (t ~ /___/)
      if (!ang && !us) next
      if ($0 ~ /^[[:space:]]*<!--/) next
      if ($0 ~ /Ngày chạy|đầu ra/) next
      if (oq && !ang) next
      printf "%d:%s\n", NR, $0
    }' "$F")"
  # 7.4 (P-43): '___' trong thân UC mà cùng dòng trích một RULE có tham số còn ___ ở rules.md là TRUNG THỰC —
  # số chưa quyết nằm ở rule, UC chỉ chép lại chỗ trống đó. Chặn ở đây thì lối thoát duy nhất là bịa số vào UC
  # trước khi rule có số (ca runxops: AC trích RULE-### `phút` = ___). '<...>' vẫn đỏ.
  RULE_BLANK=""
  for r in $(cat /dev/null $RFS 2>/dev/null | grep -oE '^## RULE-[0-9]+' | awk '{print $2}' | sort -u); do
    awk -v h="## $r" 'index($0,h)==1{f=1;print;next} f&&/^## /{f=0} f' /dev/null $RFS 2>/dev/null | grep -q '___' && RULE_BLANK="$RULE_BLANK $r "
  done
  PHK=""; PHX=""
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    if printf '%s' "$l" | grep -q '___' && ! printf '%s' "$l" | grep -qE '<[^>]+>'; then
      rid="$(printf '%s' "$l" | grep -oE 'RULE-[0-9]+' | head -1)"
      if [ -n "$rid" ] && printf '%s' "$RULE_BLANK" | grep -q " $rid "; then PHX="$PHX
$l"; continue; fi
    fi
    PHK="$PHK
$l"
  done <<< "$PHALL"
  PHALL="$PHK"
  PXN="$(printf '%s\n' "$PHX" | awk 'NF' | wc -l | tr -d ' ')"
  [ "$PXN" -gt 0 ] && info "$PXN chỗ ___ trích tham số RULE còn trống ($(printf '%s' "$RULE_BLANK" | tr -s ' ' | sed 's/^ //; s/ $//')) — hợp lệ; điền ở rules.md rồi UC theo"
  PN="$(printf '%s\n' "$PHALL" | awk 'NF' | wc -l | tr -d ' ')"
  if [ "$PN" -gt 0 ]; then
    bad "còn $PN chỗ chưa điền — adversarial pass trên spec rỗng là vô ích:"
    printf '%s\n' "$PHALL" | head -8 | sed 's/^/      /'
  else
    ok "không còn placeholder"
  fi
  OQU="$(sed -n '/^## Open Questions/,/^## /p' "$F" | grep -c '___')"; [ -z "$OQU" ] && OQU=0
  [ "$OQU" -gt 0 ] && info "$OQU chỗ ___ trong Open Questions — hợp lệ, không tính là chưa điền"

  # entities.md và glossary.md của context: CẢNH BÁO, không chặn.
  # Ba vai đọc hai file này làm đầu vào. Chạy khi chúng còn là template thì mô hình
  # đổi sau đó và AC phải sửa lời — chi phí thật, nhưng không đủ lớn để khoá người
  # dùng ra khỏi bước ⑦. Chặn ở đây là lặp lại đúng hình lỗi của #23. Xem #24.
  if [ -z "$EFALL" ]; then
    warn "$CTX chưa có entity nào ($(entity_hint)) — ba vai sẽ hỏi mà không có mô hình để đối chiếu"
  elif cat /dev/null $EFALL | grep -qE '(class|## )Entity[AB]([^A-Za-z0-9]|$)' 2>/dev/null; then
    warn "entity của $CTX còn EntityA/EntityB của template — mô hình đổi sau adversarial thì AC phải sửa lời"
  fi
  [ -n "$GFS" ] && cat /dev/null $GFS | grep -qE '<Thuật ngữ>|<Context A>' && \
    warn "glossary còn là template — ba vai và code sẽ gọi cùng một thứ bằng những tên khác nhau"
  siblings

  echo
  if [ "$FAIL" -eq 0 ]; then echo "ĐỦ ĐIỀU KIỆN — chạy ba vai được ($WARN cảnh báo)."; exit 0; fi
  echo "CHƯA ĐỦ — $FAIL lỗi, $WARN cảnh báo. Viết xong nội dung rồi chạy lại."; exit 1
fi

# 0. status
STL="$(grep -E '\*\*Status:\*\*' "$F" | head -1)"; echo "$STL" | grep -q '|' && bad "Status còn là danh sách lựa chọn — chọn một giá trị"
ST="$(echo "$STL" | grep -oE '\*\*Status:\*\* *[a-z]+' | awk '{print $2}')"
case "$ST" in draft|reviewed) ok "status: $ST";; implemented) bad "status đã implemented — dùng Phase 5 (specs/changes/) nếu đổi hành vi";; deprecated) bad "status deprecated — UC đã bỏ (#45); mở UC thay thế ghi ở ## History, không qua cổng UC này";; *) bad "status không hợp lệ: '$ST'";; esac

# 1. các mục bắt buộc
for sec in "## Actor" "## Trigger" "## Preconditions" "## Main Flow" "## Exceptions" "## Postconditions" "## Acceptance Criteria" "## Screens" "## History"; do
  grep -q "^$sec" "$F" && ok "có $sec" || bad "thiếu $sec"
done
grep -qE '<[^>]*>' <(sed -n '/^## Actor/,/^## Alternative/p' "$F" | grep -vE '^\s*$|^##') && warn "còn placeholder <...> trong Actor/Trigger/Flow"

# 2. AC vs E#
EN="$(grep -cE '^- +(\*\*)?E[0-9]+[.:]' "$F")"; AN="$(grep -cE '^### AC-[0-9]+' "$F")"
if [ "$AN" -ge 1 ] && [ "$AN" -ge $((EN+1)) ]; then ok "AC: $AN · Exceptions: $EN (≥ E# + 1)"; else bad "AC: $AN · Exceptions: $EN — cần ≥ 1 AC cho Main + 1 cho mỗi E#"; fi
grep -qE '^Given:' "$F" && grep -qE '^When:' "$F" && grep -qE '^Then:' "$F" && ok "AC dạng Given/When/Then" || bad "AC chưa có Given/When/Then"

# 3. mỗi E# có dòng trong bảng Screens (hàm screens_check ở đầu file — dùng chung với --pre)
screens_check
echo "$SCR" | grep -qE 'SCR-[0-9]+-[0-9]+' || bad "chưa có SCR-###-# nào trong ## Screens"

# 4. RULE trích phải có trong rules.md
for r in $(grep -oE 'RULE-[0-9]+' "$F" | sort -u); do
  # grep -c in "0" RỒI exit 1, nên "|| echo 0" tạo chuỗi hai dòng và phá cả
  # hai phép so sánh bên dưới. Đừng thêm fallback ở đây.
  C="$(cat /dev/null $RFS 2>/dev/null | grep -cE "^## $r\b")"; [ -z "$C" ] && C=0
  H="$(cat /dev/null $RFS 2>/dev/null | grep -E "^## $r\b" | head -1)"
  if [ "$C" = "0" ]; then bad "$r được trích nhưng không có heading trong rules.md nào ($(printf '%s' "$RFS" | sed "s#$ROOT/##g"))"
  elif [ "$C" -gt 1 ]; then bad "$r có $C heading trong rules.md — trùng ID, sửa lại (#13)"
  elif echo "$H" | grep -q '<'; then bad "$r vẫn là placeholder của template: $H — viết rule thật hoặc bỏ trích (#13)"
  else ok "$r có trong rules.md"; fi
done

# 5. Flow — mermaid (mặc định từ 3.1.0) hoặc .bpmn (đường cũ, vẫn nhận)
# .bpmn là XML nén nên script chỉ kiểm được "file có tồn tại". Phép đếm mà
# checklist DoR đòi từ đầu — "số error boundary event = số E#" — chưa bao giờ
# chạy được bằng máy. .flow.md là text nên đếm được thật, cả hai chiều.
# 2.0.0: diagram nằm TRONG thư mục UC, không còn ở diagrams/ cấp context.
FL="$DIR/$ID.flow.md"
BP="$DIR/$ID.bpmn"
OLD="$ROOT/specs/contexts/$CTX/diagrams/$ID.bpmn"
if [ -f "$FL" ]; then
  ok "$ID.flow.md (mermaid, trong thư mục UC)"
  grep -qE '^```mermaid' "$FL" && grep -qE '^[[:space:]]*(flowchart|graph)\b' "$FL" \
    || warn "$ID.flow.md chưa có khối mermaid với flowchart/graph — chưa vẽ được gì"
  grep -qE '\(\[' "$FL" || warn "$ID.flow.md chưa có node kết dạng ([...]) — Postcondition chưa có đường tới"
  # CHỈ NHÃN CẠNH mới tính: phần giữa hai dấu | trên dòng có mũi tên. Id node
  # không bao giờ nằm ở đó. Bản 3.1.0 khớp E<số> ở BẤT CỨ ĐÂU trong file, nên
  # một node kết đặt tên E1([Đăng nhập được]) — tức một kết thúc THÀNH CÔNG —
  # làm cổng tin rằng đường lỗi E1 đã được vẽ, trong khi nhánh ngoại lệ thật
  # không còn nhãn nào. ✓ giả, và sai về đúng phía nguy hiểm. Xem #17.
  # 7.5 (P-32): nhãn cạnh lấy từ PARSER (mermaid.py --edges) — nó biết đâu là nhãn, đâu là tên node, đâu là
  # chữ trong nháy kép. Không có python3 thì rơi về grep của bản trước (đường lùi, không đỏ oan).
  if mmd_ok; then LBL="$(mmd --edges "$FL")"
  else LBL="$(grep -E '(-->|==>|-\.->|--x|--o)' "$FL" 2>/dev/null | grep -oE '\|[^|]*\|')"; fi
  # chiều xuôi: E# khai trong UC phải có một mũi tên mang nhãn đó
  for e in $(grep -oE '^- +(\*\*)?E[0-9]+' "$F" | grep -oE 'E[0-9]+' | sort -u); do
    printf '%s' "$LBL" | grep -qE "(^|[^A-Za-z0-9])$e([^0-9]|$)" && ok "$e có nhánh trong flow" \
      || bad "$e có trong ## Exceptions nhưng không mũi tên nào trong $ID.flow.md mang nhãn |$e ...| — nhãn phải nằm giữa hai dấu |, tên node không tính"
  done
  # chiều ngược: nhãn trong sơ đồ phải là E# có thật. Nhãn bịa đi qua mọi cổng
  # nếu không ai đối chiếu ngược — bài học #12 và #15.
  for e in $(printf '%s' "$LBL" | grep -oE 'E[0-9]+' | sort -u); do
    grep -qE "^- +(\*\*)?$e[.:]" "$F" \
      || bad "$ID.flow.md có nhãn $e nhưng ## Exceptions của UC không có $e"
  done
  # id node dạng E<số> không còn giả mạo được nhãn, nhưng vẫn khó đọc cho người.
  # Không bắt X#([E1: ...]) — ở đó E1 đứng trước dấu hai chấm, không phải id.
  # 7.4 (P-17): chỉ xét TRONG khối ```mermaid — ghi chú văn xuôi dưới sơ đồ nhắc "E1 (…)" không phải id node.
  # 7.5 (P-32): parser trả thẳng cột id, không còn đoán bằng regex "id đứng trước dấu mở hình".
  if mmd_ok; then
    ENID="$(mmd --nodes "$FL" | awk -F'\t' '$1 ~ /^E[0-9]+$/ {print $1}' | sort -u | tr '\n' ' ')"
  else
    ENID="$(awk '/^```/{c=!c;next} c' "$FL" | grep -oE '(^|[[:space:]])E[0-9]+ *[[({]' | grep -oE 'E[0-9]+' | sort -u | tr '\n' ' ')"
  fi
  [ -n "$ENID" ] \
    && warn "$ID.flow.md đặt id node dạng E<số> ($ENID) — dễ đọc nhầm thành ngoại lệ; dùng P# cho node kết thường, X# cho node kết của ngoại lệ"
  # Sơ đồ KHÔNG RENDER ĐƯỢC thì không ai đọc lại được nó, và mọi phép đếm ở trên đếm trên một thứ không tồn tại.
  # Đo: 17/88 khối mermaid của runxops vỡ mà cổng vẫn xanh (P-32). Lint cả flow · sequence · UC · screens/README.
  mmd_lint "$FL" "$DIR/$ID.sequence.md" "$F" "$DIR/screens/README.md" \
    || bad "sơ đồ mermaid ở trên không render được (mermaid.py --lint) — sửa rồi chạy lại; sơ đồ vỡ là sơ đồ không ai đọc"
elif [ -f "$BP" ]; then
  ok "$ID.bpmn (đường cũ — .flow.md mermaid đếm được E#, cân nhắc chuyển)"
  [ -f "$BP.svg" ] || warn "chưa export $ID.bpmn.svg"
elif [ -f "$OLD" ]; then bad "$ID.bpmn còn ở chỗ cũ specs/contexts/$CTX/diagrams/ — dời vào thư mục UC (xem README mục 'Bố cục 1.x')"
else bad "thiếu ${DIR#$ROOT/}/$ID.flow.md (mermaid) — hoặc $ID.bpmn nếu vẫn dùng BPMN"; fi

# 6. entities + glossary — đo NỘI DUNG, không đo hình dạng.
# Bản trước kiểm `grep -q stateDiagram`, mà template context có sẵn một khối
# stateDiagram-v2 mẫu — nên phép kiểm khớp vào chính nó. entities.md còn nguyên
# class EntityA/EntityB vẫn in ✓ và không warn một chữ. Một phép kiểm báo xanh
# SAI tệ hơn không có phép kiểm: không có thì người ta còn tự nhớ. Cùng hình lỗi
# với #11 (tiền điều kiện đo cấu trúc) và #13 (RULE placeholder). Xem #24.
# 7.0 (T2): mỗi entity một file ở specs/core/entities/ + specs/<nghề>/entities/; UC dùng entity nào
# thì file đó là "entities của UC" (entity_cited). 6.x: entities.md của context, một file cho cả.
EF="$EFALL"
if [ -z "$EF" ]; then bad "thiếu entity — $(entity_hint)"
else
  case "$EF" in */specs/contexts/*) ok "context $CTX có entities.md";; *) ok "$CTX có $(printf '%s\n' $EF | wc -l | tr -d ' ') entity ($(printf '%s\n' $EF | xargs -n1 basename | sed 's/\.md$//' | tr '\n' ' ' | sed 's/ $//'))";; esac
  cat /dev/null $EF | grep -qE '(class|## )Entity[AB]([^A-Za-z0-9]|$)' && bad "entity còn EntityA/EntityB của template — chưa đặt tên entity thật"
  cat /dev/null $EF | grep -q '<Context>' && bad "entity còn tiêu đề '# Entity Model — <Context>' của template"
  if cat /dev/null $EF | grep -q 'stateDiagram'; then
    # CỐ Ý quét cả file chứ không xét từng mũi tên: chỉ cần MỘT mũi tên gắn UC
    # có thật là qua. Đừng siết thành "mọi mũi tên phải gắn UC" — có trạng thái
    # do THẾ GIỚI BÊN NGOÀI đổi chứ không do UC nào kéo. Ca thật ở runxops:
    # `đangSống --> đãSuspend` là do sàn khoá tài khoản, không UC nào gây ra.
    # Siết per-arrow sẽ ép người ta dán một UC-### giả lên đó — tức bịa, đúng
    # thứ cả quy trình này sinh ra để chặn.
    # 7.5 (P-32): đọc NHÃN mermaid hiểu được, không grep dòng. Một dấu ; trong nhãn làm mermaid mất TRẮNG nhãn
    # của CẢ sơ đồ (đo trên runxops core/entities/Account.md: 4/4 quan hệ về rỗng, 5 state rác) — grep vẫn thấy
    # "UC-016" và vẫn in ✓, trong khi sơ đồ người đọc thấy không còn chữ nào.
    if mmd_ok; then
      STUC="$(for _e in $EF; do mmd --states "$_e"; done | awk -F'\t' '$3 ~ /UC-[0-9]+/' | head -1)"
      if [ -n "$STUC" ]; then ok "state diagram có mũi tên gắn UC có thật (nhãn parse được)"
      elif cat /dev/null $EF | grep -qE '\-\->.*UC-[0-9]+'; then
        bad "state diagram có chữ UC-### nhưng mermaid KHÔNG đọc ra nhãn nào mang UC — nhãn đang bị mất khi render:"
        mmd_lint $EF || true
      else bad "state diagram còn '<UC-### ...>' của template — cần ít nhất một mũi tên ghi UC có thật kéo trạng thái đó"; fi
    else
      cat /dev/null $EF | grep -qE '\-\->.*UC-[0-9]+' && ok "state diagram có mũi tên gắn UC có thật" \
        || bad "state diagram còn '<UC-### ...>' của template — cần ít nhất một mũi tên ghi UC có thật kéo trạng thái đó"
    fi
    mmd_lint $EF || bad "sơ đồ mermaid của entity không render được — sửa rồi chạy lại"
  else
    warn "entity chưa có state diagram nào"
  fi
fi
# glossary: trước 3.3.0 KHÔNG script nào nhắc tới nó — grep -ric glossar scripts/ ra 0.
# Nên nó trôi im lặng suốt, trong khi CLAUDE.md của dự án bảo AI dùng đúng tên trong đó.
GF="$GFS"
if [ -z "$GF" ]; then warn "chưa có specs/glossary.md"
elif cat /dev/null $GF | grep -qE '<Thuật ngữ>|<Context A>'; then
  bad "specs/glossary.md còn nguyên template — CLAUDE.md bảo dùng đúng tên trong đó, mà trong đó chưa có tên nào"
  # Nói cái gì sai và vì sao là chưa đủ: "viết glossary đi" là một trang giấy
  # trắng. Người ở bước này gần như luôn đã viết xong entities.md, và tên entity
  # chính là mẻ thuật ngữ đầu tiên — biến trang trắng thành việc chép. So với
  # dòng cảnh báo P#/X# ở §5, vốn nói luôn phải gõ gì. Xem #24.
  ENTN="$(entity_names "$F" "$ROOT" | tr '\n' ' ')"
  if [ -n "$ENTN" ]; then
    info "mẻ đầu có sẵn — tên entity anh đã viết: $ENTN"
  else
    info "mẻ đầu lấy từ tên entity ($(entity_hint))"
  fi
  if [ "$(layout "$ROOT")" = v7 ]; then
    info "mỗi dòng một từ:  - **Tên** — nghĩa một câu. Từ xuyên suốt vào specs/glossary.md, từ riêng nghề vào specs/$CTX/glossary.md. Không nhầm với **từ gần nghĩa**."
  else
    info "mỗi dòng một từ, dưới heading '## $CTX':  - **Tên** — nghĩa một câu. Không nhầm với **từ gần nghĩa**."
  fi
else
  GN="$(cat /dev/null $GF | grep -cE '^- \*\*[^<]')"; [ -z "$GN" ] && GN=0
  [ "$GN" -ge 1 ] && ok "glossary có $GN thuật ngữ" || bad "specs/glossary.md chưa có dòng '- **từ** — nghĩa' nào"
fi

siblings
# 7.0: UC của lõi không được biết nghề — layer-check chỉ CẢNH BÁO ở đây (repo vừa migrate còn nợ cũ; githook
# pre-commit.d/20-layer-boundary chặn nợ mới khi bật).
if [ "$CTX" = core ] && [ -f "$HERE/layer-check.sh" ]; then
  LCO="$(bash "$HERE/layer-check.sh" --file "$F" "$DIR/$ID.flow.md" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep '✗' | head -3)"
  [ -n "$LCO" ] && { warn "UC ở core trích ID của nghề — lõi không biết nghề (layer-check.sh):"; printf '%s\n' "$LCO" | cut -c1-110 | sed 's/^/      /'; }
fi

# 7. adversarial pass có nội dung
AP="$(sed -n '/^## Adversarial pass/,/^## /p' "$F")"
if echo "$AP" | grep -qE 'Ngày chạy: *[0-9]{4}-[0-9]{2}-[0-9]{2}'; then ok "adversarial pass đã chạy"; else bad "mục ## Adversarial pass chưa có 'Ngày chạy: YYYY-MM-DD'"; fi
echo "$AP" | grep -qE '<câu hỏi|→ xử lý ở đâu>' && bad "adversarial pass còn placeholder"
# Lời khai "→ spec" phải kèm ID có thật, nếu không thì không ai kiểm được là
# đã thực hiện hay chưa — chính adversarial pass bắt ra chỗ này. Xem #12.
SO="$(echo "$AP" | grep -E '→ *spec' || true)"
if [ -n "$SO" ]; then
  while IFS= read -r ln; do
    [ -z "$ln" ] && continue
    IDS="$(printf '%s' "$ln" | sed 's/.*→ *spec//' | grep -oE '(RULE-[0-9]+|AC-[0-9]+|E[0-9]+)' | sort -u)"
    if [ -z "$IDS" ]; then
      bad "adversarial: '→ spec' không kèm ID nên không kiểm được: $(printf '%s' "$ln" | cut -c1-60)"
      continue
    fi
    for id in $IDS; do
      case "$id" in
        RULE-*) [ -n "$(rule_file "$id" "$ROOT")" ] && ok "adversarial → $id có thật" || bad "adversarial khai → $id nhưng rules.md không có";;
        AC-*)   grep -qE "^### $id\b" "$F" && ok "adversarial → $id có thật" || bad "adversarial khai → $id nhưng UC không có";;
        E*)     grep -qE "^- +(\*\*)?$id[.:]" "$F" && ok "adversarial → $id có thật" || bad "adversarial khai → $id nhưng UC không có";;
      esac
    done
  done <<< "$SO"
fi

# 7b. Ba vai chạy rồi mà đa số câu chưa có đầu ra thì adversarial pass mới xong
# một nửa: đã HỎI nhưng chưa QUYẾT. Đo được (#25 đo 21/24 trên ca thật), nên nói.
AQ="$(printf '%s' "$AP" | grep -cE '^[[:space:]]*- Q[0-9]+')"; [ -z "$AQ" ] && AQ=0
AE="$(printf '%s' "$AP" | grep -cE 'đầu ra: *_{2,}')"; [ -z "$AE" ] && AE=0
if [ "$AQ" -ge 3 ] && [ "$AE" -gt $((AQ/2)) ]; then
  warn "$AE/$AQ câu adversarial còn 'đầu ra: ___' — đã hỏi nhưng chưa quyết. Chạy lại /sdd-solo:adversarial $ID để nó trình từng câu kèm ngữ cảnh và lựa chọn."
fi

# 7c. Giả định triển khai — CẢNH BÁO, không chặn (#35).
# Bốn tầng yêu cầu (BR/UC/Entity/AC) không có ngăn nào cho "dựng bằng gì, chạy ở
# đâu, ai gọi". Nên thiết kế rơi vào /speckit-plan, mà nó nằm SAU cổng này. Ca
# thật: UC qua cổng với Main Flow giả định một CLI chạy trên máy; hôm sau plan
# mới lộ ra sản phẩm là server remote, ba câu trong Main Flow không thi hành
# được, phải mở cổng ra sửa. Cổng không quyết hộ được kiến trúc — nhưng bắt NÓI
# RA giả định thì rẻ, và đúng ca đó đã bị bắt.
if grep -qE '^\*\*Giả định triển khai:\*\* *[^ <]' "$F"; then
  ok "có **Giả định triển khai:** — ghi rõ ngăn xếp/nơi chạy/ai gọi"
else
  warn "UC chưa ghi '**Giả định triển khai:** <chạy ở đâu · ai gọi · ngăn xếp>' — Main Flow đang đứng trên một giả định chưa ai viết ra"
  info "một dòng là đủ. Không có nó thì bước ⑩ /sdd-solo:design không có gì để đối chiếu với specs/internal/architecture.md."
fi

# 8. open questions phải có quyết định tạm
OQ="$(sed -n '/^## Open Questions/,/^## /p' "$F" | grep -E '^- \[ \]')"
if [ -n "$OQ" ]; then echo "$OQ" | grep -vqi 'quyết định tạm' && bad "Open Question chưa có (quyết định tạm: ...)" || ok "Open Questions có quyết định tạm"; fi

# 9. commit docs + đọc lại bằng đầu chưa neo
#
# MỘT CỬA (6.0.0, #38): verify là bắt buộc. Thứ bước ⑧ cần là một người đọc KHÔNG
# BỊ NEO bởi giả định của người viết. Luật gốc mua thứ đó bằng một đêm lịch; 3.5.0
# (#27) mở thêm cửa 2 (verify) vì một đêm đo THỜI GIAN TRÔI QUA, không đo VIỆC ĐỌC
# CÓ XẢY RA KHÔNG: cùng người, cùng cái neo, sáng mai lướt 30 giây vẫn qua cổng.
# Giữ cửa 1 thêm hai bản lớn nữa thì thấy: nó vẫn là đường rẻ nhất nên vẫn là
# đường được đi — chủ dự án chốt bỏ hẳn (runxops 2026-09-13, CHG-001 đứng ở
# change-check chỉ vì "mới hôm nay").
#
# Cửa còn lại đo đúng thứ cần đo: có một lần đọc đã xảy ra và đã ra kết quả. Chốt
# chống khai gian nằm ở chỗ dòng F# phải CÓ NEO và CÓ ĐẦU RA — bịa một dòng như vậy
# tốn đúng bằng đọc thật. Và commit đọc lại phải là commit spec MỚI NHẤT: sửa spec
# sau khi đọc lại thì đọc lại lần nữa, bất kể ngày. Đọc mà không thấy gì thì cổng
# không mở — chủ ý: một lần đọc bằng đầu chưa neo trên spec cỡ UC mà không ra một
# phát hiện nào (kể cả bị bác "không phải lỗi vì") là phạm vi đọc quá hẹp.
RR="$(rr_lines "$F")"; RRN=0; RRU=0
[ -n "$RR" ] && { RRN="$(printf '%s\n' "$RR" | rr_count)"; RRU="$(printf '%s\n' "$RR" | rr_undecided)"; }
[ -z "$RRU" ] && RRU=0
# Lời khai trong ## Đọc lại phải kèm ID CÓ THẬT — y hệt luật của §7 cho
# adversarial (#12). Ca thật (runxops): một dòng F# khai '→ sửa RULE-007' sau khi
# người sửa đã đổi lại mã; thân sửa xong, còn CHỖ GHI LẠI VIỆC SỬA thì không —
# tức mục ## Đọc lại tự nó là một chỗ trôi được, và nó trôi ngay trong lượt đọc
# lại. Không kiểm thì cửa 2 mở bằng một lời khai trỏ vào chỗ không tồn tại.
if [ -n "$RR" ]; then
  while IFS= read -r ln; do
    [ -z "$ln" ] && continue
    # 7.0.1 (#53): `→ Chưa quyết (… · đề xuất: thêm AC-9)` là ĐỀ XUẤT chờ chủ dự án, không phải lời khai đã sửa —
    # ID trong đó được phép chưa tồn tại. Verify không hỏi nữa nên mọi dòng chưa bác đều có dạng này.
    # 7.4 (P-37): chỉ xét ĐUÔI SỐNG — chữ sau mũi tên cuối, bỏ (…) và `…` (rr_tail). Tới 7.3 `case *"→ Chưa quyết"*`
    # miễn cả dòng, nên đuôi sống "→ sửa AC-9" núp trước một cụm trích "(→ Chưa quyết …)" thoát kiểm; ngược lại mũi tên
    # trong trích dẫn "`✗ … → E4 …`" không phải đầu ra. Đuôi là "Chưa quyết …" thì ID trong đó là đề xuất, được phép chưa có.
    tl="$(printf '%s\n' "$ln" | rr_tail)"
    [ -z "$tl" ] && continue
    case "$tl" in *"Chưa quyết"*) continue;; esac
    for id in $(printf '%s' "$tl" | grep -oE '(RULE-[0-9]+|AC-[0-9]+|E[0-9]+)' | sort -u); do
      case "$id" in
        RULE-*) [ -n "$(rule_file "$id" "$ROOT")" ] || bad "đọc lại khai → $id nhưng rules.md không có";;
        AC-*)   grep -qE "^### $id\b" "$F" || bad "đọc lại khai → $id nhưng UC không có";;
        E*)     grep -qE "^- +(\*\*)?$id[.:]" "$F" || bad "đọc lại khai → $id nhưng UC không có";;
      esac
    done
  done <<< "$RR"
fi
# 5.2.0: chỉ tính commit docs($ID) có ĐỤNG SPEC — file UC, flow, screens/, rules.md,
# entities.md. Trước đây grep tiêu đề là đủ, nên commit `docs(UC-###): thiết kế —
# design.md + tasks.md` ở bước ⑩ (skill design §6 bảo đặt tên thế) làm cổng đỏ tới hôm
# sau dù UC-###.md không đổi một byte. "Luật đúng, phạm vi sai" — và đỏ oan thì bị học
# cách phớt lờ. Ca thật: runxops UC-009 đỏ ngay sau khi commit design.md (runxops-ea).
# Lỗ còn lại, biết mà chưa xử: sửa rules.md dưới tiêu đề docs(UC-010) hay docs(RULE-###)
# thì UC-009 không thấy — bỏ grep tiêu đề sẽ đúng nghĩa hơn nhưng làm mọi UC cùng
# context đỏ khi ai đó sửa rules.md; chưa có ca thật để cân.
# 7.0: pathspec gồm cả đường 6.x — commit docs($ID) trước migrate nằm ở specs/contexts/…; git log
# không --follow nên phải kể tên cũ, không thì UC dời sang cây mới mất sạch lịch sử đọc lại (#55).
# 7.4 (P-31): đường UC trong pathspec là MẪU `specs/*/br-*/use-cases/ID-*/…`, không phải đường hiện tại — git log
# không --follow, UC vừa `git mv` sang lát khác thì mọi commit đọc lại ở đường cũ biến mất và cổng đỏ "đổi HÀNH VI
# (không rõ)". Mẫu phải tới tay git nguyên vẹn: glog tắt glob của shell (cwd là repo thì shell nở mẫu thành đường
# hiện tại, đúng cái bẫy đang tránh).
if [ "$(layout "$ROOT")" = v7 ]; then
  SPECP="specs/*/br-*/use-cases/$ID-*/$ID.md specs/*/br-*/use-cases/$ID-*/$ID.flow.md specs/*/br-*/use-cases/$ID-*/screens $RFS $EFS specs/contexts/*/use-cases/$ID-*/$ID.md specs/contexts/*/use-cases/$ID-*/$ID.flow.md specs/contexts/*/use-cases/$ID-*/screens specs/contexts/*/entities.md specs/rules.md"
else
  SPECP="$F $DIR/$ID.flow.md $DIR/screens $RFS $EFS"
fi
glog() { set -f; git -C "$ROOT" log "$@" -- $SPECP 2>/dev/null; set +f; }
LAST="$(glog -1 --format=%cs --grep="^docs($ID)")"
LASTS="$(glog -1 --format=%s --grep="^docs($ID)")"
# #49: commit đọc lại gần nhất, và "vân tay hành vi" của spec ở một revision. Ca thật runxops
# UC-014: sáu lần đọc lại (19 → 23 → 11 → 7 → 7 → 10) vì mỗi đợt áp chữ/nhãn ở file bên cạnh
# cũng kéo theo một lượt verify trọn (~200 KB, ~10 phút). Chủ dự án chốt: chỉ MÂU THUẪN HAI CHỖ
# hoặc AC KHÔNG TEST ĐƯỢC là chặn; nợ chữ áp không cần verify lại. Cổng vì thế cho qua commit
# sau lần đọc lại NẾU vân tay hành vi không đổi: Main/Alternative/Exceptions/Postconditions/AC
# của UC · flow.md · phát biểu RULE được trích (bỏ dòng Áp dụng cho) · mermaid của entities.md.
# Đổi bất cứ vùng nào trong đó là đổi hành vi → đọc lại lần nữa (trọn hoặc --since).
# 7.4: hàm vân tay (spec_fp · fp_changed) dời sang lib.sh — close-check dùng chung (P-10).
RH="$(glog -1 --format=%H --grep="^docs($ID): đọc lại")"
FP_CHANGED=""; FP_SKIP=""
[ -n "$RH" ] && FP_CHANGED="$(fp_changed "$ROOT" "$ID" "$RH" HEAD "$EFS")"
# commit gần nhất chạm spec, BẤT KỂ tiêu đề — để câu báo "đổi HÀNH VI" chỉ đúng commit (docs(RULE-###) sửa phát biểu
# rule không mang tên UC, P-35).
LASTANY="$(glog -1 --format='%s (%cs)')"
# Phải dùng `case`, KHÔNG dùng ${LASTS#docs($ID): ...}: dấu ngoặc đơn trong
# pattern của phép bóc tiền tố làm nó không khớp gì cả, im lặng — đo được:
# chuỗi trả về y nguyên chuỗi vào, nên điều kiện luôn sai và cửa không bao
# giờ mở. Cùng họ với bẫy `ls a b` (#16): hỏng lặng lẽ, không báo lỗi.
RRC=0; case "$LASTS" in "docs($ID): đọc lại"*) RRC=1;; esac
# 7.4 (P-20): nói ra bao nhiêu phát hiện còn "→ Chưa quyết" — đầu ra hợp lệ (7.0.1 #53) nhưng cổng mở với chúng là nợ
# chủ dự án tự nhận; ✓ không được giống hệt nhau ở "đã quyết hết" và "chưa quyết gì".
rr_warn() { [ "$RRU" -gt 0 ] && warn "$RRU/$RRN phát hiện còn '→ Chưa quyết (chờ chủ dự án …)' — cổng mở là nợ anh tự nhận (#53); trả lời rồi đổi đuôi thành '→ Đã quyết: …' hoặc sửa spec + verify --since"; return 0; }
if [ "$ST" = implemented ]; then
  # 7.4 (P-16): UC đã đóng — mốc so là COMMIT ĐÓNG, không phải lần đọc lại (## Đọc lại đã nén còn một dòng, so với
  # nó thì mọi commit docs sau đóng đều đỏ "chưa đọc lại"/"đổi HÀNH VI" oan). §0 đã đỏ vì status; ở đây chỉ nói thêm
  # spec sau đóng có đổi hành vi không — có thì đó là việc của Phase 5, không phải của cổng này.
  CH="$(glog -1 --format=%H --grep="^docs($ID): implemented — traceability")"
  if [ -n "$CH" ]; then
    CHG="$(fp_changed "$ROOT" "$ID" "$CH" HEAD "$EFS")"
    if [ -z "$CHG" ]; then ok "sau commit đóng UC, spec chỉ đổi ngoài vùng hành vi — §9 không áp cho UC đã implemented"
    else bad "spec đổi HÀNH VI sau khi đóng UC — vùng:$CHG; UC implemented đổi hành vi đi qua Phase 5 (/sdd-solo:change), không sửa thẳng"; fi
  else info "UC implemented không có commit đóng của pass.sh close — §9 không áp"; fi
elif [ "$ST" = deprecated ]; then info "UC deprecated — §9 không áp"
elif [ -z "$LAST" ]; then bad "chưa có commit docs($ID) — /sdd-solo:adversarial kết thúc bằng commit này"
elif [ "$LASTS" = "docs($ID): spec reviewed — qua cổng DoR" ]; then
  # Commit spec mới nhất do chính gate-pass tạo, không phải người sửa spec. Không có
  # nhánh này thì hành động qua cổng tự phá điều kiện qua cổng (#7). Sửa spec THẬT sau
  # khi qua cổng sinh commit khác tiêu đề → rơi xuống nhánh cuối, phải đọc lại.
  ok "docs($ID) mới nhất là commit của gate-pass — đã qua cổng trước đó"
elif [ "$RRN" -eq 0 ]; then
  bad "chưa đọc lại bằng đầu chưa neo — ## Đọc lại không có dòng F# nào đủ [neo: ...] + đầu ra khác ___"
  info "/sdd-solo:verify $ID (subagent đọc lại, ghi F#, commit riêng). Từ 6.0.0 không còn cửa qua đêm."
elif [ -n "$RH" ] && [ -n "$FP_CHANGED" ]; then
  # 7.4 (P-35): so vân tay TRƯỚC khi tin "commit đọc lại là commit spec mới nhất" — commit docs(RULE-###) sửa phát
  # biểu rule không mang tên UC nên LASTS vẫn là đọc lại, mà hành vi đã đổi.
  bad "spec đổi HÀNH VI sau lần đọc lại — commit chạm spec mới nhất là '$LASTANY'; vùng đổi:$FP_CHANGED"
  info "chạy lại /sdd-solo:verify $ID --since $(git -C "$ROOT" log -1 --format=%h "$RH" 2>/dev/null) — chỉ đọc phần đổi từ lần đọc lại trước; commit đọc lại mới sẽ là mốc mới"
  # #41: "đủ để sửa, thiếu để hiểu" — nói luôn thứ tự, để lần sau người ta áp phiếu TRƯỚC verify.
  info "thứ tự: áp hết phát hiện ⑦ (kể cả chữ/nhãn, file bên cạnh) → ⑧ verify → ⑨ gate, liền nhau; sửa spec sau ⑧ là chấp nhận đọc lại lần nữa"
elif [ "$RRC" = 1 ]; then
  ok "đọc lại bằng đầu chưa neo: $RRN phát hiện có neo + đầu ra, commit riêng là commit spec mới nhất (#27, #38)"
  rr_warn
elif [ -n "$RH" ]; then
  NCH="$(glog --format=%h "$RH..HEAD" --grep="^docs($ID)" | wc -l | tr -d ' ')"
  ok "đọc lại: $RRN phát hiện có neo + đầu ra; $NCH commit spec sau đó chỉ áp chữ/nhãn — Main/Alt/Exceptions/Postconditions/AC · flow · phát biểu RULE · mermaid entities không đổi (#49)"
  [ -n "$FP_SKIP" ] && info "lần đọc lại nằm trước migrate v7 — vùng mermaid entities không so được qua mốc đó (một file/context → một file/entity); tự soát tay nếu có đổi entity"
  rr_warn
else
  bad "spec đổi HÀNH VI sau lần đọc lại — commit docs($ID) mới nhất là '$LASTS' ($LAST); không tìm thấy commit 'docs($ID): đọc lại' để so vân tay"
  info "chạy /sdd-solo:verify $ID — commit đọc lại mới sẽ là mốc"
fi
git -C "$ROOT" status --porcelain -- "$DIR" $RFS 2>/dev/null | grep -q . && bad "còn thay đổi chưa commit trong spec — commit docs($ID) trước"

echo
if [ "$FAIL" -eq 0 ]; then echo "QUA CỔNG ($WARN cảnh báo)."; exit 0; else echo "KHÔNG QUA CỔNG — $FAIL lỗi, $WARN cảnh báo. Sửa rồi chạy lại."; exit 1; fi
