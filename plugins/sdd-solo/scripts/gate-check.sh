#!/usr/bin/env bash
# gate-check.sh UC-### — Definition of Ready, kiểm cơ học. exit 0 = qua cổng.
ID="$1"; [ -z "$ID" ] && { echo "dùng: gate-check.sh UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
echo "Definition of Ready — $ID"
[ -z "$F" ] && { bad "không tìm thấy specs/contexts/*/use-cases/${ID}-*/${ID}.md"; exit 1; }
CTX="$(ctx_of "$F")"; DIR="$(dirname "$F")"
info "file: ${F#$ROOT/}"

# 0. status
STL="$(grep -E '\*\*Status:\*\*' "$F" | head -1)"; echo "$STL" | grep -q '|' && bad "Status còn là danh sách lựa chọn — chọn một giá trị"
ST="$(echo "$STL" | grep -oE '\*\*Status:\*\* *[a-z]+' | awk '{print $2}')"
case "$ST" in draft|reviewed) ok "status: $ST";; implemented) bad "status đã implemented — dùng Phase 5 (specs/changes/) nếu đổi hành vi";; *) bad "status không hợp lệ: '$ST'";; esac

# 1. các mục bắt buộc
for sec in "## Actor" "## Trigger" "## Preconditions" "## Main Flow" "## Exceptions" "## Postconditions" "## Acceptance Criteria" "## Screens" "## History"; do
  grep -q "^$sec" "$F" && ok "có $sec" || bad "thiếu $sec"
done
grep -qE '<[^>]*>' <(sed -n '/^## Actor/,/^## Alternative/p' "$F" | grep -vE '^\s*$|^##') && warn "còn placeholder <...> trong Actor/Trigger/Flow"

# 2. AC vs E#
EN="$(grep -cE '^- +(\*\*)?E[0-9]+[.:]' "$F")"; AN="$(grep -cE '^### AC-[0-9]+' "$F")"
if [ "$AN" -ge 1 ] && [ "$AN" -ge $((EN+1)) ]; then ok "AC: $AN · Exceptions: $EN (≥ E# + 1)"; else bad "AC: $AN · Exceptions: $EN — cần ≥ 1 AC cho Main + 1 cho mỗi E#"; fi
grep -qE '^Given:' "$F" && grep -qE '^When:' "$F" && grep -qE '^Then:' "$F" && ok "AC dạng Given/When/Then" || bad "AC chưa có Given/When/Then"

# 3. mỗi E# có dòng trong bảng Screens
SCR="$(sed -n '/^## Screens/,/^## /p' "$F")"
for n in $(grep -oE '^- +(\*\*)?E[0-9]+' "$F" | grep -oE '[0-9]+' | sort -un); do
  echo "$SCR" | grep -qE "^\|[[:space:]]*E$n([^0-9]|$)" && ok "E$n có màn hình" || bad "E$n chưa có dòng trong bảng ## Screens"
done
echo "$SCR" | grep -qE 'SCR-[0-9]+-[0-9]+' || bad "chưa có SCR-###-# nào trong ## Screens"

# 4. RULE trích phải có trong rules.md
RF="$ROOT/specs/rules.md"
for r in $(grep -oE 'RULE-[0-9]+' "$F" | sort -u); do
  # grep -c in "0" RỒI exit 1, nên "|| echo 0" tạo chuỗi hai dòng và phá cả
  # hai phép so sánh bên dưới. Đừng thêm fallback ở đây.
  C="$(grep -cE "^## $r\b" "$RF" 2>/dev/null)"; [ -z "$C" ] && C=0
  H="$(grep -E "^## $r\b" "$RF" 2>/dev/null | head -1)"
  if [ "$C" = "0" ]; then bad "$r được trích nhưng không có heading trong specs/rules.md"
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
  LBL="$(grep -E '(-->|==>|-\.->|--x|--o)' "$FL" 2>/dev/null | grep -oE '\|[^|]*\|')"
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
  grep -qE '(^|[[:space:]])E[0-9]+ *[[({]' "$FL" \
    && warn "$ID.flow.md đặt id node dạng E<số> — dễ đọc nhầm thành ngoại lệ; dùng P# cho node kết thường, X# cho node kết của ngoại lệ"
