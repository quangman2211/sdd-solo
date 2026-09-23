#!/usr/bin/env node
// pass.mjs — ba việc sửa file của pass.sh (5.0.0 · #45; chuyển sang node ở 7.6.0):
//
//   pass.mjs trace <file UC> <file trace> <ID> <ngày>   ⑭ dời dấu vết sang UC-###.trace.md, để lại MỘT dòng đếm
//   pass.mjs deprecate <file UC> <ngày> <lý do> <thay bằng|->   thêm dòng History "deprecated — …"
//   pass.mjs change <proposal.md> <ngày>                Status → applying, History +1 dòng
//
// Luật của `trace` (5.0.0): một bước là công cụ để NGHĨ thì để lại một QUYẾT ĐỊNH, không để lại một tài liệu.
// Adversarial · Đọc lại · History là giấy nháp: khi UC đóng, thân dời sang file cạnh (git giữ, tranh chấp thì
// mở), tại chỗ còn một dòng có số đếm bằng máy. Đo ở runxops: UC-009.md 56 KB thì ba mục đó là 28,6 KB.
import fs from 'node:fs';
import { kw, kwW } from './kw.mjs';

const [, , cmd, ...a] = process.argv;
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const read = (p) => fs.readFileSync(p, 'utf8');

/** Thân của mục `## <tên>` tới `## ` kế tiếp (hoặc hết file). Trả {start, end, body} hoặc null.
 *  7.7.0: `name` là THÂN ALTERNATION (`Đọc lại|Re-read`) chứ không phải chuỗi cố định — mục viết
 *  bằng tiếng nào cũng tìm ra. Tên mục không có ký tự đặc biệt của regex nên không cần esc. */
function section(s, name) {
  const re = new RegExp('^## (?:' + name + ')[ \\t]*\\n', 'm');
  const m = re.exec(s);
  if (!m) return null;
  const start = m.index + m[0].length;
  const rest = s.slice(start);
  const nx = /^## /m.exec(rest);
  const end = nx ? start + nx.index : s.length;
  return { start, end, body: s.slice(start, end) };
}

