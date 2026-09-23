# 8.0.1: UC-###.trace.md LÀ một đường dẫn spec. Từ 8.0.0 vòng đọc lại ghi CHỈ vào file cạnh, nên commit của
# /sdd-solo:verify chỉ chạm file đó — thiếu nó trong pathspec thì `glog` không thấy commit ấy.
# Ca này cần tồn tại riêng vì mọi phép so trước/sau đều XANH: repo cũ chưa có commit nào chỉ chạm file cạnh.
nr tracespec
S migrate.sh --trace >/dev/null
cm "docs(UC-001): dời dấu vết sang file cạnh" 2026-01-05
TR="$UCD/UC-001.trace.md"
ins_after "$TR" '- F1 Main 2 nói gửi' '- F3 Exceptions thiếu E2 cho hết hàng [neo: Main 3 · RULE-001] → không phải lỗi vì đã có Open Question'
git add -A; git -c commit.gpgsign=false commit -q --no-verify --date=2026-01-06T10:00:00 -m "docs(UC-001): đọc lại — 1 phát hiện, 0 phải sửa" -- "$TR"
chk "commit chỉ chạm file cạnh, không chạm UC-001.md" '[ "$(git show --name-only --format= HEAD | tr -d " ")" = "${TR#./}" ]'
S gate-check.sh UC-001
chk "cổng nhận commit ấy LÀ commit đọc lại (không lọt qua cửa vân tay, exit $R)" '[ $R = 0 ] && has "the separate commit is the latest spec commit"'
chk "và đếm cả phát hiện mới ghi ở file cạnh" 'hasE "with an unanchored mind: [2-9] findings"'
# ca khó: vòng đọc lại đó ĐỔI LUÔN một RULE mà UC trích — cửa vân tay không áp dụng được nữa,
# nên nếu cổng không thấy commit đọc lại thì đây là ngõ cụt, không có đường ra.
ins_after "$TR" '- F3 Exceptions thiếu E2' '- F4 RULE-001 thiếu số phút [neo: RULE-001] → sửa RULE-001'
rep specs/rules.md '## RULE-001' '## RULE-001 (đã sửa sau đọc lại)'
git add -A; git -c commit.gpgsign=false commit -q --no-verify --date=2026-01-07T10:00:00 -m "docs(UC-001): đọc lại — 2 phát hiện, 1 phải sửa" -- "$TR" specs/rules.md
S gate-check.sh UC-001
chk "đọc lại có sửa RULE, commit gồm cả hai file → vẫn mở được cổng (exit $R)" '[ $R = 0 ] && has "the separate commit is the latest spec commit"'
