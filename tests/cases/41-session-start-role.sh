# 7.3: session-start bơm hợp đồng vai + việc đang giao khi có dấu vai; worktree phụ báo sau main N commit
nr ss
S session-start.sh
chk "không dấu vai → đoạn văn cũ" 'has "nói lại cho user đang ở UC nào" && ! has "Phiên này là VAI"'
S role.sh B
S queue.sh add b-uc-001-p1 spec B "áp phiếu #1"; S queue.sh take b-uc-001-p1 B
S session-start.sh
chk "dấu vai B → hợp đồng vai, không còn đoạn cho một người" 'has "Phiên này là VAI B · spec" && has "Được ghi: specs/**" && has "KHÔNG ghi: specs/decisions.md" && ! has "nói lại cho user đang ở UC nào"'
chk "việc đang giao cho B được bơm" 'has "b-uc-001-p1 | spec | B | - | đang"'
chk "không kèm STATE.md cho vai chuyên" '! has "=== STATE.md ==="'
S role.sh --worktree D UC-001
S pass.sh gate UC-001
O="$(cd "$W/ss-d-uc-001" && unset CLAUDE_PROJECT_DIR && bash "$P/scripts/session-start.sh" 2>&1)"
chk "worktree D: hợp đồng D + sau master N commit + marker cổng thiếu" 'printf "%s" "$O" | grep -q "Phiên này là VAI D" && printf "%s" "$O" | grep -qE "Worktree phụ, sau (main|master) [0-9]+ commit" && printf "%s" "$O" | grep -q "Marker cổng"'
rm .git/sdd-role; S role.sh A
S session-start.sh
chk "vai A: kèm bảng giao việc và STATE.md" 'has "Phiên này là VAI A" && has "Bảng giao việc" && has "=== STATE.md ==="'