if (cmd === 'trace') {
  const [f, tr, ID, today] = a;
  let s = read(f);
  const moved = [];

  // 7.7.0: `alt` là thân alternation để TÌM mục (viết tiếng nào cũng thấy), `head` là tên mục
  // GHI vào file dấu vết theo doc_lang. Trước 7.7.0 hai thứ này là một chuỗi.
  const replace = (alt, head, summary) => {
    const sec = section(s, alt);
    if (!sec) return;
    const body = sec.body;
    if (body.includes('→ ' + ID + '.trace.md')) return;      // đã nén
    if (!body.trim()) return;                                 // rỗng — không có gì để dời
    // 7.4 (P-40): `<hash>`, `<label for="np-go">`, chữ trong nháy mã là NỘI DUNG, không phải khuôn — bỏ chúng
    // trước khi hỏi "còn khuôn không". Khuôn thật: YYYY-MM-DD · Ngày chạy: ___ · <...> còn lại.
    let t = body.replace(/`[^`\n]*`/g, '');
    t = t.replace(/<\/?[A-Za-z][A-Za-z0-9-]*(\s+[A-Za-z_:-]+(=("[^"]*"|'[^']*'|[^\s>]+))?)*\s*\/?>/g, '');
    if (new RegExp('YYYY-MM-DD|(?:' + kw('rundate') + '):\\s*_|<[^>\\n]+>').test(t)) return;
    moved.push([head, body.replace(/\n+$/, '') + '\n']);
    s = s.slice(0, sec.start) + summary + '\n\n' + s.slice(sec.end);
  };
  const RUN = kwW('rundate');
  const dateIn = (body) =>
    (new RegExp('(?:' + kw('rundate') + '):\\s*(\\d{4}-\\d{2}-\\d{2})').exec(body) ?? [, today])[1];

  let sec = section(s, kw('adversarial'));
  if (sec && new RegExp(kw('rundate')).test(sec.body)) {
    const n = (sec.body.match(/^\s*-\s*Q\d+\b/gm) ?? []).length;
    replace(kw('adversarial'), kwW('adversarial'),
      `- ${RUN}: ${dateIn(sec.body)} · 3 ${kwW('roles')} · ${n} ${kwW('questions')}, ${kwW('allapplied')} → ${ID}.trace.md`);
  }
  sec = section(s, kw('reread'));
  if (sec && /^- F\d+ /m.test(sec.body)) {
    const n = (sec.body.match(/^- F\d+ /gm) ?? []).length;
    const k = (sec.body.match(new RegExp('^- F\\d+ .*(?:' + kw('falsepos') + ')', 'gm')) ?? []).length;
    replace(kw('reread'), kwW('reread'),
      `- ${RUN}: ${dateIn(sec.body)} · ${n} ${kwW('findings')} · ${k} ${kwW('falsepos2')} · ${kwW('allapplied')} → ${ID}.trace.md`);
  }
  sec = section(s, 'History');
  if (sec && /^- v\d+ /m.test(sec.body)) {
    const vs = [...sec.body.matchAll(/^- v(\d+) /gm)].map((m) => Number(m[1]));
    replace('History', 'History',
      `- v${Math.max(...vs) + 1} (${today}): implemented · ${kwW('fullhistory')} → ${ID}.trace.md`);
  }
  sec = section(s, 'Open Questions');
  if (sec) {
    const closed = sec.body.match(/^[ \t]*[-*] \[x\].*\n?/gim) ?? [];
    if (closed.length) {
      moved.push([`Open Questions (${kwW('closedq')})`, closed.join('')]);
      const nb = sec.body.replace(/^[ \t]*[-*] \[x\].*\n?/gim, '');
      s = s.slice(0, sec.start) + nb + s.slice(sec.end);
    }
  }

  if (moved.length) {
    let old = '', head = '';
    try {
      old = read(tr);
    } catch {
      head = `# ${ID} — dấu vết\n\n`
        + `<!-- Sinh bởi pass.sh close ngày ${today}. Đây là GIẤY NHÁP của ${ID}: adversarial, đọc lại,\n`
        + `     history, câu hỏi đã đóng. Không phải file đọc thường — mở khi cần tra vì sao một\n`
        + `     dòng trong ${ID}.md ra như thế. context.sh và decisions.sh không đọc file này. -->\n`;
    }
    let out = old + head;
    for (const [h, b] of moved) out += `\n## ${h} — ${today}\n${b}`;
    fs.writeFileSync(tr, out);
    fs.writeFileSync(f, s);
    process.stdout.write(`  dời ${moved.length} mục sang ${ID}.trace.md\n`);
  }
} else if (cmd === 'deprecate') {
  const [f, today, reason, by] = a;
  let s = read(f);
  const vs = [...s.matchAll(/^- v(\d+) /gm)].map((m) => Number(m[1]));
  const line = `- v${(vs.length ? Math.max(...vs) : 0) + 1} (${today}, ${kwW('byowner')}): deprecated — ${reason}`
    + (by !== '-' ? ` · ${kwW('replacedby')} ${by}` : ` · ${kwW('noreplacement')}`);
  const sec = section(s, 'History');
  if (sec) {
    const body = sec.body.replace(/\n+$/, '');
    s = s.slice(0, sec.start) + body + '\n' + line + '\n' + (sec.end < s.length ? '\n' : '') + s.slice(sec.end);
  } else {
    s = s.replace(/\n+$/, '') + '\n\n## History\n' + line + '\n';
  }
  fs.writeFileSync(f, s);
} else if (cmd === 'change') {
  const [p, d] = a;
  let s = read(p);
  s = s.replace(/^(## Status\n+)[a-z]+[ \t]*$/m, '$1applying');
  if (s.includes('## History') && !s.includes(`${d}: designed -> applying`)) {
    s = s.replace(/\n+$/, '') + `\n- ${d}: designed -> applying (${kwW('c_p5')})\n`;
  }
  fs.writeFileSync(p, s);
} else {
  process.stderr.write('dùng: pass.mjs <trace|deprecate|change> …\n');
  process.exit(2);
}
