#!/usr/bin/env bash
# context.sh UC-### [--why] — MỘT lệnh in ra đúng đủ bối cảnh của một UC.
#
# Vì sao có file này. Tới 4.2.0, /sdd-solo:design dặn agent đọc 13 tên file bằng lời
# văn, và không phép kiểm nào đo được nó đã đọc chưa. Lời dặn đọc 13 file là lời dặn
# hỏng theo xác suất — và hỏng im lặng, vì bản thiết kế viết ra vẫn trôi chảy, chỉ
# thiếu một nguồn (#34: design.md nói ngược brief hai ngày không ai thấy).
# Đo ở runxops: hiểu UC-009 phải mở 15 file / 6 thư mục / 210 KB ≈ 53k token, mà
# hơn 60% là dấu vết (adversarial, đọc lại, history, chứng cứ) không phải hiệu lực.
#
# Script này gom ĐÚNG những gì đang hiệu lực và ĐÚNG những ID UC này trích:
#   UC (bỏ 3 mục dấu vết) · flow · RULE được trích · CON được trích · ADR được trích
#   · mục BR cha (không Background) · architecture (4 mục) · entity/glossary có nhắc
#   · dòng brief để agent đọc riêng (ngoài specs/, luật #34 giữ nguyên).
# In ra, không ghi file. Cuối có dòng đo KB — agent và người đều thấy giá phải trả.
#
# --why: chỉ in RULE · CON · ADR · ## Cấm — trả lời "tính năng này do cái gì quyết
# định" cho người bảo trì, một màn hình. Đây là nửa còn lại của decisions.sh:
# decisions.sh đi từ thời gian xuống quyết định; --why đi từ một UC lên quyết định.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
ID=""; WHY=0
for a in "$@"; do case "$a" in --why) WHY=1;; UC-[0-9]*) ID="$a";; esac; done
[ -z "$ID" ] && { echo "Dùng: context.sh UC-### [--why]" >&2; exit 2; }
F="$(find_uc "$ID" "$ROOT")"
[ -z "$F" ] && { printf '  \033[31m✗\033[0m không tìm thấy file %s\n' "$ID" >&2; exit 1; }
CTX="$(ctx_of "$F")"; DIR="$(dirname "$F")"
BP="$(brief_path "$ROOT")"; BS=""; [ -n "$BP" ] && BS="$(brief_sha "$ROOT" 2>/dev/null)"

python3 - "$ROOT" "$F" "$ID" "$CTX" "$WHY" "$BP" "$BS" <<'PY'
import sys, re, io, os, glob
ROOT, F, ID, CTX, WHY, BP, BS = sys.argv[1:8]; WHY = WHY == "1"
out = []; warns = []; nsrc = 0
def rd(p):
    try: return io.open(p, encoding='utf-8').read()
    except FileNotFoundError: return None
def strip_markup(s):
    # cùng luật với lib.sh strip_markup: bỏ cả khối <!-- -->, bỏ thẻ inline
    s = re.sub(r'(?s)<!--.*?-->', '', s)
    return re.sub(r'</?(br|b|i|u|em|strong|code|sub|sup|kbd|small)\s*/?>', '', s)
def sect(s, head, level='## '):
    # thân của mục `level head` tới mục cùng cấp kế tiếp (khớp tiền tố heading)
    m = re.search(r'(?ms)^' + re.escape(level + head) + r'[^\n]*\n(.*?)(?=^' + re.escape(level) + r'|\Z)', s)
    return m.group(1) if m else None
def H(t): out.append(f'\n════ {t} ════')
uc = rd(F); design = rd(os.path.join(os.path.dirname(F), 'design.md')) or ''
TRACE = {'Adversarial pass', 'Đọc lại', 'History'}

# ── 1. UC — mọi mục trừ ba mục dấu vết; Open Questions chỉ giữ câu còn mở ──
if not WHY:
    H(f'{ID}.md — phần đang hiệu lực'); nsrc += 1
    cur = None; keep = []
    for ln in uc.split('\n'):
        if ln.startswith('## '): cur = ln[3:].strip()
        if cur in TRACE: continue
        if cur == 'Open Questions' and re.match(r'\s*[-*] \[x\]', ln, re.I): continue
        keep.append(ln)
    out.append('\n'.join(keep).rstrip())
    fl = rd(os.path.join(os.path.dirname(F), f'{ID}.flow.md'))
    if fl and '```mermaid' in fl: H(f'{ID}.flow.md'); out.append(fl.rstrip()); nsrc += 1

# ── 2-4. ID UC (và design.md) trích ──
cited = uc + '\n' + design
rules = sorted(set(re.findall(r'\bRULE-[0-9]+[a-z]?\b', cited)))
cons  = sorted(set(re.findall(r'\bCON-[0-9]+\b', cited)))
adrs  = sorted(set(re.findall(r'\bADR-[0-9]+\b', cited)))

rl = rd(os.path.join(ROOT, 'specs/rules.md'))
if rules:
    H(f'RULE được trích ({len(rules)}) — specs/rules.md'); nsrc += 1
    for r in rules:
        b = sect(strip_markup(rl or ''), r + ':') if rl else None
        if b is None: b = sect(strip_markup(rl or ''), r) if rl else None
        if b is None: warns.append(f'{r} — UC trích nhưng rules.md không có'); continue
        out.append(f'## {r}\n' + b.rstrip())

