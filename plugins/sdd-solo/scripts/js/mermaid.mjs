#!/usr/bin/env node
// mermaid.mjs — đọc khối ```mermaid trong file markdown: parse ra node/cạnh/nhãn, và lint.
// Chuyển từ mermaid.py (7.5.0) sang node ở 7.6.0 — plugin bỏ python, xem CHANGELOG 7.6.0.
//
// Vì sao có file này (P-32). Tới 7.4 bốn chỗ đọc mermaid bằng grep từng dòng: gate-check §5 (nhãn cạnh E#,
// id node, node kết), gate-check §6 (stateDiagram có mũi tên gắn UC), br-check §7 (Impact Map có nhánh
// `-.->`), uc-steps ④ (có khối mermaid chưa). grep không biết đâu là nhãn, đâu là tên node, đâu là chữ
// trong nháy kép — nên một node `E1([Đăng nhập được])` từng làm cổng tin rằng đường lỗi E1 đã vẽ (#17), và
// 17/88 sơ đồ của runxops KHÔNG RENDER ĐƯỢC mà cổng vẫn xanh.
//
// Luật lint KHÔNG đoán: đo bằng chính mermaid (mermaid.parse + getDiagramFromText qua jsdom) trên 88 khối
// thật của runxops cộng một ma trận 27 ký tự × 13 ngữ cảnh. Hai loại hỏng, cùng hậu quả "sơ đồ nói sai mà
// không ai biết":
//   ① VỠ — mermaid ném lỗi, trình đọc hiện chữ đỏ thay cho hình:
//      · nhãn node flowchart KHÔNG bọc nháy kép chứa ( ) [ ] { } |
//      · nhãn bọc nháy kép chứa " lồng
//      · dấu ; trong lời của sequenceDiagram (message · Note · alt/else/opt · participant as)
//      · dấu ; trong nhãn quan hệ classDiagram; dấu : thứ hai trong nhãn quan hệ / note
//   ② MẤT CHỮ IM LẶNG — parse qua nhưng nhãn không còn:
//      · dấu ; trong nhãn `A --> B : lời` của stateDiagram-v2. Đo trên core/entities/Account.md của runxops:
//        4/4 quan hệ về nhãn RỖNG và mermaid sinh 5 state rác. Sơ đồ vẫn vẽ, chỉ là mất lời.
// KHÔNG tính là lỗi (đo được là vô hại): `;` trong nhãn flowchart · `#` · `,` · `·` · `→` · `<br/>` ·
// nháy đơn · `%%` trong nháy · `[VIỆC LỖI]` bên trong nhãn đã bọc nháy kép.
//
// Dùng:
//   mermaid.mjs --lint  <file...>   # in <file>:<dòng>: <mã> <thông điệp>; exit 1 nếu có lỗi
//   mermaid.mjs --edges <file>      # mỗi dòng một NHÃN CẠNH (chỉ nhãn, không tên node)
//   mermaid.mjs --nodes <file>      # "<id>\t<hình>\t<nhãn>"
//   mermaid.mjs --states <file>     # "<từ>\t<tới>\t<nhãn>" (stateDiagram · classDiagram)
//   mermaid.mjs --kinds <file>      # "<dòng bắt đầu>\t<loại>" của từng khối
// Thêm --json để in JSON thay vì dòng.
import fs from 'node:fs';

// ── tách khối ─────────────────────────────────────────────────────────────
const FENCE = /^\s*```+\s*mermaid\s*$/i;
const FENCE_END = /^\s*```+\s*$/;

/** [{start: dòng đầu nội dung (1-based), lines: []}] — mọi khối ```mermaid của file. */
export function blocks(path) {
  let text;
  try { text = fs.readFileSync(path, 'utf8'); } catch { return []; }
  const L = text.split('\n');
  const out = [];
  let cur = null, start = 0;
  for (let i = 0; i < L.length; i++) {
    if (cur === null) {
      if (FENCE.test(L[i])) { cur = []; start = i + 2; }
    } else if (FENCE_END.test(L[i])) {
      out.push({ start, lines: cur }); cur = null;
    } else cur.push(L[i]);
  }
  if (cur !== null) out.push({ start, lines: cur });   // khối không đóng — vẫn trả, lint sẽ báo
  return out;
}

