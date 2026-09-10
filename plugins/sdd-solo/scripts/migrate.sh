#!/usr/bin/env bash
# migrate.sh [--dry-run] — 3.x → 4.0.0: tách cây của Spec Kit ra khỏi specs/.
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
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

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
