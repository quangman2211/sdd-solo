#!/usr/bin/env node
// table.mjs — edit a markdown table in place: add a ticket row, change a cell, mark it applied (7.6.0, replacing three python blocks).
//
// A markdown table is the plugin data store (the ticket index, the queue, the UC table) because it is both machine readable and
// human editable. Editing it with sed breaks the moment a cell holds an odd character; each command below does exactly one job.
//
//   table.mjs addrow <file> <row>           insert after the last "| #n |" row, or after the header
//   table.mjs setcell <file> <key> <column>=<value>…   edit the cells of the row whose first cell is the key (columns named below)
//   table.mjs mark <file> <n> <value>       set the 5th cell of the "| #n |" row (the ticket state)
import fs from 'node:fs';
import { kw, kwW } from './kw.mjs';

const [, , cmd, file, ...rest] = process.argv;
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function read(p) { return fs.readFileSync(p, 'utf8'); }
function write(p, s) { fs.writeFileSync(p, s); }

switch (cmd) {
  case 'addrow': {
    // The same rule as the python block it replaced: after the last ticket row if there is one; with no row yet, after the
    // header rule of the index table; with no table, add the whole table. Three branches, none of which may be dropped — the
    // ticket index is where numbers are allocated, and losing a row here means a number collision next time (P-21).
    const row = rest[0];
    let s = read(file);
    const rows = [...s.matchAll(/^\| *#\d+ \|.*$/gm)];
    // 7.7.0: the index table header is read in either language; a NEW table is written per doc_lang.
    const HEADRE = new RegExp('^\\| *# *\\| *(?:' + kw('work') + ') *\\|', 'm');
    if (rows.length) {
      const i = rows[rows.length - 1].index + rows[rows.length - 1][0].length;
      s = s.slice(0, i) + '\n' + row + s.slice(i);
    } else if (HEADRE.test(s)) {
      const at = HEADRE.exec(s).index;
      const m = /^\|---\|.*$/m.exec(s.slice(at));
      const i = at + m.index + m[0].length;
      s = s.slice(0, i) + '\n' + row + s.slice(i);
    } else {
      s = s.replace(/\n+$/, '') + `\n\n| # | ${kwW('work')} | ${kwW('since')} | ${kwW('date')} | ${kwW('state')} | ${kwW('file')} |\n`
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
        if (!(k in col)) { process.stderr.write(`unknown column: ${k}\n`); process.exit(2); }
        c[col[k]] = v;
      }
      lines[i] = '| ' + c.join(' | ') + ' |';
      done = true;
      break;
    }
    if (!done) { process.stderr.write('no row ' + key + '\n'); process.exit(1); }
    write(file, lines.join('\n'));
    break;
  }
  case 'mark': {
    // JS has no inline (?m) flag like python — the flag goes in the second argument of RegExp, otherwise it is an
    // "invalid group" and node throws at once. The first trap hit when moving from python to node (7.6.0).
    const [n, val] = rest;
    const s = read(file);
    const re = new RegExp('^(\\| *#' + esc(n) + ' \\|(?:[^|]*\\|){3}) *[^|]* *(\\|)', 'm');
    write(file, s.replace(re, `$1 ${val} $2`));
    break;
  }
  default:
    process.stderr.write('usage: table.mjs <addrow|setcell|mark> <file> …\n');
    process.exit(2);
}
