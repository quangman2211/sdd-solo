# 7.3: session-start bơm hợp đồng vai + việc đang giao khi có dấu vai; worktree phụ báo sau main N commit
nr ss
S session-start.sh
chk "không dấu vai → đoạn văn cũ" 'has "restate to the user which UC" && ! has "This session is ROLE"'
S role.sh B
S queue.sh add b-uc-001-p1 spec B "áp phiếu #1"; S queue.sh take b-uc-001-p1 B
S session-start.sh
chk "dấu vai B → hợp đồng vai, không còn đoạn cho một người" 'has "This session is ROLE B · spec" && has "May write: specs/**" && has "MAY NOT write: specs/decisions.md" && ! has "restate to the user which UC"'
chk "việc đang giao cho B được bơm" 'has "b-uc-001-p1 | spec | B | - | đang"'
chk "không kèm STATE.md cho vai chuyên" '! has "=== STATE.md ==="'
S role.sh --worktree D UC-001
S pass.sh gate UC-001
O="$(cd "$W/ss-d-uc-001" && unset CLAUDE_PROJECT_DIR && bash "$P/scripts/session-start.sh" 2>&1)"
chk "worktree D: hợp đồng D + sau master N commit + marker cổng thiếu" 'printf "%s" "$O" | grep -q "This session is ROLE D" && printf "%s" "$O" | grep -qE "A secondary worktree, (main|master) is [0-9]+ commits ahead" && printf "%s" "$O" | grep -q "Gate markers"'
rm .git/sdd-role; S role.sh A
S session-start.sh
chk "vai A: kèm bảng giao việc và STATE.md" 'has "This session is ROLE A" && has "Assignment board" && has "=== STATE.md ==="'
