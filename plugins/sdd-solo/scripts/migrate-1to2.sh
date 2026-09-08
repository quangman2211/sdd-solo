#!/usr/bin/env bash
# migrate-1to2.sh — dời bố cục 1.x sang 2.0.0. Chạy MỘT lần, trong repo dự án.
#   .sdd/ giữ bộ máy · specs/ giữ toàn bộ nội dung
# Dùng git mv để giữ history. Idempotent: chạy lại không hỏng, chỉ bỏ qua
# những gì đã dời. Dừng ngay từ đầu nếu working tree bẩn — dừng giữa chừng ở
# một script dời file là trạng thái tệ nhất có thể.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; cd "$ROOT"
DRY=0; [ "$1" = "--dry-run" ] && DRY=1

LBL=""; [ "$DRY" = "1" ] && LBL=" (thử, không đụng file)"
printf 'migrate 1.x → 2.0.0 — %s%s\n' "$ROOT" "$LBL"
[ -d .git ] || { bad "không phải git repo"; exit 1; }
if [ "$DRY" = "0" ] && [ -n "$(git status --porcelain)" ]; then
  bad "working tree còn thay đổi chưa commit — commit hoặc stash trước đã."
  info "script này dời file bằng git mv; dừng giữa chừng thì rất khó lần."
  exit 1
fi

N=0
run() { # run <mô tả> <lệnh...>
  N=$((N+1)); if [ "$DRY" = "1" ]; then info "sẽ: $1"; else "${@:2}" && ok "$1" || { bad "$1"; exit 1; }; fi
}
DUP=""
DUP=""; SCAN=0
MOVED=""   # chế độ thử không đụng đĩa, phải tự nhớ thứ đã "dời" để khỏi liệt kê thừa
gone() { case " $MOVED " in *" $1 "*) return 0;; esac; return 1; }
mv1() { # mv1 <nguồn> <đích> — bỏ qua nếu nguồn không có, đã dời, hoặc đích đã có
  gone "$1" && return 0
  [ -e "$1" ] || return 0
  if [ -e "$2" ] && ! gone "$2"; then
    # Nguồn CÒN mà đích ĐÃ CÓ = hai cây cùng tồn tại. Không được im lặng bỏ qua:
    # nội dung thật ở $1, còn $2 nhiều khả năng là template rỗng do scaffold dựng.
    bad "$1 còn, mà $2 đã có — hai cây cùng tồn tại"
    DUP="$DUP $1"
    return 0
  fi
  [ "$DRY" = "0" ] && mkdir -p "$(dirname "$2")" 2>/dev/null
  MOVED="$MOVED $1"
  run "$1 → $2" git mv "$1" "$2"
}

do_moves() {
  # ── 1. hành vi về .sdd/ ─────────────────────────────────────────────────
  mv1 checklists   .sdd/checklists
  mv1 prompts      .sdd/prompts
  mv1 .gitmessage  .sdd/gitmessage
  mv1 .githooks    .sdd/hooks
  mv1 specs/contexts/_template            .sdd/templates/context
  mv1 .sdd/templates/context/use-cases/UC-000-template  .sdd/templates/use-case
  rmdir .sdd/templates/context/use-cases 2>/dev/null || true
  mv1 changes/_template                   .sdd/templates/change
  mv1 .sdd/templates/change/specs         .sdd/templates/change/delta

  # ── 2. nội dung về specs/ ───────────────────────────────────────────────
  # KHÔNG gác bằng [ ! -d specs/internal ]: đích tồn tại sẵn (do scaffold dựng)
  # thì cả khối bị bỏ qua trong im lặng và nội dung thật kẹt lại ở docs/. Để mv1
  # xét từng file — nó biết kêu ✗ khi cả hai bên cùng có. Xem #8.
  if [ -d docs ]; then
    [ "$DRY" = "0" ] && mkdir -p specs/internal
    for f in docs/* docs/.[!.]*; do [ -e "$f" ] || continue; mv1 "$f" "specs/internal/$(basename "$f")"; done
    rmdir docs 2>/dev/null || true
  fi
  if [ -d changes ]; then
    [ "$DRY" = "0" ] && mkdir -p specs/changes
    for f in changes/* changes/.[!.]*; do [ -e "$f" ] || continue; mv1 "$f" "specs/changes/$(basename "$f")"; done
    rmdir changes 2>/dev/null || true
  fi

  # ── 3. .bpmn của mỗi UC về thư mục UC ───────────────────────────────────
  # Ca thiếu .svg là bình thường (gate chỉ cảnh báo vàng) — không được dừng vì nó.
  for bp in specs/contexts/*/diagrams/UC-*.bpmn; do
    [ -e "$bp" ] || continue
    id="$(basename "$bp" .bpmn)"
    ucdir="$(find specs/contexts -type d -name "${id}-*" -path '*/use-cases/*' 2>/dev/null | head -1)"
    if [ -z "$ucdir" ]; then warn "$bp — không tìm thấy thư mục UC của $id, để nguyên"; continue; fi
    mv1 "$bp" "$ucdir/$id.bpmn"
    [ -e "$bp.svg" ] && mv1 "$bp.svg" "$ucdir/$id.bpmn.svg"
  done
}

