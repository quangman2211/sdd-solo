#!/usr/bin/env bash
# change-pass.sh CHG-### — chạy SAU khi change-check exit 0: status applying, marker, commit.
set -e
ID="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; D="$(find_chg "$ID" "$ROOT")"; [ -z "$D" ] && exit 1
P="$D/proposal.md"
python3 - "$P" "$(today)" <<'PY'
import sys,re
p,d=sys.argv[1],sys.argv[2]; s=open(p,encoding='utf-8').read()
s=re.sub(r'(?m)^(## Status\n+)[a-z]+\s*$', r'\1applying', s)
s=re.sub(r'(?m)^(## History\n)', r'\1', s)
if '## History' in s and f'{d}: designed -> applying' not in s:
    s=s.rstrip('\n')+f'\n- {d}: designed -> applying (qua cổng Phase 5)\n'
open(p,'w',encoding='utf-8').write(s)
PY
mkdir -p "$ROOT/.sdd/gate"
git -C "$ROOT" commit -q --only -m "docs($ID): change reviewed — qua cổng Phase 5" -- "$P" || true
git -C "$ROOT" rev-parse HEAD > "$ROOT/.sdd/gate/$ID.ok"
git -C "$ROOT" add ".sdd/gate/$ID.ok" && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $ID" -- ".sdd/gate/$ID.ok" || true
printf 'QUA CỔNG PHASE 5. Status -> applying · marker .sdd/gate/%s.ok · đã commit.\n' "$ID"
echo "Bước tiếp: viết test cho AC mới (đỏ trước) rồi sửa code. Commit code gắn ($ID)."
echo "Xong hết thì merge delta vào specs/, History UC v+1, và chore($ID): archive."
