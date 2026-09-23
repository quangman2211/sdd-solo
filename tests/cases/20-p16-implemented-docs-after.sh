# P-16: UC đã implemented, commit docs(UC-###) ngoài vân tay sau commit đóng → §9 vẫn so với lần đọc lại cũ.
# Hai hình: (a) ## Đọc lại chưa nén (P-40) → đỏ "spec đổi HÀNH VI"; (b) đã nén → đỏ "chưa đọc lại".
nr p16
S pass.sh gate UC-001
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  đúng một tin báo được gửi'
cm "docs(UC-001): áp chữ AC-1 sau cổng" 2026-01-10
code_uc1
S pass.sh close UC-001
rep "$UC1" '- **Rules:** RULE-001' '- **Rules:** RULE-001 · **Upstream UC:** -'
cm "docs(UC-001): sửa Dependencies" 2026-01-13
S gate-check.sh UC-001
chk "đỏ status implemented (đúng luật)" 'has "status đã implemented"'
xfail P-16 "(b) đã nén: không đỏ §9 'chưa đọc lại' trên UC implemented" '! has "chưa đọc lại bằng đầu chưa neo"'
nr p16a
ins_after "$UC1" "- F1 Main 2" "- F2 x [neo: Screens] → không phải lỗi vì commit <hash> đã bỏ"
cm "docs(UC-001): đọc lại — F2" 2026-01-06
S pass.sh gate UC-001
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  đúng một tin báo được gửi'
cm "docs(UC-001): áp chữ AC-1 sau cổng" 2026-01-10
code_uc1
S pass.sh close UC-001
chk "(a) ## Đọc lại chưa nén vì <hash> (P-40)" 'grep -q "^- F1 " "$UC1"'
rep "$UC1" '- **Rules:** RULE-001' '- **Rules:** RULE-001 · **Upstream UC:** -'
cm "docs(UC-001): sửa Dependencies" 2026-01-13
S gate-check.sh UC-001
xfail P-16 "(a) chưa nén: không đỏ 'spec đổi HÀNH VI' vì vùng đổi nằm trước commit đóng" '! has "spec đổi HÀNH VI"'
