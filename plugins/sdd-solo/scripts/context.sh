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
#
# --brief (6.5.0, #43 phần còn lại, chủ dự án uỷ quyền): bản cho subagent ⑦/⑧ — họ đọc HÀNH VI
# và RÀNG BUỘC, không đọc "dựng bằng gì". Khác bản trọn ở hai chỗ: ADR chỉ in đoạn đầu của
# ## Decision + tên các mục con (con trỏ, không thân); architecture chỉ ## Cấm · ## Ranh giới ·
# ## Nơi chạy (bỏ Ngăn xếp, Ai gọi). Đo runxops UC-014: 9 ADR Decision 53 KB, đoạn đầu ~21 KB;
# architecture 45 → ~22 KB. KHÔNG cắt RULE (mâu thuẫn nấp trong văn xuôi của rule), không lọc
# glossary theo thuật ngữ UC nhắc (đo: bỏ 24 mục mà không bớt KB). Bước ⑩ design đọc bản trọn.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
ID=""; WHY=0; BRIEF=0
for a in "$@"; do case "$a" in --why) WHY=1;; --brief) BRIEF=1;; UC-[0-9]*|BR-[0-9]*) ID="$a";; esac; done
[ -z "$ID" ] && { echo "Dùng: context.sh <UC-###|BR-###> [--why | --brief]" >&2; exit 2; }
# 7.4 (P-23): BR-### — bối cảnh của một LÁT: mục quyết định của BR (không Background), dòng của lát ở vision.md,
# RULE/ADR BR trích, architecture, entity/glossary BR nhắc. Cùng python, cùng luật cắt dấu vết; khác ở chỗ chủ thể
# là br.md thay vì UC-###.md. 6.x: specs/br.md chứa nhiều BR — chỉ lấy mục của ID.
case "$ID" in
  BR-*)
    F="$(br_file "$ID" "$ROOT")"
    { [ -f "$F" ] && [ -n "$(br_title "$ID" "$ROOT")" ]; } || { printf '  \033[31m✗\033[0m không tìm thấy %s trong %s\n' "$ID" "${F#$ROOT/}" >&2; exit 1; }
    CTX="$(owner_of_br "$ID" "$ROOT")";;
  *)
    F="$(find_uc "$ID" "$ROOT")"
    [ -z "$F" ] && { printf '  \033[31m✗\033[0m không tìm thấy file %s\n' "$ID" >&2; exit 1; }
    CTX="$(owner_of "$F")";;
esac
DIR="$(dirname "$F")"
BP="$(brief_path "$ROOT")"; BS=""; [ -n "$BP" ] && BS="$(brief_sha "$ROOT" 2>/dev/null)"
# 7.0 (#55): mọi đường dẫn nguồn tra ở lib.sh rồi đưa vào python qua env, mỗi dòng một file —
# python không tự biết bố cục. 6.x: rules.md · br.md · internal/{adr,architecture.md} ·
# contexts/<ctx>/entities.md; 7.0: rules.md của gốc + nghề · br.md của lát · adr/ · architecture.md ·
# entities/<Tên>.md mà UC nhắc tên (entity_cited). OTHERS = tên context/nghề KHÁC, để cắt khỏi glossary.
export SDD_RULES="$(rules_files "$ROOT")" SDD_BRS="$(br_files "$ROOT")" SDD_ADRS="$(adr_dirs "$ROOT")"
export SDD_ARCH="$(arch_file "$ROOT")" SDD_ENTS="$(entity_cited "$F" "$ROOT")" SDD_GLOS="$(glossary_files "$CTX" "$ROOT")"
if [ "$(layout "$ROOT")" = v7 ]; then OTHERS="$(nghe_list "$ROOT" | tr ' ' '\n' | grep -vx "${CTX:-core}")"
else OTHERS="$(ls -d "$ROOT"/specs/contexts/*/ 2>/dev/null | xargs -n1 basename | grep -v '^_' | grep -vx "$CTX")"; fi
export SDD_OTHERS="$OTHERS"

