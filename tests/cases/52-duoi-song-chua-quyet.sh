# P-46 (8.1.1): rr_undecided đếm trên CẢ DÒNG chứ không qua đuôi sống — dòng F# đã có đuôi giải quyết
# nhưng thân còn trích chữ "Chưa quyết" vẫn bị đếm. Ở trần 8.0.0 đó là cổng đỏ không có cách gỡ:
# lối duy nhất còn lại là sửa lời cũ, mà sổ chỉ-thêm thì cấm. Ca runxops: UC-031, 13 dòng F#, 11 đã trả lời,
# đếm tay đuôi sống = 2, cổng in "13 Undecided, ceiling reached".
nr duoi
RR='- Ngày chạy: 2026-01-06 · Đầu chưa neo: subagent'
# F2 ĐÃ giải quyết: sổ chỉ-thêm nên chữ "Chưa quyết" cũ còn nguyên, đuôi sống là "sửa v4"
DONE='- F2 Main 3 nói gì khi hết hàng [neo: Main 3] → Chưa quyết (chờ chủ dự án) → **sửa v4**'
# F4 chỉ TRÍCH lời cổng trong dấu nháy ngược — cũng không phải tồn đọng
QUOT='- F4 cổng từng báo `→ Chưa quyết` ở F2 [neo: Main 3] → đã hết, không phải lỗi'
# F3 CHƯA giải quyết thật
OPEN='- F3 Main 4 thiếu ngưỡng [neo: Main 4] → Chưa quyết (nợ chữ, áp lúc close)'
ins_after "$UC1" '- F1 Main 2 nói gửi' "$RR"
ins_after "$UC1" "$RR" "$DONE"
ins_after "$UC1" "$DONE" "$QUOT"
cm "docs(UC-001): đọc lại — vòng 2" 2026-01-06
sed -i.bak 's/^rr_max=.*/rr_max=2/' .sdd/config && rm -f .sdd/config.bak
S gate-check.sh UC-001
chk "đuôi sống đã giải quyết thì không còn là Chưa quyết (P-46)" '! has "are still Undecided"'
chk "chạm trần mà không còn tồn đọng → cổng mở, không chặn (P-46) (exit $R)" \
  '[ $R = 0 ] && has "at the ceiling (rr_max=2), nothing left Undecided"'
# thêm một phát hiện CÒN MỞ thật → phải đếm đúng 1, không phải 3
ins_after "$UC1" "$QUOT" "$OPEN"
cm "docs(UC-001): đọc lại — F3" 2026-01-07
S gate-check.sh UC-001
chk "một tồn đọng thật thì đếm đúng 1, và vẫn chặn (P-46) (exit $R)" \
  '[ $R = 1 ] && has "1 finding(s) are still Undecided"'
chk "rr_undecided qua stdin: 3 dòng, 1 tồn đọng thật" \
  '[ "$(printf %s\\n "$DONE
$QUOT
$OPEN" | bash -c ". \"$P/scripts/lib.sh\"; rr_undecided")" = 1 ]'
# bản tiếng Anh phải cho CÙNG con số — đuôi sống là song ngữ như mọi từ khoá khác
chk "bản tiếng Anh cùng verdict: 1 tồn đọng" \
  '[ "$(printf %s\\n "- F2 x [anchor: Main 3] → Undecided (waiting) → **fixed v4**
- F3 y [anchor: Main 4] → Undecided (owed)" | bash -c ". \"$P/scripts/lib.sh\"; rr_undecided")" = 1 ]'
