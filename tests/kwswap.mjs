#!/usr/bin/env node
// kwswap.mjs — viết lại tài liệu của repo hiện tại từ từ khoá tiếng Việt sang từ khoá tiếng Anh
// của bảng scripts/kw.tsv (7.7.0). Tham số: đường dẫn tới scripts/js/kw.mjs của plugin.
//
// Đây là nửa còn lại của phép đo "spec tiếng Anh qua cổng y hệt spec tiếng Việt": bảng là nguồn duy
// nhất, nên thêm một dòng vào kw.tsv là ca 45 tự phủ luôn, không phải sửa test. Thêm từ khoá mà quên
// định tuyến chỗ khớp trong script → ca 45 đỏ.
//
// Đổi theo VỊ TRÍ CẤU TRÚC, không thay chuỗi thô: 'Từ' · 'mở' · 'câu' là từ tiếng Việt thường gặp
// trong văn xuôi, thay thô thì bản tiếng Anh hỏng vì lý do không liên quan gì tới cổng.
//   head   ^#{1,6} X         (tiêu đề mục, mọi cấp)
//   label  **X:**            (nhãn đậm)
//   cell   | X |  ·  ^- X    (ô bảng, từ đứng riêng)
//   raw    nguyên văn
import fs from 'node:fs';
import path from 'node:path';

const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const un = (x) => x.replace(/\\(.)/g, '$1');            // bỏ escape ERE của bảng: \( → (
const { kwPairs } = await import(process.argv[2]);
const rules = [];
for (const [, kind, vi0, en0] of kwPairs()) {
  const vi = un(vi0), en = un(en0);
  if (kind === 'head')  rules.push([new RegExp('^(#{1,6} )' + esc(vi) + '(?=\\s*$|\\s)', 'gm'), (m, h) => h + en]);
  if (kind === 'label') {
    rules.push([new RegExp('\\*\\*' + esc(vi) + ':\\*\\*', 'g'), () => '**' + en + ':**']);
    // nhãn cũng hay viết TRẦN ở đầu một gạch đầu dòng: `- Ngày chạy: 2026-…`. Không phủ dạng này thì
    // mọi chỗ khớp `Ngày chạy` chưa định tuyến vẫn xanh ở bản tiếng Anh, tức phép đo hụt đúng chỗ nó phải soi.
    rules.push([new RegExp('^(\\s*[-*] )' + esc(vi) + '(?=:)', 'gm'), (m, h) => h + en]);
  }
  if (kind === 'cell') {
    rules.push([new RegExp('\\| *' + esc(vi) + ' *\\|', 'g'), () => '| ' + en + ' |']);
    rules.push([new RegExp('^(- )' + esc(vi) + '(?=\\s*$)', 'gm'), (m, h) => h + en]);
  }
  if (kind === 'raw')   rules.push([new RegExp(esc(vi), 'g'), () => en]);
}
rules.sort((a, b) => b[0].source.length - a[0].source.length);   // mẫu dài trước

const files = [];
const walk = (d) => {
  let es;
  try { es = fs.readdirSync(d, { withFileTypes: true }); } catch { return; }
  for (const e of es) {
    const q = path.join(d, e.name);
    if (e.isDirectory()) { if (e.name !== '.git') walk(q); }
    else if (/\.md$/.test(e.name)) files.push(q);
  }
};
walk('specs'); walk('notes');
if (fs.existsSync('STATE.md')) files.push('STATE.md');

let n = 0;
for (const f of files) {
  const t = fs.readFileSync(f, 'utf8');
  let u = t;
  for (const [re, fn] of rules) u = u.replace(re, fn);
  if (u !== t) { fs.writeFileSync(f, u); n++; }
}
process.stderr.write("kwswap: " + n + "/" + files.length + " file đổi sang từ khoá tiếng Anh (" + rules.length + " luật)\n");
