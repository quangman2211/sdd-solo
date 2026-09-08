#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"; ROOT="$(project_root)"
echo "=== STATE.md ==="; cat "$ROOT/STATE.md" 2>/dev/null || echo "(chưa có)"
# Phase 1: BR có gì, và có đang xây trên nền chưa viết không
echo; echo "=== BR (Phase 1) ==="
BRS="$(br_ids "$ROOT")"
if [ -z "$BRS" ]; then
  warn "specs/br.md chưa có BR nào — chạy /sdd-solo:intake"
else
  for b in $BRS; do
    [ "$b" = "BR-000" ] && { printf '  %-9s %s\n' "$b" "(mẫu của template)"; continue; }
    # Khung chưa đụng tới in ra "draft" trông y hệt một BR thật đang viết dở.
    if grep -qE "^# $b: *<" "$ROOT/specs/br.md"; then
      printf '  %-9s %s\n' "$b" "(khung trống — /sdd-solo:intake)"; continue
    fi
    st="$(br_body "$b" "$ROOT" | sed -n 's/.*\*\*Status:\*\* *//p' | head -1 | awk '{print $1}')"
    printf '  %-9s %s\n' "$b" "${st:-?}"
  done
fi
UCN="$(find "$ROOT/specs/contexts" -path '*/use-cases/UC-*/UC-*.md' -not -name '*.sequence.md' -not -name '*.flow.md' 2>/dev/null | wc -l | tr -d ' ')"
if br_untouched "$ROOT"; then
  # (d) của #18 — xây trên nền chưa viết là loại sai đắt nhất vì nó ở gốc
  if [ "$UCN" -gt 0 ]; then
    bad "br.md vẫn là template mà đã có $UCN UC — đang xây trên nền chưa viết. Chạy /sdd-solo:intake."
  else
    info "br.md còn là template — bắt đầu bằng /sdd-solo:intake"
  fi
  # (e) của #19 — AIUP nhảy thẳng vào 'hệ thống làm gì', bỏ qua tầng 'vì sao làm'
  [ -f "$ROOT/docs/requirements.md" ] && \
    warn "có docs/requirements.md của AIUP mà specs/br.md chưa có BR — /requirements đã đi vòng qua tầng BR. Chạy /sdd-solo:intake trước."
fi

echo; echo "=== UC theo status ==="
for f in $(find "$ROOT/specs/contexts" -path '*/use-cases/UC-*/UC-*.md' -not -name '*.sequence.md' 2>/dev/null | sort); do
  id="$(basename "$f" .md)"; st="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$f" | head -1 | awk '{print $2}')"
  g=""; [ -f "$ROOT/.sdd/gate/$id.ok" ] && g=" · gate ✓"
  printf '  %-8s %-12s%s\n' "$id" "${st:-?}" "$g"
done
# Phase 5: change nào đang mở, đã qua cổng chưa
CD="$(ls -d "$ROOT/specs/changes/CHG-"* "$ROOT/changes/CHG-"* 2>/dev/null)"
if [ -n "$CD" ]; then
  echo; echo "=== Change đang mở (Phase 5) ==="
  for d in $CD; do
    id="$(basename "$d" | grep -oE '^CHG-[0-9]+')"
    st="$(awk 'index($0,"## Status")==1{f=1;next} f&&/^## /{exit} f&&NF{print;exit}' "$d/proposal.md" 2>/dev/null | tr -d "[:space:]")"
    g=""; [ -f "$ROOT/.sdd/gate/$id.ok" ] && g=" · gate ✓"
    printf '  %-9s %-12s%s\n' "$id" "${st:-?}" "$g"
  done
fi
echo; "$HERE/trace-ratio.sh"; "$HERE/ac-coverage.sh"
# phụ thuộc: chỉ nói khi thiếu, đủ thì im
D="$("$HERE/deps-check.sh" 2>&1)" || { echo; echo "$D"; }
# đường dẫn code/test: sai là githook chặn hụt trong im lặng
UCT_="$(uc_test_dir "$ROOT")"
if ! has_code_path "$ROOT" || [ ! -d "$ROOT/$UCT_" ]; then
  echo; echo "=== .sdd/config ==="
  if repo_has_code "$ROOT"; then
    bad "code_paths=$(code_paths "$ROOT") — không thư mục nào tồn tại, mà repo đã có file nguồn."
    info "githook đang chặn hụt. Sửa .sdd/config cho khớp bố cục thật."
  else
    warn "code_paths=$(code_paths "$ROOT") — chưa thư mục nào tồn tại (repo chưa có code)."
  fi
  # Nhắc lại chừng nào chưa khớp: `!` lúc init dễ trôi từ lần --update thứ hai
  # trở đi, khi người ta lướt qua output.
  [ -d "$ROOT/$UCT_" ] || warn "uc_test_dir=$UCT_ — thư mục chưa tồn tại, ac-coverage đang mù. Sửa cho khớp quy ước của repo."
fi
# version: hỏi GitHub tối đa 3s, nhớ 24h. Chỉ nói khi lệch.
V="$("$HERE/version-check.sh" --remote 2>&1)" || { echo; echo "$V"; }