python3 - "$ROOT" "$F" "$ID" "$CTX" "$WHY" "$BP" "$BS" "$BRIEF" <<'PY'
import sys, re, io, os, glob
ROOT, F, ID, CTX, WHY, BP, BS, BRIEF = sys.argv[1:9]; WHY = WHY == "1"; BRIEF = BRIEF == "1"
def env_list(k): return [x for x in os.environ.get(k, '').split('\n') if x.strip()]
RULES, BRS, ADRS, ENTS, GLOS = (env_list(k) for k in ('SDD_RULES', 'SDD_BRS', 'SDD_ADRS', 'SDD_ENTS', 'SDD_GLOS'))
ARCH = os.environ.get('SDD_ARCH', ''); OTHERS = set(x.lower() for x in env_list('SDD_OTHERS'))
def rel(p): return os.path.relpath(p, ROOT)
def rel_list(ps): return ' · '.join(rel(p) for p in ps)
out = []; warns = []; srcs = []   # srcs: (tên nguồn, chỉ số bắt đầu trong out)
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
TRACE = ('Adversarial pass', 'Đọc lại', 'History')
def is_trace(title):
    t = title.strip().lower()
    return any(t.startswith(x.lower()) for x in TRACE)
def drop_trace(s):
    # #43: cắt mục dấu vết ở MỌI cấp heading của nguồn được trích, và câu hỏi đã [x].
    # Đo ở runxops UC-014 (6.0.0): 250,9 KB / 9 nguồn — History của entities.md lọt vì
    # heuristic "UC nhắc tên" khớp chữ "History"; glossary in cả ## History lẫn context
    # khác. Mục dấu vết cắt tới heading cùng cấp hoặc cao hơn kế tiếp.
    lines = s.split('\n'); keep = []; cut = 0
    for ln in lines:
        m = re.match(r'(#{1,6}) (.*)', ln)
        if m:
            lvl = len(m.group(1))
            if cut and lvl <= cut: cut = 0
            if not cut and is_trace(m.group(2)): cut = lvl; continue
        if cut: continue
        if re.match(r'\s*[-*] \[x\]', ln, re.I): continue
        keep.append(ln)
    return '\n'.join(keep)
def H(t): srcs.append((t, len(out))); out.append(f'\n════ {t} ════')
IS_BR = ID.startswith('BR-')
uc = rd(F); design = '' if IS_BR else (rd(os.path.join(os.path.dirname(F), 'design.md')) or '')

# ── 0. BR-### (7.4, P-23): chủ thể là một lát — mục quyết định của BR + dòng ở vision.md ──
if IS_BR:
    bm = re.search(r'(?ms)^# ' + re.escape(ID) + r':([^\n]*)\n(.*?)(?=^# BR-|\Z)', strip_markup(uc or ''))
    uc = bm.group(2) if bm else ''
    if not WHY and bm:
        H(f'{ID}:{bm.group(1)} — quyết định (không Background)')
        for hname in ('Goal', 'In Scope', 'Out of Scope', 'Success Metrics', 'Constraints', 'Related Use Cases', 'Đã loại khỏi brief', 'Open Questions'):
            sb = sect(uc, hname)
            if sb and sb.strip(): out.append(f'## {hname}\n' + drop_trace(sb).rstrip())
        bg = sect(uc, 'Background')
        if bg and bg.strip(): out.append(f'(## Background: {len(bg.encode())/1024:.1f} KB chứng cứ — đọc {rel(F)} khi cần)')
        vis = rd(os.path.join(ROOT, 'specs', 'vision.md'))
        rows = [l for l in (vis or '').split('\n') if l.startswith('|') and re.search(r'\b' + ID + r'\b', l)]
        if rows: H('specs/vision.md — dòng của lát'); out.extend(rows)

# ── 1. UC — mọi mục trừ ba mục dấu vết; Open Questions chỉ giữ câu còn mở ──
if not WHY and not IS_BR:
    H(f'{ID}.md — phần đang hiệu lực')
    out.append(drop_trace(uc).rstrip())
    fl = rd(os.path.join(os.path.dirname(F), f'{ID}.flow.md'))
    if fl and '```mermaid' in fl: H(f'{ID}.flow.md'); out.append(fl.rstrip())

