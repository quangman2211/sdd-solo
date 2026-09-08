#!/usr/bin/env bash
# change-check.sh CHG-### — cổng Phase 5, kiểm cơ học. exit 0 = được sửa code theo change.
# Phase 3 có 22 kiểm ở gate-check.sh; trước 3.0.0 Phase 5 không có kiểm nào, nên một
# change đụng vào hành vi ĐÃ giao cho khách vẫn vào repo được với mô tả rỗng, không
# nói đụng UC nào, không nói lật AC nào. Xem #16.
ID="$1"; [ -z "$ID" ] && { echo "dùng: change-check.sh CHG-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; D="$(find_chg "$ID" "$ROOT")"
echo "Cổng Phase 5 — $ID"
[ -z "$D" ] && { bad "không tìm thấy specs/changes/${ID}-*/"; exit 1; }
info "thư mục: ${D#$ROOT/}"

# sect <file> <heading> — nội dung một mục, bỏ chính dòng heading
sect() { awk -v h="$2" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}' "$1" 2>/dev/null; }
nonempty() { printf '%s' "$1" | grep -qvE '^[[:space:]]*$'; }
# filled — có nội dung THẬT: không rỗng, không còn <...>, và không phải toàn dòng
# "..." của template. Bản đầu chỉ kiểm rỗng nên "- ..." trong ## Rủi ro và cách lùi
# đi qua cổng như một câu trả lời hợp lệ.
filled() {
  nonempty "$1" || return 1
  printf '%s' "$1" | grep -qE '<[^>]+>' && return 1
  printf '%s' "$1" | grep -vE '^[[:space:]]*$' \
    | grep -qvE '^[[:space:]]*([-*][[:space:]]*)?\.\.\.[[:space:]]*$' || return 1
  return 0
}

P="$D/proposal.md"; G="$D/design.md"; T="$D/tasks.md"
for f in proposal.md design.md tasks.md; do
  [ -f "$D/$f" ] && ok "có $f" || bad "thiếu ${D#$ROOT/}/$f"
done
[ -d "$D/delta" ] && ok "có delta/" || bad "thiếu ${D#$ROOT/}/delta/"
[ -f "$P" ] || { echo; echo "KHÔNG QUA CỔNG — $FAIL lỗi."; exit 1; }

# 1. tiêu đề và status
grep -qE "^# $ID: *<" "$P" && bad "tiêu đề còn placeholder <Tên thay đổi>"
grep -qE "^# $ID: *[^ <]" "$P" && ok "có tiêu đề" || bad "dòng đầu proposal.md phải là '# $ID: <tên thật>'"
grep -qE 'CHG-000' "$P" "$G" "$T" 2>/dev/null && bad "còn chuỗi CHG-000 của template — sửa thành $ID"
STL="$(sect "$P" "## Status" | grep -vE '^[[:space:]]*$' | head -1)"
printf '%s' "$STL" | grep -q '|' && bad "Status còn là danh sách lựa chọn — chọn một giá trị"
ST="$(printf '%s' "$STL" | tr -d '[:space:]')"
case "$ST" in
  proposed|specified|designed) ok "status: $ST";;
  applying)  bad "status đã applying — change này đã qua cổng rồi";;
  verified|archived) bad "status $ST — change đã đóng, không mở lại; tạo CHG mới";;
  dropped)   bad "status dropped — change đã bỏ";;
  *)         bad "status không hợp lệ: '$ST'";;
esac

# 2. Why · Impact — hai mục người ta hay để nguyên template nhất
for h in "## Why" "## Impact on customers"; do
  S="$(sect "$P" "$h")"
  if ! nonempty "$S"; then bad "$h rỗng"
  elif ! filled "$S"; then bad "$h còn placeholder của template"
  else ok "$h có nội dung"; fi
done

