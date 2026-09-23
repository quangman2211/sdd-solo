# 7.3: uỷ quyền — DỪNG-<tên> phải khai; dòng Sổ trỏ #n phải có trong decisions.md
nr uyq
chk "scaffold phát notes/uy-quyen.md và notes/hang-doi.md" '[ -f notes/uy-quyen.md ] && [ -f notes/hang-doi.md ]'
S queue.sh add b-uc-001-p1 spec B
S queue.sh stop b-uc-001-p1 S9 "hết tiền"
chk "stop với tên chưa khai → cảnh báo (exit $R)" '[ $R = 0 ] && has "is not declared in notes/uy-quyen.md"'
S status.sh
chk "status: DỪNG-S9 không khai → đỏ" 'has "the queue holds STOP-S9 but notes/uy-quyen.md"'
chk "status: Phạm vi còn khuôn → nhắc" 'has "## Scope is still the template"'
S queue.sh stop b-uc-001-p1 S1 "cần push"
S status.sh
chk "status: DỪNG-S1 có khai → ✓" 'has "STOP-S1 is declared"'
app notes/uy-quyen.md "| 2026-01-10 | Ngưỡng thử lại | 3 lần | RULE-001 | #9 · decisions |"
S status.sh
chk "status: Sổ trỏ #9 mà decisions.md không có → cảnh báo" 'has "points at ticket #9 but decisions.md has no line"'
app specs/decisions.md "- 2026-01-10 — Ngưỡng thử lại 3 lần (A theo uỷ quyền, phiếu #9). Loại: không giới hạn. Chi tiết: RULE-001"
S status.sh
chk "decisions.md có #9 → hết cảnh báo" '! has "points at ticket #9 but"'