elif [ -f "$BP" ]; then
  ok "$ID.bpmn (đường cũ — .flow.md mermaid đếm được E#, cân nhắc chuyển)"
  [ -f "$BP.svg" ] || warn "chưa export $ID.bpmn.svg"
elif [ -f "$OLD" ]; then bad "$ID.bpmn còn ở chỗ cũ specs/contexts/$CTX/diagrams/ — chạy .sdd/scripts/migrate-1to2.sh"
else bad "thiếu ${DIR#$ROOT/}/$ID.flow.md (mermaid) — hoặc $ID.bpmn nếu vẫn dùng BPMN"; fi

# 6. entities + glossary — đo NỘI DUNG, không đo hình dạng.
# Bản trước kiểm `grep -q stateDiagram`, mà template context có sẵn một khối
# stateDiagram-v2 mẫu — nên phép kiểm khớp vào chính nó. entities.md còn nguyên
# class EntityA/EntityB vẫn in ✓ và không warn một chữ. Một phép kiểm báo xanh
# SAI tệ hơn không có phép kiểm: không có thì người ta còn tự nhớ. Cùng hình lỗi
# với #11 (tiền điều kiện đo cấu trúc) và #13 (RULE placeholder). Xem #24.
EF="$ROOT/specs/contexts/$CTX/entities.md"
if [ ! -f "$EF" ]; then bad "thiếu specs/contexts/$CTX/entities.md"
else
  ok "context $CTX có entities.md"
  grep -qE '(class|## )Entity[AB]([^A-Za-z0-9]|$)' "$EF" && bad "entities.md còn EntityA/EntityB của template — chưa đặt tên entity thật"
  grep -q '<Context>' "$EF" && bad "entities.md còn tiêu đề '# Entity Model — <Context>' của template"
  if grep -q 'stateDiagram' "$EF"; then
    # CỐ Ý quét cả file chứ không xét từng mũi tên: chỉ cần MỘT mũi tên gắn UC
    # có thật là qua. Đừng siết thành "mọi mũi tên phải gắn UC" — có trạng thái
    # do THẾ GIỚI BÊN NGOÀI đổi chứ không do UC nào kéo. Ca thật ở runxops:
    # `đangSống --> đãSuspend` là do sàn khoá tài khoản, không UC nào gây ra.
    # Siết per-arrow sẽ ép người ta dán một UC-### giả lên đó — tức bịa, đúng
    # thứ cả quy trình này sinh ra để chặn.
    grep -qE '\-\->.*UC-[0-9]+' "$EF" && ok "state diagram có mũi tên gắn UC có thật" \
      || bad "state diagram còn '<UC-### ...>' của template — cần ít nhất một mũi tên ghi UC có thật kéo trạng thái đó"
  else
    warn "entities.md chưa có state diagram nào"
  fi
fi
# glossary: trước 3.3.0 KHÔNG script nào nhắc tới nó — grep -ric glossar scripts/ ra 0.
# Nên nó trôi im lặng suốt, trong khi CLAUDE.md của dự án bảo AI dùng đúng tên trong đó.
GF="$ROOT/specs/glossary.md"
if [ ! -f "$GF" ]; then warn "chưa có specs/glossary.md"
elif grep -qE '<Thuật ngữ>|<Context A>' "$GF"; then
  bad "specs/glossary.md còn nguyên template — CLAUDE.md bảo dùng đúng tên trong đó, mà trong đó chưa có tên nào"
  # Nói cái gì sai và vì sao là chưa đủ: "viết glossary đi" là một trang giấy
  # trắng. Người ở bước này gần như luôn đã viết xong entities.md, và tên entity
  # chính là mẻ thuật ngữ đầu tiên — biến trang trắng thành việc chép. So với
  # dòng cảnh báo P#/X# ở §5, vốn nói luôn phải gõ gì. Xem #24.
  ENTN="$(grep -oE '^[[:space:]]*class [A-Za-z][A-Za-z0-9_]*' "$EF" 2>/dev/null | awk '{print $2}' | sort -u | tr '\n' ' ')"
  [ -z "$ENTN" ] && ENTN="$(grep -oE '^## [A-Z][A-Za-z0-9_]*' "$EF" 2>/dev/null | awk '{print $2}' \
      | grep -vxE 'Domain|History|Entity' | sort -u | tr '\n' ' ')"
  if [ -n "$ENTN" ]; then
    info "mẻ đầu có sẵn — tên entity anh đã viết: $ENTN"
  else
    info "mẻ đầu lấy từ tên entity trong specs/contexts/$CTX/entities.md"
  fi
  info "mỗi dòng một từ, dưới heading '## $CTX':  - **Tên** — nghĩa một câu. Không nhầm với **từ gần nghĩa**."
