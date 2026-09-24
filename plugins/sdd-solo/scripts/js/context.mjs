#!/usr/bin/env node
// context.mjs — gather EXACTLY ENOUGH context for a UC (or a BR slice) into one printout (5.0.0 → node at 7.6.0).
//
// Why this file exists. Up to 4.2.0, /sdd-solo:design told the agent in prose to read 13 file names, and no check
// could measure whether it had. An instruction to read 13 files is an instruction that fails by probability — and
// fails silently, because the design that comes out still reads smoothly, it is only missing one source (#34).
// Measured at runxops: understanding UC-009 meant opening 15 files / 6 directories / 210 KB ≈ 53k tokens, of which more than 60% was evidence trail and not in force.
//
// The source paths are NOT probed here: lib.sh looks them up and passes them in through the environment, one file per line (#55).
//   SDD_RULES · SDD_BRS · SDD_ADRS · SDD_ARCH · SDD_ENTS · SDD_GLOS · SDD_OTHERS
// Arguments: <root> <subject file> <ID> <owner> <WHY 0|1> <brief path> <brief sha> <BRIEF 0|1>
import fs from 'node:fs';
import path from 'node:path';
import { kw, kwW, kwAlts } from './kw.mjs';

const [, , ROOT, F, ID, CTX, WHY_, BP, BS, BRIEF_] = process.argv;
const WHY = WHY_ === '1';
const BRIEF = BRIEF_ === '1';
const IS_BR = ID.startsWith('BR-');

// The JS `\b` only knows [A-Za-z0-9_]; the python one knows accented letters too. So `\b[A-Z][A-Za-z]{2,}\b` over
// "Khoá API": python does NOT match (after "Kho" comes "á", still a letter), JS matches "Kho" — and the context pack
// picks up two entities nobody named. Measured with a snapshot of the 6.x runxops copy: 126 differing lines, all 126 from this one character.
// WB/WE are word boundaries that understand accented letters, used everywhere the old code wrote `\b` around a word.
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
const srcs = [];   // [source name, its start index in out]

/** the same rule as lib.sh strip_markup: drop the whole <!-- --> block, drop the inline tags */
function stripMarkup(s) {
  s = s.replace(/<!--[\s\S]*?-->/g, '');
  return s.replace(/<\/?(br|b|i|u|em|strong|code|sub|sup|kbd|small)\s*\/?>/g, '');
}

/** the body of the `level head` section up to the next section of the same level (matched by heading prefix) */
function sect(s, head, level = '## ') {
  const re = new RegExp('^' + esc(level + head) + '[^\\n]*\\n', 'm');
  const m = re.exec(s);
  if (!m) return null;
  const start = m.index + m[0].length;
  const rest = s.slice(start);
  const nx = new RegExp('^' + esc(level), 'm').exec(rest);
  return nx ? rest.slice(0, nx.index) : rest;
}

/** 7.7.0: a section name has several forms (vi|en). Returns the {name, body} of the form ACTUALLY IN the file — the
 *  printed name stays exactly as the document wrote it, it is not translated back into the doc_lang language. */
function sectAny(s, names, level = '## ') {
  for (const n of [].concat(names)) {
    const b = sect(s, n, level);
    if (b !== null) return { name: n, body: b };
  }
  return null;
}

// 7.7.0: the list of evidence sections comes from the kw() table (bilingual) — context.sh exports SDD_KW before calling.
const TRACE = kw('trace').split('|');
const isTrace = (title) => TRACE.some((x) => title.trim().toLowerCase().startsWith(x.toLowerCase()));

