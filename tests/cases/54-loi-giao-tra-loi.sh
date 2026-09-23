# P-47 (8.2.0): role.sh sinh lời giao coi MỌI vai là vai ÁP — mục 1 nói "áp đúng phần Cho: R" và mục 3
# rỗng, vì R là vai TRẢ LỜI phiếu: lúc R nhận việc thì phiếu chưa có Cho: nào. A phải viết tay lời giao R.
# Vai có `commit=khong` cần khuôn khác: xếp mức L0–L3 từng K · tra nguồn · viết Trả lời + Cho: · không commit.
nr traloi
S phieu.sh new "UC-001 soát code khối 1" soi
F=notes/hoi-dap/phieu/001-uc-001-soat-code-khoi-1.md
node - "$F" <<'JS'
const fs = require('fs'); const p = process.argv[2];
let s = fs.readFileSync(p, 'utf8');
s = s.replace(/^Câu:.*$/m, [
 '**K1 — nền import chỗ ghép**',
 'Câu: giữ cạnh này hay dời CLI dọn ra chỗ ghép?',
 'Đã tra: design.md:432 · tests/boundary.test.ts:23',
 '',
 '**K2 — reportInboxPart không kiểm gian**',
 'Câu: có phải kiểm AccountInvalid trước khi ghi trace không?',
 'Đã tra: design.md:334-335 · :437',
].join('\n'));
fs.writeFileSync(p, s);
JS
S role.sh R "$F"
chk "vai commit=khong → khuôn TRẢ LỜI, không phải khuôn áp (exit $R)" \
  '[ $R = 0 ] && ! has "apply exactly the" && hasE "^1\. Goal: grade"'
chk "mục 1 nói xếp mức L0–L3 và viết Cho: cho từng vai" \
  'has "L0" && has "L3" && has "Trả lời (R)" && has "Cho:"'
chk "mục 3 liệt kê các K của phiếu, không còn rỗng" 'has "K1" && has "K2" && has "nền import chỗ ghép"'
chk "mục 2 trỏ sổ hỏi để tra bảng bốn mức" 'has "notes/hoi-dap/hoi-dap.md"'
chk "mục 5 nói KHÔNG commit, A commit thay" '! has "git commit --only" && has "does not commit"'
chk "mục 6 neo là chính file phiếu, không phải hash" "has 'neo=$F'"
chk "L3 thì không tự quyết — soạn câu hỏi cho chủ dự án" 'has "does not decide"'
# vai áp vẫn nhận khuôn cũ — không được hồi quy
node - "$F" <<'JS'
const fs = require('fs'); const p = process.argv[2];
fs.writeFileSync(p, fs.readFileSync(p,'utf8').replace('Cho: <one line per role: - **B:** … · - **D:** … · - **T:** …>',
  'Cho:\n- **B:** thêm AC-3 "gửi trùng" [neo: UC-001 ## Acceptance Criteria]'));
JS
S role.sh B "$F"
chk "vai commit=co vẫn nhận khuôn ÁP như cũ (exit $R)" \
  '[ $R = 0 ] && has "apply exactly the" && has "thêm AC-3" && has "git commit --only"'
