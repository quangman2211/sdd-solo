#!/usr/bin/env bash
# migrate.sh [--dry-run] — 3.x → 4.0.0: tách cây của Spec Kit ra khỏi specs/.
# migrate.sh --evidence BR-### [--dry-run] — 5.0.0: tách thân ## Background ra br.evidence.md;
#   5.1.0: tách thêm thân ## Adversarial pass, để lại dòng đếm có số ___ ở mặt tiền.
# migrate.sh --layout v7 [--map <file>] [--dry-run] — 7.0.0: specs/contexts/<ctx>/ · specs/br.md · specs/internal/
#   → specs/{vision,architecture,decisions}.md · specs/adr/ · specs/<core|nghề>/{entities/,br-###/{br.md,evidence.md,
#   use-cases/}} · notes/{hoi-dap,soat,ban-do}/. Đọc file map (mặc định .sdd/migrate-v7.map), git mv giữ history,
#   in bảng "đã dời" và "cần tay". Xem khối `--layout v7` bên dưới.
#
#   specs/00N-<slug>/  →  .speckit/work/00N-<slug>/
#
# Vì sao: `speckit-specify/SKILL.md` dặn agent BẰNG LỜI VĂN rằng specs nằm dưới
# `specs/`, và số tiếp theo lấy bằng cách quét các thư mục đang có trong `specs/`
# — tức phép đếm đó đang đếm cả br.md, contexts/, changes/ của sdd-solo. Hai hệ
# ID (`001-` và `UC-###`), hai cây spec, một thư mục, không bên nào biết bên kia.
# (Có một `create-new-feature.sh` làm đúng việc đó, nhưng KHÔNG skill nào gọi nó
#  — đo trên 1.0.6.dev0 và trên bản cũ ở runxops. Lời văn trong skill mới là thứ
#  chạy thật, và lời văn thì không cấu hình lại được.)
#
# KHÔNG tự commit. Dời file rồi in ra những gì đã đổi; người đọc rồi commit.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
DRY=0; EV=""; LAYOUT=""; MAPF=""
PREV=""
for a in "$@"; do
  case "$PREV" in --layout) LAYOUT="$a"; PREV=""; continue;; --map) MAPF="$a"; PREV=""; continue;; esac
  case "$a" in
    --dry-run) DRY=1;;
    --evidence) EV="_";;
    --layout|--map) PREV="$a";;
    BR-[0-9]*) [ "$EV" = "_" ] && EV="$a";;
  esac
done

# ── --layout v7 : cây context → core|nghề × br-### (7.0.0, #54 #55) ─────────
# Toàn bộ logic ở khối python: tách file theo heading, dựng bảng UC, sửa đường dẫn theo tên thật
# vừa dời (cùng luật với phần Spec Kit bên dưới — liệt kê đích danh, không regex chung). Bash chỉ
# tìm khuôn: chạy từ plugin thì `templates/` ở cạnh; chạy từ bản sao .sdd/scripts/ thì hỏi bản
# plugin đang cài; không có thì python dùng khung tối thiểu và ghi vào bảng "cần tay".
if [ -n "$LAYOUT" ]; then
  [ "$LAYOUT" = "v7" ] || { echo "Dùng: migrate.sh --layout v7 [--map <file>] [--dry-run]" >&2; exit 2; }
  if [ "$(layout "$ROOT")" = v7 ] && [ ! -d "$ROOT/specs/contexts" ] && [ ! -f "$ROOT/specs/br.md" ]; then
    ok "repo đã ở bố cục 7.0 (specs/vision.md hoặc specs/*/br-###/ có, specs/contexts/ và specs/br.md không còn) — không có gì để dời"; exit 0
  fi
  [ -z "$MAPF" ] && MAPF="$ROOT/.sdd/migrate-v7.map"
  case "$MAPF" in /*) ;; *) MAPF="$ROOT/$MAPF";; esac
  TPLD=""
  for cand in "$HERE/../templates" "${CLAUDE_PLUGIN_ROOT:-/nonexistent}/templates" "$(installed_path sdd-solo 2>/dev/null)/templates"; do
    [ -f "$cand/skel/br/br.md" ] && { TPLD="$cand"; break; }
  done
  [ -z "$TPLD" ] && warn "không tìm thấy templates/ của plugin — khung br.md/rules/glossary/vision sẽ là bản tối thiểu"
  echo "=== Dời sang bố cục 7.0 — core|nghề × br-### ==="
  [ "$DRY" = "1" ] && info "--dry-run: KHÔNG đụng đĩa, chỉ in ra sẽ làm gì"
  info "map: ${MAPF#$ROOT/}"
  python3 - "$ROOT" "$DRY" "$MAPF" "${TPLD:+$TPLD/skel}" "${TPLD:+$TPLD/project}" "$(uc_test_dir "$ROOT")" "$(today)" <<'PY'
import sys, re, io, os, glob, subprocess, shutil
ROOT, DRY, MAPP, SKEL, TPL, UCT, TODAY = sys.argv[1:8]; DRY = DRY == "1"
os.chdir(ROOT)
def rd(p):
    try: return io.open(p, encoding='utf-8').read()
    except FileNotFoundError: return None
def rel(p): return os.path.relpath(p, ROOT)
def ok(m): print(f'  \033[32m✓\033[0m {m}')
def bad(m): print(f'  \033[31m✗\033[0m {m}')
def info(m): print(f'  – {m}')
MOVED, NEED, ERR = [], [], []     # (cũ, mới) · (việc, chỗ) · lỗi chặn
# ── map ───────────────────────────────────────────────────────────────────
M = {'context': {}, 'uc': {}, 'br': {}, 'adr': {}, 'rule': {}, 'entity': {}, 'glossary': {}}
mp = rd(MAPP)
if mp is None:
    bad(f'không có {rel(MAPP)} — viết file map trước (mỗi dòng: context <ctx> <nghề> · uc UC-### BR-### · br BR-### <core|nghề> · adr ADR-### <nghề> · rule RULE-### <nghề> · entity <Tên> <core|nghề> · glossary <từ-đầu-heading> <nghề>)')
    sys.exit(1)
for ln in mp.split('\n'):
    ln = ln.split('#', 1)[0].strip()
    if not ln: continue
    w = ln.split()
    if len(w) != 3 or w[0] not in M: ERR.append(f'dòng map không hiểu: {ln}'); continue
    M[w[0]][w[1]] = w[2]
CTXS = sorted(d for d in glob.glob('specs/contexts/*/') for d in [d.rstrip('/').split('/')[-1]] if not d.startswith('_'))
for c in CTXS:
    if c not in M['context']: ERR.append(f'context `{c}` chưa có dòng `context {c} <nghề>` trong map')
