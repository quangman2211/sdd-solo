# 7.2: role.sh <vai> <file phiếu> — lời giao sáu phần, chỉ nhận file, gói đọc có thật, việc chép đúng vai
nr brief
S phieu.sh new "UC-001 F-gửi trùng" soi
F=notes/hoi-dap/phieu/001-uc-001-f-gui-trung.md
node - "$F" <<'JS'
const fs = require('fs');
const p = process.argv[2];
const s = fs.readFileSync(p, 'utf8');
fs.writeFileSync(p, s.replaceAll('Cho: <one line per role: - **B:** … · - **D:** … · - **T:** …>', 'Cho:\n- **B:** thêm AC-3 "gửi trùng" [neo: UC-001 ## Acceptance Criteria] · sửa Main 2 [neo: UC-001 ## Main Flow bước 2]\n  chi tiết dòng con của B\n- **D:** chờ B\n- **T:** không có việc'));
JS
S role.sh B "$F"
chk "in đủ sáu phần (exit $R)" '[ $R = 0 ] && hasE "^1\. Goal" && hasE "^2\. Read" && hasE "^3\. The work" && hasE "^4\. MAY NOT write" && hasE "^5\. Checks" && hasE "^6\. Ending"'
chk "gói đọc trỏ file UC thật và phiếu" 'has "specs/orders/br-001/use-cases/UC-001-notify-order/UC-001.md" && has "the Cho: B part"'
chk "việc chép đúng dòng của B kèm dòng con, không lấy dòng D" 'has "thêm AC-3" && has "chi tiết dòng con của B" && ! has "chờ B"'
chk "neo được gom" 'has "Anchors: [neo: UC-001 ## Acceptance Criteria]"'
chk "vùng cấm từ .sdd/roles, kiểm thay UC-###" 'has "MAY NOT write: specs/decisions.md specs/vision.md STATE.md src tests" && has "gate-check.sh --pre UC-001"'
chk "dòng KETQUA có khoá b-uc-001-p1" 'has "role.sh --ketqua b-uc-001-p1 ket=xong"'
chk "không có đường dẫn nào không tồn tại" '! has "không tồn tại"'
S role.sh T "$F"
chk "vai T: 'không có việc' → không giao" 'has "no work" && has "Not delegated"'
S role.sh B "làm UC-001 đi"
chk "chuỗi tự do → từ chối (exit $R)" '[ $R = 1 ] && has "not a free-form string"'
S role.sh B "$F" --luot 2
chk "--luot 2 → khoá b-uc-001-p1-l2" 'has "b-uc-001-p1-l2"'
