# 7.3: hàng đợi trong git — add/next/take/done/stop/board, chỉ checkout chính ghi, worktree phụ đọc bản main
nr q
S queue.sh add b-uc-001-p1 spec B "áp phiếu #1"
S queue.sh add c-uc-001-p1 spec C --can "b-uc-001-p1"
chk "add hai việc, commit --only (exit $R)" '[ $R = 0 ] && grep -c "^| [bc]-uc-001-p1 |" notes/hang-doi.md | grep -q "^2$" && git log -1 --format=%s | grep -q "^chore(sdd): hàng đợi"'
S queue.sh next
chk "next: chỉ b (c cần b)" 'has "b-uc-001-p1" && ! has "c-uc-001-p1"'
S queue.sh take b-uc-001-p1 spec-main
chk "take → đang, ghi ai giữ" 'grep -q "^| b-uc-001-p1 | spec | B | - | đang | - | giữ:spec-main@" notes/hang-doi.md'
S queue.sh next
chk "làn spec sức chứa 1 đang bận → next rỗng" 'has "không việc nào phát được"'
S queue.sh done b-uc-001-p1
chk "done không có KETQUA → đỏ (exit $R)" '[ $R = 1 ] && has "chưa có KETQUA"'
S role.sh --ketqua b-uc-001-p1 ket=chan hoi=#2
S queue.sh done b-uc-001-p1
chk "done khi KETQUA là chan → đỏ (exit $R)" '[ $R = 1 ] && has "ket=chan, không phải xong"'
H="$(git rev-parse --short HEAD)"; S role.sh --ketqua b-uc-001-p1 ket=xong neo="$H"
S queue.sh done b-uc-001-p1
chk "done với KETQUA xong + neo → xong, cột Neo = hash (exit $R)" '[ $R = 0 ] && grep -q "^| b-uc-001-p1 | spec | B | - | xong | $H |" notes/hang-doi.md'
S queue.sh next
chk "b xong → next ra c" 'has "c-uc-001-p1"'
S queue.sh add d-uc-001-p1 code D; S queue.sh add d-uc-002-p1 code D; S queue.sh add d-uc-003-p1 code D
S queue.sh take d-uc-001-p1 wt1; S queue.sh take d-uc-002-p1 wt2
S queue.sh next
chk "làn code sức chứa 2 đầy → d-uc-003 không sẵn sàng" '! has "d-uc-003-p1"'
S queue.sh board
chk "board: đang 2 vai D, sẵn sàng c, chờ d-uc-003 (exit $R)" '[ $R = 0 ] && has "làn code   2/2 đang" && hasE "d-uc-003-p1 +cần"'
# xong không neo là đỏ
rep notes/hang-doi.md "| xong | $H |" "| xong | - |"
S queue.sh board
chk "xong mà Neo trống → board đỏ (exit $R)" '[ $R = 1 ] && has "xong mà Neo trống"'
rep notes/hang-doi.md "| xong | - |" "| xong | $H |"
# worktree phụ: không ghi được, đọc bản main
git worktree add -q "$W/q-wt" -b code/uc-001 >/dev/null 2>&1
O="$(cd "$W/q-wt" && unset CLAUDE_PROJECT_DIR && bash "$P/scripts/queue.sh" add x-1 code D 2>&1)"; R=$?
chk "worktree phụ add → từ chối (exit $R)" '[ $R = 1 ] && printf "%s" "$O" | grep -q "chỉ điều phối ở checkout chính"'
S queue.sh add e-uc-009-p1 spec B
O="$(cd "$W/q-wt" && unset CLAUDE_PROJECT_DIR && bash "$P/scripts/queue.sh" list 2>&1)"
chk "worktree phụ list đọc bản main (thấy e-uc-009-p1 vừa thêm sau khi tách)" 'printf "%s" "$O" | grep -q "e-uc-009-p1"'
