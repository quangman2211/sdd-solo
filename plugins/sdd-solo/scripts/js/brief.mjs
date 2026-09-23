#!/usr/bin/env node
// brief.mjs — sinh LỜI GIAO sáu phần cho một vai từ một file phiếu (7.2.0; chuyển sang node ở 7.6.0).
//
// Đầu vào bắt buộc là một FILE PHIẾU, không nhận chuỗi tự do: phần đắt của lời giao là neo, mà neo chỉ có
// trong phiếu. Biến môi trường do role.sh đưa vào: SDD_V (mã vai) · SDD_VN (tên vai) · SDD_ROOT · SDD_DENY ·
// SDD_CHECKS · SDD_BRANCH · SDD_LUOT · SDD_PK (gói đọc, cách nhau bằng khoảng trắng).
//
// Giữ NGUYÊN từng câu chữ của bản python nó thay — lời giao là thứ agent đọc, đổi chữ là đổi hành vi.
import fs from 'node:fs';
import path from 'node:path';

const pf = process.argv[2];
const V = process.env.SDD_V ?? '';
const VN = process.env.SDD_VN ?? '';
const root = process.env.SDD_ROOT ?? '';
const s = fs.readFileSync(pf, 'utf8');

const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const m = /^###?\s*#(\d+)\s*·\s*từ:\s*([^·\n]+?)\s*·\s*việc:\s*([^·\n]+?)\s*·\s*(\S+)/m.exec(s);
const n = m ? m[1] : '?';
const viec = (m ? m[3] : '').trim();
const IDRX = (alt) => new RegExp('(?<![\\p{L}\\p{N}_])(?:' + alt + ')-\\d+(?![\\p{L}\\p{N}_])', 'gu');
const ids = viec.match(IDRX('UC|BR|CHG|RULE|ADR'))
  || s.slice(0, 400).match(IDRX('UC|BR|CHG')) || [];
const idmain = ids[0] ?? 'viec';

// Python `(?ms)…(?=^Duyệt:|\Z)` bắt tới CUỐI CHUỖI; trong JS cờ 'm' làm `$` khớp cuối mỗi DÒNG, nên
// lazy match dừng ngay sau "Cho:" và khối việc rỗng — bẫy thứ hai khi chuyển python → node (7.6.0).
const cm = /^Cho:([\s\S]*?)(?=^Duyệt:)/m.exec(s) ?? /^Cho:([\s\S]*)/m.exec(s);
const cho = cm ? cm[1] : '';
let lines = cho.split('\n').map((l) => l.replace(/\s+$/, '')).filter((l) => l.trim());

const tok = new RegExp('(^|[\\s·,/])' + esc(V) + '([\\s·,/:(]|$)');
/** Chỉ so ở PHẦN ĐẦU MỤC: `- **B (BR-006):**` / `- **D · T:**` / mục inline `B (…)`. Không so cả dòng —
 *  `- **D:** chờ B` là việc của D, chữ "B" ở thân không đổi chủ. */
function forRole(l) {
  const h1 = /^\s*[-*]\s*\*\*([^*]+)\*\*/.exec(l);
  const h = h1 ? h1[1] : l.replace(/^\s*\**/, '').slice(0, 40);
    // `\b` của JS chỉ biết [A-Za-z0-9_], nên với tên vai có dấu nó ĐẢO chiều: `\bđiều phối\b` sau dấu `*`
  // không khớp (cả `*` lẫn `đ` đều "không phải chữ" với JS), trong khi python khớp. Biên từ phải hiểu chữ có dấu.
  return tok.test(h) || (VN && new RegExp('(?<![\\p{L}\\p{N}_])' + esc(VN) + '(?![\\p{L}\\p{N}_])', 'iu').test(h));
}