# 3. Scope — UC bị ảnh hưởng phải CÓ THẬT, đã implemented, đã qua cổng DoR.
# UC còn draft nghĩa là chưa giao cho ai; sửa thẳng ở Phase 3 rẻ hơn nhiều.
SC="$(sect "$P" "## Scope")"
UCS="$(printf '%s' "$SC" | grep -oE 'UC-[0-9]+' | sort -u)"
if [ -z "$UCS" ]; then bad "## Scope không nêu UC nào bị ảnh hưởng"; fi
for u in $UCS; do
  UF="$(find_uc "$u" "$ROOT")"
  if [ -z "$UF" ]; then bad "Scope nêu $u nhưng không có file UC — ID bịa"; continue; fi
  UST="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$UF" | head -1 | awk '{print $2}')"
  if [ "$UST" != "implemented" ]; then
    bad "$u đang '$UST', chưa implemented — sửa thẳng ở Phase 3 (History v+1), đừng mở change"
  elif [ ! -f "$ROOT/.sdd/gate/$u.ok" ]; then
    bad "$u implemented nhưng không có .sdd/gate/$u.ok — baseline không tin được"
  else ok "$u implemented, đã qua cổng"; fi
done
for r in $(printf '%s' "$SC" | grep -oE 'RULE-[0-9]+' | sort -u); do
  grep -qE "^## $r\b" "$ROOT/specs/rules.md" 2>/dev/null && ok "$r có trong rules.md" \
    || bad "Scope nêu $r nhưng rules.md không có heading"
done

# 4. History
printf '%s' "$(sect "$P" "## History")" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
  && ok "History có dòng ghi ngày" || bad "## History chưa có dòng 'YYYY-MM-DD: ...'"

# 5. design.md
if [ -f "$G" ]; then
  filled "$(sect "$G" "## Hướng kỹ thuật")" && ok "design.md có hướng kỹ thuật" \
    || bad "design.md ## Hướng kỹ thuật rỗng hoặc còn placeholder"
  for a in $(grep -oE 'ADR-[0-9]+' "$G" | sort -u); do
    if ls "$ROOT/specs/internal/adr/$a"* >/dev/null 2>&1 || ls "$ROOT/docs/adr/$a"* >/dev/null 2>&1; then
      ok "$a có file"
    else bad "design.md nêu $a nhưng không có file trong specs/internal/adr/"; fi
  done
  grep -qE 'SCR-[0-9]+-[0-9]+' "$G" || warn "design.md chưa nêu SCR-###-# nào — change không đụng màn hình nào thật à?"
  filled "$(sect "$G" "## Rủi ro và cách lùi")" && ok "có rủi ro và cách lùi" \
    || bad "design.md ## Rủi ro và cách lùi rỗng hoặc còn '...' — đổi hành vi đã giao thì phải nói đường lùi"
fi

# 6. tasks.md
if [ -f "$T" ]; then
  TC="$(grep -cE '^- \[[ x]\]' "$T")"; [ -z "$TC" ] && TC=0
  [ "$TC" -ge 1 ] && ok "tasks.md có $TC việc" || bad "tasks.md chưa có dòng '- [ ] ...' nào"
  grep -qE '^- \[[ x]\].*(Archive|archive)' "$T" && ok "có việc archive cuối vòng" \
    || warn "tasks.md chưa có việc archive — baseline sẽ không bao giờ được merge lại"
fi

# 7. delta — phần đắt nhất. Mỗi UC trong Scope phải có một delta, và delta phải
# nói đúng về baseline: không bỏ AC không tồn tại, không thêm AC trùng số.
MODS=0
[ -f "$D/delta/UC-000.delta.md" ] && [ -z "$(find_uc UC-000 "$ROOT")" ] \
  && bad "còn delta/UC-000.delta.md của template — xoá hoặc đổi tên theo UC thật"
