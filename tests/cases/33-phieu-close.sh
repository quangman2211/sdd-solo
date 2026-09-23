# 7.2 P-33: đóng phiếu đếm F# trên FILE; vai trong Cho: phải có KETQUA
nr pclose
S phieu.sh new "UC-001 đọc lại" soi
F=notes/hoi-dap/phieu/001-uc-001-doc-lai.md
node - "$F" <<'JS'
const fs = require('fs');
const p = process.argv[2];
let s = fs.readFileSync(p, 'utf8');
s = s.replaceAll('### #1 · từ: soi · việc: UC-001 đọc lại', '### #1 · từ: soi · việc: UC-001 đọc lại — **25 phát hiện · 3 chặn**');
s = s.replaceAll('Cho: <mỗi vai một dòng: - **B:** … · - **D:** … · - **T:** …>', 'Cho:\n- **B:** áp F1…F24 [neo: UC-001 ## Main Flow bước 2]\n- **D · T:** không có việc');
let body = '';
for (let i = 1; i < 25; i++) body += `- F${i} phát hiện ${i} [neo: Main 2] → sửa\n`;
s = s.replaceAll('Duyệt:\n', () => body + 'Duyệt:\n');
fs.writeFileSync(p, s);
JS
cm "chore(sdd): phiếu #1 — thân" 
S phieu.sh close 1
chk "khai 25 mà file có 24 → đỏ, kê thiếu #25 (exit $R)" '[ $R = 1 ] && has "tự khai 25 mục nhưng trên file đếm được 24"'
app "$F" "- F25 phát hiện 25 [neo: Main 3] → sửa"
S phieu.sh close 1
chk "đủ 25 nhưng B chưa có KETQUA → đỏ (exit $R)" '[ $R = 1 ] && has "vai B có việc trong Cho: nhưng chưa có KETQUA"'
H="$(git rev-parse --short HEAD)"
S role.sh --ketqua b-uc-001-p1 ket=xong neo="$H" kiem=gate-check:0
chk "role.sh --ketqua ghi file ở git-common-dir (exit $R)" '[ $R = 0 ] && [ -f .git/sdd-ketqua/b-uc-001-p1.txt ]'
S phieu.sh close 1
chk "đủ F# + KETQUA của B → đóng, mục lục đã áp (exit $R)" '[ $R = 0 ] && grep -q "^| #1 |.*| đã áp |" notes/hoi-dap/hoi-dap.md'
