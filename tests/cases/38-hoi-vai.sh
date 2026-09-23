# 7.3: sổ hỏi có địa chỉ — phieu.sh hoi + hoi-check (bốn ô · đích sau cổng · --lich-su)
nr hoi
S phieu.sh hoi D "Notify.workingHours có loại cuối tuần không"
chk "hoi D: tạo sổ từ khuôn, mục HỎI-D1 (exit $R)" '[ $R = 0 ] && [ -f notes/hoi-dap/hoi-D.md ] && grep -q "^### HỎI-D1 · Notify.workingHours" notes/hoi-dap/hoi-D.md && grep -q "^# HỎI từ vai D · code" notes/hoi-dap/hoi-D.md'
S phieu.sh hoi D "Verb receive tính là nhận được không"
chk "hoi D lần hai: HỎI-D2" 'grep -q "^### HỎI-D2 " notes/hoi-dap/hoi-D.md'
S hoi-check.sh D
chk "hoi-check: bốn ô còn khuôn → đỏ (exit $R)" '[ $R = 1 ] && has "ô \"Nguồn\" trống hoặc còn khuôn"'
python3 - <<'PY'
import io, re
p = 'notes/hoi-dap/hoi-D.md'; s = io.open(p, encoding='utf-8').read()
s = s.replace('- **Nguồn:** <file:mục đã tra>', '- **Nguồn:** UC-001 ## Open Questions · RULE-001 tham số phút')
s = s.replace('- **Chặn không:** <chặn | không chặn> — <vì sao>', '- **Chặn không:** không chặn — mọi ngày như nhau cho tới khi spec nói')
s = s.replace('- **Đang làm gì trong lúc chờ:** <…>', '- **Đang làm gì trong lúc chờ:** ca AC-1, giả định ghi ĐOÁN trong code')
s = s.replace('- **Việc cho spec khi trả lời:** <…>', '- **Việc cho spec khi trả lời:** RULE-001 dòng tham số phút · UC-001 Open Question tick [x]')
io.open(p, 'w', encoding='utf-8').write(s)
PY
S hoi-check.sh D
chk "đủ bốn ô → xanh (exit $R)" '[ $R = 0 ] && has "2 mục HỎI-D, đủ bốn ô"'
S pass.sh gate UC-001
rep notes/hoi-dap/hoi-D.md '- **Trả lời (A/R):** · **đích:**' '- **Trả lời (A/R):** không loại cuối tuần · **đích:** UC-001 ## Main Flow bước 2'
S hoi-check.sh D
chk "cổng UC-001 đã mở mà đích trỏ thân UC → đỏ (exit $R)" '[ $R = 1 ] && has "đích trỏ vào thân UC"'
rep notes/hoi-dap/hoi-D.md '**đích:** UC-001 ## Main Flow bước 2' '**đích:** specs/orders/br-001/use-cases/UC-001-notify-order/design.md ## Nơi chạy'
S hoi-check.sh D
chk "đích design.md → xanh (exit $R)" '[ $R = 0 ]'
rep notes/hoi-dap/hoi-D.md '- **Trả lời (A/R):** · **đích:**' '- **Trả lời (A/R):** có · **đích:** UC-001 AC-3 (AC đổi, History v3)'
S hoi-check.sh D
chk "đích thân UC nhưng nói AC đổi → xanh (exit $R)" '[ $R = 0 ]'
cm "docs(UC-001): HỎI-D1 D2" 2026-01-11
rep notes/hoi-dap/hoi-D.md '### HỎI-D1 · Notify.workingHours có loại cuối tuần không' '### HỎI-D1 · Notify.workingHours có loại cuối tuần và lễ không'
cm "docs(UC-001): sửa lời hỏi cũ" 2026-01-12
S hoi-check.sh D --lich-su
chk "--lich-su bắt commit sửa dòng HỎI đã có (exit $R)" '[ $R = 1 ] && has "sửa một dòng '"'"'### HỎI-'"'"' đã có"'
