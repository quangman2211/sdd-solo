#!/usr/bin/env node
// migrate.mjs — the two big moves of migrate.sh (7.0 · 5.1.0; moved to node at 7.6.0):
//
//   migrate.mjs layout   <root> <dry> <map> <skel> <tpl> <uc_test_dir> <date> <code_paths> <test_paths>
//       Move the 6.x tree (specs/contexts · specs/br.md · specs/internal) to the 7.0 layout (core|craft × br-###).
//   migrate.mjs evidence <br.md> <evidence.md> <BR-###> <dry> <date>
//       Split the ## Background (and ## Adversarial pass) body of one BR into evidence.md, leaving a counting line.
//
// The script DOES NOT COMMIT and leaves NOTHING staged (#57): it prints two commit commands split along the
// .sdd/config boundary, because pre-commit blocks spec + code/test in one commit.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const rd = (p) => { try { return fs.readFileSync(p, 'utf8'); } catch { return null; } };
const ok = (m) => console.log(`  \x1b[32m✓\x1b[0m ${m}`);
const bad = (m) => console.log(`  \x1b[31m✗\x1b[0m ${m}`);
const info = (m) => console.log(`  – ${m}`);
const rstrip = (s, ch = '\n') => s.replace(new RegExp(`[${esc(ch)}]+$`), '');
const bytes = (s) => Buffer.byteLength(s);

/** the body of `## <name>` up to the next `## ` (or the end) — returns {start, end, body} as indexes into s */
function sectionOf(s, name, from = 0) {
  const re = new RegExp('^## ' + esc(name) + '[ \\t]*\\n', 'm');
  const m = re.exec(s.slice(from));
  if (!m) return null;
  const start = from + m.index + m[0].length;
  const rest = s.slice(start);
  const nx = /^## /m.exec(rest);
  const end = nx ? start + nx.index : s.length;
  return { start, end, body: s.slice(start, end) };
}

const has = (o, k) => Object.prototype.hasOwnProperty.call(o, k);

/** like python `re.split(r'(?m)^(?=…)')` — JS drops the empty leading slice when the match is at position 0, python does not */
function splitAt(s, re) {
  const r = new RegExp(re.source, re.flags.includes('g') ? re.flags : re.flags + 'g');
  const out = [];
  let p = 0;
  for (const m of s.matchAll(r)) { out.push(s.slice(p, m.index)); p = m.index; }
  out.push(s.slice(p));
  return out;
}

const glob1 = (dir, re) => {
  try { return fs.readdirSync(dir).filter((f) => !re || re.test(f)).sort(); } catch { return []; }
};
const isDir = (p) => { try { return fs.statSync(p).isDirectory(); } catch { return false; } };
const exists = (p) => fs.existsSync(p);

