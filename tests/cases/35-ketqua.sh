# 7.2 P-26: KETQUA — xong không neo → đỏ; neo giả → đỏ; chan không hoi → đỏ; đọc được từ worktree khác
nr kq
S role.sh --ketqua d-uc-001-p3 ket=xong
chk "ket=xong thiếu neo → đỏ (exit $R)" '[ $R = 1 ] && has "bắt buộc có neo"'
S role.sh --ketqua d-uc-001-p3 ket=xong neo=deadbeef1
chk "neo là hash không có thật → đỏ (exit $R)" '[ $R = 1 ] && has "không phải commit có thật"'
S role.sh --ketqua d-uc-001-p3 ket=chan
chk "ket=chan thiếu hoi → đỏ (exit $R)" '[ $R = 1 ] && has "bắt buộc có hoi"'
S role.sh --ketqua "Khoá Xấu" ket=xong neo=x
chk "khoá có dấu cách/hoa → từ chối (exit $R)" '[ $R = 2 ]'
S role.sh --ketqua d-uc-001-p3 ket=chan hoi=#4
chk "chan có hoi → ghi (exit $R)" '[ $R = 0 ] && has "KETQUA key=d-uc-001-p3 ket=chan neo=- kiem=- hoi=#4"'
S pass.sh gate UC-001
S role.sh --ketqua d-uc-001-p3 ket=xong neo=.sdd/gate/UC-001.ok
chk "neo là marker cổng → nhận (exit $R)" '[ $R = 0 ]'
git worktree add -q "$W/kq-wt" -b code/uc-001 >/dev/null 2>&1
O="$(cd "$W/kq-wt" && bash "$P/scripts/role.sh" --ketqua d-uc-001-p3 2>&1)"
chk "worktree khác đọc được cùng file KETQUA (git-common-dir)" 'printf "%s" "$O" | grep -c "^KETQUA" | grep -q "^2$"'
