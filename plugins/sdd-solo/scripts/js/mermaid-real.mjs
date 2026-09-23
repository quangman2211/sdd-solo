#!/usr/bin/env node
// mermaid-real.mjs — lint a mermaid block with THE mermaid library itself, instead of with rules imitating it (7.6.0).
//
// Why both exist. `mermaid.mjs` is a pure parser with no dependency, running on any machine with node: its rules were measured
// against real mermaid, so they are correct for the mermaid release they were measured against (17 of 17 broken runxops blocks
// caught, 0 of 71 false). But it is still an imitation: a new mermaid release changing the syntax, or somebody writing a kind of
// diagram not in the measured sample, could make it disagree with the renderer with nobody knowing. This file closes that gap by asking the renderer.
//
// NOT the default, and the plugin does NOT install mermaid: it only runs when the project repo already has `mermaid` + `jsdom`
// in node_modules (a web project usually does), or when the user switches it on. If it is not found, it exits 3 and the caller
// falls back to the pure parser — a check that cannot run must never become a check that is red.
//
// Usage: mermaid-real.mjs <file...>       (the project ROOT comes from $SDD_ROOT or the current directory)
//   exit 0 = every block renders · 1 = a block is broken · 3 = there is no library to ask (no conclusion at all)
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { blocks } from './mermaid.mjs';

const ROOT = process.env.SDD_ROOT || process.cwd();

/** Find a package in the PROJECT node_modules (walking up from ROOT), not the plugin one. */
function resolveFrom(root, name) {
  let dir = path.resolve(root);
  for (;;) {
    const p = path.join(dir, 'node_modules', name);
    if (fs.existsSync(p)) {
      try {
        const req = createRequire(path.join(dir, 'noop.js'));
        return req.resolve(name);
      } catch {
        return p;                       // an ESM-only package: load the directory directly through package.json
      }
    }
    const up = path.dirname(dir);
    if (up === dir) return null;
    dir = up;
  }
}

async function loadMermaid() {
  const mp = resolveFrom(ROOT, 'mermaid');
  const jp = resolveFrom(ROOT, 'jsdom');
  if (!mp || !jp) return null;
  let JSDOM;
  try { ({ JSDOM } = await import(pathToFileURL(jp).href)); } catch { return null; }
  const dom = new JSDOM('<!doctype html><body></body>', { pretendToBeVisual: true });
  // mermaid demands a global DOM. `navigator` on a modern node only has a getter so it CANNOT be assigned — skip it,
  // mermaid.parse does not need it (measured on node 25; assigning navigator throws a TypeError and breaks the whole run).
  globalThis.window = dom.window;
  globalThis.document = dom.window.document;
  globalThis.HTMLElement = dom.window.HTMLElement;
  globalThis.DOMPurify = { sanitize: (x) => x, addHook: () => {}, setConfig: () => {} };
  try {
    const m = (await import(pathToFileURL(mp).href)).default;
    m.initialize({ startOnLoad: false, securityLevel: 'loose' });
    return m;
  } catch { return null; }
}

const mermaid = await loadMermaid();
if (!mermaid) {
  process.stderr.write('mermaid-real: the project has no mermaid + jsdom in node_modules — no conclusion\n');
  process.exit(3);
}

let rc = 0;
for (const f of process.argv.slice(2)) {
  for (const { start, lines } of blocks(f)) {
    try {
      await mermaid.parse(lines.join('\n'));
    } catch (e) {
      const msg = String(e?.message || e).split('\n').map((x) => x.trim()).filter(Boolean)[0] || 'parse error';
      process.stdout.write(`${f}:${start}: MMD-REAL ${msg.slice(0, 200)}\n`);
      rc = 1;
    }
  }
}
process.exit(rc);
