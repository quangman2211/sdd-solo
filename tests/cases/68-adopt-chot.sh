# 8.11.0 — cái chốt: file đã một lần vào quy trình thì KHÔNG lùi ra được.
#
# Nếu miễn trừ chỉ hỏi "file này có trong cây mốc không" thì nó đứng yên mãi: đo trên chính kho
# sdd-solo, 77 trong 103 commit chạm code CHỈ sửa file đã có (75%), nên ba trên bốn commit sẽ không
# bao giờ cần ID. Cái chốt là thứ kéo con số đó xuống, và nó phải nằm ở HOOK chứ không chỉ ở bảng
# đếm: hỏi thêm "đã có commit nào mang ID chạm vào file này chưa". Đã có thì file rời miễn trừ vĩnh
# viễn — không lời khai nào, không dòng config nào kéo nó về.
mkbrown adopt2
mkdir -p specs; app specs/s.md "# spec"
cm "docs(UC-001): spec reviewed" 2026-01-03
mkdir -p .sdd/gate; git rev-parse HEAD > .sdd/gate/UC-001.ok
cm "chore(sdd): marker" 2026-01-03

app app/a.js "const under = 1;"
cmv "feat(UC-001): a.js duoi UC"
chk "commit MANG ID vào file cũ: đi qua" 'git log -1 --format=%s | grep -q "a.js duoi UC"'
chk "và KHÔNG in lời nhắc miễn trừ — người làm đúng không bị mắng" \
  '! grep -q "predate the adoption baseline" "$W/hookerr.txt"'

app app/a.js "const after = 2;"
cmv "fix: sua lai file do khong ID"
chk "CHỐT: sau đó sửa lại chính file đó không ID → CHẶN" \
  'git log -1 --format=%s | grep -qv "sua lai file do"'
chk "và chặn bằng luật ID bình thường" 'grep -q "must carry an ID" "$W/hookerr.txt"'

git reset -q; git checkout -q HEAD -- app/a.js
app app/b.js "const sibling = 3;"
cmv "fix: file cu khac chua ai dung"
chk "file cũ chưa ai đụng vẫn được tha — chốt chỉ đóng đúng file của nó" \
  'git log -1 --format=%s | grep -q "file cu khac"'
