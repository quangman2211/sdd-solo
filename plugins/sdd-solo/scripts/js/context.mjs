#!/usr/bin/env node
// context.mjs — gom ĐÚNG ĐỦ bối cảnh của một UC (hoặc một lát BR) vào một lần in (5.0.0 → node ở 7.6.0).
//
// Vì sao có file này. Tới 4.2.0, /sdd-solo:design dặn agent đọc 13 tên file bằng lời văn, và không phép kiểm
// nào đo được nó đã đọc chưa. Lời dặn đọc 13 file là lời dặn hỏng theo xác suất — và hỏng im lặng, vì bản
// thiết kế viết ra vẫn trôi chảy, chỉ thiếu một nguồn (#34). Đo ở runxops: hiểu UC-009 phải mở 15 file /
// 6 thư mục / 210 KB ≈ 53k token, mà hơn 60% là dấu vết, không phải hiệu lực.
//
// Đường dẫn nguồn KHÔNG tự dò ở đây: lib.sh tra rồi đưa vào qua biến môi trường, mỗi dòng một file (#55).
//   SDD_RULES · SDD_BRS · SDD_ADRS · SDD_ARCH · SDD_ENTS · SDD_GLOS · SDD_OTHERS
// Tham số: <root> <file chủ thể> <ID> <owner> <WHY 0|1> <brief path> <brief sha> <BRIEF 0|1>
import fs from 'node:fs';
import path from 'node:path';

const [, , ROOT, F, ID, CTX, WHY_, BP, BS, BRIEF_] = process.argv;
const WHY = WHY_ === '1';
const BRIEF = BRIEF_ === '1';
const IS_BR = ID.startsWith('BR-');

// `\b` của JS chỉ biết [A-Za-z0-9_]; của python biết cả chữ có dấu. `\b[A-Z][A-Za-z]{2,}\b` trên
// "Khoá API" vì thế: python KHÔNG khớp (sau "Kho" còn "á" là chữ), JS khớp "Kho" — và context gói thêm
// hai entity không ai nhắc. Đo bằng snapshot bản sao runxops 6.x: 126 dòng lệch, cả 126 từ một chữ này.
// WB/WE là biên từ hiểu chữ có dấu, dùng ở mọi chỗ cũ viết `\b` quanh chữ.
const WB = '(?<![\\p{L}\\p{N}_])';
const WE = '(?![\\p{L}\\p{N}_])';
const rxw = (body, flags = '') => new RegExp(WB + body + WE, flags + 'u');

const envList = (k) => (process.env[k] ?? '').split('\n').filter((x) => x.trim());
const RULES = envList('SDD_RULES'), BRS = envList('SDD_BRS'), ADRS = envList('SDD_ADRS');
const ENTS = envList('SDD_ENTS'), GLOS = envList('SDD_GLOS');
const ARCH = process.env.SDD_ARCH ?? '';
const OTHERS = new Set(envList('SDD_OTHERS').map((x) => x.toLowerCase()));

const rel = (p) => path.relative(ROOT, p);
const relList = (ps) => ps.map(rel).join(' · ');
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const rd = (p) => { try { return fs.readFileSync(p, 'utf8'); } catch { return null; } };

const out = [];
const warns = [];
const srcs = [];   // [tên nguồn, chỉ số bắt đầu trong out]

/** cùng luật với lib.sh strip_markup: bỏ cả khối <!-- -->, bỏ thẻ inline */
function stripMarkup(s) {
  s = s.replace(/<!--[\s\S]*?-->/g, '');
  return s.replace(/<\/?(br|b|i|u|em|strong|code|sub|sup|kbd|small)\s*\/?>/g, '');
}

/** thân của mục `level head` tới mục cùng cấp kế tiếp (khớp tiền tố heading) */
function sect(s, head, level = '## ') {
  const re = new RegExp('^' + esc(level + head) + '[^\\n]*\\n', 'm');
  const m = re.exec(s);
  if (!m) return null;
  const start = m.index + m[0].length;
  const rest = s.slice(start);
  const nx = new RegExp('^' + esc(level), 'm').exec(rest);
  return nx ? rest.slice(0, nx.index) : rest;
}

const TRACE = ['Adversarial pass', 'Đọc lại', 'History'];
const isTrace = (title) => TRACE.some((x) => title.trim().toLowerCase().startsWith(x.toLowerCase()));

