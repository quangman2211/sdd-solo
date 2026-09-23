#!/usr/bin/env node
// phieu.mjs — the ticket index, REBUILT from the ticket files (8.3.0, P-49).
//
//   phieu.mjs index <index file> <phieu dir>   rewrite every `| #n |` row of the index table from the files
//
// Why the index stopped being a source. Up to 8.2.0 `phieu.sh new` appended a row wherever it ran, and R edited the
// State cell of an earlier row on main. Two writers, one table: measured at runxops, every
// `git merge --no-ff soi/uc-031` conflicted in notes/hoi-dap/hoi-dap.md and the coordinator merged it by hand
// (cb380e3a, rounds 2 and 3 of UC-031). Neither writer was wrong — the file having two of them was.
//
// `queue.sh` settled the same question in 7.3: only the main checkout writes the board, agents write KETQUA and the
// board is derived from it. This does the same one step further — the index is not written at all any more, it is
// COMPUTED, so a ticket file is the only place a fact about a ticket lives, and merging ticket files never conflicts
// because each is its own file.
//
// The State column is derived from the ticket file itself:
//   applied  — the file carries an `Applied:` line with a date (stamped by `phieu.sh close`, the only thing that
//              may say so: closing counts F#/K# on the file and demands a KETQUA from every role in For:)
//   answered — the `**Answer (R):**` box no longer holds its `<…>` placeholder
//   open     — anything else
// The "still a placeholder" test is `starts with <`, not a word match: the placeholder text `<level L0–L3>` is
// written by phieu.sh in one language while the box label follows doc_lang, and a language-free test cannot drift
// apart from them.
import fs from 'node:fs';
import path from 'node:path';
import { kw, kwW, kwAlts } from './kw.mjs';

const [, , cmd, file, dir] = process.argv;
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
// A keyword may contain regex metacharacters — `p_ans` is literally `Answer (R)` — so its alternation has to be
// built from the ESCAPED forms. `kw('p_ans')` handed straight to RegExp turns those parentheses into a capture
// group and matches `Answer R:`, which no ticket ever says: every ticket then read as still open. Measured in the
// 8.3.0 test run, on the one check that decides the State column.
const alt = (name) => kwAlts(name).map(esc).join('|');

function statusOf(body) {
  // applied — `Applied: <date>`, the stamp close() writes INTO THE FILE
  const ap = new RegExp('^(?:' + alt('p_applied') + '):[ \\t]*(\\S.*)$', 'm').exec(body);
  if (ap && !ap[1].trim().startsWith('<')) return kwW('applied');
  // answered — the Answer box no longer holds its placeholder
  const an = new RegExp('^\\*\\*(?:' + alt('p_ans') + '):\\*\\*[ \\t]*(.*)$', 'm').exec(body);
  if (an && an[1].trim() && !an[1].trim().startsWith('<')) return kwW('q_ans');
  return kwW('q_open');
}

function rowOf(f, base) {
  const body = fs.readFileSync(f, 'utf8');
  const n = parseInt(path.basename(f).slice(0, 3), 10);
  // `### #12 · from: code · task: UC-031 lane_set · 2026-09-24` — read in either language, like every header.
  const h = new RegExp('^###?\\s*#(\\d+)\\s*·\\s*(?:' + kw('from_') + '):\\s*([^·\\n]+?)\\s*·\\s*(?:'
    + kw('task') + '):\\s*([^·\\n]+?)\\s*·\\s*(\\S+)', 'm').exec(body);
  const from = h ? h[2].trim() : '?';
  const work = h ? h[3].trim() : path.basename(f, '.md').slice(4).replace(/-/g, ' ');
  const date = h ? h[4].trim() : '';
  // A `|` inside a cell would split the row into two — escape it rather than let the table silently gain a column.
  const cell = (x) => x.replaceAll('|', '\\|');
  return [n, `| #${n} | ${cell(work)} | ${cell(from)} | ${date} | ${statusOf(body)} | `
    + `[${path.basename(f)}](${base}/${path.basename(f)}) |`];
}

if (cmd !== 'index' || !file || !dir) {
  process.stderr.write('usage: phieu.mjs index <index file> <phieu dir>\n');
  process.exit(2);
}

const files = (fs.existsSync(dir) ? fs.readdirSync(dir) : [])
  .filter((x) => /^\d{3}-.*\.md$/.test(x)).sort()
  .map((x) => path.join(dir, x));
const base = path.basename(dir);
const rows = files.map((f) => rowOf(f, base)).sort((a, b) => a[0] - b[0]).map((r) => r[1]);

let s = fs.readFileSync(file, 'utf8');
const RX = /^\| *#\d+ \|.*$/gm;
const cur = [...s.matchAll(RX)];
if (cur.length) {
  // Replace the block in place: from the first row to the last, so anything around the table is untouched.
  // A rebuild must not move the doctrine text above the table, which is what people actually read.
  const a = cur[0].index, b = cur[cur.length - 1].index + cur[cur.length - 1][0].length;
  s = s.slice(0, a) + rows.join('\n') + s.slice(b);
} else {
  const HEAD = new RegExp('^\\| *# *\\| *(?:' + kw('work') + ') *\\|', 'm');
  if (HEAD.test(s)) {
    const at = HEAD.exec(s).index;
    const m = /^\|---\|.*$/m.exec(s.slice(at));
    const i = at + m.index + m[0].length;
    s = s.slice(0, i) + (rows.length ? '\n' + rows.join('\n') : '') + s.slice(i);
  } else {
    s = s.replace(/\n+$/, '')
      + `\n\n| # | ${kwW('work')} | ${kwW('since')} | ${kwW('date')} | ${kwW('state')} | ${kwW('file')} |\n`
      + '|---|---|---|---|---|---|\n' + rows.join('\n') + '\n';
  }
}
fs.writeFileSync(file, s);
process.stdout.write(`${rows.length}\n`);
