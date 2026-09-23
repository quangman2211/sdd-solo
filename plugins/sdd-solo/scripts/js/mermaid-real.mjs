#!/usr/bin/env node
// mermaid-real.mjs — lint khối mermaid bằng CHÍNH thư viện mermaid, thay vì bằng luật bắt chước nó (7.6.0).
//
// Vì sao có cả hai. `mermaid.mjs` là parser thuần, không phụ thuộc gì, chạy ở mọi máy có node: luật của nó đo
// bằng mermaid thật nên đúng với bản mermaid tại thời điểm đo (17/17 khối vỡ của runxops bắt được, 0/71 oan).
// Nhưng nó vẫn là bắt chước: mermaid ra bản mới đổi cú pháp, hay ai viết một kiểu sơ đồ chưa có trong mẫu đo,
// thì nó có thể nói khác trình vẽ mà không ai biết. File này bịt đúng khe đó bằng cách hỏi thẳng trình vẽ.
//
// KHÔNG phải mặc định, và plugin KHÔNG cài mermaid: nó chỉ chạy khi repo dự án đã có sẵn `mermaid` + `jsdom`
// trong node_modules (dự án web thường có), hoặc khi người dùng tự bật. Không tìm thấy thì thoát 3 và chỗ gọi
// rơi về parser thuần — một phép kiểm không chạy được không bao giờ được thành một phép kiểm đỏ.
//
// Dùng: mermaid-real.mjs <file...>        (ROOT của dự án lấy từ $SDD_ROOT hoặc thư mục hiện tại)
//   exit 0 = mọi khối render được · 1 = có khối vỡ · 3 = không có thư viện để hỏi (không kết luận gì)
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { blocks } from './mermaid.mjs';

const ROOT = process.env.SDD_ROOT || process.cwd();

/** Tìm một gói trong node_modules của DỰ ÁN (đi ngược lên từ ROOT), không phải của plugin. */
function resolveFrom(root, name) {
  let dir = path.resolve(root);
  for (;;) {
    const p = path.join(dir, 'node_modules', name);
    if (fs.existsSync(p)) {
      try {
        const req = createRequire(path.join(dir, 'noop.js'));
        return req.resolve(name);
      } catch {
        return p;                       // gói ESM-only: nạp thẳng thư mục qua package.json
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
  // mermaid đòi DOM toàn cục. `navigator` ở node hiện đại chỉ có getter nên KHÔNG gán được — bỏ qua nó,
  // mermaid.parse không cần (đo ở node 25; gán navigator ném TypeError và làm hỏng cả lượt).
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
  process.stderr.write('mermaid-real: dự án chưa có mermaid + jsdom trong node_modules — không kết luận gì\n');
  process.exit(3);
}

let rc = 0;
for (const f of process.argv.slice(2)) {
  for (const { start, lines } of blocks(f)) {
    try {
      await mermaid.parse(lines.join('\n'));
    } catch (e) {
      const msg = String(e?.message || e).split('\n').map((x) => x.trim()).filter(Boolean)[0] || 'parse lỗi';
      process.stdout.write(`${f}:${start}: MMD-REAL ${msg.slice(0, 200)}\n`);
      rc = 1;
    }
  }
}
process.exit(rc);
