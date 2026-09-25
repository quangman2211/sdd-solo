# 8.11.0 — `git mv` thuần vẫn là file cũ; `git mv` KÈM sửa thì không.
#
# Không có luật này thì đổi tên một file cũ vừa là xoá (được tha) vừa là thêm (bị chặn), nên việc dọn
# cấu trúc trong lúc nhận vào bị đóng băng — mà dọn cấu trúc lại đúng là việc người ta làm khi bắt
# đầu viết spec cho code cũ. Ranh giới KHÔNG phải một ngưỡng tự đặt: `R100` là chính git làm chứng
# nội dung y hệt từng byte. `R99` trở xuống đã đổi nội dung và chịu luật đầy đủ.
mkbrown adopt7
git mv app/a.js app/renamed.js
cmv "refactor: doi ten thuan"
chk "đổi tên THUẦN, không ID: đi qua" 'git log -1 --format=%s | grep -q "doi ten thuan"'

git mv app/b.js app/moved.js
app app/moved.js "const changed = 1;"
cmv "refactor: doi ten kem sua"
chk "đổi tên KÈM sửa nội dung: bị CHẶN" 'git log -1 --format=%s | grep -qv "doi ten kem sua"'
chk "và chặn bằng luật ID bình thường" 'grep -q "must carry an ID" "$W/hookerr.txt"'
