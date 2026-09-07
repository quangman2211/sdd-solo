#!/usr/bin/env bash
# close-pass.sh UC-### — status implemented, traceability, commit.
set -e
ID="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
CTX="$(ctx_of "$F")"
sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed)/\1implemented/' "$F" && rm -f "$F.bak"
BR="$(grep -oE 'BR-[0-9]+' "$F" | head -1)"; RULES="$(grep -oE 'RULE-[0-9]+' "$F" | sort -u | tr '\n' ' ')"; ADRS="$(grep -oE 'ADR-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
TR="$ROOT/specs/traceability.md"
for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
  SCRS="$(sed -n '/^## Screens/,/^## /p' "$F" | grep -oE 'SCR-[0-9]+-[0-9]+' | sort -u | tr '\n' ' ')"
  echo "| $BR | $ID | AC-$n | $RULES | $SCRS | tests/use-cases/$CTX/$ID/AC-$n.test.* | $ADRS | implemented |" >> "$TR"
done
git -C "$ROOT" commit -q --only -m "docs($ID): implemented — traceability" -- "$F" "$TR" || true
echo "ĐÃ ĐÓNG $ID. Status → implemented · traceability +$(grep -cE '^### AC-' "$F") dòng · commit xong."
echo "Nhớ: cập nhật STATE.md (/sdd-solo:state) trước khi đóng máy."
