// kw.mjs — từ khoá tài liệu song ngữ, phía node (7.7.0).
//
// Đọc THẲNG scripts/kw.tsv cạnh mình — cùng một file với `kw()` của lib.sh, không bơm qua biến môi
// trường. Bơm qua env thì quên `export` ở một script bash là hụt im lặng; đọc chung một file thì không
// có chỗ nào để quên. Lý do có bảng nằm ở đầu kw.tsv.
//
//   kw('reread')   → 'Đọc lại|Re-read'        thân alternation để ĐỌC (nhận cả hai)
//   kwh('reread')  → /^## (Đọc lại|Re-read)/m mẫu tiêu đề mục
//   kwl('slice')   → /\*\*(Lát|Slice):\*\*/   mẫu nhãn đậm
//   kwW('q_done')  → 'xong'                   MỘT vế để GHI, theo doc_lang (mặc định vi)
//
// Tên không có trong bảng thì NÉM LỖI, không trả rỗng: mẫu rỗng khớp vào mọi thứ, và cổng xanh oan
// là loại hỏng đắt nhất của repo này.
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
} catch { /* không đọc được thì kw() ném lỗi có tên file, rõ hơn là im lặng */ }

const row = (name) => {
  const r = TABLE.get(name);
  if (!r) throw new Error(`kw(${name}): không có trong ${TSV}`);
  return r;
};
/** kiểu dùng: head | label | cell | raw | group | commit | write */
export const kwKind = (name) => row(name).kind;
/** thân alternation để ĐỌC — nhận cả hai thứ tiếng, bỏ vế trùng */
export function kw(name) {
  const { vi, en } = row(name);
  const seen = [];
  for (const x of (vi + '|' + en).split('|')) if (!seen.includes(x)) seen.push(x);
  return seen.join('|');
}
/** MỘT vế để GHI. lang: 'vi' | 'en' — bash truyền xuống qua tham số hoặc SDD_DOC_LANG. */
export const kwW = (name, lang = process.env.SDD_DOC_LANG === 'en' ? 'en' : 'vi') =>
  (lang === 'en' ? row(name).en : row(name).vi);
/** kwAlts — MẢNG các dạng của một từ khoá (vi, en, bỏ trùng). Dùng ở chỗ so tên mục bằng CHUỖI
 *  chứ không bằng regex — ví dụ danh sách tên `##` mà context.mjs lần lượt cắt ra. */
export const kwAlts = (name) => kw(name).split('|');
// Nhóm KHÔNG bắt (`(?:`) là cố ý: `.source` của hai mẫu này hay được nối vào một mẫu lớn hơn, và một
// nhóm bắt lạc vào đó đẩy số thứ tự của MỌI nhóm sau nó. Đúng lỗi đó đã ăn mất phép kiểm bốn ô của
// hoi.mjs: `mm[1]` trả về chính từ khoá thay vì giá trị ô, nên ô trống nào cũng đọc ra "có điền".
export const kwh = (name, flags = 'm') => new RegExp(`^## (?:${kw(name)})`, flags);
export const kwl = (name, flags = '') => new RegExp(`\\*\\*(?:${kw(name)}):\\*\\*`, flags);
/** kwr — ghép từ khoá vào một mẫu lớn hơn: kwr('- \\*\\*%s:\\*\\* *(.*)', 'source') */
export const kwr = (tpl, name, flags = '') => new RegExp(tpl.replace('%s', `(?:${kw(name)})`), flags);
/** cặp đổi được — bộ test dùng để viết lại tài liệu sang tiếng Anh. Bỏ `group` (nhiều dạng, chỉ đọc),
 *  `commit` (nằm trong lịch sử git, không nằm trong file) và `write` (chỉ để GHI: chữ như `vai` · `anh`
 *  gặp đầy trong văn xuôi, đổi thô là hỏng bản tiếng Anh vì lý do không liên quan tới cổng). */
const NOSWAP = ['group', 'commit', 'write'];
export const kwPairs = () => [...TABLE.entries()]
  .filter(([, r]) => !NOSWAP.includes(r.kind) && r.vi !== r.en)
  .map(([n, r]) => [n, r.kind, r.vi, r.en]);
