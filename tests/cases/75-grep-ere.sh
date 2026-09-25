# 8.11.0 — phép kiểm phải cho CÙNG verdict dù máy đặt `grep.extendedRegexp` thế nào.
#
# `git log --grep` mặc định là BRE, nên `^feat(UC-001)` khớp đúng chuỗi literal và phép kiểm chạy
# đúng. Nhưng ai đặt `grep.extendedRegexp=true` trong git config toàn cục — một thiết lập hợp lệ,
# không hiếm — thì `(UC-001)` thành nhóm bắt, cùng câu lệnh trả về 0 khớp, và luật thứ tự docs→feat
# của close-check thành no-op VĨNH VIỄN trên mọi repo, không riêng repo nhận vào. Đỏ-thành-xanh im
# lặng, đúng loại CLAUDE.md gọi là đắt nhất. Đo trên chính kho sdd-solo: 67 khớp → 0.
# Lối đúng là `-E` KÈM escape (chính lối `gate_commit` của lib.sh đã dùng). Escape MỘT MÌNH còn tệ
# hơn: trong BRE `\(` là NHÓM, nên nó làm hỏng luôn ca mặc định.
nr ere
gate_pass
mkdir -p src/notify; printf 'const x = 1;\n' > src/notify/a.js
cm "feat(UC-001): ma" 2026-01-20

S close-check.sh UC-001
V1="$(printf '%s\n' "$O" | grep -cE '^ *(✓|✗|!)')"
D1="$(printf '%s\n' "$O" | grep -c 'docs(UC-001) comes before')"

git config grep.extendedRegexp true
S close-check.sh UC-001
V2="$(printf '%s\n' "$O" | grep -cE '^ *(✓|✗|!)')"
D2="$(printf '%s\n' "$O" | grep -c 'docs(UC-001) comes before')"
git config --unset grep.extendedRegexp

chk "close-check cho cùng số dòng verdict dù ERE bật hay tắt ($V1 vs $V2)" '[ "$V1" = "$V2" ]'
chk "luật thứ tự docs→feat vẫn CHẠY khi ERE bật ($D1 vs $D2)" '[ "$D1" = "$D2" ] && [ "$D1" != 0 ]'

chk "không còn chỗ nào dùng --grep mà thiếu -E" \
  '! grep -rn -- "--grep=" "$P/scripts/" | grep -v " -E "'
