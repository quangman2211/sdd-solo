# P-30: --pre không soi bảng ## Screens — thiếu dòng E1 vẫn xanh, cổng đầy đủ mới đỏ
nr p30
rep "$UC1" '| E1 | SCR-001-1 lỗi E1 | Chưa gửi được | thử lại |' '| Main 3 | SCR-001-1 | đơn | mở |'
S gate-check.sh --pre UC-001
chk "P-30 · --pre đỏ khi E1 không có dòng trong ## Screens (được exit $R)" '[ $R = 1 ] && has "E1 has no row"'
cm "docs(UC-001): đọc lại — bỏ dòng E1" 2026-01-06
S gate-check.sh UC-001
chk "cổng đầy đủ đỏ E1 chưa có dòng (exit $R)" '[ $R = 1 ] && has "E1 has no row"'