// ─────────────────────────────────────────────────────────────────────────
function cmdLayout(argv) {
  const [ROOT, DRY_, MAPP, SKEL, TPL, UCT, TODAY, CODEP_, TESTP_] = argv;
  const DRY = DRY_ === '1';
  const CODEP = CODEP_.split(/\s+/).filter(Boolean);
  const TESTP = TESTP_.split(/\s+/).filter(Boolean);
  const under = (f, ps) => ps.some((p) => p === '.' || p === './'
    || f === p.replace(/\/$/, '') || f.startsWith(p.replace(/\/$/, '') + '/'));
  process.chdir(ROOT);
  const rel = (p) => path.relative(ROOT, p);

  const MOVED = [], NEED = [], ERR = [];
  // ── map ────────────────────────────────────────────────────────────────
  const M = { context: {}, uc: {}, br: {}, adr: {}, rule: {}, entity: {}, glossary: {} };
  const mp = rd(MAPP);
  if (mp === null) {
    bad(`there is no ${rel(MAPP)} — write the map file first (one per line: context <ctx> <craft> · uc UC-### BR-### · br BR-### <core|craft> · adr ADR-### <craft> · rule RULE-### <craft> · entity <Name> <core|craft> · glossary <heading-first-word> <craft>)`);
    process.exit(1);
  }
  for (let ln of mp.split('\n')) {
    ln = ln.split('#')[0].trim();
    if (!ln) continue;
    const w = ln.split(/\s+/);
    if (w.length !== 3 || !has(M, w[0])) { ERR.push(`map line not understood: ${ln}`); continue; }
    M[w[0]][w[1]] = w[2];
  }
  const CTXS = glob1('specs/contexts').filter((d) => isDir(`specs/contexts/${d}`) && !d.startsWith('_')).sort();
  for (const c of CTXS) if (!has(M.context, c)) ERR.push(`the context \`${c}\` has no \`context ${c} <craft>\` line in the map`);
  const ngheOfCtx = M.context;

  // ── BR trong br.md ─────────────────────────────────────────────────────
  const brmd = rd('specs/br.md') ?? '';
  const BRSEC = {};
  for (const m of brmd.matchAll(/^# (BR-[0-9]+):[^\n]*\n[\s\S]*?(?=^# BR-|$(?![\s\S]))/gm)) BRSEC[m[1]] = m[0];
  const BRHEAD = brmd.includes('# BR-') ? brmd.slice(0, brmd.indexOf('# BR-')) : brmd;
  for (const b of Object.keys(BRSEC)) {
    if (b === 'BR-000') continue;
    if (!has(M.br, b)) ERR.push(`${b} has no \`br ${b} <core|craft>\` line in the map`);
  }

  // ── UC ─────────────────────────────────────────────────────────────────
  const UCS = {};
  for (const c of CTXS) {
    for (const dn of glob1(`specs/contexts/${c}/use-cases`, /^UC-/)) {
      const d = `specs/contexts/${c}/use-cases/${dn}`;
      if (!isDir(d)) continue;
      const uid = /^UC-[0-9]+/.exec(dn)[0];
      const f = rd(`${d}/${uid}.md`) ?? '';
      const br = M.uc[uid] ?? (/Liên quan tới BR:\*\* *(BR-[0-9]+)/.exec(f) ?? [, null])[1];
      const st = (/\*\*Status:\*\* *([a-z]+)/.exec(f) ?? [, '?'])[1];
      const ti = ((/^# UC-[0-9]+: *(.*)/m.exec(f) ?? [, '___'])[1] ?? '___').trim();
      UCS[uid] = { dir: d, ctx: c, br, status: st, title: ti };
      if (!br) ERR.push(`${uid} does not know which BR it belongs to — add \`uc ${uid} BR-###\` to the map`);
      else if (!has(M.br, br)) ERR.push(`${uid} → ${br} but ${br} has no \`br ${br} <core|craft>\` line in the map`);
    }
  }
  // the use-cases.md table of each context → its rows by UC
  const ROWS = {};
  for (const c of CTXS) {
    const t = rd(`specs/contexts/${c}/use-cases.md`) ?? '';
    for (const ln of t.split('\n')) {
      const cells = ln.trim().replace(/^\||\|$/g, '').split('|').map((x) => x.trim());
      if (cells.length >= 5 && /^UC-[0-9]+$/.test(cells[0])) ROWS[cells[0]] = [cells[1], cells[2], cells[3], cells[4]];
    }
  }
  if (ERR.length) {
    for (const e of ERR) bad(e);
    console.log(`\nNOT RUN — ${ERR.length} map entries missing. Fix ${rel(MAPP)} and run again.`);
    process.exit(1);
  }
  const ngheOfBr = (b) => M.br[b];
  const brDir = (b) => `specs/${ngheOfBr(b)}/br-${b.slice(3)}`;

  // ── the plan ───────────────────────────────────────────────────────────
  const ACTS = [];
  const mv = (o, n) => { ACTS.push(['mv', o, n]); MOVED.push([o, n]); };
  const write = (p, c) => ACTS.push(['write', p, c]);
  const rm = (p) => ACTS.push(['rm', p]);

  // 1. internal/ → the root + notes/
  const ADR_ROOT = [];
  for (const b of glob1('specs/internal')) {
    const f = `specs/internal/${b}`;
    if (b === 'architecture.md') mv(f, 'specs/architecture.md');
    else if (b === 'decisions.md') mv(f, 'specs/decisions.md');
    else if (b === 'adr' && isDir(f)) {
      for (const ab of glob1(f)) {
        const a = `${f}/${ab}`;
        const aid = /^ADR-[0-9]+/.exec(ab);
        const n = aid ? M.adr[aid[0]] : null;
        mv(a, n ? `specs/${n}/adr/${ab}` : `specs/adr/${ab}`);
        if (aid && !n) ADR_ROOT.push(aid[0]);
      }
    } else if (/^hoi-.*\.md$/.test(b)) mv(f, `notes/hoi-dap/${b}`);
    else if (/^soat-.*\.md$/.test(b)) mv(f, `notes/soat/${b}`);
    else if (b.includes('ban-do')) mv(f, `notes/ban-do/${b}`);
    else {
      mv(f, `notes/${b}`);
      NEED.push(['a file in internal/ of no known kind, moved into notes/ — sort it by hand if needed', `notes/${b}`]);
    }
  }
  if (ADR_ROOT.length) {
    NEED.push([`ADRs left in the root specs/adr/ because the map did not say: ${ADR_ROOT.join(', ')} — for one belonging to a single craft, add \`adr ADR-### <craft>\` to the map (and run again) or \`git mv\` it into specs/<craft>/adr/`, 'specs/adr/']);
  }

  // 2. br.md → one slice per BR
  const SKEL_BR = SKEL ? rd(`${SKEL}/br/br.md`) : null;
  const brTable = (b, ucs) => {
    const rows = ['| UC | Tên | Actor | BR | Status |', '|---|---|---|---|---|'];
    const seen = new Set();
    for (const u of [...ucs].sort()) {
      let n, a, s;
      if (has(ROWS, u)) { [n, a, , s] = ROWS[u]; }
      else { n = UCS[u]?.title ?? '___'; a = '___'; s = UCS[u]?.status ?? 'draft'; }
      rows.push(`| ${u} | ${n} | ${a} | ${b} | ${s} |`);
      seen.add(u);
    }
    // a use-cases.md row claiming this BR with no UC directory yet (a UC not opened / dropped before opening)
    for (const u of Object.keys(ROWS).sort()) {
      const [n, a, rb, s] = ROWS[u];
      if (rb === b && !seen.has(u)) rows.push(`| ${u} | ${n} | ${a} | ${b} | ${s} |`);
    }
    return rows.join('\n');
  };
  const UC_BY_BR = {};
  for (const [u, x] of Object.entries(UCS)) (UC_BY_BR[x.br] ??= []).push(u);
  const brKeys = Object.keys(BRSEC);
  const biggest = brKeys.length
    ? brKeys.reduce((a, b) => (BRSEC[b].length > BRSEC[a].length ? b : a))
    : null;
  for (const [b, sec] of Object.entries(BRSEC)) {
    if (b === 'BR-000') continue;
    let s = sec;
    if (!s.includes('**Lát:**')) {
      s = s.replace(/^(- \*\*Status:\*\*[^\n]*\n)/m, `$1- **Lát:** ${ngheOfBr(b)} · ___\n`);
      NEED.push([`${b}: fill in \`**Lát:** ${ngheOfBr(b)} · <slice name>\` from the \`## Nghề và lát\` table of specs/vision.md`, `${brDir(b)}/br.md`]);
    }
    s = s.replaceAll('→ specs/br.evidence.md', '→ evidence.md');
    const tbl = brTable(b, UC_BY_BR[b] ?? []);
    if (/^## Related Use Cases/m.test(s)) {
      s = s.replace(/^(## Related Use Cases[^\n]*\n)/m, (mm) => mm + tbl + '\n\n');
    } else s = rstrip(s) + '\n\n## Related Use Cases\n' + tbl + '\n';
    const dst = `${brDir(b)}/br.md`;
    if (b === biggest) mv('specs/br.md', dst);
    write(dst, rstrip(s) + '\n');
  }
  if (biggest === 'BR-000' || (brKeys.length && !(biggest in BRSEC))) rm('specs/br.md');
  if (BRHEAD.trim() && !BRHEAD.includes('Mỗi BR một mục')) {
    write('notes/br-header.md', BRHEAD);
    NEED.push(['the head of specs/br.md (before the first BR) is not the template — it was set aside', 'notes/br-header.md']);
  }
  if ('BR-000' in BRSEC) info('BR-000 (the template sample) dropped — 7.0 has its sample in specs/core/br-000/ after init --update');
  // a BR that only exists in the uc map → build a skeleton
  const brFromUc = [...new Set(Object.values(UCS).map((x) => x.br))].filter((b) => !has(BRSEC, b)).sort();
  for (const b of brFromUc) {
    const n = ngheOfBr(b);
    const dst = `${brDir(b)}/br.md`;
    let s;
    if (SKEL_BR) {
      s = SKEL_BR.replaceAll('BR-000', b).replace(/\n<!-- Khuôn một lát\.[\s\S]*?-->\n/, '\n');
      s = s.replace('- **Lát:** <core | nghề> · <tên lát đúng như bảng `## Nghề và lát` của specs/vision.md>', `- **Lát:** ${n} · ___`);
      s = s.replace(/^## Related Use Cases\n[\s\S]*?(?=^## |$(?![\s\S]))/m,
        '## Related Use Cases\n' + brTable(b, UC_BY_BR[b]) + '\n\n');
      s = s.replace('- **Status:** draft | approved | in-progress | done', '- **Status:** draft');
    } else {
      s = `# ${b}: ___\n\n## Metadata\n- **Status:** draft\n- **Lát:** ${n} · ___\n- **Last updated:** ${TODAY}\n\n## Goal\n___\n\n## Related Use Cases\n${brTable(b, UC_BY_BR[b])}\n`;
    }
    write(dst, s);
    NEED.push([`${b} was not in br.md — a skeleton was built (Status draft) holding ${[...UC_BY_BR[b]].sort().join(', ')}; write the real BR`, dst]);
  }

  // 3. br.evidence.md → the evidence.md of each slice
  const ev = rd('specs/br.evidence.md');
  if (ev !== null) {
    const EVSEC = {};
    for (const m of ev.matchAll(/^## (BR-[0-9]+) — [^\n]*\n[\s\S]*?(?=^## BR-[0-9]+ — |$(?![\s\S]))/gm)) {
      (EVSEC[m[1]] ??= []).push(m[0]);
    }
    const orphan = Object.keys(EVSEC).filter((b) => !has(M.br, b));
    const placed = Object.keys(EVSEC).filter((b) => has(M.br, b));
    for (const b of orphan) NEED.push([`the evidence of ${b} has no destination slice (the BR is not in the map) — left in the old file`, 'specs/br.evidence.md']);
    if (placed.length && !orphan.length) mv('specs/br.evidence.md', `${brDir(placed[0])}/evidence.md`);
    for (const b of placed) {
      write(`${brDir(b)}/evidence.md`,
        `# ${b} — chứng cứ\n\nTách từ specs/br.evidence.md (${TODAY}). Mở khi tranh chấp; context.sh không đọc.\n\n`
        + rstrip(EVSEC[b].join('\n')) + '\n');
    }
  }

  // 4. UC dirs
  for (const u of Object.keys(UCS).sort()) {
    const x = UCS[u];
    const n = ngheOfBr(x.br);
    const dst = `${brDir(x.br)}/use-cases/${path.basename(x.dir)}`;
    mv(x.dir, dst);
    const f = rd(`${x.dir}/${u}.md`) ?? '';
    const oldBr = (/Liên quan tới BR:\*\* *(BR-[0-9]+)/.exec(f) ?? [, null])[1];
    // the "before 7.0" trace goes inside <!-- --> — strip_markup drops it, so layer-check does not count a core UC as quoting its old craft
    let f2 = f.replace(/^- \*\*Bounded Context:\*\* *[^\n]*$/m,
      `- **Nghề:** ${n} · **Lát:** ${x.br} <!-- 7.0 (${TODAY}): dời từ context \`${x.ctx}\``
      + (oldBr && oldBr !== x.br ? `, ${oldBr}` : '') + ' -->');
    if (oldBr && oldBr !== x.br) {   // the `uc` map changed the BR: the Metadata line must say the same thing as the directory
      f2 = f2.replace(/^(- \*\*Liên quan tới BR:\*\* *)BR-[0-9]+/m, `$1${x.br}`);
    }
    if (f2 !== f) write(`${dst}/${u}.md`, f2);
    if (n !== ngheOfCtx[x.ctx]) {
      NEED.push([`${u} moved to \`${n}\` (context \`${x.ctx}\` → craft \`${ngheOfCtx[x.ctx]}\`): the entities it uses must live in \`specs/core/entities/\` or \`specs/${n}/entities/\` — add an \`entity <Name> ${n}\` line to the map if there is none`, dst]);
    }
    const td = `${UCT}/${x.ctx}/${u}`;
    if (isDir(td) && n !== x.ctx) mv(td, `${UCT}/${n}/${u}`);
  }

  // 5. entities.md → one file per entity
  for (const c of CTXS) {
    const p = `specs/contexts/${c}/entities.md`;
    const t = rd(p);
    if (t === null) continue;
    const n = ngheOfCtx[c];
    const parts = splitAt(t, /^(?=## )/m);
    const readme = [`# Entities — ${n} (từ context \`${c}\`)\n`,
      parts[0].startsWith('# ') ? parts[0].split('\n').slice(1).join('\n') : parts[0]];
    for (const sec of parts.slice(1)) {
      const head = sec.split('\n', 1)[0].slice(3).trim();
      const bt = /`([A-Za-z][A-Za-z0-9_]*)`/.exec(head);
      const fw = /^([A-Z][A-Za-z0-9_]*)(?![\p{L}\p{N}_])/u.exec(head);   // a word boundary that understands accented letters, like python
      const name = bt ? bt[1] : (fw && head.split(/\s+/)[0] === fw[1] ? fw[1] : null);
      if (name === null || name === 'Domain' || name === 'History') { readme.push(sec); continue; }
      const dn = has(M.entity, name) ? M.entity[name] : n;
      const body = sec.includes('\n') ? sec.slice(sec.indexOf('\n') + 1) : '';
      write(`specs/${dn}/entities/${name}.md`,
        `# ${name}\n\n<!-- tách từ entities.md của context \`${c}\`, mục \`## ${head}\` (${TODAY}) -->\n\n- **Thuộc:** ${dn}\n`
        + rstrip(body) + '\n');
      MOVED.push([`${p} ## ${head}`, `specs/${dn}/entities/${name}.md`]);
    }
    write(`specs/${n}/entities/README.md`, rstrip(readme.join('')) + '\n');
    rm(p);
    MOVED.push([p, `specs/${n}/entities/README.md (the Domain Model · the non-entity part)`]);
    for (const extra of ['README.md', 'use-cases.md', 'diagrams/README.md']) {
      if (exists(`specs/contexts/${c}/${extra}`)) rm(`specs/contexts/${c}/${extra}`);
    }
    for (const dn2 of glob1(`specs/contexts/${c}/diagrams`)) {
      if (dn2 !== 'README.md') mv(`specs/contexts/${c}/diagrams/${dn2}`, `notes/ban-do/${c}-diagrams/${dn2}`);
    }
  }

  // 6. rules.md → by craft
  const rl = rd('specs/rules.md') ?? '';
  if (Object.keys(M.rule).length) {
    const parts = splitAt(rl, /^(?=## RULE-)/m);
    const keep = [parts[0]];
    const per = {};
    for (const sec of parts.slice(1)) {
      const rid = /^## (RULE-[0-9]+)/.exec(sec)[1];
      const n = has(M.rule, rid) ? M.rule[rid] : undefined;
      if (n) { (per[n] ??= []).push(sec); MOVED.push([`specs/rules.md ## ${rid}`, `specs/${n}/rules.md`]); }
      else keep.push(sec);
    }
    if (Object.keys(per).length) {
      write('specs/rules.md', rstrip(keep.join('')) + '\n');
      for (const [n, secs] of Object.entries(per)) {
        let head = SKEL ? rd(`${SKEL}/nghe/rules.md`) : null;
        head = (head ?? '# Business Rules — <nghề>\n').split('## RULE-')[0].replaceAll('<nghề>', n);
        write(`specs/${n}/rules.md`, rstrip(head) + '\n\n' + rstrip(secs.join('')) + '\n');
      }
    }
  }

  // 7. glossary.md → by craft
  const gl = rd('specs/glossary.md') ?? '';
  {
    const parts = splitAt(gl, /^(?=## )/m);
    const keep = [parts[0]];
    const per = {};
    const STAY = [];
    const CORE_ENT = new Set(Object.entries(M.entity).filter(([, v]) => v === 'core').map(([k]) => k));
    const ROOT_TERMS = new Set(Object.entries(M.glossary)
      .filter(([, v]) => ['gốc', 'goc', 'root'].includes(v)).map(([k]) => k));
    const termNames = (block) => {   // the names in **bold** and in `backticks` on the first line of a term entry
      const h = block.split('\n', 1)[0];
      return new Set([...(h.match(/\*\*([^*]+)\*\*/g) ?? []).map((x) => x.slice(2, -2)),
        ...[...h.matchAll(/`([A-Za-z][A-Za-z0-9_]*)`/g)].map((m) => m[1])]);
    };
    for (const sec of parts.slice(1)) {
      const head = sec.split('\n', 1)[0].slice(3).trim();
      const fwArr = head.replace(/[^A-Za-z0-9_-]/g, ' ').split(/\s+/).filter(Boolean);
      const fw = fwArr.length ? fwArr[0].toLowerCase() : '';
      let n = has(M.glossary, fw) ? M.glossary[fw] : (has(ngheOfCtx, fw) ? ngheOfCtx[fw] : undefined);
      if (['gốc', 'goc', 'root'].includes(n)) n = undefined;
      if (n && fw !== 'history') {
        const blocks = splitAt(sec, /^(?=- )/m);
        const go = [blocks[0]];
        for (const bl of blocks.slice(1)) {
          const names = termNames(bl);
          const hit = [...names].some((x) => CORE_ENT.has(x) || ROOT_TERMS.has(x));
          if (hit) {
            STAY.push(rstrip(bl) + '\n');
            MOVED.push([`specs/glossary.md ## ${head.slice(0, 30)} · ${[...names].sort().join(', ').slice(0, 40)}`,
              'specs/glossary.md ## Chung (a core entity / declared as root)']);
          } else go.push(bl);
        }
        (per[n] ??= []).push(go.join(''));
        MOVED.push([`specs/glossary.md ## ${head.slice(0, 40)}`, `specs/${n}/glossary.md`]);
      } else keep.push(sec);
    }
    if (STAY.length) {
      const staySec = '## Chung — từ của entity core, giữ ở gốc (migrate 7.0)\n' + STAY.join('') + '\n';
      let hist = keep.findIndex((k) => k.startsWith('## History'));
      if (hist < 0) hist = keep.length;
      keep.splice(hist, 0, staySec);
    }
    if (Object.keys(per).length) {
      write('specs/glossary.md', rstrip(keep.join('')) + '\n');
      for (const [n, secs] of Object.entries(per)) {
        let head = SKEL ? rd(`${SKEL}/nghe/glossary.md`) : null;
        head = (head ?? '# Glossary — <nghề>\n').split('\n- **')[0].replaceAll('<nghề>', n);
        write(`specs/${n}/glossary.md`, rstrip(head) + '\n\n' + rstrip(secs.join('')) + '\n');
      }
      NEED.push(['glossary: the entries named after a context moved to the craft glossary; what is left at the root must be a term SHARED by every craft — check it again', 'specs/glossary.md']);
    }
  }

  // 8. vision.md · config
  if (!exists('specs/vision.md')) {
    const v = TPL ? rd(`${TPL}/specs/vision.md`) : null;
    write('specs/vision.md', v ?? '# Hướng — tầng 0\n\n## Định vị\n___\n\n## Không thu hẹp\n- ___\n\n## Nghề và lát\n| Nghề | Lát | BR | Trạng thái | Mở khi |\n|---|---|---|---|---|\n');
    NEED.push(['write specs/vision.md — the owner does, in plain words: the positioning · what must not be narrowed · the crafts and slices table (every BR quotes one row of it) · what "done" means per craft', 'specs/vision.md']);
  }
  const NGHE = [...new Set([...Object.values(M.br), ...Object.values(ngheOfCtx),
    ...Object.values(M.adr), ...Object.values(M.rule), ...Object.values(M.entity)])]
    .filter((n) => n !== 'core').sort();
  const cfg = rd('.sdd/config') ?? '';
  if (!/^nghe_paths=/m.test(cfg)) {
    write('.sdd/config', rstrip(cfg) + '\n# nghe_paths: tên các nghề (thư mục specs/<nghề>/, src/<nghề>/). core không kể. migrate --layout v7 ghi (7.0).\nnghe_paths=' + NGHE.join(' ') + '\n');
  }
  for (const n of NGHE) {
    if (!exists(`specs/${n}/README.md`)) {
      const r = SKEL ? rd(`${SKEL}/nghe/README.md`) : null;
      write(`specs/${n}/README.md`, (r ?? '# Nghề: <tên>\n').replaceAll('<tên>', n));
    }
  }

  // 8b. .sdd/manifest: a template file just moved keeps its manifest row under its NEW NAME (the install-time sha is kept)
  const MAN = rd('.sdd/manifest');
  if (MAN !== null) {
    const ren = {};
    for (const [o, nw] of MOVED) {
      if (!o.includes(' ## ') && !nw.includes(' (') && o.startsWith('specs/internal/')) ren[o] = nw;
    }
    const outl = [];
    for (const ln of MAN.split('\n')) {
      const pth = ln.split(' ')[0];
      if (pth in ren) outl.push(ren[pth] + ln.slice(pth.length));
      else if (pth === 'specs/br.md' || pth.startsWith('specs/contexts/')) continue;
      else outl.push(ln);
    }
    if (outl.join('\n') !== MAN) write('.sdd/manifest', outl.join('\n'));
  }

  // 9. fix the paths inside the files — by the REAL name just moved, longest first
  const REPL = [];
  for (const [o, nw] of MOVED) {
    if (o.includes(' ## ') || nw.includes(' (')) continue;
    REPL.push([o, nw]);
  }
  for (const c of CTXS) {
    const n = ngheOfCtx[c];
    REPL.push([`specs/contexts/${c}/entities.md`, `specs/${n}/entities/`]);
    const brs = [...new Set(Object.values(UCS).filter((x) => x.ctx === c).map((x) => x.br))].sort();
    if (brs.length === 1) REPL.push([`specs/contexts/${c}/use-cases.md`, `${brDir(brs[0])}/br.md`]);
  }
  REPL.sort((a, b) => b[0].length - a[0].length);
  // #56 (7.0.1): a test moved to a craft is also quoted WITHOUT the uc_test_dir prefix — a relative import from the code/harness.
  const RREPL = [];
  const UCTAIL = path.basename(UCT.replace(/\/$/, ''));
  for (const [o, nw] of MOVED) {
    const pre = UCT.replace(/\/$/, '') + '/';
    if (o.startsWith(pre) && nw.startsWith(pre)) {
      const a = o.slice(pre.length), b = nw.slice(pre.length);
      RREPL.push([new RegExp('(?<![\\w.-])' + esc(`${UCTAIL}/${a}`) + '(?![\\w-])', 'g'), `${UCTAIL}/${b}`]);
    }
  }
  const AMBIG = ['specs/br.md', 'specs/br.evidence.md', 'specs/contexts/', 'specs/internal/'];
  const FILES = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (['.git', 'node_modules', '.speckit', 'dist'].includes(e.name)) continue;
        if (dir === '.' && e.name === '.sdd') continue;
        walk(p);
      } else if (/\.(md|json|ya?ml|[cm]?[tj]sx?|py|sh|txt)$/.test(e.name)) {
        FILES.push(p.startsWith('./') ? p.slice(2) : p);
      }
    }
  };
  walk('.');
  FILES.push('.sdd/config', 'CLAUDE.md');
  // the source brief is NOT edited: br-check/session-start compare its sha with the `Nguồn brief:` line
  const BRIEF = ((/^brief_path=(.*)$/m.exec(rd('.sdd/config') ?? '') ?? [, ''])[1]).trim();
  let files = FILES;
  if (BRIEF) {
    files = FILES.filter((f) => f !== BRIEF);
    if ((rd(BRIEF) ?? '').includes('specs/')) {
      NEED.push([`the source brief mentions an old path — NOT edited automatically (the sha must stay); leave it, or edit it and reload with /sdd-solo:intake`, BRIEF]);
    }
  }
  const TOUCH = [], LEFT = {};
  const pendingNew = new Map();
  for (const a of ACTS) if (a[0] === 'write') pendingNew.set(a[1], a[2]);   // a later write overrides an earlier one
  const movedDst = (f) => {
    for (const [o, nw] of MOVED) {
      if (o.includes(' ## ') || nw.includes(' (')) continue;
      if (f === o || f.startsWith(o + '/')) return nw + f.slice(o.length);
    }
    return f;
  };
  const cands = new Map();
  for (const f of new Set(files)) {
    if (ACTS.some((a) => a[0] === 'rm' && a[1] === f)) continue;
    const d = movedDst(f);
    if (!cands.has(d)) cands.set(d, f);
  }
  for (const p of pendingNew.keys()) cands.set(p, null);
  for (const dst of [...cands.keys()].sort()) {
    const src = cands.get(dst);
    const t = pendingNew.has(dst) ? pendingNew.get(dst) : rd(src);
    if (t === null || t === undefined) continue;
    let t2 = t;
    for (const [o, nw] of REPL) t2 = t2.split(o).join(nw);
    for (const [rx, nw] of RREPL) t2 = t2.replace(rx, nw);
    if (t2 !== t) { write(dst, t2); TOUCH.push(dst); }
    const left = AMBIG.reduce((s2, a) => s2 + t2.split(a).length - 1, 0);
    if (left) LEFT[dst] = left;
  }

  // ── execution ──────────────────────────────────────────────────────────
  const git = (args) => {
    try { return { code: 0, out: execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }) }; }
    catch (e) { return { code: e.status ?? 1, out: '' }; }
  };
  const tracked = (p) => git(['ls-files', '--error-unmatch', p]).code === 0;
  const move = (src, dst) => {   // like shutil.move: an existing destination directory means moving INTO it
    const d = isDir(dst) ? path.join(dst, path.basename(src)) : dst;
    try { fs.renameSync(src, d); }
    catch { fs.cpSync(src, d, { recursive: true }); fs.rmSync(src, { recursive: true, force: true }); }
  };
  if (!DRY) {
    for (const a of ACTS) {
      if (a[0] !== 'mv') continue;
      fs.mkdirSync(path.dirname(a[2]) || '.', { recursive: true });
      if (exists(a[2]) && !isDir(a[2])) fs.rmSync(a[2]);
      if (tracked(a[1])) git(['mv', '-k', a[1], a[2]]);
      if (exists(a[1])) move(a[1], a[2]);
    }
    for (const a of ACTS) {
      if (a[0] !== 'write') continue;
      fs.mkdirSync(path.dirname(a[1]) || '.', { recursive: true });
      fs.writeFileSync(a[1], a[2]);
      git(['add', a[1]]);
    }
    for (const a of ACTS) {
      if (a[0] !== 'rm' || !exists(a[1])) continue;
      if (tracked(a[1])) git(['rm', '-q', '-r', '--cached', a[1]]);
      fs.rmSync(a[1], { recursive: true, force: true });
    }
    const pruneEmpty = (d) => {
      if (!isDir(d)) return;
      for (const e of fs.readdirSync(d)) pruneEmpty(path.join(d, e));
      try { if (!fs.readdirSync(d).length) fs.rmdirSync(d); } catch { /* not empty */ }
    };
    for (const d of ['specs/contexts', 'specs/internal', UCT]) pruneEmpty(d);
    for (const c of CTXS) {
      pruneEmpty('specs/contexts');
      const d = `specs/contexts/${c}`;
      if (isDir(d) && fs.readdirSync(d).length) NEED.push([`specs/contexts/${c}/ still holds files outside the template — look and move them by hand`, d]);
    }
    // #57 (7.0.1): leave NOTHING staged — reset the index to HEAD and print two add commands along the .sdd/config boundary.
    git(['reset', '-q']);
  }
  const intracked = (p) => git(['ls-tree', '-d', '--name-only', 'HEAD', p]).out.trim() !== '' || tracked(p);
  const CT = [...CODEP, ...TESTP, UCT];
  const ADD_A = [], ADD_B = [];
  for (const pth of ['specs', 'notes', '.sdd/config', '.sdd/manifest']) {
    if (exists(pth) || intracked(pth)) ADD_A.push(pth);
  }
  for (const f of [...new Set(TOUCH)].sort()) {
    if (under(f, ['specs', 'notes', '.sdd'])) continue;
    (under(f, CT) ? ADD_B : ADD_A).push(f);
  }
  let addB = ADD_B;
  if (exists(UCT) || intracked(UCT)) {
    if (MOVED.some(([o]) => o.startsWith(UCT.replace(/\/$/, '') + '/'))) {
      addB = [UCT, ...ADD_B.filter((f) => !under(f, [UCT]))];
    }
  }

  // ── the report ─────────────────────────────────────────────────────────
  console.log(`\n=== ${DRY ? 'WOULD move' : 'Moved'} (${MOVED.length}) ===`);
  for (const [o, nw] of MOVED) console.log(`  ${o}\n      → ${nw}`);
  console.log(`\n=== Files whose paths were fixed (${TOUCH.length}) ===`);
  for (const f of TOUCH) console.log(`  ${f}`);
  const leftKeys = Object.keys(LEFT);
  if (leftKeys.length) {
    const tot = Object.values(LEFT).reduce((a, b) => a + b, 0);
    console.log(`\n=== Still pointing at the old place, and a machine cannot decide (${tot} spots) — \`specs/br.md\` is now several slices, and \`specs/contexts/\` / \`specs/internal/\` are gone ===`);
    for (const [f, k] of leftKeys.map((f) => [f, LEFT[f]]).sort((a, b) => b[1] - a[1]).slice(0, 30)) {
      console.log(`  ${String(k).padStart(3)}  ${f}`);
    }
  }
  console.log(`\n=== CẦN TAY (${NEED.length}) ===`);
  NEED.forEach(([w, p], i) => console.log(`  ${String(i + 1).padStart(2)}. ${w}\n      @ ${p}`));
  console.log();
  if (DRY) console.log('--dry-run: nothing was touched on disk. Run again without --dry-run to do it.');
  else {
    const q = (xs) => xs.map((x) => (/[^\p{L}\p{N}_./@:+-]/u.test(x) ? "'" + x.replaceAll("'", "'\\''") + "'" : x)).join(' ');
    console.log('Not committed, the index is empty — the script deliberately does not stage or commit for you. Read git status, do the NEEDS HANDS items (or leave them),');
    console.log('then TWO commits split along the .sdd/config boundary (pre-commit blocks spec + code/test in one commit):');
    console.log(`  git add -A -- ${q(ADD_A)} && git commit -m 'chore(sdd): migrate bố cục 7.0 — core|nghề × br-###, tầng 0 vision.md'`);
    if (addB.length) {
      console.log(`  git add -A -- ${q(addB)} && git commit -m 'chore(sdd): migrate 7.0 — dời test UC theo nghề, sửa đường dẫn trong code/test'`);
    } else {
      console.log('  (no test was moved and no code/test file needed fixing — one commit is enough)');
    }
    console.log('  Other files that were untracked/modified before the migration are NOT in those two commands — deliberately.');
    console.log('Then: /sdd-solo:init --update (the new templates, cleaning up the old ones) · /sdd-solo:status · gate-check for each open UC.');
  }
}

// ─────────────────────────────────────────────────────────────────────────
function cmdEvidence(argv) {
  const [brp, evp, BR, dry_, today] = argv;
  const dry = dry_ === '1';
  const MARK = '→ ' + (brp.endsWith('/specs/br.md') ? 'specs/br.evidence.md' : path.basename(evp));
  const s = rd(brp) ?? '';
  const m = new RegExp('^# ' + esc(BR) + ':[\\s\\S]*?(?=^# BR-|$(?![\\s\\S]))', 'm').exec(s);
  if (!m) { console.log(`  ✗ no '# ${BR}:' found in specs/br.md`); process.exit(1); }
  const sec = m[0];
  const bg = sectionOf(sec, 'Background');
  if (!bg) { console.log(`  ✗ ${BR} has no ## Background`); process.exit(1); }
  const body = bg.body;
  const bgDone = body.includes(MARK);
  if (bgDone) console.log(`  ✓ ${BR} ## Background has already been split — not doing it again`);
  const paras = bgDone ? [] : body.replace(/^\n+|\n+$/g, '').split(/\n[ \t]*\n/);
  const keep = [], move = [];
  let nmove = 0;
  for (const pgh of paras) {
    const first = pgh.replace(/^\s+/, '').split('\n', 1)[0];
    if (first.startsWith('### ')) {
      const cur = first.slice(4).trim();
      keep.push(first + '\n' + MARK);
      move.push(['### ' + cur, null]);
      const rest = pgh.includes('\n') ? pgh.slice(pgh.indexOf('\n') + 1) : '';
      if (rest.trim()) { move.push([null, rest]); nmove++; }
    } else if (first.startsWith('**')) keep.push(pgh);
    else { move.push([null, pgh]); nmove++; }
  }
  const kb0 = bytes(body) / 1024;
  const newbody = bgDone ? body : (keep.join('\n\n') + '\n\n');
  const kb1 = bytes(newbody) / 1024;
  if (!bgDone) console.log(`  ${BR} ## Background: ${kb0.toFixed(1)} KB → ${kb1.toFixed(1)} KB · moved ${nmove} paragraphs, kept ${keep.length} heading/** lines`);

  // 5.1.0 — the ## Adversarial pass of a BR is the same kind of evidence, but Phase 1 IS ALLOWED to keep `___`:
  // the counting line must show the `___` number up front, not "all applied". Keep the words "Ngày chạy:" (br-check §10 greps them).
  const ap = sectionOf(sec, 'Adversarial pass');
  let apMove = null;
  if (ap && ap.body.includes('Ngày chạy') && !ap.body.includes(MARK) && !/YYYY-MM-DD|<[^>\n]+>/.test(ap.body)) {
    const ab = ap.body;
    const d = /Ngày chạy:\s*(\d{4}-\d{2}-\d{2})/.exec(ab)[1];
    const qs = ab.match(/^\s*-\s*Q\d+\b.*$/gm) ?? [];
    const blank = qs.filter((q) => /→\s*`?___/.test(q)).length;
    const noarrow = qs.filter((q) => !q.includes('→')).length;
    const applied = qs.length - blank - noarrow;
    const onv = /trên v(\d+)/.exec(ab);
    const line = `- Ngày chạy: ${d} · 3 vai` + (onv ? ` · trên v${onv[1]}` : '')
      + ` · ${qs.length} câu → ${applied} đã áp · ${blank + noarrow} → ___ ${MARK}`;
    apMove = [rstrip(ab) + '\n', line];
    console.log(`  ${BR} ## Adversarial pass: ${(bytes(ab) / 1024).toFixed(1)} KB → 1 line · ${qs.length} questions, ${applied} applied, ${blank + noarrow} still ___`);
  }
  if (ap && ap.body.includes('Ngày chạy') && ap.body.includes(MARK)) {
    console.log(`  ✓ ${BR} ## Adversarial pass has already been split — not doing it again`);
  }
  if (bgDone && !apMove) process.exit(0);
  if (dry) { console.log('  --dry-run: nothing touched on disk'); process.exit(0); }

  let ev = rd(evp);
  if (ev === null) {
    ev = '# Chứng cứ — thân ## Background của specs/br.md\n\n'
      + '<!-- Sinh bởi migrate.sh --evidence. Đây là CHỨNG CỨ lúc viết BR (số đo, trích dẫn dài),\n'
      + '     không phải thứ đang hiệu lực. br.md giữ mục lục ### trỏ về đây. context.sh và\n'
      + '     decisions.sh không đọc file này; cần tra "hồi đó đo ra sao" thì mở. -->\n';
  }
  if (!bgDone) {
    ev += `\n## ${BR} — ## Background — tách ${today}\n`;
    for (const [h, t] of move) ev += h ? `\n${h}\n` : t + '\n';
  }
  let sec2 = sec.slice(0, bg.start) + newbody + sec.slice(bg.end);
  if (apMove) {
    ev += `\n## ${BR} — ## Adversarial pass — tách ${today}\n` + apMove[0];
    const ap2 = sectionOf(sec2, 'Adversarial pass');
    sec2 = sec2.slice(0, ap2.start) + apMove[1] + '\n\n' + sec2.slice(ap2.end);
  }
  fs.writeFileSync(evp, ev);
  fs.writeFileSync(brp, s.slice(0, m.index) + sec2 + s.slice(m.index + sec.length));
  console.log(`  ✓ wrote ${path.relative(process.cwd(), evp)} and updated ${path.relative(process.cwd(), brp)} — not committed`);
  console.log(`  git add ${path.relative(process.cwd(), brp)} ${path.relative(process.cwd(), evp)} && git commit -m 'docs(${BR}): dời dấu vết BR sang evidence.md'`);
}

// ── trace: the evidence trail out of the body and into <base>.trace.md (8.0.0) ──────────────────────────
// Exit 0 = this file was moved, exit 1 = nothing to do. migrate.sh counts on that to print its tally.
//
// The three sections are appended to the side file VERBATIM, in the order they stood, under one dated
// `## <name>` heading each — no summarising, no renumbering, no rewriting. A trail that a migration edited
// is no longer a trail. The body gets a `## Evidence` pointer in its place, at the spot where the first
// moved section stood, so the section order of the UC does not change either.
//
// Idempotence is decided from content, per file: no trail section in the body → already done, exit 1; and a
// side file that already contains the exact block being appended is left alone. Neither the date nor a marker
// file is consulted, because those are the two things an interrupted run gets wrong.
function cmdTrace(a) {
  const [f, tr, ID, dry, today] = a;
  const DRY = dry === '1';
  const s0 = rd(f);
  if (s0 === null) return 1;
  let s = s0;
  const moved = [];
  // read either language: a repo migrating to 8.0.0 was written before the templates turned English.
  const NAMES = [['Adversarial pass'], ['Đọc lại', 'Re-read'], ['History']];
  let anchor = -1;
  for (const alts of NAMES) {
    for (const n of alts) {
      const sec = sectionOf(s, n);
      if (!sec) continue;
      const hstart = s.lastIndexOf('\n## ', sec.start) + 1;
      if (anchor < 0 || hstart < anchor) anchor = hstart;
      moved.push([n, sec, hstart]);
      break;
    }
  }
  if (!moved.length) return 1;
  // cut from the bottom up so the earlier offsets stay valid
  moved.sort((x, y) => y[2] - x[2]);
  for (const [, sec, hstart] of moved) s = s.slice(0, hstart) + s.slice(sec.end);
  const ptr = `## Evidence\n`
    + `The adversarial pass, the re-read and the history of ${ID} live in \`${path.basename(tr)}\`, beside this file.\n`
    + `The gate reads them there; nothing was dropped, and this file stays the size of the thing it specifies.\n\n`;
  const at = Math.min(anchor, s.length);
  s = s.slice(0, at) + ptr + s.slice(at);

  // The moved section goes in under a PLAIN heading — `## Re-read`, never `## Re-read — <date>`. A dated heading
  // is what `pass.sh close` writes for a block it has PUT AWAY, and the gate reads only the plain one (lib.sh
  // ev_body). Dating the live section here would hand the gate an empty trail on every UC that had ever been
  // closed. So: merge into the plain section when the file already has one, create it when it does not, and let
  // whatever dated archive blocks are already in the file sit untouched around it.
  let out = rd(tr);
  if (out === null) {
    out = `# ${ID} — evidence trail\n\n`
      + `<!-- Moved out of ${path.basename(f)} by migrate.sh --trace on ${today} (8.0.0). This is the SCRATCH PAPER\n`
      + `     of ${ID}: the adversarial pass, the re-read, the history. Append only — nothing here is ever rewritten,\n`
      + `     which is what makes it evidence. The gate reads these sections here; ${path.basename(f)} keeps a pointer. -->\n`;
  }
  for (const [n, sec] of [...moved].reverse()) {
    const body = rstrip(s0.slice(sec.start, sec.end));
    if (!body.trim()) continue;
    const cur = sectionOf(out, n);
    if (cur) {
      if (rstrip(cur.body).includes(body)) continue;               // already merged — run it again, nothing happens
      out = out.slice(0, cur.end).replace(/\n*$/, '\n') + body + '\n' + out.slice(cur.end);
    } else {
      out = rstrip(out) + `\n\n## ${n}\n${body}\n`;
    }
  }
  const saved = bytes(s0) - bytes(s);
  if (DRY) {
    info(`${path.relative(process.cwd(), f)} — would move ${moved.length} section(s), ${saved} bytes, into ${path.basename(tr)}`);
  } else {
    fs.writeFileSync(tr, out);
    fs.writeFileSync(f, s);
    ok(`${path.relative(process.cwd(), f)} — ${moved.length} section(s), ${saved} bytes → ${path.basename(tr)}`);
  }
  return 0;
}

const [, , cmd, ...rest] = process.argv;
if (cmd === 'layout') cmdLayout(rest);
else if (cmd === 'evidence') cmdEvidence(rest);
else if (cmd === 'trace') process.exit(cmdTrace(rest));
else { process.stderr.write('usage: migrate.mjs <layout|evidence|trace> …\n'); process.exit(2); }
