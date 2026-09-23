#!/usr/bin/env bash
# close-check.sh UC-### — Definition of Done. exit 0 = đóng được.
ID="$1"; [ -z "$ID" ] && { echo "dùng: close-check.sh UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
echo "Definition of Done — $ID"
[ -z "$F" ] && { bad "không tìm thấy file UC"; exit 1; }
CTX="$(owner_of "$F")"; SLUG="$(slug_of "$F")"
[ -f "$ROOT/.sdd/gate/$ID.ok" ] && ok "đã qua cổng DoR" || bad "chưa có marker .sdd/gate/$ID.ok — chạy /sdd-solo:gate"
# 7.4 (P-10): marker cổng nói "spec ĐÃ ĐƯỢC đọc lại ở commit X". Sửa AC sau X bằng docs(UC-###) thì marker vẫn còn mà
# điều nó chứng nhận không còn — tới 7.3 không script nào so lại. Vân tay §9 của gate-check (lib: fp_changed) so từ
# commit gate-pass tới HEAD: Main/Alt/Exceptions/Postconditions/AC · flow · phát biểu RULE · mermaid entities.
GH="$(git -C "$ROOT" log -1 -E --format=%H --grep="^docs\($ID\): spec reviewed — ($(kw c_dor))" 2>/dev/null)"
if [ -n "$GH" ]; then
  CHG="$(fp_changed "$ROOT" "$ID" "$GH" HEAD "$(entity_cited "$F" "$ROOT" | tr '\n' ' ')")"
  ST="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$F" | head -1 | awk '{print $2}')"
  if [ -z "$CHG" ]; then ok "vân tay hành vi không đổi kể từ commit qua cổng"
  elif [ "$ST" = implemented ] || [ "$ST" = deprecated ]; then
    # UC đã đóng: đổi sau cổng là vết lịch sử (Phase 5, rule sửa cho UC khác) — không còn gì để verify lại. Đo runxops
    # 7.4: 10/12 UC implemented có vùng đổi; chặn thì close-check đỏ trên thứ đã đóng, và đỏ oan thì bị học cách phớt lờ.
    warn "UC $ST — spec đổi vùng hành vi sau commit qua cổng ($CHG ); vết lịch sử, không áp lại cổng"
  else
    bad "spec đổi HÀNH VI sau khi qua cổng — vùng:$CHG (vân tay §9, #49); marker cổng không còn đúng với spec hiện tại"
    info "/sdd-solo:verify $ID --since $(git -C "$ROOT" log -1 --format=%h "$GH" 2>/dev/null) rồi /sdd-solo:gate lại — gate-pass tạo mốc mới"
  fi
fi
# Tầng thiết kế (4.0.0). Đóng một UC mà không có design.md nghĩa là code đã viết
# ra từ một quyết định kỹ thuật không nằm ở đâu cả — sáu tháng sau không ai đọc
# lại được VÌ SAO nó dựng như thế, và "chưa bàn" trông y hệt "đã bàn rồi quên ghi".
DDIR="$(dirname "$F")"
if [ -f "$DDIR/design.md" ]; then
  ok "có design.md"
  [ -f "$DDIR/tasks.md" ] && ok "có tasks.md" || warn "thiếu tasks.md — mỗi AC lẽ ra có một việc và một test"
else
  bad "thiếu design.md trong thư mục UC — chạy /sdd-solo:design $ID (bước ⑩)"
fi
# test theo AC
UCT="$(uc_test_dir "$ROOT")"
TD="$ROOT/$UCT/$CTX/$ID"
for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
  ls "$TD"/AC-$n.test.* >/dev/null 2>&1 && ok "AC-$n có test" || bad "AC-$n chưa có $UCT/$CTX/$ID/AC-$n.test.*"
