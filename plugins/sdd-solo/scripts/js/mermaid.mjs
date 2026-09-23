#!/usr/bin/env node
// mermaid.mjs — read the ```mermaid blocks of a markdown file: parse out the nodes/edges/labels, and lint.
// Moved from mermaid.py (7.5.0) to node at 7.6.0 — the plugin dropped python, see CHANGELOG 7.6.0.
//
// Why this file exists (P-32). Up to 7.4, four places read mermaid by grepping line by line: gate-check §5 (the E#
// edge labels, the node ids, the terminal nodes), gate-check §6 (a stateDiagram with an arrow carrying a UC),
// br-check §7 (an Impact Map with a `-.->` branch), uc-steps ④ (is there a mermaid block). grep does not know a
// label from a node name from text inside double quotes — so a node `E1([Logged in])` once convinced the gate that
// the E1 error path had been drawn (#17), and 17 of runxops 88 diagrams DID NOT RENDER while the gate stayed green.
//
// The lint rules DO NOT GUESS: they were measured with mermaid itself (mermaid.parse + getDiagramFromText through
// jsdom) over 88 real runxops blocks plus a matrix of 27 characters × 13 contexts. Two kinds of breakage, with the
// same consequence "the diagram says the wrong thing and nobody knows":
//   ① BROKEN — mermaid throws, and the reader shows red text instead of a picture:
//      · a flowchart node label NOT wrapped in double quotes containing ( ) [ ] { } |
//      · a double-quoted label containing a nested "
//      · a ; inside sequenceDiagram text (a message · Note · alt/else/opt · participant as)
//      · a ; in a classDiagram relation label; a second : in a relation label / note
//   ② SILENTLY LOST TEXT — it parses but the label is gone:
//      · a ; in the `A --> B : text` label of a stateDiagram-v2. Measured on runxops core/entities/Account.md:
//        4 of 4 relations came back with an EMPTY label and mermaid produced 5 junk states. The diagram still draws, it has just lost its words.
// NOT counted as an error (measured harmless): a `;` in a flowchart label · `#` · `,` · `·` · `→` · `<br/>` ·
// a single quote · `%%` inside quotes · `[BROKEN WORK]` inside an already double-quoted label.
//
// Usage:
//   mermaid.mjs --lint  <file...>   # prints <file>:<line>: <code> <message>; exit 1 if there was an error
//   mermaid.mjs --edges <file>      # one EDGE LABEL per line (labels only, no node names)
//   mermaid.mjs --nodes <file>      # "<id>\t<shape>\t<label>"
//   mermaid.mjs --states <file>     # "<from>\t<to>\t<label>" (stateDiagram · classDiagram)
//   mermaid.mjs --kinds <file>      # "<start line>\t<kind>" per block
// Add --json to print JSON instead of lines.
import fs from 'node:fs';

// ── splitting the blocks ──────────────────────────────────────────────────
const FENCE = /^\s*```+\s*mermaid\s*$/i;
const FENCE_END = /^\s*```+\s*$/;

/** [{start: the first content line (1-based), lines: []}] — every ```mermaid block of the file. */
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
  if (cur !== null) out.push({ start, lines: cur });   // an unclosed block — still returned, the lint will report it
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

/** Drop `%%` to the end of the line — but not when it is inside double quotes. */
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

/** Replace the contents of each "…" with spaces of the same length — keeping the column indexes. */
export function unquoted(s) {
  let out = '', q = false;
  for (const c of s) {
    if (c === '"') { q = !q; out += '"'; } else out += q ? ' ' : c;
  }
  return out;
}

// ── flowchart ─────────────────────────────────────────────────────────────
// The open/close pairs of every shape, LONGEST FIRST (([ must be tried before ( and [)
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
      errs.push([n, 'MMD-E02', `${what}: a nested double quote inside an already double-quoted label — mermaid breaks`]);
    }
    return;
  }
  const bad = [...new Set([...label].filter((c) => BREAK_CHARS.includes(c)))].sort();
  if (bad.length) {
    errs.push([n, 'MMD-E01',
      `${what} is not double-quoted and contains ${bad.join(' ')} — mermaid breaks; wrap the label in "…"`]);
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
        if (j < 0) { errs.push([n, 'MMD-E01', 'an edge label opened with | and never closed']); break; }
        const before = ln.slice(0, i).replace(/\s+$/, '');
        if (LINK_RE.test(before.slice(-6)) || before.endsWith('--') || before.endsWith('==')) {
          const lbl = ln.slice(i + 1, j);
          const t = lbl.trim();
          // a double-quoted edge label: -->|"text (with brackets)"| — valid, and runxops uses it often
          if (t.startsWith('"') && t.endsWith('"') && t.length >= 2) {
            edges.push([n, t.slice(1, -1)]);
            checkLabel(n, t.slice(1, -1), true, errs, 'edge label');
          } else {
            edges.push([n, t]);
            checkLabel(n, lbl, false, errs, 'edge label');
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
          // A double-quoted label: the closing " decides where the label ends, NOT the first ] —
          // `W4["… · [BROKEN WORK]"]` is a valid label and mermaid accepts it (measured on runxops br-006).
          const qs = ln.indexOf('"', bodyAt);
          const qe = ln.indexOf('"', qs + 1);
          if (qe < 0) {
            errs.push([n, 'MMD-E02', 'a label opens a double quote and never closes it: ' + ln.slice(qs, qs + 40)]);
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
        checkLabel(n, label, quoted, errs, 'node label ' + m[0]);
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
        errs.push([n, 'MMD-E03', 'a ; inside sequenceDiagram text — mermaid takes it as the end of the sentence and BREAKS; '
          + 'change it to — or · , or wrap the whole text in "…"']);
      }
    } else if (kind.startsWith('stateDiagram')) {
      const m = ST_REL.exec(ln) || ST_NOTE.exec(ln) || ST_DESC.exec(ln);
      const txt = m?.groups?.t ?? null;
      if (txt && unquoted(txt).includes(';')) {
        errs.push([n, 'MMD-E04', 'a ; inside a stateDiagram label — the label is LOST ENTIRELY on render '
          + '(mermaid cuts the sentence and produces junk states); change it to — or ·']);
      }
      const note = ST_NOTE.exec(ln);
      if (note && unquoted(note.groups.t).includes(':')) {
        errs.push([n, 'MMD-E05', 'a second : in a stateDiagram note — mermaid breaks']);
      }
    } else if (kind === 'classDiagram') {
      const m = CL_REL.exec(ln);
      if (m) {
        const t = unquoted(m.groups.t);
        if (t.includes(';')) errs.push([n, 'MMD-E03', 'a ; in a classDiagram relation label — mermaid breaks']);
        if (t.includes(':')) errs.push([n, 'MMD-E05', 'a second : in a classDiagram relation label — mermaid breaks']);
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
/** [{start, kind, nodes, edges, states, errs}] — the line numbers already mapped to the REAL file lines. */
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
    process.stderr.write('usage: mermaid.mjs <' + MODES.join('|') + '> <file...> [--json]\n');
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