# ── 2-4. ID UC (và design.md) trích ──
cited = drop_trace(uc) + '\n' + design
rules = sorted(set(re.findall(r'\bRULE-[0-9]+[a-z]?\b', cited)))
cons  = [] if IS_BR else sorted(set(re.findall(r'\bCON-[0-9]+\b', cited)))   # BR: CON nằm ngay ## Constraints ở trên
adrs  = sorted(set(re.findall(r'\bADR-[0-9]+\b', cited)))

rl = '\n'.join((rd(p) or '') for p in RULES)
if rules:
    H(f'RULE được trích ({len(rules)}) — {rel_list(RULES) or "specs/rules.md"}')
    rls = strip_markup(rl or '')
    for r in rules:
        # chỉ heading + thân của RULE này (## hoặc ###), không bao giờ cả file
        b = None
        for lvl in ('## ', '### '):
            b = sect(rls, r + ':', lvl)
            if b is None: b = sect(rls, r, lvl)
            if b is not None: break
        if b is None: warns.append(f'{r} — UC trích nhưng rules.md không có'); continue
        out.append(f'## {r}\n' + drop_trace(b).rstrip())

br = '\n'.join((rd(p) or '') for p in BRS)
brs = strip_markup(br)
if cons:
    H(f'CON được trích ({len(cons)}) — {rel_list(BRS) or "specs/br.md"} ## Constraints')
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
    H(f'ADR được trích ({len(adrs)}) — {rel_list(ADRS) + "/" if ADRS else "specs/adr/"}')
    for a in adrs:
        fs = [f for d in ADRS for f in sorted(glob.glob(os.path.join(d, a + '*'))) if not os.path.basename(f).startswith('_')]
        if not fs: warns.append(f'{a} — UC trích nhưng không có file ADR'); continue
        t = strip_markup(rd(fs[0]) or '')
        title = next((l for l in t.split('\n') if l.startswith('# ')), f'# {a}')
        st = (sect(t, 'Status') or '').strip().split('\n')[0]
        dec = drop_trace(sect(t, 'Decision') or '').strip()
        if BRIEF:
            # đoạn đầu tới ### đầu tiên + tên mục con; đoạn đầu rỗng thì mục con đầu tiên nguyên
            parts = re.split(r'(?m)^(?=### )', dec)
            head = parts[0].strip(); subs = [p.split('\n', 1)[0] for p in parts[1:]]
            if not head and parts[1:]: head = parts[1].strip(); subs = subs[1:]
            dec = head + ('\n' + '\n'.join(f'{h} — (mục con, xem file)' for h in subs) if subs else '')
        out.append(f'{title}\nStatus: {st}\n{dec}')

# ── 5. BR cha — quyết định, không chứng cứ ──
brid = None if IS_BR else re.search(r'\bBR-[0-9]+\b', uc)
if not WHY and brid:
    b = brid.group(0)
    body = re.search(r'(?ms)^# ' + re.escape(b) + r':([^\n]*)\n(.*?)(?=^# BR-|\Z)', brs)
    if body:
        H(f'{b}:{body.group(1)} — quyết định (không Background)')
        for hname in ('Goal', 'In Scope', 'Out of Scope', 'Success Metrics', 'Đã loại khỏi brief'):
            sb = sect(body.group(2), hname)
            if sb and sb.strip(): out.append(f'## {hname}\n' + drop_trace(sb).rstrip())
    else: warns.append(f'{b} — UC trỏ tới nhưng br.md không có')

# ── 6. architecture.md — bốn mục ──
ar = rd(ARCH) if ARCH else None
if ar:
    ars = strip_markup(ar)
    heads = ('Cấm',) if WHY else (('Cấm', 'Ranh giới', 'Nơi chạy') if BRIEF else ('Ngăn xếp', 'Nơi chạy', 'Ai gọi', 'Cấm'))
    H(rel(ARCH) + (' — --brief: Cấm · Ranh giới · Nơi chạy' if BRIEF else ''))
    for hname in heads:
        sb = sect(ars, hname)
        if sb is None:
            if hname != 'Ranh giới': warns.append(f'architecture.md thiếu ## {hname}')
            continue
        if re.search(r'<[^>\n]+>', sb): warns.append(f'architecture.md ## {hname} còn placeholder <...> — chưa ai quyết')
        out.append(f'## {hname}\n' + drop_trace(sb).rstrip())