# Quét trước, dời sau. Dừng giữa chừng ở một script dời file là trạng thái tệ
# nhất có thể — nên phát hiện 'hai cây cùng tồn tại' phải xảy ra TRƯỚC khi
# đụng file đầu tiên. Xem #8.
SCAN=1; REAL="$DRY"; DRY=1; do_moves >/dev/null 2>&1; DRY="$REAL"; SCAN=0
if [ -n "$DUP" ]; then
  bad "cây cũ và cây mới cùng tồn tại — chưa dời file nào"
  for d in $DUP; do info "$d còn, mà đích đã có"; done
  echo
  echo "Gần như chắc chắn vì đã chạy /sdd-solo:init --update TRƯỚC migrate: cây"
  echo "mới là template rỗng, nội dung thật vẫn ở chỗ cũ. Cách gỡ: so nội dung"
  echo "từng cặp, git rm -r cái rỗng, rồi chạy lại migrate."
  exit 1
fi
MOVED=""; FAIL=0; N=0
do_moves

# ── 4. git config trỏ chỗ mới ───────────────────────────────────────────
if [ -d .sdd/hooks ]; then
  run "core.hooksPath = .sdd/hooks" git config core.hooksPath .sdd/hooks
  chmod +x .sdd/hooks/* 2>/dev/null || true
fi
[ -f .sdd/gitmessage ] && run "commit.template = .sdd/gitmessage" git config commit.template .sdd/gitmessage

# ── 5. manifest viết lại theo đường dẫn mới ─────────────────────────────
# Sai chỗ này thì lần init --update sau ghi đè file user đã sửa tay.
if [ -f .sdd/manifest ] && [ "$DRY" = "0" ]; then
  python3 - <<'PY'
import re, pathlib
m = pathlib.Path(".sdd/manifest")
MAP = [("checklists/", ".sdd/checklists/"), ("prompts/", ".sdd/prompts/"),
       (".gitmessage", ".sdd/gitmessage"), ("docs/", "specs/internal/"),
       ("changes/_template/specs/", ".sdd/templates/change/delta/"),
       ("changes/_template/", ".sdd/templates/change/"), ("changes/", "specs/changes/"),
       ("specs/contexts/_template/use-cases/UC-000-template/", ".sdd/templates/use-case/"),
       ("specs/contexts/_template/", ".sdd/templates/context/"),
       ("src/README.md", ""), ("tests/README.md", "")]
out = []
for line in m.read_text(encoding="utf-8").splitlines():
    if not line.strip(): continue
    rel, rest = (line.split(" ", 1) + [""])[:2]
    for a, b in MAP:
        if rel.startswith(a):
            rel = "" if b == "" else b + rel[len(a):]
            break
    if rel: out.append(rel + " " + rest)
# Sau khi đổi tên, hai dòng có thể cùng trỏ một đường dẫn (một do scaffold ghi,
# một do đổi tên từ chỗ cũ). scaffold đọc dòng CUỐI, nên giữ đúng dòng cuối.
seen = {}
for line in out: seen[line.split(" ", 1)[0]] = line
out = list(seen.values())
m.write_text("\n".join(out) + "\n", encoding="utf-8")
print("  \033[32m✓\033[0m .sdd/manifest — viết lại %d dòng theo đường dẫn mới" % len(out))
PY
fi

echo
if [ "$DRY" = "1" ]; then echo "Thử xong — $N việc sẽ chạy. Bỏ --dry-run để làm thật."; exit 0; fi
if [ "$FAIL" -gt 0 ]; then echo "DỪNG — $FAIL lỗi. Repo đang dở, xem git status."; exit 1; fi
echo "Xong $N việc. Tiếp theo:"
echo "  1. /sdd-solo:init --update    (lấy .sdd/scripts/ và template 2.0.0)"
echo "  2. .sdd/scripts/gate-check.sh UC-###   — kiểm lại vài UC"
echo "  3. git add -A && git commit -m 'chore(sdd): migrate bố cục 2.0.0'"