nghe_of_ctx = M['context']
# ── BR trong br.md ────────────────────────────────────────────────────────
brmd = rd('specs/br.md') or ''
BRSEC = {}   # BR-### → nội dung mục
for m in re.finditer(r'(?ms)^# (BR-[0-9]+):[^\n]*\n.*?(?=^# BR-|\Z)', brmd): BRSEC[m.group(1)] = m.group(0)
BRHEAD = brmd[:brmd.index('# BR-')] if '# BR-' in brmd else brmd
for b in BRSEC:
    if b == 'BR-000': continue
    if b not in M['br']: ERR.append(f'{b} chưa có dòng `br {b} <core|nghề>` trong map')
# ── UC ────────────────────────────────────────────────────────────────────
UCS = {}   # UC-### → dict(dir, ctx, br, status, title)
for d in sorted(glob.glob('specs/contexts/*/use-cases/UC-*/')):
    d = d.rstrip('/'); uid = re.match(r'UC-[0-9]+', os.path.basename(d)).group(0)
    f = rd(f'{d}/{uid}.md') or ''
    br = M['uc'].get(uid) or (re.search(r'Liên quan tới BR:\*\* *(BR-[0-9]+)', f) or [None, None])[1]
    st = (re.search(r'\*\*Status:\*\* *([a-z]+)', f) or [None, '?'])[1]
    ti = (re.search(r'(?m)^# UC-[0-9]+: *(.*)', f) or [None, '___'])[1].strip()
    ctx = d.split('/')[2]
    UCS[uid] = dict(dir=d, ctx=ctx, br=br, status=st, title=ti)
    if not br: ERR.append(f'{uid} không biết thuộc BR nào — thêm `uc {uid} BR-###` vào map')
    elif br not in M['br']: ERR.append(f'{uid} → {br} nhưng {br} chưa có dòng `br {br} <core|nghề>` trong map')
# bảng use-cases.md của từng context → hàng theo UC
ROWS = {}   # UC-### → (tên, actor, br, status)
for c in CTXS:
    t = rd(f'specs/contexts/{c}/use-cases.md') or ''
    for ln in t.split('\n'):
        cells = [x.strip() for x in ln.strip().strip('|').split('|')]
        if len(cells) >= 5 and re.match(r'^UC-[0-9]+$', cells[0]): ROWS[cells[0]] = (cells[1], cells[2], cells[3], cells[4])
if ERR:
    for e in ERR: bad(e)
    print(f'\nKHÔNG CHẠY — {len(ERR)} chỗ map thiếu. Sửa {rel(MAPP)} rồi chạy lại.'); sys.exit(1)
def nghe_of_br(b): return M['br'][b]
def br_dir(b): return f'specs/{nghe_of_br(b)}/br-{b[3:]}'
# ── kế hoạch: mọi thao tác gom vào danh sách, DRY thì chỉ in ──────────────
ACTS = []   # ('mv', old, new) · ('write', path, content) · ('rm', path) · ('mkdir', path)
def mv(o, n): ACTS.append(('mv', o, n)); MOVED.append((o, n))
def write(p, c): ACTS.append(('write', p, c))
def rm(p): ACTS.append(('rm', p))
# 1. internal/ → gốc + notes/
ADR_ROOT = []
for f in sorted(glob.glob('specs/internal/*')):
    b = os.path.basename(f)
    if b == 'architecture.md': mv(f, 'specs/architecture.md')
    elif b == 'decisions.md': mv(f, 'specs/decisions.md')
    elif b == 'adr' and os.path.isdir(f):
        for a in sorted(glob.glob(f + '/*')):
            ab = os.path.basename(a); aid = re.match(r'ADR-[0-9]+', ab)
            n = M['adr'].get(aid.group(0)) if aid else None
            mv(a, f'specs/{n}/adr/{ab}' if n else f'specs/adr/{ab}')
            if aid and not n: ADR_ROOT.append(aid.group(0))
    elif re.match(r'hoi-.*\.md$', b): mv(f, f'notes/hoi-dap/{b}')
    elif re.match(r'soat-.*\.md$', b): mv(f, f'notes/soat/{b}')
    elif 'ban-do' in b: mv(f, f'notes/ban-do/{b}')
    else: mv(f, f'notes/{b}'); NEED.append(('file internal/ không thuộc loại nào, đã đưa vào notes/ — xếp lại tay nếu cần', f'notes/{b}'))
