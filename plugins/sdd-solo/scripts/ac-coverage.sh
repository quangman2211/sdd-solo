#!/usr/bin/env bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
acs=$(grep -rhoE '^### AC-[0-9]+' "$ROOT/specs/contexts" --include='UC-*.md' --exclude-dir='_template' 2>/dev/null | wc -l | tr -d ' ')
tests=$(find "$ROOT/tests/use-cases" -name 'AC-*.test.*' 2>/dev/null | wc -l | tr -d ' ')
echo "AC coverage (AC có file test / tổng AC): $tests/$acs"
