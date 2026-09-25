# 8.11.0 — mốc nhận vào: file CŨ được tha, file MỚI vẫn chịu luật đầy đủ.
#
# Trên kho đã có code, `init` đóng băng kho ngay ngày đầu: mọi commit chạm code_paths đòi ID, mà ID
# dạng UC lại đòi `.sdd/gate/UC-###.ok`, thứ chưa thể có vì chưa một dòng spec nào được viết. Mốc
# nhận vào gỡ đúng cái đó mà không mở cửa: tha theo FILE có trong cây mốc, chứ không theo lời commit.
# Ranh giới phải đo là "cũ được tha" VÀ "mới bị chặn" — chỉ đo một vế thì một cơ chế tha tất cả cũng
# xanh.
mkbrown adopt1
chk "scaffold ghi adopt_from cho kho đã có code" \
  'grep -qE "^adopt_from=[0-9a-f]{40}$" .sdd/config'
chk "mốc là commit CÓ THẬT trong lịch sử, không phải số bịa" \
  'git cat-file -e "$(sed -n "s/^adopt_from=//p" .sdd/config)^{commit}"'

# ① file cũ, không ID → qua, và phải NÊU TÊN file chứ không chỉ nói chung chung
app app/a.js "const c = 3;"
cmv "fix: sua file cu"
chk "sửa file cũ không ID: commit đi qua" 'git log -1 --format=%s | grep -q "sua file cu"'
chk "và hook nêu đích danh file được tha" 'grep -q "app/a.js" "$W/hookerr.txt"'
chk "và nói rõ đây không phải miễn spec" 'grep -q "NOT exempt from being specified" "$W/hookerr.txt"'

# ② file MỚI, không ID → chặn. Đây là vế giữ cho cơ chế không thành cờ bỏ qua.
printf 'const n = 9;\n' > app/new.js
cmv "feat: them file moi"
chk "file mới không ID: bị CHẶN" 'git log -1 --format=%s | grep -qv "them file moi"'
chk "và chặn bằng đúng câu cũ, không phải câu của nhận vào" \
  'grep -q "must carry an ID" "$W/hookerr.txt"'

# ③ trộn cũ + mới: file mới vẫn phải kéo cả commit xuống
git rm -q --cached app/new.js >/dev/null 2>&1; rm -f app/new.js
app app/b.js "const d = 4;"
printf 'const m = 8;\n' > app/new2.js
cmv "feat: tron cu va moi"
chk "trộn cũ+mới không ID: vẫn bị CHẶN" 'git log -1 --format=%s | grep -qv "tron cu va moi"'
chk "và file cũ trong đó vẫn được nêu tên" 'grep -q "app/b.js" "$W/hookerr.txt"'
