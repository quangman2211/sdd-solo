# P-55 (8.4.2): gate-check §8 lấy mục Open Question bằng `grep -E '^- \[ \]'` — chỉ DÒNG MỞ. Mục viết dài,
# xuống dòng thụt lề (đúng khuôn 120 cột của chính plugin) thì "(quyết định tạm: …)" nằm ở dòng 2–4 và bị bỏ
# qua → ✗ oan. Và thông báo không nói MỤC NÀO nên người sửa phải tự dò. Cùng gốc với P-54.
nr oqnd
node - "$UC1" <<'JS'
const fs = require('fs'); const p = process.argv[2];
fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replace(
  '- [ ] bao nhiêu phút (quyết định tạm: ___)',
  [ '- [ ] ngưỡng `maxConcurrentProfiles` cho một gian: bao nhiêu hồ sơ chạy song song thì máy nền còn',
    '  giữ được nhịp, và con số đó có khác nhau giữa Windows với macOS không',
    '  (quyết định tạm: 4 trên cả hai, đo lại ở UC sau)',
    '- [ ] bao nhiêu phút (quyết định tạm: ___)' ].join('\n')));
JS
cm "docs(UC-001): Open Question nhiều dòng" 2026-01-06
S gate-check.sh UC-001
chk "cụm ở dòng nối tiếp vẫn tính là có quyết định tạm (P-55) (exit $R)" \
  '! has "has no (quyết định tạm" && ! has "an Open Question has no"'
chk "cổng xanh trở lại" '[ $R = 0 ]'
# mục THIẾU thật thì vẫn đỏ, và phải NÊU TÊN mục
node - "$UC1" <<'JS'
const fs = require('fs'); const p = process.argv[2];
fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replace(
  '  (quyết định tạm: 4 trên cả hai, đo lại ở UC sau)\n', ''));
JS
cm "docs(UC-001): bỏ quyết định tạm" 2026-01-07
S gate-check.sh UC-001
chk "mục thật sự thiếu → vẫn đỏ (exit $R)" '[ $R = 1 ] && has "an Open Question has no"'
chk "và NÊU TÊN mục vi phạm, không bắt người sửa tự dò (P-55)" 'has "maxConcurrentProfiles"'
chk "không kê nhầm mục đang có quyết định tạm" '! has "bao nhiêu phút"'