if ADR_ROOT: NEED.append((f'ADR để ở gốc specs/adr/ vì map không nói: {", ".join(ADR_ROOT)} — cái nào riêng một nghề thì thêm `adr ADR-### <nghề>` vào map (chạy lại) hoặc `git mv` sang specs/<nghề>/adr/', 'specs/adr/'))
# 2. br.md → mỗi BR một lát
SKEL_BR = rd(f'{SKEL}/br/br.md') if SKEL else None
def br_table(b, ucs):
    rows = ['| UC | Tên | Actor | BR | Status |', '|---|---|---|---|---|']
    seen = set()
    for u in sorted(ucs):
        if u in ROWS: n, a, _, s = ROWS[u]
        else: n, a, s = UCS.get(u, {}).get('title', '___'), '___', UCS.get(u, {}).get('status', 'draft')
        rows.append(f'| {u} | {n} | {a} | {b} | {s} |'); seen.add(u)
    # hàng use-cases.md nói thuộc BR này mà chưa có thư mục UC (UC chưa mở / bỏ trước khi mở)
    for u, (n, a, rb, s) in sorted(ROWS.items()):
        if rb == b and u not in seen: rows.append(f'| {u} | {n} | {a} | {b} | {s} |')
    return '\n'.join(rows)
UC_BY_BR = {}
for u, x in UCS.items(): UC_BY_BR.setdefault(x['br'], []).append(u)
biggest = max(BRSEC, key=lambda k: len(BRSEC[k])) if BRSEC else None
for b, sec in BRSEC.items():
    if b == 'BR-000': continue
    s = sec
    if '**Lát:**' not in s:
        s = re.sub(r'(?m)^(- \*\*Status:\*\*[^\n]*\n)', r'\1' + f'- **Lát:** {nghe_of_br(b)} · ___\n', s, count=1)
        NEED.append((f'{b}: điền `**Lát:** {nghe_of_br(b)} · <tên lát>` theo bảng `## Nghề và lát` của specs/vision.md', f'{br_dir(b)}/br.md'))
    s = s.replace('→ specs/br.evidence.md', '→ evidence.md')
    tbl = br_table(b, UC_BY_BR.get(b, []))
    if re.search(r'(?m)^## Related Use Cases', s):
        s = re.sub(r'(?m)^(## Related Use Cases[^\n]*\n)', r'\1' + tbl.replace('\\', '\\\\') + '\n\n', s, count=1)
    else: s = s.rstrip('\n') + '\n\n## Related Use Cases\n' + tbl + '\n'
    dst = f'{br_dir(b)}/br.md'
    if b == biggest: mv('specs/br.md', dst)
    write(dst, s.rstrip('\n') + '\n')
if biggest == 'BR-000' or (BRSEC and biggest not in BRSEC): rm('specs/br.md')
if BRHEAD.strip() and 'Mỗi BR một mục' not in BRHEAD:
    write('notes/br-header.md', BRHEAD); NEED.append(('phần đầu specs/br.md (trước BR đầu tiên) không phải khuôn — đã cất', 'notes/br-header.md'))
if 'BR-000' in BRSEC: info('BR-000 (mẫu khuôn) bỏ — bản 7.0 có mẫu ở specs/core/br-000/ khi init --update')
# BR chỉ có trong map uc → tạo khung
for b in sorted(set(x['br'] for x in UCS.values()) - set(BRSEC)):
    n = nghe_of_br(b); dst = f'{br_dir(b)}/br.md'
    if SKEL_BR:
        s = re.sub(r'(?s)\n<!-- Khuôn một lát\..*?-->\n', '\n', SKEL_BR.replace('BR-000', b), count=1)
        s = s.replace('- **Lát:** <core | nghề> · <tên lát đúng như bảng `## Nghề và lát` của specs/vision.md>', f'- **Lát:** {n} · ___')
        s = re.sub(r'(?ms)^## Related Use Cases\n.*?(?=^## |\Z)', '## Related Use Cases\n' + br_table(b, UC_BY_BR[b]).replace('\\', '\\\\') + '\n\n', s, count=1)
        s = s.replace('- **Status:** draft | approved | in-progress | done', '- **Status:** draft')
    else:
        s = f'# {b}: ___\n\n## Metadata\n- **Status:** draft\n- **Lát:** {n} · ___\n- **Last updated:** {TODAY}\n\n## Goal\n___\n\n## Related Use Cases\n{br_table(b, UC_BY_BR[b])}\n'
    write(dst, s)
    NEED.append((f'{b} chưa có trong br.md — đã dựng khung (Status draft) chứa {", ".join(sorted(UC_BY_BR[b]))}; viết BR thật', dst))
