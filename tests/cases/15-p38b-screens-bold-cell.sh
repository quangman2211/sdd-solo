# P-38b: ô đầu in đậm `**E1**` hoặc ô gộp `E1 · E2` trong ## Screens trượt phép "E# có màn hình"
nr p38b
rep "$UC1" '| E1 | SCR-001-1 lỗi E1 |' '| **E1** | SCR-001-1 lỗi E1 |'
cm "docs(UC-001): đọc lại — in đậm E1" 2026-01-06
S gate-check.sh UC-001
xfail P-38b "ô **E1** vẫn tính là E1 có màn hình (được exit $R)" '[ $R = 0 ] && ! has "E1 chưa có dòng"'
rep "$UC1" '| **E1** | SCR-001-1 lỗi E1 |' '| E1 · E2 | SCR-001-1 lỗi E1 |'
ins_after "$UC1" "- **E1. Gửi hỏng:**" "- **E2. Hết hạn:** token hết hạn → SCR-001-1 hiện \"Đăng nhập lại\". Hệ thống dừng."
ins_after "$UC1" "Then:  tin được thử lại" "
### AC-3: E2 hết hạn
Given: token hết hạn
When:  hệ thống gửi
Then:  hiện Đăng nhập lại"
rep "$FL1" 'T2 --> P1' 'T2 -->|E2 hết hạn| X2([E2: dừng])
  T2 --> P1'
cm "docs(UC-001): đọc lại — ô gộp" 2026-01-07
S gate-check.sh UC-001
xfail P-38b "ô gộp E1 · E2 tách được (được exit $R)" '[ $R = 0 ] && ! has "chưa có dòng"'