for u in $UCS; do
  DF="$D/delta/$u.delta.md"
  if [ ! -f "$DF" ]; then bad "Scope nêu $u nhưng thiếu delta/$u.delta.md"; continue; fi
  UF="$(find_uc "$u" "$ROOT")"; [ -z "$UF" ] && continue
  HAS=0
  for h in ADDED MODIFIED REMOVED; do
    S="$(awk -v h="## $h" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f{print}' "$DF")"
    nonempty "$S" || continue
    printf '%s' "$S" | grep -qE '^\.\.\.$|<[^>]+>' && bad "delta/$u ## $h còn placeholder"
    HAS=1
    case "$h" in
      ADDED)
        for a in $(printf '%s' "$S" | grep -oE '^### AC-[0-9]+' | grep -oE 'AC-[0-9]+'); do
          grep -qE "^### $a\b" "$UF" && bad "delta/$u ADDED $a nhưng baseline đã có $a — trùng số, đánh số tiếp đi" \
            || ok "delta/$u thêm $a"
        done
        printf '%s' "$S" | grep -qE '^Given:' && printf '%s' "$S" | grep -qE '^Then:' \
          || bad "delta/$u ADDED chưa có Given/When/Then";;
      MODIFIED)
        MODS=$((MODS+1))
        for x in $(printf '%s' "$S" | grep -oE '^### (AC-[0-9]+|E[0-9]+)' | awk '{print $2}'); do
          case "$x" in
            AC-*) grep -qE "^### $x\b" "$UF" && ok "delta/$u sửa $x" || bad "delta/$u MODIFIED $x nhưng baseline không có $x";;
            E*)   grep -qE "^- +(\*\*)?$x[.:]" "$UF" && ok "delta/$u sửa $x" || bad "delta/$u MODIFIED $x nhưng baseline không có $x";;
          esac
        done
        printf '%s' "$S" | grep -qE '^Cũ:' && printf '%s' "$S" | grep -qE '^Mới:' \
          || bad "delta/$u MODIFIED phải ghi cả 'Cũ:' và 'Mới:' — không có thì không ai review được";;
      REMOVED)
        MODS=$((MODS+1))
        while IFS= read -r ln; do
          printf '%s' "$ln" | grep -qE '^### ' || continue
          x="$(printf '%s' "$ln" | grep -oE '(AC-[0-9]+|E[0-9]+)' | head -1)"
          [ -z "$x" ] && { bad "delta/$u REMOVED thiếu ID: $(printf '%s' "$ln" | cut -c1-50)"; continue; }
          grep -qE "^### $x\b|^- +(\*\*)?$x[.:]" "$UF" || bad "delta/$u REMOVED $x nhưng baseline không có $x"
          printf '%s' "$ln" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
            || bad "delta/$u REMOVED $x chưa ghi ngày deprecated"
          printf '%s' "$ln" | grep -qiE 'lý do' \
            || bad "delta/$u REMOVED $x chưa ghi lý do"
        done <<< "$S";;
    esac
  done
  [ "$HAS" = 0 ] && bad "delta/$u không có mục ADDED/MODIFIED/REMOVED nào có nội dung"
done
# Phase 5 tồn tại để lật AC đã giao. Chỉ thêm AC mới thì đó là Phase 3.
if [ "$MODS" = 0 ] && [ -n "$UCS" ]; then
  bad "không delta nào MODIFIED/REMOVED — change chỉ thêm AC, không phá AC cũ → đây là Phase 3 (History v+1), không mở change"
else
  [ "$MODS" -gt 0 ] && ok "$MODS mục lật AC cũ — đúng phạm vi Phase 5"
fi

# 8. commit docs + ngủ qua đêm — cùng luật với cổng DoR. Đổi hành vi đã giao cho
# khách thì lại càng phải đọc lại ở một buổi khác.
LAST="$(git -C "$ROOT" log -1 --format=%cs --grep="^docs($ID)" 2>/dev/null)"
LASTS="$(git -C "$ROOT" log -1 --format=%s --grep="^docs($ID)" 2>/dev/null)"
if [ -z "$LAST" ]; then bad "chưa có commit docs($ID) — commit change rồi để qua một đêm"
elif [ "$LAST" = "$(today)" ] && [ "$LASTS" = "docs($ID): change reviewed — qua cổng Phase 5" ]; then
  ok "docs($ID) hôm nay là commit của change-pass — đã qua cổng trước đó"
elif [ "$LAST" = "$(today)" ]; then bad "commit docs($ID) mới hôm nay ($LAST) — đọc lại ở một buổi khác"
else ok "docs($ID) commit $LAST — đã qua ít nhất một đêm"; fi
git -C "$ROOT" status --porcelain -- "$D" 2>/dev/null | grep -q . && bad "còn thay đổi chưa commit trong $ID"

echo
if [ "$FAIL" -eq 0 ]; then echo "QUA CỔNG PHASE 5 ($WARN cảnh báo)."; exit 0; else echo "KHÔNG QUA CỔNG — $FAIL lỗi, $WARN cảnh báo."; exit 1; fi