else: warns.append('thiếu ' + (rel(ARCH) if ARCH else 'specs/architecture.md'))

# ── 7. entity + glossary có nhắc trong UC ──
if not WHY:
    # 7.0 (T2): mỗi entity một file — entity_cited đã lọc theo tên UC nhắc, in nguyên file (bỏ dấu vết).
    # 6.x: một entities.md cho cả context — tách khối ## theo tên UC nhắc như trước.
    en = None
    if ENTS and not any('/specs/contexts/' in p for p in ENTS):
        H(f'entities — {len(ENTS)} entity UC nhắc tên ({", ".join(os.path.basename(p)[:-3] for p in ENTS)})')
        out.append('\n\n'.join(drop_trace(strip_markup(rd(p) or '')).rstrip() for p in ENTS))
    elif ENTS: en = rd(ENTS[0])
    if en:
        ens = drop_trace(strip_markup(en)); blocks = re.split(r'(?m)^(?=#{2,3} )', ens)
        words = set(w.lower() for w in re.findall(r'\b[A-Z][A-Za-z]{2,}\b', drop_trace(uc)))
        def first_word(bl):
            h = bl.split('\n', 1)[0].lstrip('# ').strip()
            ws = re.sub(r'[^A-Za-z]', ' ', h).split()
            return ws[0].lower() if ws else ''
        picked = [bl for bl in blocks if bl.startswith('#') and first_word(bl) in words]
        if picked:
            H(f'entities.md — {len(picked)} mục UC nhắc tên (trong {sum(1 for b in blocks if b.startswith("#"))})')
            out.append('\n'.join(b.rstrip() for b in picked))
        else:
            H('entities.md — không tách được theo tên, in cả'); out.append(ens.rstrip())
    gl = '\n'.join((rd(p) or '') for p in GLOS) if GLOS else None
    if gl:
        # #43: bỏ ## History và mục ## <context khác> — gate-check đòi thuật ngữ nằm dưới
        # heading '## <ctx>', nên heading bắt đầu bằng tên một context khác là của họ.
        # 7.0: OTHERS là tên các nghề khác; glossary gốc lẽ ra không có mục nghề, có thì cũng cắt.
        others = OTHERS
        gls = drop_trace(strip_markup(gl)); kept = []; dropped = 0; skip = False
        for ln in gls.split('\n'):
            m = re.match(r'## (.*)', ln)
            if m:
                w = re.sub(r'[^A-Za-z0-9_-]', ' ', m.group(1)).split()
                skip = bool(w) and w[0].lower() in others
                if skip: dropped += 1
            elif ln.startswith('# '): skip = False
            if not skip: kept.append(ln)
        H(rel_list(GLOS) + (f' — bỏ {dropped} mục của context khác' if dropped else ''))
        out.append('\n'.join(kept).rstrip())

# ── 8. brief — đọc riêng ──
if not WHY:
    H('brief nguồn')
    out.append(f'{BP} · sha256 {BS} — ĐỌC RIÊNG file này; nó nằm ngoài specs/ và không phép kiểm nào khác nhìn tới (#34)'
               if BP else 'dự án không khai brief_path trong .sdd/config — không có brief nguồn')

text = '\n'.join(out).strip() + '\n'
sys.stdout.write(text)
for w in warns: print(f'  ! {w}')
kb = len(text.encode()) / 1024
print(f'\n--- context.sh {ID}{" --why" if WHY else ""}{" --brief" if BRIEF else ""}: {kb:.1f} KB · {len(srcs)} nguồn')
# #43: kích thước từng nguồn — để thấy nguồn nào phình, thay vì một tổng không chỉ vào đâu.
sizes = []
for i, (t, k) in enumerate(srcs):
    end = srcs[i + 1][1] if i + 1 < len(srcs) else len(out)
    sizes.append((len('\n'.join(out[k:end]).encode()) / 1024, t))
big = max((x for x, _ in sizes), default=0)
for x, t in sizes:
    print(f'  {x:6.1f} KB  {t[:70]}' + ('   ← lớn nhất' if x == big and big > 0 and len(sizes) > 1 else ''))
PY