# 3. br.evidence.md → evidence.md của từng lát
ev = rd('specs/br.evidence.md')
if ev is not None:
    EVSEC = {}
    for m in re.finditer(r'(?ms)^## (BR-[0-9]+) — [^\n]*\n.*?(?=^## BR-[0-9]+ — |\Z)', ev): EVSEC.setdefault(m.group(1), []).append(m.group(0))
    orphan = [b for b in EVSEC if b not in M['br']]
    placed = [b for b in EVSEC if b in M['br']]
    for b in orphan: NEED.append((f'evidence của {b} không có lát đích (BR không trong map) — để lại ở file cũ', 'specs/br.evidence.md'))
    if placed and not orphan: mv('specs/br.evidence.md', f'{br_dir(placed[0])}/evidence.md')
    for b in placed:
        write(f'{br_dir(b)}/evidence.md', f'# {b} — chứng cứ\n\nTách từ specs/br.evidence.md ({TODAY}). Mở khi tranh chấp; context.sh không đọc.\n\n' + '\n'.join(EVSEC[b]).rstrip('\n') + '\n')
# 4. UC dirs
for u, x in sorted(UCS.items()):
    n = nghe_of_br(x['br']); dst = f'{br_dir(x["br"])}/use-cases/{os.path.basename(x["dir"])}'
    mv(x['dir'], dst)
    f = rd(f'{x["dir"]}/{u}.md') or ''
    f2 = re.sub(r'(?m)^- \*\*Bounded Context:\*\* *[^\n]*$', f'- **Nghề:** {n} · **Lát:** {x["br"]} (trước 7.0: context `{x["ctx"]}`)', f, count=1)
    old_br = (re.search(r'Liên quan tới BR:\*\* *(BR-[0-9]+)', f) or [None, None])[1]
    if old_br and old_br != x['br']:   # map `uc` đổi BR (UC-024 console → BR core mới): dòng Metadata phải nói cùng một thứ với thư mục
        f2 = re.sub(r'(?m)^(- \*\*Liên quan tới BR:\*\* *)BR-[0-9]+', r'\g<1>' + f'{x["br"]} (trước 7.0: {old_br})', f2, count=1)
    if f2 != f: write(f'{dst}/{u}.md', f2)
    if n != nghe_of_ctx[x['ctx']]:
        NEED.append((f'{u} sang `{n}` (context `{x["ctx"]}` → nghề `{nghe_of_ctx[x["ctx"]]}`): entity nó dùng phải nằm ở `specs/core/entities/` hoặc `specs/{n}/entities/` — thêm dòng `entity <Tên> {n}` vào map nếu chưa', dst))
    # test
    td = f'{UCT}/{x["ctx"]}/{u}'
    if os.path.isdir(td) and n != x['ctx']: mv(td, f'{UCT}/{n}/{u}')
# 5. entities.md → mỗi entity một file
for c in CTXS:
    p = f'specs/contexts/{c}/entities.md'; t = rd(p)
    if t is None: continue
    n = nghe_of_ctx[c]
    parts = re.split(r'(?m)^(?=## )', t)
    readme = [f'# Entities — {n} (từ context `{c}`)\n', parts[0].split('\n', 1)[1] if parts[0].startswith('# ') else parts[0]]
    for sec in parts[1:]:
        head = sec.split('\n', 1)[0][3:].strip()
        bt = re.search(r'`([A-Za-z][A-Za-z0-9_]*)`', head)
        fw = re.match(r'([A-Z][A-Za-z0-9_]*)\b', head)
        name = bt.group(1) if bt else (fw.group(1) if fw and head.split()[0] == fw.group(1) else None)
        if name is None or name in ('Domain', 'History'):
            readme.append(sec); continue
        dn = M['entity'].get(name, n)
        body = sec.split('\n', 1)[1] if '\n' in sec else ''
        write(f'specs/{dn}/entities/{name}.md', f'# {name}\n\n<!-- tách từ entities.md của context `{c}`, mục `## {head}` ({TODAY}) -->\n\n- **Thuộc:** {dn}\n' + body.rstrip('\n') + '\n')
        MOVED.append((f'{p} ## {head}', f'specs/{dn}/entities/{name}.md'))
    write(f'specs/{n}/entities/README.md', ''.join(readme).rstrip('\n') + '\n')
    rm(p); MOVED.append((p, f'specs/{n}/entities/README.md (Domain Model · phần không phải entity)'))
    for extra in ('README.md', 'use-cases.md', 'diagrams/README.md'):
        if os.path.exists(f'specs/contexts/{c}/{extra}'): rm(f'specs/contexts/{c}/{extra}')
    for d in glob.glob(f'specs/contexts/{c}/diagrams/*'):
        if os.path.basename(d) != 'README.md': mv(d, f'notes/ban-do/{c}-diagrams/{os.path.basename(d)}')
# 6. rules.md → nghề
rl = rd('specs/rules.md') or ''
if M['rule']:
    parts = re.split(r'(?m)^(?=## RULE-)', rl); keep = [parts[0]]; per = {}
    for sec in parts[1:]:
        rid = re.match(r'## (RULE-[0-9]+)', sec).group(1); n = M['rule'].get(rid)
        if n: per.setdefault(n, []).append(sec); MOVED.append((f'specs/rules.md ## {rid}', f'specs/{n}/rules.md'))
        else: keep.append(sec)
    if per:
        write('specs/rules.md', ''.join(keep).rstrip('\n') + '\n')
        for n, secs in per.items():
            head = rd(f'{SKEL}/nghe/rules.md') if SKEL else None
            head = (head or '# Business Rules — <nghề>\n').split('## RULE-')[0].replace('<nghề>', n)
            write(f'specs/{n}/rules.md', head.rstrip('\n') + '\n\n' + ''.join(secs).rstrip('\n') + '\n')
