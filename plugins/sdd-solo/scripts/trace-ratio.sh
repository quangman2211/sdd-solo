#!/usr/bin/env bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
total=$(git -C "$ROOT" log --format=%s -- src tests 2>/dev/null | grep -vE '^chore\(sdd\)' | wc -l | tr -d ' ')
traced=$(git -C "$ROOT" log --format=%s -- src tests 2>/dev/null | grep -cE '\((UC|BR|RULE|ADR|CHG)-[0-9]+\)')
echo "Trace ratio (commit src/tests có ID): $traced/$total"
