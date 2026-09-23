# 7.2 P-21: cấp số phiếu có khoá — hai worktree, mỗi bên 8 lượt new song song → 16 số khác nhau, không trùng
nr phieu
S phieu.sh new "UC-001 gửi trùng" soi
chk "new: tạo #1, file + dòng mục lục + commit giữ chỗ (exit $R)" '[ $R = 0 ] && [ -f notes/hoi-dap/phieu/001-uc-001-gui-trung.md ] && grep -q "^| #1 |" notes/hoi-dap/hoi-dap.md && git log -1 --format=%s | grep -q "phiếu #1 giữ chỗ"'
chk "file phiếu có header đúng khuôn" 'grep -q "^### #1 · từ: soi · việc: UC-001 gửi trùng · " notes/hoi-dap/phieu/001-uc-001-gui-trung.md'
git worktree add -q "$W/phieu-wt" -b spec2 >/dev/null 2>&1
( cd "$W/phieu-wt" && unset CLAUDE_PROJECT_DIR && for i in 1 2 3 4 5 6 7 8; do bash "$P/scripts/phieu.sh" new "wt việc $i" spec >/dev/null 2>&1; done ) &
for i in 1 2 3 4 5 6 7 8; do bash "$P/scripts/phieu.sh" new "main việc $i" soi >/dev/null 2>&1; done
wait
# file 001 có ở cả hai (worktree tách sau #1) → đếm theo TÊN FILE duy nhất, rồi xem số có trùng giữa hai tên khác nhau không
ALL="$( { ls notes/hoi-dap/phieu; ls "$W/phieu-wt/notes/hoi-dap/phieu"; } | sort -u | grep -oE '^[0-9]+' | sort )"
NU="$(printf '%s\n' "$ALL" | sort -u | wc -l | tr -d ' ')"; NT="$(printf '%s\n' "$ALL" | wc -l | tr -d ' ')"
chk "17 phiếu ở hai worktree → 17 số khác nhau (được $NU/$NT)" '[ "$NU" = 17 ] && [ "$NT" = 17 ]'
chk "số lớn nhất là 17 (max của mục lục ∪ file ∪ git log --all)" '[ "$(printf "%s\n" "$ALL" | sort -n | tail -1 | sed "s/^0*//")" = 17 ]'
S phieu.sh muc-luc
chk "muc-luc ở main: khớp mục lục/file (exit $R)" '[ $R = 0 ] && has "mục lục và file khớp"'
# mục lục lệch → đỏ
cp notes/hoi-dap/phieu/001-uc-001-gui-trung.md notes/hoi-dap/phieu/001-trung.md
S phieu.sh muc-luc
chk "hai file cùng số → đỏ (exit $R)" '[ $R = 1 ] && has "hai file cùng số"'
rm notes/hoi-dap/phieu/001-trung.md
S phieu.sh list --mo
chk "list --mo in phiếu còn mở" 'has "| #1 |"'