# 7. glossary.md → nghề
gl = rd('specs/glossary.md') or ''
parts = re.split(r'(?m)^(?=## )', gl); keep = [parts[0]]; per = {}
for sec in parts[1:]:
    head = sec.split('\n', 1)[0][3:].strip(); fw = re.sub(r'[^A-Za-z0-9_-]', ' ', head).split()
    fw = fw[0].lower() if fw else ''
    n = M['glossary'].get(fw) or nghe_of_ctx.get(fw)
    if n and fw != 'history': per.setdefault(n, []).append(sec); MOVED.append((f'specs/glossary.md ## {head[:40]}', f'specs/{n}/glossary.md'))
    else: keep.append(sec)
if per:
    write('specs/glossary.md', ''.join(keep).rstrip('\n') + '\n')
    for n, secs in per.items():
        head = rd(f'{SKEL}/nghe/glossary.md') if SKEL else None
        head = (head or '# Glossary — <nghề>\n').split('\n- **')[0].replace('<nghề>', n)
        write(f'specs/{n}/glossary.md', head.rstrip('\n') + '\n\n' + ''.join(secs).rstrip('\n') + '\n')
    NEED.append(('glossary: mục theo tên context đã sang glossary nghề; mục còn ở gốc phải là từ CHUNG mọi nghề — soát lại', 'specs/glossary.md'))
# 8. vision.md · config
if not os.path.exists('specs/vision.md'):
    v = rd(f'{TPL}/specs/vision.md') if TPL else None
    write('specs/vision.md', v or '# Hướng — tầng 0\n\n## Định vị\n___\n\n## Không thu hẹp\n- ___\n\n## Nghề và lát\n| Nghề | Lát | BR | Trạng thái | Mở khi |\n|---|---|---|---|---|\n')
    NEED.append(('viết specs/vision.md — chủ dự án, bằng lời thường: định vị · không thu hẹp · bảng nghề và lát (mỗi BR trích một dòng ở đó) · "xong" mỗi nghề', 'specs/vision.md'))
NGHE = sorted(set(M['br'].values()) | set(nghe_of_ctx.values()) | set(M['adr'].values()) | set(M['rule'].values()) | set(M['entity'].values()) - {'core'})
NGHE = [n for n in NGHE if n != 'core']
cfg = rd('.sdd/config') or ''
if not re.search(r'(?m)^nghe_paths=', cfg):
    write('.sdd/config', cfg.rstrip('\n') + '\n# nghe_paths: tên các nghề (thư mục specs/<nghề>/, src/<nghề>/). core không kể. migrate --layout v7 ghi (7.0).\nnghe_paths=' + ' '.join(NGHE) + '\n')
for n in NGHE:
    if not os.path.exists(f'specs/{n}/README.md'):
        r = rd(f'{SKEL}/nghe/README.md') if SKEL else None
        write(f'specs/{n}/README.md', (r or '# Nghề: <tên>\n').replace('<tên>', n))
# 9. sửa đường dẫn trong file — theo tên THẬT vừa dời, dài trước ngắn sau; đích mơ hồ thì không sửa, chỉ đếm
REPL = []
for o, nw in MOVED:
    if ' ## ' in o or ' (' in nw: continue
    REPL.append((o, nw))
for c in CTXS:
    n = nghe_of_ctx[c]
    REPL.append((f'specs/contexts/{c}/entities.md', f'specs/{n}/entities/'))
    brs = sorted(set(x['br'] for x in UCS.values() if x['ctx'] == c))
    if len(brs) == 1: REPL.append((f'specs/contexts/{c}/use-cases.md', f'{br_dir(brs[0])}/br.md'))
REPL.sort(key=lambda t: -len(t[0]))
AMBIG = ['specs/br.md', 'specs/br.evidence.md', 'specs/contexts/', 'specs/internal/']
FILES = []
for dp, dn, fn in os.walk('.'):
    dn[:] = [d for d in dn if d not in ('.git', 'node_modules', '.speckit', 'dist') and not (dp == '.' and d == '.sdd')]
    for f in fn:
        if re.search(r'\.(md|json|ya?ml|ts|js|sh|txt)$', f): FILES.append(os.path.join(dp, f)[2:])
FILES.append('.sdd/config'); FILES.append('CLAUDE.md')
# brief nguồn KHÔNG sửa: br-check/session-start so sha của nó với dòng `Nguồn brief:` — đổi một byte là "brief đã đổi kể từ lần nạp"
BRIEF = (re.search(r'(?m)^brief_path=(.*)$', rd('.sdd/config') or '') or [None, ''])[1].strip()
if BRIEF:
    FILES = [f for f in FILES if f != BRIEF]
    if BRIEF and (rd(BRIEF) or '').count('specs/'): NEED.append((f'brief nguồn nhắc đường dẫn cũ — KHÔNG tự sửa (sha phải giữ); để nguyên, hoặc sửa rồi nạp lại bằng /sdd-solo:intake', BRIEF))
TOUCH, LEFT = [], {}
pending_new = {a[1]: a[2] for a in ACTS if a[0] == 'write'}   # ghi sau đè ghi trước
def moved_dst(f):
    for o, nw in MOVED:
        if ' ## ' in o or ' (' in nw: continue
        if f == o or f.startswith(o + '/'): return nw + f[len(o):]
    return f
