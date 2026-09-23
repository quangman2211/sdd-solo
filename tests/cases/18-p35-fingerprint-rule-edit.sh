# P-35: nhánh "đọc lại là commit spec mới nhất" bỏ qua phép so vân tay — sửa thân RULE-001 bằng docs(RULE-001) vẫn xanh im lặng
nr p35
rep specs/rules.md '- Phát biểu: mỗi Order vào trạng thái new sinh một tin báo.' '- Phát biểu: mỗi Order vào trạng thái new sinh một tin báo, trừ đơn test.'
cm "docs(RULE-001): thêm ngoại lệ đơn test" 2026-01-06
S gate-check.sh UC-001
chk "P-35 · sửa thân RULE được trích sau đọc lại → cổng nói vùng đổi rules" 'has "areas changed"'
