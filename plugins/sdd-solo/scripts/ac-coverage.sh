#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; UCT="$(uc_test_dir "$ROOT")"
acs=$(grep -rhoE '^### AC-[0-9]+' "$ROOT/specs/contexts" --include='UC-*.md' 2>/dev/null | wc -l | tr -d ' ')
tests=$(find "$ROOT/$UCT" -name 'AC-*.test.*' 2>/dev/null | wc -l | tr -d ' ')
if [ "$tests" = "0" ] && [ ! -d "$ROOT/$UCT" ] && [ "$acs" != "0" ]; then
  echo "AC coverage: ? — chưa có thư mục $UCT (kiểm uc_test_dir trong .sdd/config). Tổng AC: $acs"
else
  echo "AC coverage (AC có file test / tổng AC): $tests/$acs"
fi
