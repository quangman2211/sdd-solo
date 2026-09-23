# 8.0.0: trần vòng đọc lại — ở trần mà còn Chưa quyết thì cổng đỏ, và thêm một vòng KHÔNG mở được cổng
nr tran
RR='- Ngày chạy: 2026-01-06 · Đầu chưa neo: subagent'
UND='- F2 Main 3 nói gì khi hết hàng [neo: Main 3] → Chưa quyết (chờ chủ dự án)'
# vòng 1 đã có sẵn trong fixture; thêm vòng 2 có một phát hiện Chưa quyết
ins_after "$UC1" '- F1 Main 2 nói gửi' "$RR"
ins_after "$UC1" "$RR" "$UND"
cm "docs(UC-001): đọc lại — vòng 2" 2026-01-06
S gate-check.sh UC-001
chk "rr_max=3, mới 2 vòng → chưa chạm trần, chỉ cảnh báo Chưa quyết (exit $R)" '! has "reached the ceiling"'
# hạ trần xuống 2 → chạm
sed -i.bak 's/^rr_max=.*/rr_max=2/' .sdd/config && rm -f .sdd/config.bak
S gate-check.sh UC-001
chk "rr_max=2, 2 vòng, 1 Chưa quyết → đỏ vì chạm trần (exit $R)" '[ $R = 1 ] && has "round 2 of the re-read has reached the ceiling (rr_max=2)" && has "1 finding(s) are still Undecided"'
# thêm một vòng nữa KHÔNG mở được cổng — đó là cả ý nghĩa của trần
ins_after "$UC1" '- F1 Main 2 nói gửi' '- Ngày chạy: 2026-01-07 · Đầu chưa neo: subagent'
cm "docs(UC-001): đọc lại — vòng 3" 2026-01-07
S gate-check.sh UC-001
chk "thêm vòng 3 vẫn đỏ — vòng mới không phải là câu trả lời (exit $R)" '[ $R = 1 ] && has "round 3 of the re-read has reached the ceiling"'
# quyết nó thì hết đỏ
rep "$UC1" '→ Chưa quyết (chờ chủ dự án)' '→ Đã quyết: báo "hết hàng" ở Main 3'
cm "docs(UC-001): đọc lại — quyết F2" 2026-01-08
S gate-check.sh UC-001
chk "quyết xong → hết đỏ vì trần, và nói rõ đang ở trần" '! has "are still Undecided" && has "at the ceiling (rr_max=2)"'
# rr_max=0 tắt hẳn
rep "$UC1" '→ Đã quyết: báo "hết hàng" ở Main 3' '→ Chưa quyết (chờ chủ dự án)'
sed -i.bak 's/^rr_max=.*/rr_max=0/' .sdd/config && rm -f .sdd/config.bak
cm "docs(UC-001): đọc lại — mở lại F2" 2026-01-09
S gate-check.sh UC-001
chk "rr_max=0 → không đếm vòng, không đỏ vì trần" '! has "the ceiling"'
# repo KHÔNG có dòng rr_max: mặc định là 3, không phải tắt
sed -i.bak '/^rr_max=/d' .sdd/config && rm -f .sdd/config.bak
chk "không có dòng rr_max thì mặc định 3 (trần mặc định là một con số, không phải tắt)" '[ "$(cd . && bash -c ". \"$P/scripts/lib.sh\"; rr_max \"$PWD\"")" = 3 ]'
