# 8.11.0 — dời mốc không mua được gì, và bị nhìn thấy.
#
# `.sdd/config` nằm ngoài manifest, `commit-msg` loại `^\.sdd/` khỏi SRCLIKE, và `^chore\(sdd\)` được
# miễn ID — cộng ba thứ đó lại thì `sed` một dòng rồi commit `chore(sdd)` là hợp lệ. Nếu dời mốc tới
# HEAD mà miễn trừ lại phủ toàn kho thì đây đúng là cờ bỏ qua README từ chối. Hai thứ chặn: cái chốt
# (file đã vào quy trình không lùi ra, bất kể dòng config nói gì) và một dòng đỏ vệ sinh ở status đọc
# giá trị git GHI LẦN ĐẦU bằng pickaxe. Đỏ vệ sinh, không phải cổng: chặn commit vì một phép kiểm
# toàn vẹn config là đóng băng kho, đúng cái bệnh đang chữa.
mkbrown adopt6
mkdir -p specs; app specs/s.md "# spec"
cm "docs(UC-001): spec reviewed" 2026-01-03
mkdir -p .sdd/gate; git rev-parse HEAD > .sdd/gate/UC-001.ok
cm "chore(sdd): marker" 2026-01-03
app app/a.js "const under = 1;"
cmv "feat(UC-001): a.js duoi UC"
S adopt.sh --count
N1="$(printf '%s\n' "$O" | grep -oE 'ever touched: [0-9]+' | grep -oE '[0-9]+')"

sed -i.bak "s/^adopt_from=.*/adopt_from=$(git rev-parse HEAD)/" .sdd/config && rm -f .sdd/config.bak
cm "chore(sdd): doi moc toi HEAD" 2026-01-04

S adopt.sh --count
N2="$(printf '%s\n' "$O" | grep -oE 'ever touched: [0-9]+' | grep -oE '[0-9]+')"
chk "dời mốc KHÔNG kéo file đã vào quy trình trở lại ($N1 → $N2)" '[ "$N1" = "$N2" ]'

app app/a.js "const again = 2;"
cmv "fix: thu lai sau khi doi moc"
chk "và file đó vẫn bị CHẶN sau khi dời mốc" 'git log -1 --format=%s | grep -qv "thu lai sau khi"'

S status.sh
chk "status đỏ: mốc đã bị dời" 'has "it was moved"'
chk "và nêu cả giá trị ghi lần đầu lẫn giá trị hiện tại" \
  'hasE "first recorded in git was [0-9a-f]{40}"'
chk "và nói rõ dời mốc không mua được gì" 'has "moving it buys nothing"'
