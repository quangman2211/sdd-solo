# 7.7.0: spec viết bằng TIẾNG ANH phải qua cổng y hệt spec viết bằng tiếng Việt.
#
# Phép đo là ĐỐI CHIẾU, không phải kê từng dòng: dựng hai bản sao của cùng một repo, một bản
# đổi mọi từ khoá tài liệu sang vế tiếng Anh của bảng kw(), rồi chạy cùng bộ script và so
# verdict. Chỗ khớp nào còn viết THẲNG chuỗi tiếng Việt sẽ lộ ra ở đây — và chỉ ở đây, vì nó
# không làm bản tiếng Việt đỏ, tức mọi phép đo khác vẫn xanh trong khi spec tiếng Anh rớt cổng.
# Đó đúng là loại hỏng đắt nhất: cổng đỏ oan mà không ai biết vì sao.
#
# Vì sao không đổi hẳn sang tiếng Anh: lịch sử git bất biến. runxops có 50 commit subject tiếng
# Việt mà gate-check §9 grep vào chính chúng — bỏ vế tiếng Việt là mọi UC đã đóng mất bằng chứng
# đọc lại, và không migrate nào chữa được.

verdict() { printf '%s\n' "$O" | grep -cE '^  ✗'; }
oks()     { printf '%s\n' "$O" | grep -cE '^  ✓'; }

# ── ① cổng đầy đủ: tiếng Việt và tiếng Anh cùng exit, cùng số ✗ ─────────────────────────
nr lang-vi
S gate-check.sh UC-001;        RV=$R; XV="$(verdict)"; OV="$(oks)"
S gate-check.sh --pre UC-001;  PV=$R; PXV="$(verdict)"
S uc-steps.sh UC-001;          UV=$R
S br-check.sh BR-001;          BV=$R; BXV="$(verdict)"
S decisions.sh;                DV=$R; DN="$(printf '%s\n' "$O" | wc -l | tr -d ' ')"
S close-check.sh UC-001;       CV=$R; CXV="$(verdict)"
S layer-check.sh;              LV=$R; LXV="$(verdict)"

nr lang-en
kw_swap
# lần đọc lại của bản tiếng Anh có tiêu đề commit tiếng Anh — §9 phải nhận qua vế `re-read`
cm "docs(UC-001): re-read — 1 finding, 0 to fix" 2026-01-04
cm "chore(sdd): state" 2026-01-05
chk "kw_swap thật sự đổi từ khoá (## Re-read · **Craft:** · **Slice:**)" \
  'grep -q "^## Re-read" "$UC1" && grep -q "\*\*Craft:\*\* orders" "$UC1" && grep -q "\*\*Slice:\*\* BR-001" "$UC1" && ! grep -q "^## Đọc lại" "$UC1"'

S gate-check.sh UC-001
chk "gate-check: spec tiếng Anh cùng exit ($R) và cùng số ✗ ($(verdict) ↔ $XV) với tiếng Việt" \
  '[ "$R" = "$RV" ] && [ "$(verdict)" = "$XV" ] && [ "$(oks)" = "$OV" ]'
S gate-check.sh --pre UC-001
chk "gate-check --pre: cùng exit ($R ↔ $PV), cùng số ✗ ($(verdict) ↔ $PXV)" \
  '[ "$R" = "$PV" ] && [ "$(verdict)" = "$PXV" ]'
S uc-steps.sh UC-001
chk "uc-steps: cùng exit ($R ↔ $UV)" '[ "$R" = "$UV" ]'
S br-check.sh BR-001
chk "br-check: cùng exit ($R ↔ $BV), cùng số ✗ ($(verdict) ↔ $BXV)" \
  '[ "$R" = "$BV" ] && [ "$(verdict)" = "$BXV" ]'
# decisions.sh so SỐ DÒNG chứ không so chữ: thân quyết định vừa bị đổi sang tiếng Anh nên chữ khác nhau
# là đúng; cái phải giống là ĐẾM ĐƯỢC BAO NHIÊU. Đo trên bản sao runxops trước khi định tuyến: 190 → 173,
# mất 17 quyết định mà không một dòng đỏ nào — đúng loại hụt chỉ phép đo này thấy.
S decisions.sh
chk "decisions.sh: cùng exit ($R ↔ $DV), gom cùng số dòng ($(printf '%s\n' "$O" | wc -l | tr -d ' ') ↔ $DN)" \
  '[ "$R" = "$DV" ] && [ "$(printf "%s\n" "$O" | wc -l | tr -d " ")" = "$DN" ]'
S close-check.sh UC-001
chk "close-check: cùng exit ($R ↔ $CV), cùng số ✗ ($(verdict) ↔ $CXV)" \
  '[ "$R" = "$CV" ] && [ "$(verdict)" = "$CXV" ]'
S layer-check.sh
chk "layer-check: cùng exit ($R ↔ $LV), cùng số ✗ ($(verdict) ↔ $LXV)" \
  '[ "$R" = "$LV" ] && [ "$(verdict)" = "$LXV" ]'

# ── ② §9: commit đọc lại viết bằng tiếng Anh vẫn được nhận ──────────────────────────────
S gate-check.sh UC-001
chk "§9 nhận commit 'docs(UC-001): re-read' — không báo chưa đọc lại" \
  '! hasE "chưa (có commit )?đọc lại|chưa đọc lại"'

# ── ③ context.sh: gói bối cảnh bỏ đúng ba mục dấu vết khi chúng viết tiếng Anh ───────────
S context.sh UC-001
chk "context.sh bỏ ## Re-read khỏi gói như bỏ ## Đọc lại (exit $R)" \
  '[ $R = 0 ] && ! has "## Re-read" && ! has "## Đọc lại"'

# ── ④ cổng vẫn ĐỎ đúng chỗ trên spec tiếng Anh — song ngữ không được nới tay ────────────
rep "$UC1" '## Re-read' '## Re-read (chưa chạy)'
S gate-check.sh UC-001
chk "đổi tên mục Re-read thì cổng đỏ lại như với tiếng Việt (exit $R)" '[ $R = 1 ]'
