# P-20: cổng đếm "→ Chưa quyết" y như đã quyết — xanh giống hệt nhau ở "chưa quyết gì" và "đã quyết hết".
# Luật đã hoà với 7.0.1 (#53): Chưa quyết VẪN là đầu ra hợp lệ (verify không hỏi; cổng mở với nó là nợ tự nhận),
# nhưng lib đếm riêng (rr_undecided) và gate-check / change-check phải NÓI RA con số bằng một cảnh báo.
O="$(printf '%s\n' '- F1 x [neo: AC-1] → Chưa quyết (chờ chủ dự án: y · đề xuất: AC-1: z)' | bash -c ". $P/scripts/lib.sh; rr_count")"
chk "rr_count: '→ Chưa quyết' vẫn là đầu ra hợp lệ (#53) (được $O)" '[ "$O" = 1 ]'
O="$(printf '%s\n' '- F1 x [neo: AC-1] → Chưa quyết (chờ chủ dự án: y)' | bash -c ". $P/scripts/lib.sh; rr_undecided")"
chk "P-20 · rr_undecided đếm được dòng Chưa quyết (được $O)" '[ "$O" = 1 ]'
O="$(printf '%s\n' '- F1 x [neo: AC-1] → ___' | bash -c ". $P/scripts/lib.sh; rr_count")"
chk "rr_count: '→ ___' không tính (được $O)" '[ "$O" = 0 ]'
O="$(printf '%s\n' '- F1 x [neo: AC-1] → không phải lỗi vì y' | bash -c ". $P/scripts/lib.sh; rr_count")"
chk "rr_count: đầu ra thật tính 1 (được $O)" '[ "$O" = 1 ]'
nr p20
ins_after "$UC1" "- F1 Main 2" "- F2 E1 thử lại mấy lần [neo: E1] → Chưa quyết (chờ chủ dự án: số lần · đề xuất: RULE-001: 3 lần)"
cm "docs(UC-001): đọc lại — 2 phát hiện, 0 phải sửa" 2026-01-06
S gate-check.sh UC-001
chk "P-20 · cổng vẫn mở với dòng Chưa quyết (#53) (exit $R)" '[ $R = 0 ]'
chk "P-20 · cổng NÓI RA 1/2 phát hiện còn Chưa quyết (cảnh báo)" 'has "1 of 2 findings still"'
