# 7.2 P-29: skill không còn `git add specs/ && git commit` — vùng stage là của cả cây
N="$(grep -rn 'git add specs/ &&' "$P/skills" | wc -l | tr -d ' ')"
chk "không skill nào còn 'git add specs/ && git commit' (được $N)" '[ "$N" = 0 ]'
N2="$(grep -rln 'git commit --only' "$P/skills" | wc -l | tr -d ' ')"
chk "adversarial · intake · design · verify dùng --only kê đích danh (được $N2 skill)" '[ "$N2" -ge 4 ]'