/** #43: cut the evidence sections at EVERY heading level of a quoted source, plus the [x] answered questions. */
function dropTrace(s) {
  const lines = s.split('\n');
  const keep = [];
  let cut = 0;
  for (let i = 0; i < lines.length; i++) {
    const ln = lines[i];
    const m = /^(#{1,6}) (.*)/.exec(ln);
    if (m) {
      const lvl = m[1].length;
      if (cut && lvl <= cut) cut = 0;
      if (!cut && isTrace(m[2])) { cut = lvl; continue; }
    }
    if (cut) continue;
    // 8.4.1 (P-54): drop the WHOLE answered item, not just the line the `[x]` is on. Up to 8.4.0 this dropped the
    // opening line and kept every indented continuation, so the brief carried a fragment with no subject:
    // measured while C verified UC-032, `iv, R xếp \`L0\`): \`entity ScheduledRun\`…` arrived as if it were a live
    // sentence (UC-015 showed two more). That is worse than leaving the question in: a reviewing subagent reads a
    // claim belonging to no item at all, and invents a finding about it or steps around it.
    const q = /^([ \t]*)[-*] \[x\]/i.exec(ln);
    if (q) {
      const ind = q[1].length;
      let j = i + 1, blanks = 0;
      while (j < lines.length) {
        const nx = lines[j];
        // A blank line may sit INSIDE a loose list item, so hold it: it is only part of the item if something
        // more-indented follows. Otherwise it is the separator before the next item and has to stay.
        if (/^[ \t]*$/.test(nx)) { blanks++; j++; continue; }
        if (/^#{1,6} /.test(nx)) break;
        if (/^([ \t]*)/.exec(nx)[1].length > ind) { blanks = 0; j++; continue; }
        break;
      }
      i = j - 1 - blanks;
      continue;
    }
    keep.push(ln);
  }
  return keep.join('\n');
}

const H = (t) => { srcs.push([t, out.length]); out.push(`\n════ ${t} ════`); };

let uc = rd(F);
const design = IS_BR ? '' : (rd(path.join(path.dirname(F), 'design.md')) ?? '');

// ── 0. BR-### (7.4, P-23): the subject is a slice — the BR decision sections + its row in vision.md ──
if (IS_BR) {
  const bm = new RegExp('^# ' + esc(ID) + ':([^\\n]*)\\n([\\s\\S]*?)(?=^# BR-|$(?![\\s\\S]))', 'm')
    .exec(stripMarkup(uc ?? ''));
  uc = bm ? bm[2] : '';
  if (!WHY && bm) {
    H(`${ID}:${bm[1]} — the decisions (without Background)`);
    for (const hname of ['Goal', 'In Scope', 'Out of Scope', 'Success Metrics', 'Constraints',
      'Related Use Cases', kwAlts('droppedbrief'), kwAlts('openq')]) {
      const sc = sectAny(uc, hname);
      if (sc && sc.body.trim()) out.push(`## ${sc.name}\n` + dropTrace(sc.body).replace(/\s+$/, ''));
    }
    const bg = sect(uc, 'Background');
    if (bg && bg.trim()) {
      out.push(`(## Background: ${(Buffer.byteLength(bg) / 1024).toFixed(1)} KB of evidence — read ${rel(F)} when you need it)`);
    }
    const vis = rd(path.join(ROOT, 'specs', 'vision.md'));
    const rows = (vis ?? '').split('\n').filter((l) => l.startsWith('|') && rxw(ID).test(l));
    if (rows.length) { H('specs/vision.md — the slice row'); out.push(...rows); }
  }
}

// ── 1. the UC — every section but the three evidence ones; Open Questions keeps only the open ones ──
if (!WHY && !IS_BR) {
  H(`${ID}.md — the part in force`);
  out.push(dropTrace(uc).replace(/\s+$/, ''));
  const fl = rd(path.join(path.dirname(F), `${ID}.flow.md`));
  if (fl && fl.includes('```mermaid')) { H(`${ID}.flow.md`); out.push(fl.replace(/\s+$/, '')); }
}

// ── 2-4. the IDs the UC (and design.md) quotes ──
const cited = dropTrace(uc) + '\n' + design;
const uniqSort = (xs) => [...new Set(xs)].sort();
const rules = uniqSort(cited.match(rxw('RULE-[0-9]+[a-z]?', 'g')) ?? []);
const cons = IS_BR ? [] : uniqSort(cited.match(rxw('CON-[0-9]+', 'g')) ?? []);   // BR: its CONs are in the ## Constraints just above
const adrs = uniqSort(cited.match(rxw('ADR-[0-9]+', 'g')) ?? []);

const rl = RULES.map((p) => rd(p) ?? '').join('\n');
if (rules.length) {
  H(`the quoted RULEs (${rules.length}) — ${relList(RULES) || 'specs/rules.md'}`);
  const rls = stripMarkup(rl || '');
  for (const r of rules) {
    let b = null;
    for (const lvl of ['## ', '### ']) {
      b = sect(rls, r + ':', lvl);
      if (b === null) b = sect(rls, r, lvl);
      if (b !== null) break;
    }
    if (b === null) { warns.push(`${r} — quoted by the UC but not in rules.md`); continue; }
    out.push(`## ${r}\n` + dropTrace(b).replace(/\s+$/, ''));
  }
}

const br = BRS.map((p) => rd(p) ?? '').join('\n');
const brs = stripMarkup(br);
if (cons.length) {
  H(`the quoted CONs (${cons.length}) — ${relList(BRS) || 'specs/br.md'} ## Constraints`);
  // skip BR-000 (the sample BR) — the same rule as br-check and decisions.sh
  const brsNo0 = brs.replace(/^# BR-000:[\s\S]*?(?=^# BR-|$(?![\s\S]))/m, '');
  const lines = brsNo0.split('\n');
  for (const c of cons) {
    let hit = null;
    for (let i = 0; i < lines.length; i++) {
      if (new RegExp('-?\\s*\\*\\*' + esc(c) + WE, 'u').test(lines[i])) {
        hit = lines[i].trim();
        if (i + 1 < lines.length && new RegExp('^\\s+- (?:' + kw('since') + '):').test(lines[i + 1])) hit += '\n' + lines[i + 1].replace(/\s+$/, '');
        break;
      }
    }
    if (hit === null) { warns.push(`${c} — quoted by the UC but not in br.md (outside BR-000)`); continue; }
    out.push(hit);
  }
}

if (adrs.length) {
  H(`the quoted ADRs (${adrs.length}) — ${ADRS.length ? relList(ADRS) + '/' : 'specs/adr/'}`);
  for (const aid of adrs) {
    const fs_ = [];
    for (const d of ADRS) {
      let names = [];
      try { names = fs.readdirSync(d).sort(); } catch { names = []; }
      for (const nm of names) if (nm.startsWith(aid) && !nm.startsWith('_')) fs_.push(path.join(d, nm));
    }
    if (!fs_.length) { warns.push(`${aid} — quoted by the UC but there is no ADR file`); continue; }
    const t = stripMarkup(rd(fs_[0]) ?? '');
    const title = t.split('\n').find((l) => l.startsWith('# ')) ?? `# ${aid}`;
    const st = (sect(t, 'Status') ?? '').trim().split('\n')[0];
    let dec = dropTrace(sect(t, 'Decision') ?? '').trim();
    if (BRIEF) {
      // the first paragraph up to the first ### + the sub-section names; if the first paragraph is empty, the first sub-section whole
      const parts = dec.split(/^(?=### )/m);
      let head = parts[0].trim();
      let subs = parts.slice(1).map((p) => p.split('\n', 1)[0]);
      if (!head && parts.length > 1) { head = parts[1].trim(); subs = subs.slice(1); }
      dec = head + (subs.length ? '\n' + subs.map((h) => `${h} — (a sub-section, see the file)`).join('\n') : '');
    }
    out.push(`${title}\nStatus: ${st}\n${dec}`);
  }
}

// ── 5. the parent BR — the decisions, not the evidence ──
const brid = IS_BR ? null : rxw('BR-[0-9]+').exec(uc);
if (!WHY && brid) {
  const b = brid[0];
  const body = new RegExp('^# ' + esc(b) + ':([^\\n]*)\\n([\\s\\S]*?)(?=^# BR-|$(?![\\s\\S]))', 'm').exec(brs);
  if (body) {
    H(`${b}:${body[1]} — the decisions (without Background)`);
    for (const hname of ['Goal', 'In Scope', 'Out of Scope', 'Success Metrics', kwAlts('droppedbrief')]) {
      const sc = sectAny(body[2], hname);
      if (sc && sc.body.trim()) out.push(`## ${sc.name}\n` + dropTrace(sc.body).replace(/\s+$/, ''));
    }
  } else warns.push(`${b} — pointed at by the UC but not in br.md`);
}

// ── 6. architecture.md — four sections ──
const ar = ARCH ? rd(ARCH) : null;
if (ar) {
  const ars = stripMarkup(ar);
  // 7.7.0: `heads` holds KEYWORD NAMES, not words — looked up in the table so both languages are read, and the
  // warning is printed per doc_lang. The section name that goes into the pack stays exactly as the file wrote it.
  const heads = WHY ? ['forbidden'] : (BRIEF ? ['forbidden', 'boundaries', 'runswhere']
    : ['stack', 'runswhere', 'callers', 'forbidden']);
  H(rel(ARCH) + (BRIEF ? ` — --brief: ${['forbidden', 'boundaries', 'runswhere'].map((k) => kwW(k)).join(' · ')}` : ''));
  for (const key of heads) {
    const sc = sectAny(ars, kwAlts(key));
    if (sc === null) {
      if (key !== 'boundaries') warns.push(`architecture.md is missing ## ${kwW(key)}`);
      continue;
    }
    if (/<[^>\n]+>/.test(sc.body)) warns.push(`architecture.md ## ${sc.name} still has a <...> placeholder — nobody decided`);
    out.push(`## ${sc.name}\n` + dropTrace(sc.body).replace(/\s+$/, ''));
  }
} else warns.push('missing ' + (ARCH ? rel(ARCH) : 'specs/architecture.md'));

// ── 7. the entities + glossary named in the UC ──
if (!WHY) {
  // 7.0 (T2): one file per entity — entity_cited already filtered by the names the UC uses, so print the whole file (minus the evidence).
  // 6.x: one entities.md for the whole context — split the ## blocks by the names the UC uses, as before.
  let en = null;
  if (ENTS.length && !ENTS.some((p) => p.includes('/specs/contexts/'))) {
    H(`entities — ${ENTS.length} entities the UC names (${ENTS.map((p) => path.basename(p).slice(0, -3)).join(', ')})`);
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
      H(`entities.md — ${picked.length} entries the UC names (out of ${blocks.filter((b) => b.startsWith('#')).length})`);
      out.push(picked.map((b) => b.replace(/\s+$/, '')).join('\n'));
    } else {
      H('entities.md — could not be split by name, printing it whole');
      out.push(ens.replace(/\s+$/, ''));
    }
  }
  const gl = GLOS.length ? GLOS.map((p) => rd(p) ?? '').join('\n') : null;
  if (gl) {
    // #43: drop ## History and the ## <other context> sections — gate-check requires a term to sit under the heading
    // '## <ctx>', so a heading starting with another context name belongs to them.
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
    H(relList(GLOS) + (dropped ? ` — dropped ${dropped} entries of another context` : ''));
    out.push(kept.join('\n').replace(/\s+$/, ''));
  }
}

// ── 8. the brief — read separately ──
if (!WHY) {
  H('the source brief');
  out.push(BP
    ? `${BP} · sha256 ${BS} — READ THIS FILE SEPARATELY; it is outside specs/ and no other check looks at it (#34)`
    : 'the project declares no brief_path in .sdd/config — there is no source brief');
}

const text = out.join('\n').trim() + '\n';
process.stdout.write(text);
for (const w of warns) process.stdout.write(`  ! ${w}\n`);
const kb = Buffer.byteLength(text) / 1024;
process.stdout.write(`\n--- context.sh ${ID}${WHY ? ' --why' : ''}${BRIEF ? ' --brief' : ''}: ${kb.toFixed(1)} KB · ${srcs.length} sources\n`);
// #43: the size of each source — so the bloated one is visible, instead of one total pointing nowhere.
const sizes = srcs.map(([t, k], i) => {
  const end = i + 1 < srcs.length ? srcs[i + 1][1] : out.length;
  return [Buffer.byteLength(out.slice(k, end).join('\n')) / 1024, t];
});
const big = sizes.length ? Math.max(...sizes.map(([x]) => x)) : 0;
for (const [x, t] of sizes) {
  process.stdout.write(`  ${x.toFixed(1).padStart(6)} KB  ${t.slice(0, 70)}`
    + (x === big && big > 0 && sizes.length > 1 ? '   ← the largest' : '') + '\n');
}
