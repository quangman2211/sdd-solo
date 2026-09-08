#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
P="$(printf '%s %s' "$(code_paths "$ROOT")" "$(test_paths "$ROOT")" | tr ' ' '\n' | awk 'NF&&!a[$0]++' | tr '\n' ' ' | sed 's/ *$//')"
total=$(git -C "$ROOT" log --format=%s -- $P 2>/dev/null | grep -vE '^chore\(sdd\)' | wc -l | tr -d ' ')
traced=$(git -C "$ROOT" log --format=%s -- $P 2>/dev/null | grep -cE '\((UC|BR|RULE|ADR|CHG)-[0-9]+\)')
if [ "$total" = "0" ] && repo_has_code "$ROOT"; then
  # 0/0 đọc như "sạch" trong khi thật ra là "mù" — repo có code mà không nằm
  # trong đường dẫn đang đếm.
  echo "Trace ratio: ? — repo có file nguồn nhưng không commit nào đụng: $P"
  echo "            → sửa code_paths/test_paths trong .sdd/config"
else
  echo "Trace ratio (commit trong $(printf '%s' "$P" | sed 's/ /, /g') có ID): $traced/$total"
fi
