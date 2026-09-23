# P-37 / nợ 7.0.1: `case *"→ Chưa quyết"*` miễn CẢ dòng, nên đuôi sống "→ sửa AC-9" núp sau chữ trích thoát kiểm ID
nr p37
ins_after "$UC1" "- F1 Main 2" "- F2 thiếu AC gửi trùng [neo: AC-1] → đã sửa AC-9 — chưa-quyết cũ: (→ Chưa quyết (chờ chủ dự án: x))"
cm "docs(UC-001): đọc lại — ghi lại đuôi F2" 2026-01-06
S gate-check.sh UC-001
chk "P-37 · đuôi sống → AC-9 vẫn bị kiểm dù dòng trích '→ Chưa quyết' (được exit $R)" '[ $R = 1 ] && has "AC-9 nhưng UC không có"'
