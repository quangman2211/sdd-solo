#!/usr/bin/env node
// hoi.mjs — check one role question log: all four boxes filled, an answered entry carries a target, no duplicate/skipped numbers (7.3.0 → node 7.6.0).
//
// The most expensive rule here: **the UC gate is open and the `target:` box points into the UC body** is a ✗. That is runxops
// rule 6 turned into a measurement — UC-025: 25 ASK entries, each one dragging a round of editing the UC body and then a full
// verify round. After the gate, the answer goes into design.md or decisions.md; the UC body only reopens when an AC really changes.
//
// Usage: hoi.mjs <log file> <role code> <root>   · exit 1 if there is a ✗
import fs from 'node:fs';
import path from 'node:path';
import { kw, kwl, kwW } from './kw.mjs';

const [, , file, V, root] = process.argv;
const s = fs.readFileSync(file, 'utf8');
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const out = (kind, m) => process.stdout.write(
  (kind === 'bad' ? '  \x1b[31m✗\x1b[0m ' : kind === 'warn' ? '  \x1b[33m!\x1b[0m ' : '  \x1b[32m✓\x1b[0m ') + m + '\n');

// 7.7.0: the four required boxes are looked up in the table — a question log written in English must be checkable like a Vietnamese one.
// FIELDS holds the keyword NAMES, the patterns are built from kw() so they accept either side; the printed name uses kw_w per doc_lang.
const FIELDS = ['source', 'blocking', 'waiting', 'specwork'];
const ASK = kw('ask');
const blocks = s.split(new RegExp('^(?=### (?:' + ASK + ')-)', 'm'));
const nums = [];
let bad = 0, warn = 0;

for (const b of blocks) {
  const m = new RegExp('^### (?:' + ASK + ')-' + esc(V) + '(\\d+)[ ·]').exec(b);
  if (!m) continue;
  const n = Number(m[1]);
  nums.push(n);
  const tag = `HỎI-${V}${n}`;
  for (const fl of FIELDS) {
    const mm = new RegExp(kwl(fl).source + '\\s*(.*)').exec(b);
    const val = mm ? mm[1].trim() : '';
    if (!val || /^<[^>]*>\s*$/.test(val) || val === '-' || val === '___') {
      out('bad', `${tag}: the box "${kwW(fl)}" is empty or still a template`); bad++;
    }
  }
  const okChan = new RegExp(kwl('blocking').source + '\\s*(?:' + kw('blockvals') + ')(?![\\p{L}\\p{N}_])', 'u').exec(b);
  if (!okChan && kwl('blocking').test(b)) {
    out('bad', `${tag}: "Blocking" must start with blocking | not blocking`); bad++;
  }
  const ans = new RegExp(kwl('answer').source + '\\s*(.*)').exec(b);
  const ansv = ans ? ans[1].trim() : '';
  const ansvCore = ansv.replace(new RegExp('·\\s*' + kwl('target').source + '.*$'), '').trim();
  if (ansvCore && !/^<[^>]*>$/.test(ansvCore)) {
    const d = new RegExp(kwl('target').source + '\\s*(.*)').exec(b);
    const dv = d ? d[1].trim() : '';
    if (!dv || /^<[^>]*>$/.test(dv)) {
      out('bad', `${tag}: answered with no target: (design.md · decisions.md · UC-### AC-# when the AC changes)`); bad++;
    } else {
      const uc = /\bUC-\d+\b/.exec(dv);
      if (uc && !dv.includes('design.md') && !dv.includes('decisions')
          && !new RegExp('\\bAC-?\\d*\\b|' + kw('acchanged') + '|History').test(dv)
          && fs.existsSync(path.join(root, '.sdd/gate', uc[0] + '.ok'))) {
        out('bad', `${tag}: the gate of ${uc[0]} is open and the target points into the UC body (${dv.slice(0, 50)}) — after the gate, answer in design.md/decisions.md; the UC body only reopens when an AC changes`);
        bad++;
      }
    }
  }
}

const dup = [...new Set(nums.filter((x) => nums.filter((y) => y === x).length > 1))].sort((a, b2) => a - b2);
if (dup.length) { out('bad', 'duplicate ASK numbers: ' + dup.join(' ')); bad++; }
if (nums.length) {
  const gaps = [];
  for (let i = 1; i < Math.max(...nums); i++) if (!nums.includes(i)) gaps.push(i);
  if (gaps.length) { out('warn', 'gaps in the ASK numbering: ' + gaps.join(' ')); warn++; }
  if (bad === 0) out('ok', `${nums.length} ASK-${V} entries, all four boxes filled`);
} else {
  process.stdout.write('  – there is no ASK entry yet\n');
}
process.exit(bad ? 1 : 0);
