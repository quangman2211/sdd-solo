# P-20: rr_count đếm `→ Chưa quyết` là "có đầu ra"
O="$(printf '%s\n' '- F1 x [neo: AC-1] → Chưa quyết' | bash -c ". $P/scripts/lib.sh; rr_count")"
xfail P-20 "rr_count: '→ Chưa quyết' không tính là đầu ra (được $O)" '[ "$O" = 0 ]'
O="$(printf '%s\n' '- F1 x [neo: AC-1] → ___' | bash -c ". $P/scripts/lib.sh; rr_count")"
chk "rr_count: '→ ___' không tính (được $O)" '[ "$O" = 0 ]'
O="$(printf '%s\n' '- F1 x [neo: AC-1] → không phải lỗi vì y' | bash -c ". $P/scripts/lib.sh; rr_count")"
chk "rr_count: đầu ra thật tính 1 (được $O)" '[ "$O" = 1 ]'
