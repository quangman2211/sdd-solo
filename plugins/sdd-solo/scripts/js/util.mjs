#!/usr/bin/env node
// util.mjs — những việc nhỏ mà bash làm vụng: đọc JSON, in JSON, thay khối giữa hai marker, bỏ dấu tiếng Việt.
// Gom một file để bash có đúng MỘT chỗ gọi, thay cho 9 khối python nhúng rải rác (7.6.0).
//
// Mỗi lệnh con giữ NGUYÊN đầu vào/đầu ra của khối python nó thay — snapshot đầu ra mọi script phải khác 0 dòng.
//
//   util.mjs json <file> <đường.dẫn>        đọc một trường JSON theo đường dẫn "a.b.0.c" (im lặng nếu không có)
//   util.mjs hookjson <ngữ cảnh>            in JSON hookSpecificOutput của SessionStart
//   util.mjs marker <file> <mở> <đóng> <khối>   thay phần giữa hai marker bằng khối mới
//   util.mjs slug <chữ>                     bỏ dấu tiếng Việt → slug a-z0-9-
//   util.mjs installed <plugin> <ver|path>  đọc installed_plugins.json của Claude Code
//   util.mjs mkt <tên marketplace> <đường.dẫn>  đọc known_marketplaces.json
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const [, , cmd, ...args] = process.argv;
const out = (s) => process.stdout.write(s + '\n');

function readJson(file) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return null; }
}

/** Đi theo đường dẫn "a.b.0.c"; mảng nhận chỉ số số. Trả undefined nếu hụt. */
function dig(d, dotted) {
  for (const k of dotted.split('.')) {
    if (d === null || d === undefined) return undefined;
    d = Array.isArray(d) ? d[Number(k)] : d[k];
  }
  return d;
}

/** Bản cài mới nhất của một plugin trong installed_plugins.json (khoá dạng "tên@marketplace"). */
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
    // Bỏ dấu bằng NFD rồi cắt dấu tổ hợp; đ/Đ không phải dấu tổ hợp nên thay tay.
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
    process.stderr.write('dùng: util.mjs <json|hookjson|marker|slug|installed|mkt> …\n');
    process.exit(2);
}
