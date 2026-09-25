# 8.9.0 — P-66 (queue.sh add không kiểm dạng nên gọi đảo không bị chặn) và P-65 (vai đo, KETQUA có dat=).
#
# `add <key> <lane> <role>`: tham số 2 là LÀN (khai ở ## Lanes, có sức chứa), tham số 3 là VAI (khai ở
# .sdd/roles). Tới 8.8.0 làn lạ chỉ WARN và vai không kiểm gì. Đo trên hàng đợi runxops 25/09: 20 hàng
# hỏng — 5 hàng gọi đảo (lane=C role=UC-034), 1 hàng UC nằm ô làn, 14 hàng làn `test` chưa khai. Cảnh báo
# đã có bị bỏ qua 14 lần, nên chỗ nào CHỨNG MINH được là sai thì chặn.
nr p66
S queue.sh add k1 B UC-012
chk "P-66 · gọi đảo (làn là một vai, vai là một UC) bị chặn (exit $R)" '[ $R != 0 ]'
chk "P-66 · và in ra đúng lệnh phải gõ" 'has "queue.sh add k1" && has "UC-012"'
chk "P-66 · không ghi hàng nào vào bảng" '! grep -q "^| k1 " notes/hang-doi.md'
S queue.sh add k2 UC-012 B
chk "P-66 · UC nằm ô làn bị chặn (exit $R)" '[ $R != 0 ] && ! grep -q "^| k2 " notes/hang-doi.md'
S queue.sh add k3 spec UC-012
chk "P-66 · ID đứng chỗ vai bị chặn (exit $R)" '[ $R != 0 ] && ! grep -q "^| k3 " notes/hang-doi.md'
# vai chưa khai thì CHỈ cảnh báo, cùng lý lẽ với làn chưa khai: chặn là bắt repo viết xong chính sách
# của mình rồi mới được xếp việc, và đó không phải cái đã hỏng ở runxops.
S queue.sh add k3b spec Z
chk "P-66 · vai chưa khai chỉ cảnh báo (exit $R)" '[ $R = 0 ] && has "Z" && grep -q "^| k3b " notes/hang-doi.md'
# làn CHƯA KHAI chỉ cảnh báo — nó có thể sắp được khai, và chặn ở đây bắt repo đang chạy sửa tay
S queue.sh add k4 test T
chk "P-66 · làn chưa khai vẫn chỉ cảnh báo, và nói rõ cái giá (exit $R)" \
  '[ $R = 0 ] && has "not declared" && has "capacity"'
S queue.sh add k5 spec B
chk "gọi đúng thì vẫn chạy như cũ (exit $R)" '[ $R = 0 ] && grep -q "^| k5 " notes/hang-doi.md'

# P-65 · KETQUA có dat=<đạt>/<tổng>: một con số điều phối cần nhìn ngay, không phải một luật mới.
nr p65
mkdir -p notes/do && printf '# e2e UC-012\n' > notes/do/e2e-UC-012.md && cm "docs: báo cáo đo"
S queue.sh add e-012 do E
chk "khuôn có vai E và làn do (exit $R)" '[ $R = 0 ]'
S queue.sh take e-012
# kiểm tra kiêm những: `kiem=` cố ý trích một `dat=` khác, đúng bẫy P-58
S role.sh --ketqua e-012 ket=xong neo=notes/do/e2e-UC-012.md dat=11/13 "kiem=2 bước đỏ (vòng trước dat=9/9), ghi phiếu"
chk "P-65 · ghi được dat= (exit $R)" '[ $R = 0 ] && has "dat=11/13"'
KQL="$(tail -1 "$(git rev-parse --git-common-dir)/sdd-ketqua/e-012.txt")"
chk "P-65 · dat= đứng TRƯỚC kiem= nên kq_field không đọc nhầm chuỗi trong kiem=" \
  '[ "$(bash -c ". \"$P/scripts/lib.sh\"; kq_field dat \"$KQL\"")" = 11/13 ]'
S queue.sh board
chk "P-65 · board in số đo ra" 'has "11/13"'
S role.sh --ketqua e-012 ket=xong neo=notes/do/e2e-UC-012.md dat=11-13
chk "P-65 · dat= sai dạng bị chặn (exit $R)" '[ $R != 0 ]'
# không thêm luật: đo thiếu vẫn done được, vì thiếu là một phát hiện để ghi phiếu, không phải một cổng
S queue.sh done e-012
chk "P-65 · dat=11/13 vẫn done được — không thêm cổng nào (exit $R)" '[ $R = 0 ]'
chk "P-65 · nhưng nói ra là đo còn thiếu" 'has "11/13"'