else
  GN="$(grep -cE '^- \*\*[^<]' "$GF")"; [ -z "$GN" ] && GN=0
  [ "$GN" -ge 1 ] && ok "glossary có $GN thuật ngữ" || bad "specs/glossary.md chưa có dòng '- **từ** — nghĩa' nào"
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
        RULE-*) grep -qE "^## $id\b" "$RF" 2>/dev/null && ok "adversarial → $id có thật" || bad "adversarial khai → $id nhưng rules.md không có";;
        AC-*)   grep -qE "^### $id\b" "$F" && ok "adversarial → $id có thật" || bad "adversarial khai → $id nhưng UC không có";;
        E*)     grep -qE "^- +(\*\*)?$id[.:]" "$F" && ok "adversarial → $id có thật" || bad "adversarial khai → $id nhưng UC không có";;
      esac
    done
  done <<< "$SO"
fi

# 8. open questions phải có quyết định tạm
OQ="$(sed -n '/^## Open Questions/,/^## /p' "$F" | grep -E '^- \[ \]')"
if [ -n "$OQ" ]; then echo "$OQ" | grep -vqi 'quyết định tạm' && bad "Open Question chưa có (quyết định tạm: ...)" || ok "Open Questions có quyết định tạm"; fi

# 9. commit docs + ngủ qua đêm
LAST="$(git -C "$ROOT" log -1 --format=%cs --grep="^docs($ID)" 2>/dev/null)"
LASTS="$(git -C "$ROOT" log -1 --format=%s --grep="^docs($ID)" 2>/dev/null)"
if [ -z "$LAST" ]; then bad "chưa có commit docs($ID) — /sdd-solo:adversarial kết thúc bằng commit này"
elif [ "$LAST" = "$(today)" ] && [ "$LASTS" = "docs($ID): spec reviewed — qua cổng DoR" ]; then
  # Commit docs mới nhất do chính gate-pass tạo, không phải người sửa spec.
  # Không có nhánh này thì hành động qua cổng tự phá điều kiện qua cổng và
  # gate-check đỏ liên tục tới hôm sau. Sửa spec THẬT sau khi qua cổng vẫn
  # sinh commit docs khác tiêu đề, nên vẫn phải ngủ lại một đêm. Xem #7.
  ok "docs($ID) hôm nay là commit của gate-pass — đã qua cổng trước đó"
elif [ "$LAST" = "$(today)" ]; then bad "commit docs($ID) mới hôm nay ($LAST) — spec phải được đọc lại ở một buổi khác"
else ok "docs($ID) commit $LAST — đã qua ít nhất một đêm"; fi
git -C "$ROOT" status --porcelain -- "$DIR" "$RF" 2>/dev/null | grep -q . && bad "còn thay đổi chưa commit trong spec — commit docs($ID) trước"

echo
if [ "$FAIL" -eq 0 ]; then echo "QUA CỔNG ($WARN cảnh báo)."; exit 0; else echo "KHÔNG QUA CỔNG — $FAIL lỗi, $WARN cảnh báo. Sửa rồi chạy lại."; exit 1; fi
