#!/usr/bin/env bash
# migrate.sh [--dry-run] — 3.x → 4.0.0: tách cây của Spec Kit ra khỏi specs/.
# migrate.sh --evidence BR-### [--dry-run] — 5.0.0: tách thân ## Background ra br.evidence.md;
#   5.1.0: tách thêm thân ## Adversarial pass, để lại dòng đếm có số ___ ở mặt tiền.
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
DRY=0; EV=""
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1;;
    --evidence) EV="_";;
    BR-[0-9]*) [ "$EV" = "_" ] && EV="$a";;
  esac
done

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
