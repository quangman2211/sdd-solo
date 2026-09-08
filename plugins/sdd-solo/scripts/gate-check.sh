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
  grep -qE "^## $r\b" "$RF" 2>/dev/null && ok "$r có trong rules.md" || bad "$r được trích nhưng không có heading trong specs/rules.md"
done

# 5. BPMN
# 2.0.0: .bpmn nằm TRONG thư mục UC, không còn ở diagrams/ cấp context.
BP="$DIR/$ID.bpmn"
OLD="$ROOT/specs/contexts/$CTX/diagrams/$ID.bpmn"
if [ -f "$BP" ]; then ok "$ID.bpmn (trong thư mục UC)"
elif [ -f "$OLD" ]; then bad "$ID.bpmn còn ở chỗ cũ specs/contexts/$CTX/diagrams/ — chạy .sdd/scripts/migrate-1to2.sh"
else bad "thiếu ${DIR#$ROOT/}/$ID.bpmn"; fi
[ -f "$BP.svg" ] || warn "chưa export $ID.bpmn.svg"

# 6. entities
[ -f "$ROOT/specs/contexts/$CTX/entities.md" ] && ok "context $CTX có entities.md" || bad "thiếu specs/contexts/$CTX/entities.md"
grep -q 'stateDiagram' "$ROOT/specs/contexts/$CTX/entities.md" 2>/dev/null || warn "entities.md chưa có state diagram nào"

# 7. adversarial pass có nội dung
AP="$(sed -n '/^## Adversarial pass/,/^## /p' "$F")"
if echo "$AP" | grep -qE 'Ngày chạy: *[0-9]{4}-[0-9]{2}-[0-9]{2}'; then ok "adversarial pass đã chạy"; else bad "mục ## Adversarial pass chưa có 'Ngày chạy: YYYY-MM-DD'"; fi
echo "$AP" | grep -qE '<câu hỏi|→ xử lý ở đâu>' && bad "adversarial pass còn placeholder"

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
