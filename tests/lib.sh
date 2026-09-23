#!/usr/bin/env bash
# tests/lib.sh — hàm dùng chung cho bộ test của plugin (7.1.0). bash 3.2.
#
# Mỗi ca là một file tests/cases/<slug>.sh, chạy trong subshell của run.sh, dùng các hàm dưới đây.
# Mỗi phép đo ghi MỘT dòng vào $RES: <PASS|FAIL|XFAIL|XPASS>\t<ca>\t<tên phép đo>.
#   chk   "tên" 'điều kiện'        — phải đúng (hồi quy). Sai là FAIL, run.sh exit 1.
#   xfail "P-##" "tên" 'điều kiện' — lỗi CÒN MỞ: điều kiện mô tả hành vi ĐÚNG mà bản này chưa có.
#                                     Sai → XFAIL (chờ, không tính lỗi). Đúng → XPASS: lỗi đã được sửa,
#                                     đổi ca sang chk và ghi CHANGELOG.
# Repo giả: mkbase dựng $W/base MỘT lần (scaffold thật + fixtures/v7 + 4 commit có ngày); nr <tên>
# chép base thành $W/<tên> và cd vào đó. Mọi commit trong ca đi qua cm (--no-verify) trừ khi ca
# cố ý đo githook.

clean() { sed 's/\x1b\[[0-9;]*m//g'; }
_res() { printf '%s\t%s\t%s\n' "$1" "${CASE:-?}" "$2" >> "$RES"; printf '  %-5s %s\n' "$1" "$2"; }
chk()   { if eval "$2"; then _res PASS "$1"; else _res FAIL "$1"; fi; }
xfail() { if eval "$3"; then _res XPASS "$1 · $2"; else _res XFAIL "$1 · $2"; fi; }

# S <script.sh> [args…] → $O (output đã bỏ màu, cả stderr) · $R (exit code). Không dùng pipe: $? của
# pipe là của lệnh cuối (bẫy đo 7.0.1).
S() { local s="$1"; shift; O="$(bash "$P/scripts/$s" "$@" 2>&1)"; R=$?; O="$(printf '%s\n' "$O" | clean)"; }
has()  { printf '%s\n' "$O" | grep -qF -- "$1"; }
hasE() { printf '%s\n' "$O" | grep -qE -- "$1"; }

# cm "<tiêu đề>" [YYYY-MM-DD] — add -A + commit --no-verify, ngày cố định để §9 so được
cm() {
  local d="${2:-2026-01-10}T10:00:00"
  git add -A
  GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" git commit -q --no-verify --allow-empty -m "$1"
}
# cmv "<tiêu đề>" — commit CÓ hook (đo githook); trả exit code của git
cmv() { git add -A; git commit -q -m "$1" 2>"$W/hookerr.txt"; }

# rep <file> <cũ> <mới> — thay đúng MỘT chuỗi, lỗi nếu không có (đừng để ca đo trên file không đổi)
rep() { node - "$1" "$2" "$3" <<'JS'
const fs = require('fs');
const [p, a, b] = process.argv.slice(2);
const s = fs.readFileSync(p, 'utf8');
if (!s.includes(a)) { console.error('rep: không thấy chuỗi trong ' + p + ': ' + a.slice(0, 60)); process.exit(1); }
fs.writeFileSync(p, s.replace(a, () => b));
JS
}
# ins_after <file> <dòng mốc (chuỗi con)> <dòng mới> — chèn sau dòng đầu tiên chứa mốc
ins_after() { node - "$1" "$2" "$3" <<'JS'
const fs = require('fs');
const [p, m, t] = process.argv.slice(2);
const L = fs.readFileSync(p, 'utf8').split('\n');
const i = L.findIndex((l) => l.includes(m));
if (i < 0) { console.error('ins_after: không thấy mốc trong ' + p + ': ' + m.slice(0, 60)); process.exit(1); }
L.splice(i + 1, 0, t);
fs.writeFileSync(p, L.join('\n'));
JS
}
app() { printf '%s\n' "$2" >> "$1"; }

# kw_swap — đổi mọi từ khoá tài liệu của repo hiện tại sang vế tiếng Anh của bảng kw() (7.7.0).
# Bảng ở lib.sh là nguồn duy nhất: thêm một từ khoá ở đó là ca 45 tự phủ luôn.
kw_swap() { node "$T/kwswap.mjs" "$P/scripts/js/kw.mjs"; }

UC1=specs/orders/br-001/use-cases/UC-001-notify-order/UC-001.md
FL1=specs/orders/br-001/use-cases/UC-001-notify-order/UC-001.flow.md
UCD=specs/orders/br-001/use-cases/UC-001-notify-order