br = rd(os.path.join(ROOT, 'specs/br.md')) or ''
brs = strip_markup(br)
if cons:
    H(f'CON được trích ({len(cons)}) — specs/br.md ## Constraints'); nsrc += 1
    # bỏ BR-000 (BR mẫu) — cùng luật với br-check và decisions.sh
    brs_no0 = re.sub(r'(?ms)^# BR-000:.*?(?=^# BR-|\Z)', '', brs)
    lines = brs_no0.split('\n')
    for c in cons:
        hit = None
        for i, ln in enumerate(lines):
            if re.match(r'-?\s*\*\*' + re.escape(c) + r'\b', ln):
                hit = ln.strip()
                if i + 1 < len(lines) and re.match(r'\s+- Từ:', lines[i + 1]): hit += '\n' + lines[i + 1].rstrip()
                break
        if hit is None: warns.append(f'{c} — UC trích nhưng br.md không có (ngoài BR-000)'); continue
        out.append(hit)

if adrs:
    H(f'ADR được trích ({len(adrs)}) — specs/internal/adr/'); nsrc += 1
    for a in adrs:
        fs = glob.glob(os.path.join(ROOT, 'specs/internal/adr', a + '*')) + glob.glob(os.path.join(ROOT, 'docs/adr', a + '*'))
        if not fs: warns.append(f'{a} — UC trích nhưng không có file ADR'); continue
        t = strip_markup(rd(fs[0]) or '')
        title = next((l for l in t.split('\n') if l.startswith('# ')), f'# {a}')
        st = (sect(t, 'Status') or '').strip().split('\n')[0]
        dec = (sect(t, 'Decision') or '').strip()
        out.append(f'{title}\nStatus: {st}\n{dec}')

# ── 5. BR cha — quyết định, không chứng cứ ──
brid = re.search(r'\bBR-[0-9]+\b', uc)
if not WHY and brid:
    b = brid.group(0)
    body = re.search(r'(?ms)^# ' + re.escape(b) + r':([^\n]*)\n(.*?)(?=^# BR-|\Z)', brs)
    if body:
        H(f'{b}:{body.group(1)} — quyết định (không Background)'); nsrc += 1
        for hname in ('Goal', 'In Scope', 'Out of Scope', 'Success Metrics', 'Đã loại khỏi brief'):
            sb = sect(body.group(2), hname)
            if sb and sb.strip(): out.append(f'## {hname}\n' + sb.rstrip())
    else: warns.append(f'{b} — UC trỏ tới nhưng br.md không có')

# ── 6. architecture.md — bốn mục ──
ar = rd(os.path.join(ROOT, 'specs/internal/architecture.md'))
if ar:
    ars = strip_markup(ar)
    heads = ('Cấm',) if WHY else ('Ngăn xếp', 'Nơi chạy', 'Ai gọi', 'Cấm')
    H('specs/internal/architecture.md'); nsrc += 1
    for hname in heads:
        sb = sect(ars, hname)
        if sb is None: warns.append(f'architecture.md thiếu ## {hname}'); continue
        if re.search(r'<[^>\n]+>', sb): warns.append(f'architecture.md ## {hname} còn placeholder <...> — chưa ai quyết')
        out.append(f'## {hname}\n' + sb.rstrip())
else: warns.append('thiếu specs/internal/architecture.md')

# ── 7. entity + glossary có nhắc trong UC ──
if not WHY:
    en = rd(os.path.join(ROOT, 'specs/contexts', CTX, 'entities.md'))
    if en:
        ens = strip_markup(en); blocks = re.split(r'(?m)^(?=#{2,3} )', ens)
        words = set(w.lower() for w in re.findall(r'\b[A-Z][A-Za-z]{2,}\b', uc))
        picked = [bl for bl in blocks if bl.startswith('#') and
                  (lambda h: h and h.lower() in words)(re.sub(r'[^A-Za-z]', ' ', bl.split('\n', 1)[0].lstrip('# ')).split()[0] if bl.split('\n', 1)[0].lstrip('# ').strip() else '')]
        if picked:
            H(f'entities.md — {len(picked)} mục UC nhắc tên (trong {sum(1 for b in blocks if b.startswith("#"))})'); nsrc += 1
            out.append('\n'.join(b.rstrip() for b in picked))
        else:
            H('entities.md — không tách được theo tên, in cả'); nsrc += 1; out.append(ens.rstrip())
    gl = rd(os.path.join(ROOT, 'specs/glossary.md'))
    if gl: H('specs/glossary.md'); out.append(strip_markup(gl).rstrip()); nsrc += 1

# ── 8. brief — đọc riêng ──
if not WHY:
    H('brief nguồn')
    out.append(f'{BP} · sha256 {BS} — ĐỌC RIÊNG file này; nó nằm ngoài specs/ và không phép kiểm nào khác nhìn tới (#34)'
               if BP else 'dự án không khai brief_path trong .sdd/config — không có brief nguồn')

text = '\n'.join(out).strip() + '\n'
sys.stdout.write(text)
for w in warns: print(f'  ! {w}')
kb = len(text.encode()) / 1024
print(f'\n--- context.sh {ID}{" --why" if WHY else ""}: {kb:.1f} KB · {nsrc} nguồn')
PY
