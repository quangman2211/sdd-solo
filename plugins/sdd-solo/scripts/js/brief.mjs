#!/usr/bin/env node
// brief.mjs — generate the six-part BRIEF for a role from a ticket file (7.2.0; moved to node at 7.6.0).
//
// The input must be a TICKET FILE, not a free-form string: the expensive part of a brief is the anchor, and the anchor only
// exists in a ticket. The environment variables role.sh passes in: SDD_V (the role code) · SDD_VN (the role name) · SDD_ROOT ·
// SDD_DENY · SDD_CHECKS · SDD_BRANCH · SDD_LUOT · SDD_PK (the reading pack, space separated).
//
// KEEP every word of the python version it replaced — a brief is what the agent reads, and changing the words changes the behaviour.
import fs from 'node:fs';
import { kw, kwW } from './kw.mjs';
import path from 'node:path';

const pf = process.argv[2];
const V = process.env.SDD_V ?? '';
const VN = process.env.SDD_VN ?? '';
const root = process.env.SDD_ROOT ?? '';
const s = fs.readFileSync(pf, 'utf8');

const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const m = new RegExp('^###?\\s*#(\\d+)\\s*·\\s*(?:' + kw('from_') + '):\\s*([^·\\n]+?)\\s*·\\s*(?:'
    + kw('task') + '):\\s*([^·\\n]+?)\\s*·\\s*(\\S+)', 'm').exec(s);
const n = m ? m[1] : '?';
const viec = (m ? m[3] : '').trim();
const IDRX = (alt) => new RegExp('(?<![\\p{L}\\p{N}_])(?:' + alt + ')-\\d+(?![\\p{L}\\p{N}_])', 'gu');
const ids = viec.match(IDRX('UC|BR|CHG|RULE|ADR'))
  || s.slice(0, 400).match(IDRX('UC|BR|CHG')) || [];
const idmain = ids[0] ?? 'viec';

// Python `(?ms)…(?=^Duyệt:|\Z)` matches to the END OF THE STRING; in JS the 'm' flag makes `$` match the end of each LINE, so
// the lazy match stopped right after "Cho:" and the work block came out empty — the second trap when moving python → node (7.6.0).
const FOR = '^(?:' + kw('forwhom') + '):', APP = '^(?:' + kw('approve') + '):';
const cm = new RegExp(FOR + '([\\s\\S]*?)(?=' + APP + ')', 'm').exec(s)
  ?? new RegExp(FOR + '([\\s\\S]*)', 'm').exec(s);
const cho = cm ? cm[1] : '';
let lines = cho.split('\n').map((l) => l.replace(/\s+$/, '')).filter((l) => l.trim());

const tok = new RegExp('(^|[\\s·,/])' + esc(V) + '([\\s·,/:(]|$)');
/** Compare only at the HEAD OF THE ENTRY: `- **B (BR-006):**` / `- **D · T:**` / an inline entry `B (…)`. Not the whole line —
 *  `- **D:** chờ B` is D work, and a "B" in the body does not change whose it is. */
function forRole(l) {
  const h1 = /^\s*[-*]\s*\*\*([^*]+)\*\*/.exec(l);
  const h = h1 ? h1[1] : l.replace(/^\s*\**/, '').slice(0, 40);
    // The JS `\b` only knows [A-Za-z0-9_], so with an accented role name it works BACKWARDS: `\bđiều phối\b` after a `*`
  // does not match (to JS both `*` and `đ` are "not a word character"), while python matches. A word boundary must understand accents.
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
// the table | K | Level | Decision | For | — a row with V in the last cell
for (const l of s.split('\n')) {
  if (l.startsWith('|') && /^\|\s*[KF]\d+/.test(l)) {
    const cells = l.replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
    if (cells.length && forRole(cells[cells.length - 1])) mine.push(l.trim());
  }
}
let whole = false;
if (!mine.length && lines.length) { mine = lines; whole = true; }

if (mine.length === 1 && new RegExp(kw('nowork'), 'i').test(mine[0])) {
  process.stdout.write(`Ticket #${n}: For: ${V} — "no work". Not delegated.\n`);
  process.exit(0);
}

const neo = [];
const ANCHOR = new RegExp('\\[(?:' + kw('anchor') + '):[^\\]]*\\]', 'g');
for (const x of s.match(ANCHOR) ?? []) {
  if (!neo.includes(x) && x.replace(/^\[|\]$/g, '').replace(new RegExp('^(?:' + kw('anchor') + '):'), '').trim()) neo.push(x);
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

const FORW = kwW('forwhom');   // the section name as WRITTEN, per doc_lang
const out = [];
out.push(`Role ${V} · ${VN} · ticket #${n} · work ${ids.join(' ') || viec} · round ${luot}`);
out.push(`1. Goal: apply exactly the "${FORW}: ${V}" part of ticket #${n} to ${idmain} — add nothing, and where the ticket is silent, open a new ticket and stop.`);
out.push('2. Read (point at it, do not copy): ' + pk.concat([`${rel} the ${FORW}: ${V} part`]).join(' · ') + '. Read no other ticket, and do not read the coordination log.');
out.push('3. The work, with the settled tails (copied verbatim from the ticket' + (whole ? ` — NO line was found for this role alone, so the whole ${FORW}: block is given` : '') + '):');
for (const l of mine) out.push('   ' + l);
if (neo.length) out.push('   Anchors: ' + neo.join(' '));
out.push('4. MAY NOT write: ' + (deny || '(not declared)') + ' · decide no business question yourself (a missing number/enum/permission → bash .sdd/scripts/phieu.sh new, then STOP) · no AskUserQuestion · no push.' + (branch ? ' Step 0: git merge main.' : ''));
out.push('5. Checks before committing: ' + (checks || '(per .sdd/roles)') + ' — print the ✓/✗ counts, do not just say "green". Commit <type>(' + idmain + '): … listing the files by name: git commit --only -m … -- <file>; trailer Vai: ' + V + '.');
out.push(`6. Ending: bash .sdd/scripts/role.sh --ketqua ${key} ket=xong neo=<commit hash> kiem=<✓/✗> hoi=- con=- (blocked: ket=chan hoi=<#ticket>) then send exactly that KETQUA line back to the coordinator, ≤ 10 lines. Then STOP.`);

const txt = out.join('\n');
process.stdout.write(txt + '\n');
if (missing.length) process.stderr.write('\n! the reading pack has a path that does not exist: ' + missing.join(' ') + '\n');
if (txt.length > 1500) {
  process.stderr.write(`\n! the brief is ${txt.length} characters > 1,500 — pasted into some tools it will not send itself (see the orchestrate appendix); write it to a file and prompt "$(cat file)"\n`);
}