cands = {}
for f in set(FILES):
    if any(a[0] == 'rm' and a[1] == f for a in ACTS): continue
    cands.setdefault(moved_dst(f), f)
for pth in pending_new: cands[pth] = None
for dst, src in sorted(cands.items()):
    # file sắp ghi mới thì sửa trên nội dung mới; file sắp dời thì sửa rồi ghi ở đích
    t = pending_new[dst] if dst in pending_new else rd(src)
    if t is None: continue
    t2 = t
    for o, nw in REPL: t2 = t2.replace(o, nw)
    if t2 != t: write(dst, t2); TOUCH.append(dst)
    left = sum(t2.count(a) for a in AMBIG)
    if left: LEFT[dst] = left
# ── thực thi ──────────────────────────────────────────────────────────────
def tracked(p): return subprocess.run(['git', 'ls-files', '--error-unmatch', p], capture_output=True).returncode == 0
if not DRY:
    for a in ACTS:
        if a[0] == 'mv':
            os.makedirs(os.path.dirname(a[2]) or '.', exist_ok=True)
            if os.path.exists(a[2]) and not os.path.isdir(a[2]): os.remove(a[2])
            if tracked(a[1]): subprocess.run(['git', 'mv', '-k', a[1], a[2]], check=False)
            if os.path.exists(a[1]): shutil.move(a[1], a[2])
    for a in ACTS:
        if a[0] == 'write':
            os.makedirs(os.path.dirname(a[1]) or '.', exist_ok=True)
            io.open(a[1], 'w', encoding='utf-8').write(a[2]); subprocess.run(['git', 'add', a[1]], check=False)
    for a in ACTS:
        if a[0] == 'rm' and os.path.exists(a[1]):
            if tracked(a[1]): subprocess.run(['git', 'rm', '-q', '-r', '--cached', a[1]], check=False)
            if os.path.isdir(a[1]): shutil.rmtree(a[1])
            else: os.remove(a[1])
    for d in ['specs/contexts', 'specs/internal', UCT]:
        for dp, dn, fn in os.walk(d, topdown=False):
            if os.path.isdir(dp) and not os.listdir(dp): os.rmdir(dp)
    for c in CTXS:
        for dp, dn, fn in os.walk('specs/contexts', topdown=False):
            if os.path.isdir(dp) and not os.listdir(dp): os.rmdir(dp)
        d = f'specs/contexts/{c}'
        if os.path.isdir(d) and os.listdir(d): NEED.append((f'specs/contexts/{c}/ còn file không thuộc khuôn — xem và dời tay', d))
    for pth in ['specs', 'notes', UCT, '.sdd/config']:
        if os.path.exists(pth): subprocess.run(['git', 'add', '-A', pth], check=False)
# ── báo cáo ───────────────────────────────────────────────────────────────
print(f'\n=== {"SẼ dời" if DRY else "Đã dời"} ({len(MOVED)}) ===')
for o, nw in MOVED: print(f'  {o}\n      → {nw}')
print(f'\n=== File đã sửa đường dẫn ({len(TOUCH)}) ===')
for f in TOUCH: print(f'  {f}')
if LEFT:
    print(f'\n=== Còn trỏ chỗ cũ mà máy không tự quyết được ({sum(LEFT.values())} chỗ) — `specs/br.md` giờ là nhiều lát, `specs/contexts/` / `specs/internal/` không còn ===')
    for f, k in sorted(LEFT.items(), key=lambda t: -t[1])[:30]: print(f'  {k:3}  {f}')
print(f'\n=== CẦN TAY ({len(NEED)}) ===')
for i, (w, p) in enumerate(NEED, 1): print(f'  {i:2}. {w}\n      @ {p}')
print()
if DRY: print('--dry-run: chưa đụng đĩa. Chạy lại không có --dry-run để làm thật.')
else:
    print('Chưa commit — script cố ý không commit hộ. Đọc git status, làm các mục CẦN TAY (hoặc để sau), rồi:')
    print("  git add -A && git commit -m 'chore(sdd): migrate bố cục 7.0 — core|nghề × br-###, tầng 0 vision.md'")
    print('Sau đó: /sdd-solo:init --update (khuôn mới, dọn khuôn cũ) · /sdd-solo:status · gate-check từng UC đang mở.')
PY
  exit $?
fi

# ── --evidence BR-### : tách thân ## Background sang specs/br.evidence.md ────
# 5.0.0. Đo ở runxops: BR-001 dài 73 KB thì ## Background 31,8 KB — 15 mục ###
# chứng cứ đo từ dữ liệu thật ("982/1986 ô có nhiều hơn một dòng"). Chứng cứ là
# thứ làm BR đứng vững LÚC VIẾT; sau đó nó là thứ mọi lượt đọc đều phải lội qua,
# và số đo tháng 9/2026 sang năm sau là dấu vết chứ không còn là hiệu lực.
# Giữ trong br.md: mọi `### heading` (mục lục) + mọi đoạn bắt đầu bằng `**`
# (`**Vì sao vẫn xây:**`, `**Nguồn brief:**` — br-check đọc chúng). Thân đi.
if [ -n "$EV" ]; then
  [ "$EV" = "_" ] && { echo "Dùng: migrate.sh --evidence BR-### [--dry-run]" >&2; exit 2; }
  python3 - "$ROOT/specs/br.md" "$ROOT/specs/br.evidence.md" "$EV" "$DRY" "$(today)" <<'PY'