# nr <tên> — repo mới từ base, cd vào, CLAUDE_PROJECT_DIR trỏ tới
nr() { rm -rf "$W/$1"; cp -R "$W/base" "$W/$1"; cd "$W/$1" || exit 1; export CLAUDE_PROJECT_DIR="$W/$1"; }

# gate_pass — đưa UC-001 qua cổng (pass.sh gate), rồi design + test + feat để close được
gate_pass() { S pass.sh gate UC-001 >/dev/null; }
code_uc1() {
  printf '# Design UC-001\n\n## Ngăn xếp\nNode\n' > "$UCD/design.md"
  printf '# Tasks\n- [x] AC-1\n' > "$UCD/tasks.md"
  cm "docs(UC-001): thiết kế — design.md + tasks.md" 2026-01-11
  mkdir -p src/orders/notify tests/use-cases/orders/UC-001
  printf 'export const notify = (o) => ({ sent: true, order: o });\n' > src/orders/notify/index.js
  printf 'describe("UC-001 / AC-1", () => {});\n' > tests/use-cases/orders/UC-001/AC-1.test.js
  printf 'describe("UC-001 / AC-2", () => {});\n' > tests/use-cases/orders/UC-001/AC-2.test.js
  cm "feat(UC-001): báo đơn" 2026-01-12
}

# mkbase — dựng repo gốc một lần. 4 commit như bộ kiểm 7.0.1:
#   init (01-02) → docs(UC-001): spec v2 (01-03) → docs(UC-001): đọc lại (01-04) → chore(sdd): state
mkbase() {
  rm -rf "$W/base"; mkdir -p "$W/base"; cd "$W/base" || exit 1
  git init -q; git config user.email test@sdd; git config user.name sdd-test; git config commit.gpgsign false
  export CLAUDE_PROJECT_DIR="$W/base"
  bash "$P/scripts/scaffold.sh" "$P" "$W/base" >"$W/scaffold.log" 2>&1 || { cat "$W/scaffold.log"; echo "scaffold hỏng"; exit 1; }
  # Repo gốc của bộ test là BẢN TIẾNG VIỆT — fixtures/v7 viết tiếng Việt, và mọi ca so chữ với nó.
  # scaffold ghi doc_lang=en cho dự án MỚI (7.8.0), nên ở đây phải ghi đè về vi, nếu không chiều GHI
  # của kw_w ra tiếng Anh và bản nền tự nó thành bản đã dịch — ca 45 sẽ không còn gì để so.
  sed -i.bak "s/^doc_lang=.*/doc_lang=vi/" "$W/base/.sdd/config" && rm -f "$W/base/.sdd/config.bak"
  cp -R "$T/fixtures/v7/." "$W/base/"
  # commit 1: chưa có adversarial/đọc lại/v2
  node - "$UC1" <<'JS'
const fs = require('fs');
const p = process.argv[2];
let s = fs.readFileSync(p, 'utf8');
s = s.replace('- Ngày chạy: 2026-01-03 · Session mới: [x]\n', '- Ngày chạy: ___ · Session mới: [ ]\n');
s = s.replace(/^## Đọc lại\n[\s\S]*?(?=^## History)/m, '## Đọc lại\n- Ngày chạy: ___ · Đầu chưa neo: subagent\n\n');
s = s.replace('- v2 (2026-01-03, anh): sau adversarial pass\n', '');
fs.writeFileSync(p + '.v1', s);
JS
  cp "$UC1" "$UC1.final"; mv "$UC1.v1" "$UC1"
  cm "chore(sdd): init" 2026-01-02
  # commit 2: adversarial + v2
  node - "$UC1" <<'JS'
const fs = require('fs');
const p = process.argv[2];
let s = fs.readFileSync(p, 'utf8');
s = s.replace('- Ngày chạy: ___ · Session mới: [ ]\n', '- Ngày chạy: 2026-01-03 · Session mới: [x]\n');
s = s.replace('- v1 (2026-01-02, anh): initial\n', '- v1 (2026-01-02, anh): initial\n- v2 (2026-01-03, anh): sau adversarial pass\n');
fs.writeFileSync(p, s);
JS
  cm "docs(UC-001): spec v2 — sau adversarial pass" 2026-01-03
  # commit 3: đọc lại
  mv "$UC1.final" "$UC1"
  cm "docs(UC-001): đọc lại — 1 phát hiện, 0 phải sửa" 2026-01-04
  cm "chore(sdd): state" 2026-01-05
  cd "$T"
}
