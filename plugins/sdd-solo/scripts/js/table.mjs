#!/usr/bin/env node
// table.mjs — sửa bảng markdown tại chỗ: thêm dòng phiếu, đổi ô, đánh dấu đã áp (7.6.0, thay ba khối python).
//
// Bảng markdown là kho dữ liệu của plugin (mục lục phiếu, hàng đợi, bảng UC) vì nó vừa máy đọc được vừa
// người sửa được. Sửa bằng sed thì hỏng ngay khi một ô có ký tự lạ; mỗi lệnh dưới đây làm đúng một việc.
//
//   table.mjs addrow <file> <dòng>          chèn dòng sau dòng "| #n |" cuối cùng, hoặc sau header
//   table.mjs setcell <file> <khoá> <cột>=<giá trị>…   sửa ô của dòng có ô đầu là khoá (cột: tên đã khai dưới)
//   table.mjs mark <file> <n> <giá trị>     đặt ô thứ 5 của dòng "| #n |" (trạng thái phiếu)
import fs from 'node:fs';

const [, , cmd, file, ...rest] = process.argv;
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function read(p) { return fs.readFileSync(p, 'utf8'); }
function write(p, s) { fs.writeFileSync(p, s); }

switch (cmd) {
  case 'addrow': {
    // Cùng luật với khối python nó thay: sau dòng phiếu cuối nếu có; chưa có dòng nào thì sau gạch header
    // của bảng mục lục; chưa có bảng thì thêm cả bảng. Ba nhánh, không nhánh nào được bỏ — mục lục phiếu là
    // chỗ cấp số, mất một dòng ở đây là trùng số ở lượt sau (P-21).
    const row = rest[0];
    let s = read(file);
    const rows = [...s.matchAll(/^\| *#\d+ \|.*$/gm)];
    const HEAD = '| # | Việc |';
    if (rows.length) {
      const i = rows[rows.length - 1].index + rows[rows.length - 1][0].length;
      s = s.slice(0, i) + '\n' + row + s.slice(i);
    } else if (s.includes(HEAD)) {
      const at = s.indexOf(HEAD);
      const m = /^\|---\|.*$/m.exec(s.slice(at));
      const i = at + m.index + m[0].length;
      s = s.slice(0, i) + '\n' + row + s.slice(i);
    } else {
      s = s.replace(/\n+$/, '') + '\n\n| # | Việc | Từ | Ngày | Trạng thái | File |\n'
        + '|---|---|---|---|---|---|\n' + row + '\n';
    }
    write(file, s);
    break;
  }
  case 'setcell': {
    const key = rest[0];
    const kv = Object.fromEntries(rest.slice(1).map((a) => {
      const i = a.indexOf('=');
      return [a.slice(0, i), a.slice(i + 1)];
    }));
    const col = { trangthai: 4, neo: 5, ghichu: 6 };
    const lines = read(file).split('\n');
    const re = new RegExp('^\\|\\s*' + esc(key) + '\\s*\\|');
    let done = false;
    for (let i = 0; i < lines.length; i++) {
      if (!re.test(lines[i].trim())) continue;
      const c = lines[i].trim().replace(/^\||\|$/g, '').split('|').map((x) => x.trim());
      while (c.length < 7) c.push('');
      for (const [k, v] of Object.entries(kv)) {
        if (!(k in col)) { process.stderr.write(`cột lạ: ${k}\n`); process.exit(2); }
        c[col[k]] = v;
      }
      lines[i] = '| ' + c.join(' | ') + ' |';
      done = true;
      break;
    }
    if (!done) { process.stderr.write('không có dòng ' + key + '\n'); process.exit(1); }
    write(file, lines.join('\n'));
    break;
  }
  case 'mark': {
    // JS không có cờ inline (?m) như python — cờ phải ở tham số thứ hai của RegExp, nếu không nó là
    // "nhóm không hợp lệ" và node ném ngay. Bẫy đầu tiên gặp khi chuyển từ python sang node (7.6.0).
    const [n, val] = rest;
    const s = read(file);
    const re = new RegExp('^(\\| *#' + esc(n) + ' \\|(?:[^|]*\\|){3}) *[^|]* *(\\|)', 'm');
    write(file, s.replace(re, `$1 ${val} $2`));
    break;
  }
  default:
    process.stderr.write('dùng: table.mjs <addrow|setcell|mark> <file> …\n');
    process.exit(2);
}
