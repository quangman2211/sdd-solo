#!/usr/bin/env bash
# pass.sh <gate|close|change> <ID> — chạy SAU khi phép kiểm tương ứng exit 0.
#
# Gộp từ gate-pass.sh + close-pass.sh + change-pass.sh (4.0.0). Ba script cũ
# cùng một hình: đổi Status, ghi dấu vết, commit riêng. Giữ NGUYÊN từng câu chữ
# commit message và từng dòng in ra — githook và `gate-check` §9 nhận diện commit
# bằng tiêu đề, nên đổi một ký tự ở đây là mở một lỗ im lặng ở chỗ khác.
#
# Vì sao mode tường minh chứ không đoán theo tiền tố ID: `UC-###` đi qua HAI pass
# khác nhau (⑨ gate và ⑭ close). Tiền tố không phân biệt được hai cái đó, và một
# script tự đoán sai giữa "reviewed" với "implemented" thì hỏng im lặng.
set -e
MODE="${1:-}"; ID="${2:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
case "$MODE" in
  gate|close|change) ;;
  *) echo "Dùng: pass.sh <gate|close|change> <ID>" >&2; exit 2;;
esac
[ -z "$ID" ] && { echo "Dùng: pass.sh $MODE <ID>" >&2; exit 2; }
ROOT="$(project_root)"

# marker + commit marker — chung cho gate và change
mark() {
  mkdir -p "$ROOT/.sdd/gate"
  git -C "$ROOT" rev-parse HEAD > "$ROOT/.sdd/gate/$1.ok"
  git -C "$ROOT" add ".sdd/gate/$1.ok" \
    && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $1" -- ".sdd/gate/$1.ok" || true
}

case "$MODE" in

gate)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  sed -i.bak -E 's/(\*\*Status:\*\* *)draft/\1reviewed/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  git -C "$ROOT" commit -q --only -m "docs($ID): spec reviewed — qua cổng DoR" -- "$F" || true
  mark "$ID"
  printf 'QUA CỔNG. Status -> reviewed · marker .sdd/gate/%s.ok · đã commit.\n' "$ID"
  printf 'Bước tiếp: /sdd-solo:design %s — thiết kế trước khi viết dòng code đầu tiên.\n' "$ID"
  ;;

close)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  CTX="$(ctx_of "$F")"
  sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed)/\1implemented/' "$F" && rm -f "$F.bak"
  BR="$(grep -oE 'BR-[0-9]+' "$F" | head -1)"
  RULES="$(grep -oE 'RULE-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  ADRS="$(grep -oE 'ADR-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  TR="$ROOT/specs/traceability.md"
  for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
    SCRS="$(sed -n '/^## Screens/,/^## /p' "$F" | grep -oE 'SCR-[0-9]+-[0-9]+' | sort -u | tr '\n' ' ')"
    echo "| $BR | $ID | AC-$n | $RULES | $SCRS | tests/use-cases/$CTX/$ID/AC-$n.test.* | $ADRS | implemented |" >> "$TR"
  done
  git -C "$ROOT" commit -q --only -m "docs($ID): implemented — traceability" -- "$F" "$TR" || true
  echo "ĐÃ ĐÓNG $ID. Status → implemented · traceability +$(grep -cE '^### AC-' "$F") dòng · commit xong."
  echo "Nhớ: cập nhật STATE.md (/sdd-solo:state) trước khi đóng máy."
  ;;

change)
  D="$(find_chg "$ID" "$ROOT")"; [ -z "$D" ] && exit 1
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
  git -C "$ROOT" commit -q --only -m "docs($ID): change reviewed — qua cổng Phase 5" -- "$P" || true
  mark "$ID"
  printf 'QUA CỔNG PHASE 5. Status -> applying · marker .sdd/gate/%s.ok · đã commit.\n' "$ID"
  echo "Bước tiếp: viết test cho AC mới (đỏ trước) rồi sửa code. Commit code gắn ($ID)."
  echo "Xong hết thì merge delta vào specs/, History UC v+1, và chore($ID): archive."
  ;;

esac
