# 7.2: --kiem-lich-su chạy luật vùng ghi qua lịch sử, chỉ đọc
nr hist
S pass.sh gate UC-001
mkdir -p src; printf 'x\n' > src/a.js; app "$UC1" "- v3 (2026-01-09, anh): trộn"
cm "feat(UC-001): commit trộn spec + code" 2026-01-09
S role.sh --kiem-lich-su HEAD~3..HEAD
chk "in số commit không vai nào được ghi đủ ≥ 1 (exit $R)" '[ $R = 0 ] && hasE "^  [1-9][0-9]* commit không vai nào được ghi đủ"'
chk "kê đúng commit trộn" 'has "commit trộn spec + code"'
chk "cây làm việc không đổi (chỉ đọc)" '[ -z "$(git status --porcelain)" ]'
