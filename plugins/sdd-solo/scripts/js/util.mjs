#!/usr/bin/env node
// util.mjs — the small jobs bash does clumsily: read JSON, print JSON, replace the block between two markers, strip Vietnamese accents.
// Gathered into one file so bash has exactly ONE place to call, replacing 9 scattered embedded python blocks (7.6.0).
//
// Each sub-command keeps the EXACT input/output of the python block it replaced — an output snapshot of every script must differ by 0 lines.
//
//   util.mjs json <file> <dotted.path>       read one JSON field by the path "a.b.0.c" (silent if absent)
//   util.mjs hookjson <context>              print the SessionStart hookSpecificOutput JSON
//   util.mjs marker <file> <open> <close> <block>   replace what is between two markers with a new block
//   util.mjs slug <text>                     strip Vietnamese accents → an a-z0-9- slug
//   util.mjs installed <plugin> <ver|path>   read the Claude Code installed_plugins.json
//   util.mjs mkt <marketplace name> <dotted.path>  read known_marketplaces.json
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const [, , cmd, ...args] = process.argv;
const out = (s) => process.stdout.write(s + '\n');

function readJson(file) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return null; }
}

/** Follow the path "a.b.0.c"; an array takes a numeric index. Returns undefined on a miss. */
function dig(d, dotted) {
  for (const k of dotted.split('.')) {
    if (d === null || d === undefined) return undefined;
    d = Array.isArray(d) ? d[Number(k)] : d[k];
  }
  return d;
}

/** The newest installed version of a plugin in installed_plugins.json (the key has the form "name@marketplace"). */
function installedEntry(name) {
  const d = readJson(path.join(os.homedir(), '.claude', 'plugins', 'installed_plugins.json'));
  const plugins = d?.plugins;
  if (!plugins) return null;
  for (const [k, v] of Object.entries(plugins)) {
    if (k.split('@')[0] === name && Array.isArray(v) && v.length) return v[v.length - 1];
  }
  return null;
}

switch (cmd) {
  case 'json': {
    const v = dig(readJson(args[0]), args[1] ?? '');
    if (v !== undefined && v !== null) out(typeof v === 'string' ? v : JSON.stringify(v));
    break;
  }
  case 'hookjson': {
    out(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: args[0] ?? '',
      },
    }));
    break;
  }
  case 'marker': {
    const [file, begin, end, block] = args;
    const s = fs.readFileSync(file, 'utf8');
    const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const re = new RegExp(esc(begin) + '[\\s\\S]*?' + esc(end));
    fs.writeFileSync(file, s.replace(re, `${begin}\n${block}\n${end}`));
    break;
  }
  case 'slug': {
    // Strip the accents with NFD then cut the combining marks; đ/Đ are not combining marks, so replace them by hand.
    const s = (args[0] ?? '')
      .normalize('NFD').replace(/[̀-ͯ]/g, '')
      .replace(/đ/g, 'd').replace(/Đ/g, 'D')
      .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
    out(s.slice(0, 40));
    break;
  }
  case 'installed': {
    const e = installedEntry(args[0]);
    if (e) out(String((args[1] === 'path' ? e.installPath : e.version) ?? ''));
    break;
  }
  case 'mkt': {
    const d = readJson(path.join(os.homedir(), '.claude', 'plugins', 'known_marketplaces.json'));
    const v = dig(d?.[args[0]] ?? {}, args[1] ?? '');
    out(typeof v === 'string' ? v : '');
    break;
  }
  default:
    process.stderr.write('usage: util.mjs <json|hookjson|marker|slug|installed|mkt> …\n');
    process.exit(2);
}