done
# thứ tự docs → feat
D0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^docs($ID)" 2>/dev/null | head -1)"
F0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^feat($ID)" 2>/dev/null | head -1)"
if [ -z "$F0" ]; then warn "chưa có commit feat($ID) — commit code trước khi close"
elif [ -n "$D0" ] && [ "$D0" -lt "$F0" ]; then ok "docs($ID) đứng trước feat($ID)"; else bad "feat($ID) không có docs($ID) đứng trước"; fi
# rule ngầm: số literal trong code của UC.
# TẬP FILE CODE CỦA UC — hai nguồn cộng lại (7.0.1, P-15):
#  ① file trong code_paths mà các commit không-merge có `(UC-###)` ở tiêu đề đã chạm, còn tồn tại, không phải test.
#     Bố cục 7.0 đặt code theo KHÁI NIỆM (src/core/domain/session/, web/, deploy/) chứ không theo slug UC; tới
#     7.0.0 chỉ có nguồn ② nên UC-024 runxops đỏ "đã có feat nhưng không đọc được file code nào" dù 17/17 AC có
#     test. Commit đã mang ID vì githook bắt — đó là liên kết UC → code duy nhất máy tin được.
#  ② theo slug: thư mục (src/domain/<slug>/) hoặc file (src/domain/<slug>.js). Gộp MỌI đường dẫn khớp, không
#     head -1 — thư mục rỗng cạnh file thật (git mv để lại) từng thắng file thật và biến DoD thành "sạch".
CP="$(code_paths "$ROOT")"; TPS="$(test_paths "$ROOT") $UCT"
in_paths() { local x; for x in $2; do x="${x%/}"; [ "$x" = . ] && return 0; case "$1" in "$x"/*|"$x") return 0;; esac; done; return 1; }
CFILES="$(git -C "$ROOT" log --no-merges --format='@@%s' --name-only 2>/dev/null \
  | awk -v t="($ID)" '/^@@/ { k = index($0, t) > 0; next } k && NF && !a[$0]++' \
  | while IFS= read -r f; do
      [ -f "$ROOT/$f" ] || continue
      in_paths "$f" "$CP" || continue
      in_paths "$f" "$TPS" && continue
      printf '%s\n' "$f"
    done | grep -vE '\.(test|spec)\.')"   # không `case` ở đây: bash 3.2 không parse `pat)` trong $( )
NC1="$(printf '%s\n' "$CFILES" | grep -c .)"
for d in $CP; do
  [ -d "$ROOT/$d" ] || continue
  CFILES="$CFILES
$(cd "$ROOT" && { find "$d" -type d -name "$SLUG" -exec find {} -type f \; ; find "$d" -type f -name "$SLUG.*"; } 2>/dev/null | grep -vE '\.(test|spec)\.')"
done
CFILES="$(printf '%s\n' "$CFILES" | awk 'NF&&!a[$0]++')"
# Đếm file THẬT SỰ đọc được. 0 file = "không biết", không phải "sạch".
NF_="$(printf '%s\n' "$CFILES" | grep -c .)"
if [ "$NF_" -gt 0 ]; then
  info "code của $ID: $NF_ file — $NC1 do commit ($ID) chạm, $((NF_-NC1)) thêm theo slug $SLUG"
  L="$(cd "$ROOT" && printf '%s\n' "$CFILES" | tr '\n' '\0' | xargs -0 grep -HnE '([=<>!]=?|:|,|\() *[0-9]+\b|[0-9]+ *\* *[0-9]+' 2>/dev/null \
       | grep -vE '\.(test|spec)\.[a-z]+:|RULE-|CON-|ADR-' \
       | grep -vE '\[[0-9]+\]' \
       | grep -vE '\b(i|j|k|n|idx|index)\b *[=<>!]=? *[0-9]+' \
       | awk '{ if ($0 ~ /[0-9]+ *\* *[0-9]+/) { print; next }
                if ($0 ~ /[-+*\/]= *[0-9]+/) next
                if ($0 ~ /(substring|substr|slice|splice|padStart|padEnd|charAt|repeat|toFixed)\(/) next
                print }' \
       | grep -vE 'v?[0-9]+\.[0-9]+\.[0-9]+' \
       | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|/\*|\*|#|--)')"   # dòng chỉ là chú thích: tập theo commit kéo cả .sh/.sql, chú thích không phải luật
  if [ -n "$L" ]; then
    # Không cắt lặng lẽ (P-15): tới 7.0.0 in head -8 và không nói còn bao nhiêu. Tập lớn → số đếm + file đủ.
    LN_="$(printf '%s\n' "$L" | grep -c .)"
    LOUT="$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null)/sdd/literal-$ID.txt"
    mkdir -p "$(dirname "$LOUT")" 2>/dev/null && printf '%s\n' "$L" > "$LOUT" || LOUT=""
    warn "$LN_ dòng số literal cần soi (phải trích RULE/CON hoặc giải thích)$( [ "$LN_" -gt 8 ] && printf ' — 8 dòng đầu dưới đây')${LOUT:+; đủ ở $LOUT}:"
    printf '%s\n' "$L" | head -8 | sed 's/^/      /'
    # Spec đã đánh dấu chỗ trống mà code đã điền số — rule ngầm đắt nhất.
    if grep -qiE "($(kw openq_any))" "$F" 2>/dev/null && grep -qE '^[[:space:]]*[-*] \[ \]' "$F" 2>/dev/null; then
      warn "$ID còn Open Question chưa đóng mà code đã có số — soi hai chỗ này với nhau"
    fi
  else
    ok "không thấy số literal lạ trong $NF_ file code của $ID"
  fi
elif [ -n "$F0" ]; then
  bad "đã có feat($ID) nhưng không đọc được file code nào: không commit ($ID) nào chạm file trong $CP, và không có thư mục/file tên $SLUG — sửa code_paths ở .sdd/config"
else
  warn "chưa tìm thấy code của $ID trong: $CP — chưa soi được rule ngầm"
fi
grep -qE '^- v[0-9]+ ' "$F" && ok "History có dòng" || bad "History rỗng"
git -C "$ROOT" status --porcelain 2>/dev/null | grep -q . && warn "còn thay đổi chưa commit"
echo
if [ "$FAIL" -eq 0 ]; then echo "ĐÓNG ĐƯỢC ($WARN cảnh báo)."; exit 0; else echo "CHƯA ĐÓNG — $FAIL lỗi."; exit 1; fi
