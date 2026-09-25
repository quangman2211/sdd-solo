# 8.11.0 — không đọc được mốc thì KHÔNG tha, và phải nói vì sao.
#
# Đây là ca hỏng-im-lặng của cơ chế này. Clone `--depth 1` là ca nguy hiểm nhất: `cat-file` không
# thấy gì trong cây mốc, mọi file đọc ra là "mới", và một nhánh viết cẩu thả lật thành THA TẤT CẢ —
# ở CI, không một dòng nào trông sai. Tiền lệ cho lựa chọn nằm ngay trong chính file hook
# (`commit-msg`, khối config sai): "a source file matching no path → block, do not wave it through in
# silence". Và không bao giờ được báo "file này mới", vì đó là đỏ không lối ra, loại #23 / P-43.
mkbrown adopt5
sed -i.bak "s/^adopt_from=.*/adopt_from=deadbeefdeadbeefdeadbeefdeadbeefdeadbeef/" .sdd/config && rm -f .sdd/config.bak
cm "chore(sdd): moc tro vao commit khong ton tai" 2026-01-03

app app/a.js "const x = 1;"
cmv "fix: sua file cu voi moc hong"
chk "mốc hỏng: file cũ KHÔNG còn được tha, commit bị chặn" \
  'git log -1 --format=%s | grep -qv "sua file cu voi moc hong"'
chk "hook nói RÕ vì sao miễn trừ không áp dụng" \
  'grep -q "adoption baseline cannot be read" "$W/hookerr.txt"'
chk "và nói thẳng nguyên tắc: không kiểm được thì không cấp" \
  'grep -q "cannot be checked is not granted" "$W/hookerr.txt"'
chk "KHÔNG báo nhầm là 'file này mới' — đó là đỏ không lối ra" \
  '! grep -qi "did not exist" "$W/hookerr.txt"'

S adopt.sh
chk "adopt.sh cũng đỏ và không giả vờ đếm được (exit $R)" '[ $R = 0 ] && has "unreadable"'
S status.sh
chk "status đỏ về mốc không đọc được" 'has "baseline cannot be read"'
