# P-48 (8.2.0): role.sh --worktree tạo worktree + nhánh nhưng không có lệnh ngược. Đo ở runxops 24/09:
# 4 workspace + 18 nhánh code/·test/ của UC-016…030 còn sót sau close, chủ dự án tự phát hiện.
nr don
D="$W/don-d-uc-001"; T2="$W/don-t-uc-001"
S role.sh --worktree D UC-001
chk "dựng worktree D cho UC-001 (exit $R)" '[ $R = 0 ] && [ -d "$D" ] && git show-ref --verify --quiet refs/heads/code/uc-001'
S role.sh --worktree T UC-001
chk "dựng worktree T cho UC-001" '[ -d "$T2" ] && git show-ref --verify --quiet refs/heads/test/uc-001'
# --dry-run nói sẽ làm gì mà không đụng gì
S role.sh --don UC-001 --dry-run
chk "--dry-run kê đủ hai worktree + hai nhánh, không xoá gì (exit $R)" \
  '[ $R = 0 ] && has "code/uc-001" && has "test/uc-001" && [ -d "$D" ] && [ -d "$T2" ]'
S role.sh --don UC-001
chk "dọn: cả hai worktree biến mất (exit $R)" '[ $R = 0 ] && [ ! -d "$D" ] && [ ! -d "$T2" ]'
chk "dọn: cả hai nhánh đã hợp nhất bị xoá" \
  '! git show-ref --verify --quiet refs/heads/code/uc-001 && ! git show-ref --verify --quiet refs/heads/test/uc-001'
chk "git worktree list không còn dòng lạc" '[ "$(git worktree list | wc -l | tr -d " ")" = 1 ]'
# nhánh CHƯA hợp nhất thì không được xoá — mất việc là không lùi lại được
S role.sh --worktree D UC-002
mkdir -p "$W/don-d-uc-002/src" && printf 'x\n' > "$W/don-d-uc-002/src/x.js"
git -C "$W/don-d-uc-002" add src/x.js && git -C "$W/don-d-uc-002" -c core.hooksPath=/dev/null commit -q -m "feat(UC-002): x"
S role.sh --don UC-002
chk "worktree vẫn dọn, nhưng nhánh chưa hợp nhất thì GIỮ và nói lý do (exit $R)" \
  '[ $R = 1 ] && [ ! -d "$W/don-d-uc-002" ] && git show-ref --verify --quiet refs/heads/code/uc-002 && has "not merged"'
# không có gì để dọn thì nói thế, không đỏ
S role.sh --don UC-009
chk "UC không có làn nào → nói không có gì để dọn, exit 0 (exit $R)" '[ $R = 0 ] && has "UC-009"'