const KIND_RE = /^\s*(flowchart|graph|sequenceDiagram|stateDiagram-v2|stateDiagram|classDiagram|erDiagram|journey|gantt|pie|mindmap|timeline|gitGraph|quadrantChart|requirementDiagram|C4Context|block-beta|sankey-beta)\b/;

export function kindOf(lines) {
  for (const ln of lines) {
    const s = stripComment(ln).trim();
    if (!s || s.startsWith('%%')) continue;
    const m = KIND_RE.exec(s);
    return m ? m[1] : '?';
  }
  return '?';
}

/** Bỏ `%%` tới hết dòng — nhưng không bỏ khi nó nằm trong nháy kép. */
export function stripComment(ln) {
  let out = '', q = false;
  for (let i = 0; i < ln.length; i++) {
    const c = ln[i];
    if (c === '"') q = !q;
    if (!q && ln.startsWith('%%', i)) break;
    out += c;
  }
  return out;
}

/** Thay nội dung mỗi "…" bằng khoảng trắng cùng độ dài — giữ chỉ số cột. */
export function unquoted(s) {
  let out = '', q = false;
  for (const c of s) {
    if (c === '"') { q = !q; out += '"'; } else out += q ? ' ' : c;
  }
  return out;
}

// ── flowchart ─────────────────────────────────────────────────────────────
// Cặp mở/đóng của mọi hình, DÀI TRƯỚC NGẮN (([ phải thử trước ( và [)
const SHAPES = [
  ['(((', ')))', 'double-circle'], ['[[', ']]', 'subroutine'], ['[(', ')]', 'cylinder'],
  ['([', '])', 'stadium'], ['((', '))', 'circle'], ['{{', '}}', 'hexagon'],
  ['[/', '/]', 'parallelogram'], ['[\\', '\\]', 'parallelogram-alt'],
  ['[/', '\\]', 'trapezoid'], ['[\\', '/]', 'trapezoid-alt'],
  ['[', ']', 'rect'], ['(', ')', 'round'], ['{', '}', 'rhombus'], ['>', ']', 'asymmetric'],
];
const ID_RE = /[A-Za-z0-9_][A-Za-z0-9_.-]*$/;
const LINK_RE = /(-{2,}>|={2,}>|-\.-+>|-{2,}x|-{2,}o|<-{2,}>|-{3,}|={3,}|-\.-+)/;
const KEYWORD = new Set(['subgraph', 'end', 'direction', 'classDef', 'class', 'style',
  'linkStyle', 'click', 'accTitle', 'accDescr', 'flowchart', 'graph']);
const BREAK_CHARS = '()[]{}|';

function checkLabel(n, label, quoted, errs, what) {
  if (quoted) {
    if (label.includes('"')) {
      errs.push([n, 'MMD-E02', `${what}: nháy kép lồng trong nhãn đã bọc nháy kép — mermaid vỡ`]);
    }
    return;
  }
  const bad = [...new Set([...label].filter((c) => BREAK_CHARS.includes(c)))].sort();
  if (bad.length) {
    errs.push([n, 'MMD-E01',
      `${what} chưa bọc nháy kép mà có ${bad.join(' ')} — mermaid vỡ; bọc nhãn trong "…"`]);
  }
}