/** #43: cắt mục dấu vết ở MỌI cấp heading của nguồn được trích, và câu hỏi đã [x]. */
function dropTrace(s) {
  const keep = [];
  let cut = 0;
  for (const ln of s.split('\n')) {
    const m = /^(#{1,6}) (.*)/.exec(ln);
    if (m) {
      const lvl = m[1].length;
      if (cut && lvl <= cut) cut = 0;
      if (!cut && isTrace(m[2])) { cut = lvl; continue; }
    }
    if (cut) continue;
    if (/^\s*[-*] \[x\]/i.test(ln)) continue;
    keep.push(ln);
  }
  return keep.join('\n');
}

const H = (t) => { srcs.push([t, out.length]); out.push(`\n════ ${t} ════`); };

let uc = rd(F);
const design = IS_BR ? '' : (rd(path.join(path.dirname(F), 'design.md')) ?? '');

// ── 0. BR-### (7.4, P-23): chủ thể là một lát — mục quyết định của BR + dòng ở vision.md ──
if (IS_BR) {
  const bm = new RegExp('^# ' + esc(ID) + ':([^\\n]*)\\n([\\s\\S]*?)(?=^# BR-|$(?![\\s\\S]))', 'm')
    .exec(stripMarkup(uc ?? ''));
  uc = bm ? bm[2] : '';
  if (!WHY && bm) {
    H(`${ID}:${bm[1]} — quyết định (không Background)`);
    for (const hname of ['Goal', 'In Scope', 'Out of Scope', 'Success Metrics', 'Constraints',
      'Related Use Cases', 'Đã loại khỏi brief', 'Open Questions']) {
      const sb = sect(uc, hname);
      if (sb && sb.trim()) out.push(`## ${hname}\n` + dropTrace(sb).replace(/\s+$/, ''));
    }
    const bg = sect(uc, 'Background');
    if (bg && bg.trim()) {
      out.push(`(## Background: ${(Buffer.byteLength(bg) / 1024).toFixed(1)} KB chứng cứ — đọc ${rel(F)} khi cần)`);
    }
    const vis = rd(path.join(ROOT, 'specs', 'vision.md'));
    const rows = (vis ?? '').split('\n').filter((l) => l.startsWith('|') && rxw(ID).test(l));
    if (rows.length) { H('specs/vision.md — dòng của lát'); out.push(...rows); }
  }
}

// ── 1. UC — mọi mục trừ ba mục dấu vết; Open Questions chỉ giữ câu còn mở ──
if (!WHY && !IS_BR) {
  H(`${ID}.md — phần đang hiệu lực`);
  out.push(dropTrace(uc).replace(/\s+$/, ''));
  const fl = rd(path.join(path.dirname(F), `${ID}.flow.md`));
  if (fl && fl.includes('```mermaid')) { H(`${ID}.flow.md`); out.push(fl.replace(/\s+$/, '')); }
}

// ── 2-4. ID UC (và design.md) trích ──
const cited = dropTrace(uc) + '\n' + design;
const uniqSort = (xs) => [...new Set(xs)].sort();
const rules = uniqSort(cited.match(rxw('RULE-[0-9]+[a-z]?', 'g')) ?? []);
const cons = IS_BR ? [] : uniqSort(cited.match(rxw('CON-[0-9]+', 'g')) ?? []);   // BR: CON nằm ngay ## Constraints ở trên
const adrs = uniqSort(cited.match(rxw('ADR-[0-9]+', 'g')) ?? []);

const rl = RULES.map((p) => rd(p) ?? '').join('\n');
if (rules.length) {
  H(`RULE được trích (${rules.length}) — ${relList(RULES) || 'specs/rules.md'}`);
  const rls = stripMarkup(rl || '');
  for (const r of rules) {
    let b = null;
    for (const lvl of ['## ', '### ']) {
      b = sect(rls, r + ':', lvl);
      if (b === null) b = sect(rls, r, lvl);
      if (b !== null) break;
    }
    if (b === null) { warns.push(`${r} — UC trích nhưng rules.md không có`); continue; }
    out.push(`## ${r}\n` + dropTrace(b).replace(/\s+$/, ''));
  }
}

const br = BRS.map((p) => rd(p) ?? '').join('\n');
const brs = stripMarkup(br);
if (cons.length) {
  H(`CON được trích (${cons.length}) — ${relList(BRS) || 'specs/br.md'} ## Constraints`);
  // bỏ BR-000 (BR mẫu) — cùng luật với br-check và decisions.sh
  const brsNo0 = brs.replace(/^# BR-000:[\s\S]*?(?=^# BR-|$(?![\s\S]))/m, '');
  const lines = brsNo0.split('\n');
  for (const c of cons) {
    let hit = null;
    for (let i = 0; i < lines.length; i++) {
      if (new RegExp('-?\\s*\\*\\*' + esc(c) + WE, 'u').test(lines[i])) {
        hit = lines[i].trim();
        if (i + 1 < lines.length && /^\s+- Từ:/.test(lines[i + 1])) hit += '\n' + lines[i + 1].replace(/\s+$/, '');
        break;
      }
    }
    if (hit === null) { warns.push(`${c} — UC trích nhưng br.md không có (ngoài BR-000)`); continue; }
    out.push(hit);
  }
}

if (adrs.length) {
  H(`ADR được trích (${adrs.length}) — ${ADRS.length ? relList(ADRS) + '/' : 'specs/adr/'}`);
  for (const aid of adrs) {
    const fs_ = [];
    for (const d of ADRS) {
      let names = [];
      try { names = fs.readdirSync(d).sort(); } catch { names = []; }
      for (const nm of names) if (nm.startsWith(aid) && !nm.startsWith('_')) fs_.push(path.join(d, nm));
    }
    if (!fs_.length) { warns.push(`${aid} — UC trích nhưng không có file ADR`); continue; }
    const t = stripMarkup(rd(fs_[0]) ?? '');
    const title = t.split('\n').find((l) => l.startsWith('# ')) ?? `# ${aid}`;
    const st = (sect(t, 'Status') ?? '').trim().split('\n')[0];
    let dec = dropTrace(sect(t, 'Decision') ?? '').trim();
    if (BRIEF) {
      // đoạn đầu tới ### đầu tiên + tên mục con; đoạn đầu rỗng thì mục con đầu tiên nguyên
      const parts = dec.split(/^(?=### )/m);
      let head = parts[0].trim();
      let subs = parts.slice(1).map((p) => p.split('\n', 1)[0]);
      if (!head && parts.length > 1) { head = parts[1].trim(); subs = subs.slice(1); }
      dec = head + (subs.length ? '\n' + subs.map((h) => `${h} — (mục con, xem file)`).join('\n') : '');
    }
    out.push(`${title}\nStatus: ${st}\n${dec}`);
  }
}

// ── 5. BR cha — quyết định, không chứng cứ ──
const brid = IS_BR ? null : rxw('BR-[0-9]+').exec(uc);
if (!WHY && brid) {
  const b = brid[0];
  const body = new RegExp('^# ' + esc(b) + ':([^\\n]*)\\n([\\s\\S]*?)(?=^# BR-|$(?![\\s\\S]))', 'm').exec(brs);
  if (body) {
    H(`${b}:${body[1]} — quyết định (không Background)`);
    for (const hname of ['Goal', 'In Scope', 'Out of Scope', 'Success Metrics', 'Đã loại khỏi brief']) {
      const sb = sect(body[2], hname);
      if (sb && sb.trim()) out.push(`## ${hname}\n` + dropTrace(sb).replace(/\s+$/, ''));
    }
  } else warns.push(`${b} — UC trỏ tới nhưng br.md không có`);
}

// ── 6. architecture.md — bốn mục ──
const ar = ARCH ? rd(ARCH) : null;
if (ar) {
  const ars = stripMarkup(ar);
  const heads = WHY ? ['Cấm'] : (BRIEF ? ['Cấm', 'Ranh giới', 'Nơi chạy'] : ['Ngăn xếp', 'Nơi chạy', 'Ai gọi', 'Cấm']);
  H(rel(ARCH) + (BRIEF ? ' — --brief: Cấm · Ranh giới · Nơi chạy' : ''));
  for (const hname of heads) {
    const sb = sect(ars, hname);
    if (sb === null) {
      if (hname !== 'Ranh giới') warns.push(`architecture.md thiếu ## ${hname}`);
      continue;
    }
    if (/<[^>\n]+>/.test(sb)) warns.push(`architecture.md ## ${hname} còn placeholder <...> — chưa ai quyết`);
    out.push(`## ${hname}\n` + dropTrace(sb).replace(/\s+$/, ''));
  }
} else warns.push('thiếu ' + (ARCH ? rel(ARCH) : 'specs/architecture.md'));

// ── 7. entity + glossary có nhắc trong UC ──
if (!WHY) {
  // 7.0 (T2): mỗi entity một file — entity_cited đã lọc theo tên UC nhắc, in nguyên file (bỏ dấu vết).
  // 6.x: một entities.md cho cả context — tách khối ## theo tên UC nhắc như trước.
  let en = null;
  if (ENTS.length && !ENTS.some((p) => p.includes('/specs/contexts/'))) {
    H(`entities — ${ENTS.length} entity UC nhắc tên (${ENTS.map((p) => path.basename(p).slice(0, -3)).join(', ')})`);
    out.push(ENTS.map((p) => dropTrace(stripMarkup(rd(p) ?? '')).replace(/\s+$/, '')).join('\n\n'));
  } else if (ENTS.length) en = rd(ENTS[0]);
  if (en) {
    const ens = dropTrace(stripMarkup(en));
    const blocks = ens.split(/^(?=#{2,3} )/m);
    const words = new Set((dropTrace(uc).match(rxw('[A-Z][A-Za-z]{2,}', 'g')) ?? []).map((w) => w.toLowerCase()));
    const firstWord = (bl) => {
      const h = bl.split('\n', 1)[0].replace(/^#+\s*/, '').trim();
      const ws = h.replace(/[^A-Za-z]/g, ' ').split(/\s+/).filter(Boolean);
      return ws.length ? ws[0].toLowerCase() : '';
    };
    const picked = blocks.filter((bl) => bl.startsWith('#') && words.has(firstWord(bl)));
    if (picked.length) {
      H(`entities.md — ${picked.length} mục UC nhắc tên (trong ${blocks.filter((b) => b.startsWith('#')).length})`);
      out.push(picked.map((b) => b.replace(/\s+$/, '')).join('\n'));
    } else {
      H('entities.md — không tách được theo tên, in cả');
      out.push(ens.replace(/\s+$/, ''));
    }
  }
  const gl = GLOS.length ? GLOS.map((p) => rd(p) ?? '').join('\n') : null;
  if (gl) {
    // #43: bỏ ## History và mục ## <context khác> — gate-check đòi thuật ngữ nằm dưới heading '## <ctx>',
    // nên heading bắt đầu bằng tên một context khác là của họ.
    const gls = dropTrace(stripMarkup(gl));
    const kept = [];
    let dropped = 0, skip = false;
    for (const ln of gls.split('\n')) {
      const m = /^## (.*)/.exec(ln);
      if (m) {
        const w = m[1].replace(/[^A-Za-z0-9_-]/g, ' ').split(/\s+/).filter(Boolean);
        skip = w.length > 0 && OTHERS.has(w[0].toLowerCase());
        if (skip) dropped++;
      } else if (ln.startsWith('# ')) skip = false;
      if (!skip) kept.push(ln);
    }
    H(relList(GLOS) + (dropped ? ` — bỏ ${dropped} mục của context khác` : ''));
    out.push(kept.join('\n').replace(/\s+$/, ''));
  }
}

// ── 8. brief — đọc riêng ──
if (!WHY) {
  H('brief nguồn');
  out.push(BP
    ? `${BP} · sha256 ${BS} — ĐỌC RIÊNG file này; nó nằm ngoài specs/ và không phép kiểm nào khác nhìn tới (#34)`
    : 'dự án không khai brief_path trong .sdd/config — không có brief nguồn');
}

const text = out.join('\n').trim() + '\n';
process.stdout.write(text);
for (const w of warns) process.stdout.write(`  ! ${w}\n`);
const kb = Buffer.byteLength(text) / 1024;
process.stdout.write(`\n--- context.sh ${ID}${WHY ? ' --why' : ''}${BRIEF ? ' --brief' : ''}: ${kb.toFixed(1)} KB · ${srcs.length} nguồn\n`);
// #43: kích thước từng nguồn — để thấy nguồn nào phình, thay vì một tổng không chỉ vào đâu.
const sizes = srcs.map(([t, k], i) => {
  const end = i + 1 < srcs.length ? srcs[i + 1][1] : out.length;
  return [Buffer.byteLength(out.slice(k, end).join('\n')) / 1024, t];
});
const big = sizes.length ? Math.max(...sizes.map(([x]) => x)) : 0;
for (const [x, t] of sizes) {
  process.stdout.write(`  ${x.toFixed(1).padStart(6)} KB  ${t.slice(0, 70)}`
    + (x === big && big > 0 && sizes.length > 1 ? '   ← lớn nhất' : '') + '\n');
}
