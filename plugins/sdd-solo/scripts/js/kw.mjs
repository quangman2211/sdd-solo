// kw.mjs — the bilingual documentation keywords, node side (7.7.0).
//
// Reads scripts/kw.tsv next to it DIRECTLY — the same file as `kw()` in lib.sh, nothing passed through an
// environment variable. Passing through env means forgetting an `export` in one bash script is a silent miss;
// reading the same file leaves nothing to forget. The reasoning for the table is at the top of kw.tsv.
//
//   kw('reread')   → 'Đọc lại|Re-read'        the alternation body for READING (accepts either)
//   kwh('reread')  → /^## (Đọc lại|Re-read)/m the section-heading pattern
//   kwl('slice')   → /\*\*(Lát|Slice):\*\*/   the bold-label pattern
//   kwW('q_done')  → 'xong'                   ONE side for WRITING, per doc_lang (default vi)
//
// A name not in the table THROWS, it does not return empty: an empty pattern matches everything, and a falsely
// green gate is the most expensive kind of breakage in this repo.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const TSV = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'kw.tsv');
const TABLE = new Map();
try {
  for (const ln of fs.readFileSync(TSV, 'utf8').split('\n')) {
    if (!ln || ln.startsWith('#')) continue;
    const c = ln.split('\t');
    if (c.length >= 4) TABLE.set(c[0], { kind: c[1], vi: c[2], en: c[3] });
  }
} catch { /* unreadable → kw() throws with the file name, which is clearer than silence */ }

const row = (name) => {
  const r = TABLE.get(name);
  if (!r) throw new Error(`kw(${name}): not in ${TSV}`);
  return r;
};
/** the kind: head | label | cell | raw | group | commit | write */
export const kwKind = (name) => row(name).kind;
/** the alternation body for READING — accepts either language, dropping a duplicate side */
export function kw(name) {
  const { vi, en } = row(name);
  const seen = [];
  for (const x of (vi + '|' + en).split('|')) if (!seen.includes(x)) seen.push(x);
  return seen.join('|');
}
/** ONE side for WRITING. lang: 'vi' | 'en' — bash passes it down as an argument or through SDD_DOC_LANG. */
export const kwW = (name, lang = process.env.SDD_DOC_LANG === 'en' ? 'en' : 'vi') =>
  (lang === 'en' ? row(name).en : row(name).vi);
/** kwAlts — the ARRAY of forms of one keyword (vi, en, deduplicated). Used where a section name is compared
 *  as a STRING and not as a regex — for example the list of `##` names context.mjs cuts out one by one. */
export const kwAlts = (name) => kw(name).split('|');
// The NON-capturing group (`(?:`) is deliberate: the `.source` of these two patterns is often concatenated into a
// larger pattern, and a stray capture group in there shifts the number of EVERY group after it. That exact bug ate
// the four-box check of hoi.mjs: `mm[1]` returned the keyword itself instead of the cell value, so every empty box read as filled.
export const kwh = (name, flags = 'm') => new RegExp(`^## (?:${kw(name)})`, flags);
export const kwl = (name, flags = '') => new RegExp(`\\*\\*(?:${kw(name)}):\\*\\*`, flags);
/** kwr — splice a keyword into a larger pattern: kwr('- \\*\\*%s:\\*\\* *(.*)', 'source') */
export const kwr = (tpl, name, flags = '') => new RegExp(tpl.replace('%s', `(?:${kw(name)})`), flags);
/** the swappable pairs — the test suite uses them to rewrite the documents into English. Drops `group` (multi-form,
 *  read only), `commit` (it lives in the git history, not in a file) and `write` (write only: words like `vai` · `anh`
 *  occur all over ordinary prose, and swapping them crudely breaks the English side for reasons unrelated to the gate). */
const NOSWAP = ['group', 'commit', 'write'];
export const kwPairs = () => [...TABLE.entries()]
  .filter(([, r]) => !NOSWAP.includes(r.kind) && r.vi !== r.en)
  .map(([n, r]) => [n, r.kind, r.vi, r.en]);
