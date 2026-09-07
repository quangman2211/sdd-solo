#!/usr/bin/env bash
# gate-pass.sh UC-### — chạy SAU khi gate-check exit 0: status reviewed, marker, commit.
set -e
ID="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
sed -i.bak -E 's/(\*\*Status:\*\* *)draft/\1reviewed/' "$F" && rm -f "$F.bak"
sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
mkdir -p "$ROOT/.sdd/gate"
git -C "$ROOT" commit -q --only -m "docs($ID): spec reviewed — qua cổng DoR" -- "$F" || true
git -C "$ROOT" rev-parse HEAD > "$ROOT/.sdd/gate/$ID.ok"
git -C "$ROOT" add ".sdd/gate/$ID.ok" && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $ID" -- ".sdd/gate/$ID.ok" || true
echo "QUA CỔNG. Status → reviewed · marker .sdd/gate/$ID.ok · đã commit. Bước tiếp: /specify (chỉ trích ID) → /plan"
