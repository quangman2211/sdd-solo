# Repo gốc phải qua --pre và cổng đầy đủ; #53: dòng `→ Chưa quyết (… đề xuất: AC-9)` không bị kiểm ID.
nr base-green
S gate-check.sh --pre UC-001
chk "--pre xanh trên repo gốc (được exit $R)" '[ $R = 0 ]'
S gate-check.sh UC-001
chk "cổng đầy đủ xanh trên repo gốc (được exit $R)" '[ $R = 0 ] && has "THROUGH THE GATE"'
ins_after "$UC1" "- F1 Main 2" "- F2 thiếu AC cho gửi trùng [neo: AC-1] → Chưa quyết (chờ chủ dự án: có chặn trùng không · đề xuất: thêm AC-9)"
cm "docs(UC-001): đọc lại — bổ sung F2" 2026-01-06
S gate-check.sh UC-001
chk "#53: đề xuất AC-9 trong dòng Chưa quyết không đỏ" '[ $R = 0 ] && ! has "AC-9 but the UC has no such AC"'