let mine = [];
if (lines.length && lines[0].includes(' · ') && !/^\s*[-*]/.test(lines[0])) {
  mine = mine.concat(lines[0].split(' · ').map((x) => x.trim()).filter(forRole));
  lines = lines.slice(1);
}
let cur = null;
for (const l of lines) {
  if (/^\s*[-*]/.test(l)) cur = forRole(l);
  if (cur) mine.push(l);
}
// bảng | K | Mức | Quyết | Cho | — dòng có V ở ô cuối
for (const l of s.split('\n')) {
  if (l.startsWith('|') && /^\|\s*[KF]\d+/.test(l)) {
    const cells = l.replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
    if (cells.length && forRole(cells[cells.length - 1])) mine.push(l.trim());
  }
}
let whole = false;
if (!mine.length && lines.length) { mine = lines; whole = true; }

if (mine.length === 1 && /không có việc/i.test(mine[0])) {
  process.stdout.write(`Phiếu #${n}: Cho: ${V} — "không có việc". Không giao.\n`);
  process.exit(0);
}

const neo = [];
for (const x of s.match(/\[neo:[^\]]*\]/g) ?? []) {
  if (!neo.includes(x) && x.replace(/^\[|\]$/g, '').replace('neo:', '').trim()) neo.push(x);
}
const pk = (process.env.SDD_PK ?? '').split(/\s+/).filter(Boolean);
const missing = pk.filter((p) => !fs.existsSync(path.join(root, p.split(':')[0])));
const deny = process.env.SDD_DENY ?? '';
const checks = (process.env.SDD_CHECKS ?? '').replaceAll('UC-###', idmain).replaceAll('BR-###', idmain);
const branch = process.env.SDD_BRANCH ?? '';
const luot = process.env.SDD_LUOT ?? '1';
let key = `${V.toLowerCase()}-${idmain.toLowerCase()}-p${n}` + (luot !== '1' ? `-l${luot}` : '');
key = key.replace(/[^a-z0-9._-]/g, '-').slice(0, 40);
const rel = path.isAbsolute(pf) ? path.relative(root, pf) : pf;

const out = [];
out.push(`Vai ${V} · ${VN} · phiếu #${n} · việc ${ids.join(' ') || viec} · lượt ${luot}`);
out.push(`1. Mục tiêu: áp đúng phần "Cho: ${V}" của phiếu #${n} vào ${idmain} — không thêm ý, chỗ phiếu không nói thì phiếu mới rồi dừng.`);
out.push('2. Đọc (trỏ, không chép): ' + pk.concat([`${rel} phần Cho: ${V}`]).join(' · ') + '. Không đọc phiếu khác, không đọc sổ điều phối.');
out.push('3. Việc, đuôi đã chốt (chép nguyên phiếu' + (whole ? ' — KHÔNG tìm thấy dòng riêng cho vai, đưa cả khối Cho:' : '') + '):');
for (const l of mine) out.push('   ' + l);
if (neo.length) out.push('   Neo: ' + neo.join(' '));
out.push('4. KHÔNG ghi: ' + (deny || '(không khai)') + ' · không tự quyết nghiệp vụ (số/enum/quyền thiếu → bash .sdd/scripts/phieu.sh new, rồi DỪNG) · không AskUserQuestion · không push.' + (branch ? ' Bước 0: git merge main.' : ''));
out.push('5. Kiểm trước commit: ' + (checks || '(theo .sdd/roles)') + ' — in số ✓/✗, không nói "xanh" suông. Commit <type>(' + idmain + '): … kê đích danh file: git commit --only -m … -- <file>; đuôi Vai: ' + V + '.');
out.push(`6. Kết: bash .sdd/scripts/role.sh --ketqua ${key} ket=xong neo=<hash commit> kiem=<✓/✗> hoi=- con=- (chặn: ket=chan hoi=<#phiếu>) rồi gửi đúng dòng KETQUA về điều phối, ≤ 10 dòng. Xong thì DỪNG.`);

const txt = out.join('\n');
process.stdout.write(txt + '\n');
if (missing.length) process.stderr.write('\n! gói đọc có đường dẫn không tồn tại: ' + missing.join(' ') + '\n');
if (txt.length > 1500) {
  process.stderr.write(`\n! lời giao ${txt.length} ký tự > 1.500 — dán vào một số công cụ sẽ không tự gửi (orchestrate phụ lục); ghi ra file rồi prompt "$(cat file)"\n`);
}