export function fcParse(lines) {
  const nodes = [], edges = [], errs = [];
  lines.forEach((raw, idx) => {
    const n = idx + 1;
    const ln = stripComment(raw);
    const s = ln.trim();
    if (!s) return;
    if (KEYWORD.has(s.split(/\s+/)[0])) return;
    let i = 0;
    while (i < ln.length) {
      if (ln[i] === '|') {
        const j = ln.indexOf('|', i + 1);
        if (j < 0) { errs.push([n, 'MMD-E01', 'nhãn cạnh mở bằng | mà không có | đóng']); break; }
        const before = ln.slice(0, i).replace(/\s+$/, '');
        if (LINK_RE.test(before.slice(-6)) || before.endsWith('--') || before.endsWith('==')) {
          const lbl = ln.slice(i + 1, j);
          const t = lbl.trim();
          // nhãn cạnh bọc nháy kép: -->|"lời (có ngoặc)"| — hợp lệ, và runxops dùng thường
          if (t.startsWith('"') && t.endsWith('"') && t.length >= 2) {
            edges.push([n, t.slice(1, -1)]);
            checkLabel(n, t.slice(1, -1), true, errs, 'nhãn cạnh');
          } else {
            edges.push([n, t]);
            checkLabel(n, lbl, false, errs, 'nhãn cạnh');
          }
        }
        i = j + 1;
        continue;
      }
      let hit = null;
      for (const [op, cl, shape] of SHAPES) {
        if (!ln.startsWith(op, i)) continue;
        const m = ID_RE.exec(ln.slice(0, i));
        if (!m) continue;
        const bodyAt = i + op.length;
        let label, quoted, j;
        if (ln.slice(bodyAt).replace(/^\s+/, '').startsWith('"')) {
          // Nhãn bọc nháy kép: dấu " đóng quyết định hết nhãn, KHÔNG phải dấu ] đầu tiên —
          // `W4["… · [VIỆC LỖI]"]` là nhãn hợp lệ, mermaid nhận (đo trên runxops br-006).
          const qs = ln.indexOf('"', bodyAt);
          const qe = ln.indexOf('"', qs + 1);
          if (qe < 0) {
            errs.push([n, 'MMD-E02', 'nhãn mở nháy kép mà không đóng: ' + ln.slice(qs, qs + 40)]);
            hit = ln.length;
            break;
          }
          j = ln.indexOf(cl, qe + 1);
          if (j < 0) continue;
          label = ln.slice(qs + 1, qe); quoted = true;
        } else {
          j = ln.indexOf(cl, bodyAt);
          if (j < 0) continue;
          label = ln.slice(bodyAt, j); quoted = false;
        }
        nodes.push([n, m[0], shape, label.trim(), quoted]);
        checkLabel(n, label, quoted, errs, 'nhãn node ' + m[0]);
        hit = j + cl.length;
        break;
      }
      if (hit !== null) { i = hit; continue; }
      i += 1;
    }
  });
  return { nodes, edges, errs };
}

