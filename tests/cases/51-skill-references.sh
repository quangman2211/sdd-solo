# 8.1.0: nhánh loại trừ nhau của skill nằm ở references/, và router phải trỏ đúng.
# Hỏng ở đây là hỏng IM LẶNG: SKILL.md vẫn hợp lệ, plugin validate vẫn xanh, chỉ là model được bảo
# đọc một file không tồn tại — hoặc một file có thật mà không ai bảo đọc, tức là luật biến mất.
nr skref
REF="$(find "$P/skills" -type d -name references | sort)"
chk "có ít nhất một skill dùng references/ (8.1.0)" '[ -n "$REF" ]'
# ① mọi file references/ được nhắc tới đều tồn tại
MISS=""
for sk in "$P"/skills/*/SKILL.md; do
  d="$(dirname "$sk")"
  for f in $(grep -oE 'references/[A-Za-z0-9_-]+\.md' "$sk" | sort -u); do
    [ -f "$d/$f" ] || MISS="$MISS $(basename "$d")/$f"
  done
done
chk "mọi references/*.md được nhắc trong SKILL.md đều có thật (thiếu:${MISS:- không})" '[ -z "$MISS" ]'
# ② mọi file references/ có thật đều được SKILL.md của chính nó nhắc tới
ORPH=""
for d in $REF; do
  sk="$(dirname "$d")/SKILL.md"
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    grep -q "references/$(basename "$f")" "$sk" || ORPH="$ORPH $(basename "$(dirname "$d")")/$(basename "$f")"
  done
done
chk "mọi file trong references/ đều được SKILL.md của nó trỏ tới (mồ côi:${ORPH:- không})" '[ -z "$ORPH" ]'
# ③ router phải nói ĐƯỜNG DẪN ĐẦY ĐỦ + đường lùi, đúng khuôn mà skill đã dùng cho script
NOPATH=""
for d in $REF; do
  sk="$(dirname "$d")/SKILL.md"; n="$(basename "$(dirname "$d")")"
  grep -q "CLAUDE_PLUGIN_ROOT}/skills/$n/references/" "$sk" || NOPATH="$NOPATH $n:thiếu-đường-dẫn"
  grep -q "find ~/.claude/plugins -type f -name" "$sk" || NOPATH="$NOPATH $n:thiếu-đường-lùi"
done
chk "router nêu đủ đường dẫn \${CLAUDE_PLUGIN_ROOT} + đường lùi find (${NOPATH:- đủ})" '[ -z "$NOPATH" ]'
# ④ ngưỡng của Anthropic: SKILL.md dưới 500 dòng
LONG="$(for sk in "$P"/skills/*/SKILL.md; do n=$(grep -c '' "$sk"); [ "$n" -ge 500 ] && printf '%s:%s ' "$(basename "$(dirname "$sk")")" "$n"; done)"
chk "mọi SKILL.md dưới 500 dòng (skill-creator, progressive disclosure) (${LONG:- đạt})" '[ -z "$LONG" ]'
# ⑤ phần đã dời KHÔNG còn sót lại trong thân skill — dời mà quên xoá là hai bản trôi khác nhau
chk "adversarial: thân skill không còn tầng UC/BR" '! grep -qE "^## (A\. The UC layer|B\. The BR layer)" "$P/skills/adversarial/SKILL.md"'
chk "intake: thân skill không còn thân hai chế độ" '! grep -qE "^## (A\. Interview mode|B\. Brief conversion mode)" "$P/skills/intake/SKILL.md"'
chk "references/ không rơi vào dự án (scaffold không chép skill)" '[ ! -d .sdd/skills ] && [ -z "$(find . -path ./\.git -prune -o -type d -name references -print 2>/dev/null)" ]'