import sys, re, io
brp, evp, BR, dry, today = sys.argv[1:6]; dry = dry == "1"
s = io.open(brp, encoding='utf-8').read()
m = re.search(r'(?ms)^# ' + re.escape(BR) + r':.*?(?=^# BR-|\Z)', s)
if not m: print(f"  ✗ không thấy '# {BR}:' trong specs/br.md"); sys.exit(1)
sec = m.group(0)
bg = re.search(r'(?ms)^## Background[ \t]*\n(.*?)(?=^## |\Z)', sec)
if not bg: print(f"  ✗ {BR} không có ## Background"); sys.exit(1)
body = bg.group(1)
bg_done = '→ specs/br.evidence.md' in body
if bg_done: print(f"  ✓ {BR} ## Background đã tách rồi — không làm lại")
paras = [] if bg_done else re.split(r'\n[ \t]*\n', body.strip('\n'))
keep, move, cur = [], [], '(mở đầu)'
nmove = 0
for pgh in paras:
    first = pgh.lstrip().split('\n', 1)[0]
    if first.startswith('### '):
        cur = first[4:].strip()
        keep.append(first + '\n→ specs/br.evidence.md')
        move.append(('### ' + cur, None))
        rest = pgh.split('\n', 1)[1] if '\n' in pgh else ''
        if rest.strip(): move.append((None, rest)); nmove += 1
    elif first.startswith('**'):
        keep.append(pgh)
    else:
        move.append((None, pgh)); nmove += 1
kb0 = len(body.encode()) / 1024
newbody = body if bg_done else ('\n\n'.join(keep) + '\n\n')
kb1 = len(newbody.encode()) / 1024
if not bg_done: print(f"  {BR} ## Background: {kb0:.1f} KB → {kb1:.1f} KB · dời {nmove} đoạn, giữ {len(keep)} dòng heading/**")
# 5.1.0 — ## Adversarial pass của BR cùng loại dấu vết (cùng bảng đo 5.0.0: 6,5 KB ở
# BR-001), nhưng khác UC một chỗ: Phase 1 ĐƯỢC PHÉP còn `___`. Nên dòng đếm phải in số
# `___` ra mặt tiền — nợ lộ ở chỗ ai cũng đọc, thay vì chôn ở dòng 300 — chứ không
# phải "đã áp hết". Giữ chữ "Ngày chạy:" vì br-check §10 grep đúng chuỗi đó.
ap = re.search(r'(?ms)^## Adversarial pass[ \t]*\n(.*?)(?=^## |\Z)', sec)
ap_move = None
if ap and 'Ngày chạy' in ap.group(1) and '→ specs/br.evidence.md' not in ap.group(1) \
      and not re.search(r'YYYY-MM-DD|<[^>\n]+>', ap.group(1)):
    ab = ap.group(1)
    d = re.search(r'Ngày chạy:\s*(\d{4}-\d{2}-\d{2})', ab).group(1)
    qs = re.findall(r'(?m)^\s*-\s*Q\d+\b.*$', ab)
    blank = sum(1 for q in qs if re.search(r'→\s*`?___', q))
    noarrow = sum(1 for q in qs if '→' not in q)
    applied = len(qs) - blank - noarrow
    onv = re.search(r'trên v(\d+)', ab)
    line = (f'- Ngày chạy: {d} · 3 vai' + (f' · trên v{onv.group(1)}' if onv else '') +
            f' · {len(qs)} câu → {applied} đã áp · {blank + noarrow} → ___ → specs/br.evidence.md')
    ap_move = (ab.rstrip('\n') + '\n', line)
    print(f"  {BR} ## Adversarial pass: {len(ab.encode())/1024:.1f} KB → 1 dòng · {len(qs)} câu, {applied} đã áp, {blank + noarrow} còn ___")
if ap and 'Ngày chạy' in ap.group(1) and '→ specs/br.evidence.md' in ap.group(1):
    print(f"  ✓ {BR} ## Adversarial pass đã tách rồi — không làm lại")
if bg_done and not ap_move:
    sys.exit(0)
if dry:
    print("  --dry-run: chưa đụng đĩa"); sys.exit(0)
try: ev = io.open(evp, encoding='utf-8').read()
except FileNotFoundError:
    ev = ('# Chứng cứ — thân ## Background của specs/br.md\n\n'
          '<!-- Sinh bởi migrate.sh --evidence. Đây là CHỨNG CỨ lúc viết BR (số đo, trích dẫn dài),\n'
          '     không phải thứ đang hiệu lực. br.md giữ mục lục ### trỏ về đây. context.sh và\n'
          '     decisions.sh không đọc file này; cần tra "hồi đó đo ra sao" thì mở. -->\n')
if not bg_done:
    ev += f'\n## {BR} — ## Background — tách {today}\n'
    for h, t in move:
        if h: ev += f'\n{h}\n'
        else: ev += t + '\n'
sec2 = sec[:bg.start(1)] + newbody + sec[bg.end(1):]
if ap_move:
    ev += f'\n## {BR} — ## Adversarial pass — tách {today}\n' + ap_move[0]
    ap2 = re.search(r'(?ms)^## Adversarial pass[ \t]*\n(.*?)(?=^## |\Z)', sec2)
    sec2 = sec2[:ap2.start(1)] + ap_move[1] + '\n\n' + sec2[ap2.end(1):]
