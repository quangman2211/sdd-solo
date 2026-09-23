#!/usr/bin/env node
// hoi.mjs — kiểm sổ hỏi của một vai: bốn ô đủ, đã trả lời thì có đích, số không trùng/nhảy (7.3.0 → node 7.6.0).
//
// Luật đắt nhất ở đây: **cổng UC đã mở mà ô `đích:` trỏ vào thân UC** là ✗. Đó là luật 6 của runxops thành
// phép đo — UC-025: 25 mục HỎI, mỗi câu kéo một lượt sửa thân UC rồi một lượt verify trọn. Sau cổng, câu trả
// lời đi vào design.md hoặc decisions.md; thân UC chỉ mở lại khi một AC thật sự đổi.
//
// Dùng: hoi.mjs <file sổ> <mã vai> <root>   · exit 1 nếu có ✗
import fs from 'node:fs';
import path from 'node:path';

const [, , file, V, root] = process.argv;
const s = fs.readFileSync(file, 'utf8');
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const out = (kind, m) => process.stdout.write(
  (kind === 'bad' ? '  \x1b[31m✗\x1b[0m ' : kind === 'warn' ? '  \x1b[33m!\x1b[0m ' : '  \x1b[32m✓\x1b[0m ') + m + '\n');

const FIELDS = ['Nguồn', 'Chặn không', 'Đang làm gì trong lúc chờ', 'Việc cho spec khi trả lời'];
const blocks = s.split(/^(?=### HỎI-)/m);
const nums = [];
let bad = 0, warn = 0;

for (const b of blocks) {
  const m = new RegExp('^### HỎI-' + esc(V) + '(\\d+)[ ·]').exec(b);
  if (!m) continue;
  const n = Number(m[1]);
  nums.push(n);
  const tag = `HỎI-${V}${n}`;
  for (const fl of FIELDS) {
    const mm = new RegExp('\\*\\*' + esc(fl) + ':\\*\\*\\s*(.*)').exec(b);
    const val = mm ? mm[1].trim() : '';
    if (!val || /^<[^>]*>\s*$/.test(val) || val === '-' || val === '___') {
      out('bad', `${tag}: ô "${fl}" trống hoặc còn khuôn`); bad++;
    }
  }
  const okChan = /\*\*Chặn không:\*\*\s*(chặn|không chặn)\b/.exec(b);
  if (!okChan && /\*\*Chặn không:\*\*/.test(b)) {
    out('bad', `${tag}: "Chặn không" phải bắt đầu bằng chặn | không chặn`); bad++;
  }
  const ans = /\*\*Trả lời \(A\/R\):\*\*\s*(.*)/.exec(b);
  const ansv = ans ? ans[1].trim() : '';
  const ansvCore = ansv.replace(/·\s*\*\*đích:\*\*.*$/, '').trim();
  if (ansvCore && !/^<[^>]*>$/.test(ansvCore)) {
    const d = /\*\*đích:\*\*\s*(.*)/.exec(b);
    const dv = d ? d[1].trim() : '';
    if (!dv || /^<[^>]*>$/.test(dv)) {
      out('bad', `${tag}: đã trả lời mà không có đích: (design.md · decisions.md · UC-### AC-# khi AC đổi)`); bad++;
    } else {
      const uc = /\bUC-\d+\b/.exec(dv);
      if (uc && !dv.includes('design.md') && !dv.includes('decisions')
          && !/\bAC-?\d*\b|AC đổi|History/.test(dv)
          && fs.existsSync(path.join(root, '.sdd/gate', uc[0] + '.ok'))) {
        out('bad', `${tag}: cổng ${uc[0]} đã mở mà đích trỏ vào thân UC (${dv.slice(0, 50)}) — sau cổng trả lời ở design.md/decisions.md; thân UC chỉ mở khi một AC đổi`);
        bad++;
      }
    }
  }
}

const dup = [...new Set(nums.filter((x) => nums.filter((y) => y === x).length > 1))].sort((a, b2) => a - b2);
if (dup.length) { out('bad', 'số HỎI trùng: ' + dup.join(' ')); bad++; }
if (nums.length) {
  const gaps = [];
  for (let i = 1; i < Math.max(...nums); i++) if (!nums.includes(i)) gaps.push(i);
  if (gaps.length) { out('warn', 'số HỎI nhảy: ' + gaps.join(' ')); warn++; }
  if (bad === 0) out('ok', `${nums.length} mục HỎI-${V}, đủ bốn ô`);
} else {
  process.stdout.write('  – chưa có mục HỎI nào\n');
}
process.exit(bad ? 1 : 0);
