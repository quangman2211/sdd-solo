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
# Toàn bộ logic ở js/migrate.mjs: tách file theo heading, dựng bảng UC, sửa đường dẫn theo tên thật
# vừa dời (cùng luật với phần Spec Kit bên dưới — liệt kê đích danh, không regex chung). Bash chỉ
# tìm khuôn: chạy từ plugin thì `templates/` ở cạnh; chạy từ bản sao .sdd/scripts/ thì hỏi bản
# plugin đang cài; không có thì js/migrate.mjs dùng khung tối thiểu và ghi vào bảng "cần tay".
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
  need_node "migrate.sh --layout v7"
  node "$HERE/js/migrate.mjs" layout "$ROOT" "$DRY" "$MAPF" "${TPLD:+$TPLD/skel}" "${TPLD:+$TPLD/project}" "$(uc_test_dir "$ROOT")" "$(today)" "$(code_paths "$ROOT")" "$(test_paths "$ROOT")"
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
  # 7.0: đường qua lib — 6.x specs/br.md · specs/br.evidence.md; 7.0 br.md · evidence.md của lát. Dòng đếm để lại
  # trỏ `→ <tên file evidence tương đối với br.md>` (br-check nhận `→ .*evidence\.md`).
  need_node "migrate.sh --evidence"
  node "$HERE/js/migrate.mjs" evidence "$(br_file "$EV" "$ROOT")" "$(evidence_file "$EV" "$ROOT")" "$EV" "$DRY" "$(today)"
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
