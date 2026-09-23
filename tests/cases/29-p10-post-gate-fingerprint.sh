# P-10: sau cổng, sửa AC bằng docs(UC-###) — không script nào so lại vân tay §9
nr p10
S pass.sh gate UC-001
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  không gửi gì cả'
cm "docs(UC-001): đảo AC-1 sau cổng" 2026-01-10
code_uc1
S close-check.sh UC-001
chk "P-10 · close-check thấy AC đổi sau cổng (vân tay)" 'hasE "fingerprint|BEHAVIOUR"'
