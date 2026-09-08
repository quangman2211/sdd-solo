#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"; ROOT="$(project_root)"
echo "=== STATE.md ==="; cat "$ROOT/STATE.md" 2>/dev/null || echo "(chưa có)"
echo; echo "=== UC theo status ==="
for f in $(find "$ROOT/specs/contexts" -path '*/use-cases/UC-*/UC-*.md' -not -path '*_template*' -not -name '*.sequence.md' 2>/dev/null | sort); do
  id="$(basename "$f" .md)"; st="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$f" | head -1 | awk '{print $2}')"
  g=""; [ -f "$ROOT/.sdd/gate/$id.ok" ] && g=" · gate ✓"
  printf '  %-8s %-12s%s\n' "$id" "${st:-?}" "$g"
done
echo; "$HERE/trace-ratio.sh"; "$HERE/ac-coverage.sh"
# phụ thuộc: chỉ nói khi thiếu, đủ thì im
D="$("$HERE/deps-check.sh" 2>&1)" || { echo; echo "$D"; }
# đường dẫn code/test: sai là githook chặn hụt trong im lặng
if ! has_code_path "$ROOT"; then
  echo; echo "=== .sdd/config ==="
  if repo_has_code "$ROOT"; then
    bad "code_paths=$(code_paths "$ROOT") — không thư mục nào tồn tại, mà repo đã có file nguồn."
    info "githook đang chặn hụt. Sửa .sdd/config cho khớp bố cục thật."
  else
    warn "code_paths=$(code_paths "$ROOT") — chưa thư mục nào tồn tại (repo chưa có code)."
  fi
fi
# version: hỏi GitHub tối đa 3s, nhớ 24h. Chỉ nói khi lệch.
V="$("$HERE/version-check.sh" --remote 2>&1)" || { echo; echo "$V"; }