io.open(evp, 'w', encoding='utf-8').write(ev)
s2 = s[:m.start()] + sec2 + s[m.end():]
io.open(brp, 'w', encoding='utf-8').write(s2)
print(f"  ✓ đã ghi specs/br.evidence.md và cập nhật specs/br.md — chưa commit")
print(f"  git add specs/br.md specs/br.evidence.md && git commit -m 'docs({BR}): dời dấu vết BR sang br.evidence.md'")
PY
  exit $?
fi

DIRS="$(find "$ROOT/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | sort)"
if [ -z "$DIRS" ]; then
  ok "specs/ không có thư mục 00N-* nào — không có gì để tách"
  exit 0
fi

echo "=== Tách cây Spec Kit ra khỏi specs/ ==="
[ "$DRY" = "1" ] && info "--dry-run: KHÔNG đụng đĩa, chỉ in ra sẽ làm gì"

DEST="$ROOT/.speckit/work"
N=0; NAMES=""
for d in $DIRS; do
  b="$(basename "$d")"; NAMES="$NAMES $b"
  CNT="$(find "$d" -type f 2>/dev/null | wc -l | tr -d ' ')"
  printf '  specs/%s  →  .speckit/work/%s   (%s file)\n' "$b" "$b" "$CNT"
  if [ "$DRY" = "0" ]; then
    mkdir -p "$DEST"
    # git mv giữ history; repo chưa track thì lùi về mv thường.
    if git -C "$ROOT" ls-files --error-unmatch "specs/$b" >/dev/null 2>&1; then
      git -C "$ROOT" mv "specs/$b" ".speckit/work/$b" 2>/dev/null || mv "$d" "$DEST/$b"
    else
      mv "$d" "$DEST/$b"
    fi
  fi
  N=$((N+1))
done

# Đường dẫn trong file: nếu không sửa, plan.md tự trỏ về một chỗ không còn gì.
#
# Tìm và sửa theo TÊN THƯ MỤC THẬT SỰ VỪA DỜI, không theo dạng `specs/00N-`.
# Bản 4.0.0 dùng regex chung nên nó viết lại cả một CÂU VÍ DỤ trong tài liệu
# vendor của Spec Kit (`.claude/skills/speckit-specify/SKILL.md`: *"for example,
# `specs/003-user-auth`"*) — `003-user-auth` không hề tồn tại trong repo, và sau
# lượt sed thì file vendor nói sai về chính công cụ nó tả. Cùng luật đã dùng cho
# `strip_markup()`: liệt kê đích danh thì KHÔNG THỂ đụng nhầm, chứ không phải
# ít khả năng đụng nhầm. Hụt thì hụt về phía an toàn.
echo
echo "=== Đường dẫn trỏ tới chỗ cũ ==="
# KHÔNG dùng `grep -r`. Đệ quy của grep là thứ máy người dùng quyết, không phải
# ta: trên máy này `grep` tương tác là ugrep, và ugrep TÔN TRỌNG .gitignore.
# Ca sát sườn: `.specify/feature.json` — file migrate BẮT BUỘC phải sửa — nằm
# trong `.specify/.gitignore`. Một grep biết đọc .gitignore (ripgrep, ugrep,
# git grep) trả rỗng ở đó, và migrate im lặng để lại một con trỏ chết. Hụt kiểu
# này không có dòng đỏ nào: danh sách ngắn đi trông y hệt "không có gì để sửa".
# `find | xargs` bỏ hẳn phụ thuộc vào ngữ nghĩa đệ quy của grep.
# `/dev/null` là toán hạng luôn có: nó ép grep in tên file kể cả khi chỉ còn một
# file, và chặn grep quay ra đọc stdin khi find không ra gì.
FILES="$(find "$ROOT" -type f \( -name '*.md' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' \) \
         -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null)"
HITS=""
for b in $NAMES; do
  H="$(printf '%s\n' "$FILES" | grep -v '^$' | tr '\n' '\0' \
       | xargs -0 grep -nF "specs/$b" /dev/null 2>/dev/null)"
  [ -n "$H" ] && HITS="$(printf '%s\n%s' "$HITS" "$H")"
done
HITS="$(printf '%s' "$HITS" | grep -v '^$' | head -40)"
if [ -z "$HITS" ]; then
  ok "không file nào trỏ tới thư mục vừa dời"
else
  printf '%s\n' "$HITS" | sed 's/^/  /'
  if [ "$DRY" = "0" ]; then
    printf '%s\n' "$HITS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
      [ -f "$f" ] || continue
      for b in $NAMES; do
        sed -i.bak "s#specs/$b#.speckit/work/$b#g" "$f" && rm -f "$f.bak"
      done
    done
    ok "đã sửa đường dẫn tới thư mục vừa dời trong những file trên"
  else
    info "--dry-run: chưa sửa file nào"
  fi
fi

echo
if [ "$DRY" = "1" ]; then
  printf 'Sẽ tách %s thư mục. Chạy lại KHÔNG có --dry-run để làm thật.\n' "$N"
  exit 0
fi
printf 'Đã tách %s thư mục. specs/ giờ chỉ còn cây của sdd-solo.\n' "$N"
echo "Đọc lại git status rồi tự commit — script cố ý không commit hộ:"
echo "  git add -A && git commit -m 'chore(sdd): tách cây Spec Kit ra .speckit/work (4.0.0)'"