// ── sequence · state · class ──────────────────────────────────────────────
const SEQ_MSG = /^\s*[A-Za-z0-9_"][^:]*?(->>|-->>|->|-->|-[)x]|--[)x])[^:]*:(.*)$/;
const SEQ_TEXT = /^\s*(Note\s+(over|left of|right of)[^:]*:|participant\s+\S+\s+as\s+|actor\s+\S+\s+as\s+|alt\s+|else\s+|opt\s+|loop\s+|par\s+|and\s+|critical\s+|rect\s+|box\s+|autonumber\b)/i;
const ST_REL = /^\s*(?<a>[^\s:]+)\s*(?<ar>-->|--)\s*(?<b>[^\s:]+)\s*(?::\s*(?<t>.*))?$/;
const ST_NOTE = /^\s*note\s+(left|right)\s+of\s+[^:]+:(?<t>.*)$/i;
const ST_DESC = /^\s*(?<a>[A-Za-z0-9_]+)\s*:\s*(?<t>.+)$/;
const CL_REL = /^\s*\S+\s*(?:"[^"]*"\s*)?(?:<\|--|--\|>|\*--|o--|--\*|--o|<--|-->|--|\.\.>|<\.\.|\.\.)\s*(?:"[^"]*"\s*)?\S+\s*:\s*(?<t>.*)$/;

export function otherLint(kind, lines) {
  const errs = [];
  lines.forEach((raw, idx) => {
    const n = idx + 1;
    const ln = stripComment(raw);
    if (kind === 'sequenceDiagram') {
      const m = SEQ_MSG.exec(ln);
      const txt = m ? m[2] : (SEQ_TEXT.test(ln) ? ln : null);
      if (txt !== null && unquoted(txt).includes(';')) {
        errs.push([n, 'MMD-E03', 'dấu ; trong lời của sequenceDiagram — mermaid coi là hết câu và VỠ; '
          + 'đổi thành — hoặc · , hoặc bọc cả lời trong "…"']);
      }
    } else if (kind.startsWith('stateDiagram')) {
      const m = ST_REL.exec(ln) || ST_NOTE.exec(ln) || ST_DESC.exec(ln);
      const txt = m?.groups?.t ?? null;
      if (txt && unquoted(txt).includes(';')) {
        errs.push([n, 'MMD-E04', 'dấu ; trong nhãn của stateDiagram — nhãn MẤT TRẮNG khi render '
          + '(mermaid cắt câu, sinh state rác); đổi thành — hoặc ·']);
      }
      const note = ST_NOTE.exec(ln);
      if (note && unquoted(note.groups.t).includes(':')) {
        errs.push([n, 'MMD-E05', 'dấu : thứ hai trong note của stateDiagram — mermaid vỡ']);
      }
    } else if (kind === 'classDiagram') {
      const m = CL_REL.exec(ln);
      if (m) {
        const t = unquoted(m.groups.t);
        if (t.includes(';')) errs.push([n, 'MMD-E03', 'dấu ; trong nhãn quan hệ classDiagram — mermaid vỡ']);
        if (t.includes(':')) errs.push([n, 'MMD-E05', 'dấu : thứ hai trong nhãn quan hệ classDiagram — mermaid vỡ']);
      }
    }
  });
  return errs;
}

export function stRels(lines) {
  const out = [];
  lines.forEach((raw, idx) => {
    const ln = stripComment(raw);
    const m = ST_REL.exec(ln) || CL_REL.exec(ln);
    if (!m) return;
    const g = m.groups || {};
    out.push([idx + 1, g.a ?? '', g.b ?? '', (g.t ?? '').trim()]);
  });
  return out;
}

// ── API ───────────────────────────────────────────────────────────────────
/** [{start, kind, nodes, edges, states, errs}] — dòng đã quy về dòng THẬT của file. */
export function analyze(path) {
  const out = [];
  for (const { start, lines } of blocks(path)) {
    const kind = kindOf(lines);
    let nodes = [], edges = [], states = [], errs = [];
    if (kind === 'flowchart' || kind === 'graph') {
      ({ nodes, edges, errs } = fcParse(lines));
    } else {
      errs = otherLint(kind, lines);
      if (kind.startsWith('stateDiagram') || kind === 'classDiagram') states = stRels(lines);
    }
    const off = start - 1;
    out.push({
      start, kind,
      nodes: nodes.map(([n, ...r]) => [n + off, ...r]),
      edges: edges.map(([n, l]) => [n + off, l]),
      states: states.map(([n, ...r]) => [n + off, ...r]),
      errs: errs.map(([n, c, m]) => [n + off, c, m]),
    });
  }
  return out;
}

const MODES = ['--lint', '--edges', '--nodes', '--states', '--kinds'];

export function main(argv) {
  const mode = argv[2];
  if (!MODES.includes(mode) || argv.length < 4) {
    process.stderr.write('dùng: mermaid.mjs <' + MODES.join('|') + '> <file...> [--json]\n');
    return 2;
  }
  const asJson = argv.includes('--json');
  const files = argv.slice(3).filter((a) => a !== '--json');
  const acc = [];
  let rc = 0;
  const w = (s) => process.stdout.write(s);
  for (const f of files) {
    for (const { start, kind, nodes, edges, states, errs } of analyze(f)) {
      if (mode === '--lint') {
        for (const [n, code, msg] of errs) {
          acc.push({ file: f, line: n, code, msg });
          if (!asJson) w(`${f}:${n}: ${code} ${msg}\n`);
          rc = 1;
        }
      } else if (mode === '--edges') {
        for (const [n, label] of edges) {
          acc.push({ file: f, line: n, label });
          if (!asJson && label) w(`${label}\n`);
        }
      } else if (mode === '--nodes') {
        for (const [n, id, shape, label] of nodes) {
          acc.push({ file: f, line: n, id, shape, label });
          if (!asJson) w(`${id}\t${shape}\t${label}\n`);
        }
      } else if (mode === '--states') {
        for (const [n, from, to, label] of states) {
          acc.push({ file: f, line: n, from, to, label });
          if (!asJson) w(`${from}\t${to}\t${label}\n`);
        }
      } else if (mode === '--kinds') {
        acc.push({ file: f, line: start, kind });
        if (!asJson) w(`${start}\t${kind}\n`);
      }
    }
  }
  if (asJson) w(JSON.stringify(acc) + '\n');
  return rc;
}

if (import.meta.url === `file://${process.argv[1]}`) process.exit(main(process.argv));
