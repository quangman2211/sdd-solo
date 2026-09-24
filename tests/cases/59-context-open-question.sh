# P-54 (8.4.1): context.sh --brief bỏ dòng mở `- [x] …` của một Open Question ĐÃ ĐÓNG (đúng ý: không đưa
# câu đã đóng cho vai đọc) nhưng GIỮ các dòng nối tiếp thụt lề của chính mục đó → bản ngữ cảnh có mảnh câu
# cụt không thuộc mục nào. Ca thật: C đọc "iv, R xếp `L0`): `entity ScheduledRun`…" khi verify UC-032.
# Hệ quả: subagent verify/adversarial đọc một câu không có chủ ngữ — sinh F# giả hoặc bỏ sót.
nr ctxq
node - "$UC1" <<'JS'
const fs = require('fs'); const p = process.argv[2];
fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replace(
  '- [ ] bao nhiêu phút (quyết định tạm: ___)',
  [ '- [x] ĐÃ ĐÓNG: chọn kiểu mốc thời gian (2026-01-05, R xếp `L0`): `entity ScheduledRun`',
    '  dùng `timestamptz`, không dùng `timestamp` — nguồn `architecture.md:88`',
    '  và một dòng nối tiếp nữa của chính mục đã đóng',
    '',
    '- [ ] bao nhiêu phút (quyết định tạm: ___)',
    '  dòng nối tiếp của câu CÒN MỞ — phải giữ' ].join('\n')));
JS
cm "docs(UC-001): Open Questions" 2026-01-06
S context.sh UC-001 --brief
chk "câu đã đóng: dòng mở bị bỏ (ý cũ, giữ nguyên) (exit $R)" '[ $R = 0 ] && ! has "ĐÃ ĐÓNG: chọn kiểu mốc"'
chk "và CẢ KHỐI nối tiếp của nó cũng bị bỏ — không còn mảnh câu cụt (P-54)" \
  '! has "dùng \`timestamptz\`" && ! has "một dòng nối tiếp nữa của chính mục đã đóng"'
chk "câu CÒN MỞ vẫn nguyên, cả dòng nối tiếp của nó" \
  'has "bao nhiêu phút" && has "dòng nối tiếp của câu CÒN MỞ"'
chk "mục ## Open Questions vẫn còn (không nuốt cả mục)" 'has "Open Questions"'
# file thật không bị đụng — context chỉ đọc
chk "file UC không đổi một byte" 'grep -q "ĐÃ ĐÓNG: chọn kiểu mốc" "$UC1" && grep -q "timestamptz" "$UC1"'
# heading ngay sau một câu đã đóng thì dừng đúng chỗ
node - "$UC1" <<'JS'
const fs = require('fs'); const p = process.argv[2];
fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replace(
  '- [ ] bao nhiêu phút (quyết định tạm: ___)\n  dòng nối tiếp của câu CÒN MỞ — phải giữ',
  '- [x] câu đóng cuối mục\n  nối tiếp của nó'));
JS
cm "docs(UC-001): câu đóng cuối mục" 2026-01-07
S context.sh UC-001 --brief
chk "câu đóng ở CUỐI mục: không nuốt sang mục sau" '[ $R = 0 ] && ! has "nối tiếp của nó" && has "Open Questions"'
