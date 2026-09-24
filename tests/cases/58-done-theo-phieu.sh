# P-50 (8.4.0): việc kết `ket=chan hoi=#n` rồi được phiếu giải quyết thì không có đường đóng —
# `done` đòi ket=xong mới, `stop` đòi tên điểm dừng (nó không dừng, nó xong). --theo-phieu là
# HÌNH DẠNG bằng chứng thứ hai, không phải miễn trừ: phiếu phải có dấu "Đã áp" do phieu.sh close đóng.
nr dtp
S phieu.sh new "UC-001 kho rỗng" code
PF="$(ls notes/hoi-dap/phieu/001-*.md)"
S queue.sh add b-uc-001-k1 spec B
S queue.sh take b-uc-001-k1
S role.sh --ketqua b-uc-001-k1 ket=chan hoi=#1
chk "việc đang chặn vì phiếu #1 (exit $R)" '[ $R = 0 ]'
S queue.sh done b-uc-001-k1
chk "done thường: từ chối vì KETQUA cuối là chan (exit $R)" '[ $R = 1 ] && has "ket=chan"'
S queue.sh done b-uc-001-k1 --theo-phieu '#1'
chk "--theo-phieu: từ chối khi phiếu CHƯA đóng (exit $R)" '[ $R = 1 ] && has "not closed"'
# đóng phiếu bằng tay như phieu.sh close làm: đóng dấu vào FILE
printf 'Đã áp: 2026-01-09\n' >> "$PF"
S queue.sh done b-uc-001-k1 --theo-phieu '#1'
chk "phiếu đã có dấu Đã áp → đóng được, không phải làm lại việc (exit $R)" \
  '[ $R = 0 ] && has "ticket #1"'
chk "neo là chính file phiếu, không phải chuỗi rỗng" 'grep -E "^\| *b-uc-001-k1 *\|" notes/hang-doi.md | grep -q "001-"'
chk "trạng thái trong bảng là xong" 'grep -E "^\| *b-uc-001-k1 *\|" notes/hang-doi.md | grep -q "xong"'
S queue.sh done b-uc-001-k1 --theo-phieu '#9'
chk "phiếu không có thật → từ chối (exit $R)" '[ $R = 1 ] && has "no file for ticket #9"'
