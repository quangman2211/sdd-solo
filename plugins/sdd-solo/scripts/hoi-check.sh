#!/usr/bin/env bash
# hoi-check.sh <vai | file> [--lich-su] — kiểm sổ hỏi có địa chỉ notes/hoi-dap/hoi-<V>.md (7.3). exit 1 nếu có ✗.
#   1. mỗi mục HỎI-<V>n có đủ bốn ô (Nguồn · Chặn không · Đang làm gì trong lúc chờ · Việc cho spec khi trả lời), không còn <…>
#   2. `Chặn không:` là chặn | không chặn
#   3. mục đã trả lời phải có `đích:`; cổng của UC-### đã mở (.sdd/gate/UC-###.ok) mà đích trỏ vào THÂN UC (không phải
#      design.md / decisions.md, không nói "AC") → ✗ — luật: sau cổng câu của D/T trả ở design.md hoặc decisions.md,
#      thân UC chỉ mở lại khi một AC đổi (runxops _chung.md luật 6; 25 câu HỎI của UC-025 mỗi câu kéo một lượt verify)
#   4. số HỎI-<V>n không trùng; nhảy số thì cảnh báo
#   --lich-su: soi `git log -p` — commit nào SỬA một dòng `### HỎI-` đã có (sổ chỉ-thêm); chạy ở status, không ở githook
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; A="${1:-}"; [ -z "$A" ] && { sed -n '2,9p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
if [ -f "$A" ]; then F="$A"; V="$(basename "$A" .md | sed 's/^hoi-//')"; else V="$A"; F="$ROOT/notes/hoi-dap/hoi-$V.md"; fi
[ -f "$F" ] || { info "chưa có ${F#$ROOT/}"; exit 0; }
echo "Sổ hỏi vai $V — ${F#$ROOT/}"
if [ "$2" = --lich-su ] || [ "$3" = --lich-su ]; then
  N=0
  for h in $(git -C "$ROOT" log --format=%h --diff-filter=M -- "${F#$ROOT/}" 2>/dev/null); do
    if git -C "$ROOT" show "$h" -- "${F#$ROOT/}" | grep -qE '^-### HỎI-'; then N=$((N+1)); bad "$h sửa một dòng '### HỎI-' đã có — sổ chỉ-thêm: $(git -C "$ROOT" log -1 --format=%s "$h" | cut -c1-60)"; fi
  done
  [ "$N" = 0 ] && ok "không commit nào sửa dòng HỎI đã có"
fi
python3 - "$F" "$V" "$ROOT" <<'PY'
import sys, io, re, os
f, V, root = sys.argv[1:4]
s = io.open(f, encoding='utf-8').read()
blocks = re.split(r'(?m)^(?=### HỎI-)', s)
nums = []; bad = 0; warn = 0
def out(k, m): print(('  \x1b[31m✗\x1b[0m ' if k == 'bad' else '  \x1b[33m!\x1b[0m ' if k == 'warn' else '  \x1b[32m✓\x1b[0m ') + m)
fields = ['Nguồn', 'Chặn không', 'Đang làm gì trong lúc chờ', 'Việc cho spec khi trả lời']
for b in blocks:
    m = re.match(r'### HỎI-' + re.escape(V) + r'(\d+)[ ·]', b)
    if not m: continue
    n = int(m.group(1)); nums.append(n); tag = f'HỎI-{V}{n}'
    for fl in fields:
        mm = re.search(r'\*\*' + re.escape(fl) + r':\*\*\s*(.*)', b)
        val = mm.group(1).strip() if mm else ''
        if not val or re.match(r'^<[^>]*>\s*$', val) or val in ('-', '___'):
            out('bad', f'{tag}: ô "{fl}" trống hoặc còn khuôn'); bad += 1
    mm = re.search(r'\*\*Chặn không:\*\*\s*(chặn|không chặn)\b', b)
    if not mm and re.search(r'\*\*Chặn không:\*\*', b): out('bad', f'{tag}: "Chặn không" phải bắt đầu bằng chặn | không chặn'); bad += 1
    ans = re.search(r'\*\*Trả lời \(A/R\):\*\*\s*(.*)', b)
    ansv = ans.group(1).strip() if ans else ''
    ansv_core = re.sub(r'·\s*\*\*đích:\*\*.*$', '', ansv).strip()
    if ansv_core and not re.match(r'^<[^>]*>$', ansv_core):
        d = re.search(r'\*\*đích:\*\*\s*(.*)', b)
        dv = d.group(1).strip() if d else ''
        if not dv or re.match(r'^<[^>]*>$', dv): out('bad', f'{tag}: đã trả lời mà không có đích: (design.md · decisions.md · UC-### AC-# khi AC đổi)'); bad += 1
        else:
            uc = re.search(r'\bUC-\d+\b', dv)
            if uc and 'design.md' not in dv and 'decisions' not in dv and not re.search(r'\bAC-?\d*\b|AC đổi|History', dv):
                if os.path.exists(os.path.join(root, '.sdd/gate', uc.group(0) + '.ok')):
                    out('bad', f'{tag}: cổng {uc.group(0)} đã mở mà đích trỏ vào thân UC ({dv[:50]}) — sau cổng trả lời ở design.md/decisions.md; thân UC chỉ mở khi một AC đổi'); bad += 1
dup = sorted(set(x for x in nums if nums.count(x) > 1))
if dup: out('bad', 'số HỎI trùng: ' + ' '.join(map(str, dup))); bad += 1
if nums:
    gaps = [i for i in range(1, max(nums)) if i not in nums]
    if gaps: out('warn', 'số HỎI nhảy: ' + ' '.join(map(str, gaps))); warn += 1
    if bad == 0: out('ok', f'{len(nums)} mục HỎI-{V}, đủ bốn ô')
else: print('  – chưa có mục HỎI nào')
sys.exit(1 if bad else 0)
PY
R=$?; [ "$R" != 0 ] && FAIL=$((FAIL+1))
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
