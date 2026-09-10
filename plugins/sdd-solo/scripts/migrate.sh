#!/usr/bin/env bash
# migrate.sh [--dry-run] — 3.x → 4.0.0: tách cây của Spec Kit ra khỏi specs/.
#
#   specs/00N-<slug>/  →  .speckit/work/00N-<slug>/
#
# Vì sao: `.specify/scripts/bash/create-new-feature.sh` hardcode
# SPECS_DIR="$REPO_ROOT/specs" và `get_highest_from_specs` quét `specs/*` để lấy
# số kế tiếp — nó đang đếm cả br.md, contexts/, changes/ của sdd-solo. Hai hệ ID
# (`001-` và `UC-###`), hai cây spec, một thư mục, không bên nào biết bên kia.
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
N=0
for d in $DIRS; do
  b="$(basename "$d")"
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
# Chỉ sửa tiền tố `specs/00N-` — không đụng những dòng trỏ vào specs/contexts/,
# vì đó là cây của sdd-solo và nó KHÔNG dời đi đâu cả.
echo
echo "=== Đường dẫn trỏ tới chỗ cũ ==="
HITS="$(grep -rn 'specs/[0-9][0-9][0-9]-' "$ROOT" \
        --include='*.md' --include='*.json' --include='*.yml' --include='*.yaml' \
        --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null | head -40)"
if [ -z "$HITS" ]; then
  ok "không file nào trỏ tới specs/00N-*"
else
  printf '%s\n' "$HITS" | sed 's/^/  /'
  if [ "$DRY" = "0" ]; then
    printf '%s\n' "$HITS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
      [ -f "$f" ] || continue
      sed -i.bak 's#specs/\([0-9][0-9][0-9]-\)#.speckit/work/\1#g' "$f" && rm -f "$f.bak"
    done
    ok "đã sửa tiền tố specs/00N- → .speckit/work/00N- trong những file trên"
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
