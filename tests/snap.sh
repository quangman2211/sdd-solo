#!/usr/bin/env bash
# tests/snap.sh <repo> <thư mục ra> [plugin] — chụp đầu ra MỌI script kiểm trên một repo thật
# (bỏ màu, bỏ dòng version/ngày). Dùng để so "không hồi quy": chụp trước và sau khi sửa plugin trên
# bản sao runxops (6.x chưa migrate và 7.0), rồi `diff -r`. Quy trình ở CLAUDE.md của repo plugin.
R="$1"; O="$2"; P="${3:-$(cd "$(dirname "$0")/../plugins/sdd-solo" && pwd)}"
[ -d "$R" ] && [ -n "$O" ] || { echo "dùng: snap.sh <repo> <thư mục ra> [plugin]" >&2; exit 2; }
mkdir -p "$O"; cd "$R" || exit 1; export CLAUDE_PROJECT_DIR="$R"
clean() { sed 's/\x1b\[[0-9;]*m//g' | grep -vE 'version|Version|GitHub|plugin-dir|--- context.sh'; }
for u in $(find specs -path '*/use-cases/UC-*/UC-*.md' -not -name '*.flow.md' -not -name '*.sequence.md' -not -name '*.trace.md' 2>/dev/null | sed -E 's#.*/(UC-[0-9]+)\.md#\1#' | sort -u); do
  bash "$P/scripts/gate-check.sh" --pre "$u" 2>&1 | clean > "$O/gate-pre-$u.txt"
  bash "$P/scripts/gate-check.sh" "$u" 2>&1 | clean > "$O/gate-$u.txt"
  bash "$P/scripts/design-check.sh" "$u" 2>&1 | clean > "$O/design-$u.txt"
  bash "$P/scripts/close-check.sh" "$u" 2>&1 | clean > "$O/close-$u.txt"
  bash "$P/scripts/uc-steps.sh" "$u" 2>&1 | clean > "$O/steps-$u.txt"
  bash "$P/scripts/context.sh" "$u" 2>&1 | clean > "$O/ctx-$u.txt"
  bash "$P/scripts/context.sh" "$u" --brief 2>&1 | clean > "$O/ctxb-$u.txt"
  bash "$P/scripts/context.sh" "$u" --why 2>&1 | clean > "$O/ctxw-$u.txt"
done
for b in $(bash -c ". '$P/scripts/lib.sh'; br_ids '$R'" 2>/dev/null); do bash "$P/scripts/br-check.sh" "$b" 2>&1 | clean > "$O/br-$b.txt"; done
bash "$P/scripts/status.sh" 2>&1 | clean > "$O/status.txt"
bash "$P/scripts/metrics.sh" 2>&1 | clean > "$O/metrics.txt"
bash "$P/scripts/decisions.sh" 2>&1 | clean > "$O/decisions.txt"
bash "$P/scripts/layer-check.sh" 2>&1 | clean > "$O/layer.txt"
for c in $(ls -d specs/changes/CHG-* 2>/dev/null | sed -E 's#.*/(CHG-[0-9]+).*#\1#'); do bash "$P/scripts/change-check.sh" "$c" 2>&1 | clean > "$O/chg-$c.txt"; done
bash "$P/scripts/session-start.sh" 2>&1 | clean | sed 's/session-[a-z0-9-]*//' > "$O/session.txt"
echo "$(ls "$O" | wc -l | tr -d ' ') file → $O"
