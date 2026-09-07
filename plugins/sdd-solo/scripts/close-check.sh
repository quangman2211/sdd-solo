#!/usr/bin/env bash
# close-check.sh UC-### — Definition of Done. exit 0 = đóng được.
ID="$1"; [ -z "$ID" ] && { echo "dùng: close-check.sh UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
echo "Definition of Done — $ID"
[ -z "$F" ] && { bad "không tìm thấy file UC"; exit 1; }
CTX="$(ctx_of "$F")"; SLUG="$(slug_of "$F")"
[ -f "$ROOT/.sdd/gate/$ID.ok" ] && ok "đã qua cổng DoR" || bad "chưa có marker .sdd/gate/$ID.ok — chạy /sdd-solo:gate"
# test theo AC
TD="$ROOT/tests/use-cases/$CTX/$ID"
for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
  ls "$TD"/AC-$n.test.* >/dev/null 2>&1 && ok "AC-$n có test" || bad "AC-$n chưa có tests/use-cases/$CTX/$ID/AC-$n.test.*"
done
# thứ tự docs → feat
D0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^docs($ID)" | head -1)"
F0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^feat($ID)" | head -1)"
if [ -z "$F0" ]; then warn "chưa có commit feat($ID) — commit code trước khi close"
elif [ -n "$D0" ] && [ "$D0" -lt "$F0" ]; then ok "docs($ID) đứng trước feat($ID)"; else bad "feat($ID) không có docs($ID) đứng trước"; fi
# rule ngầm: số literal trong src của UC
SD="$(cd "$ROOT" && find src -type d -name "$SLUG" 2>/dev/null | head -1)"
if [ -n "$SD" ]; then
  L="$(cd "$ROOT" && grep -rnE '(=|>|<|>=|<=|==) *[0-9]{2,}\b' "$SD" 2>/dev/null | grep -vE '\.(test|spec)\.[a-z]+:|RULE-|CON-|ADR-' | head -8)"
  [ -n "$L" ] && { warn "số literal cần soi (phải trích RULE/CON hoặc giải thích):"; echo "$L" | sed 's/^/      /'; } || ok "không thấy số literal lạ trong src/…/$SLUG"
else warn "không tìm thấy src/**/$SLUG để soi rule ngầm"; fi
grep -qE '^- v[0-9]+ ' "$F" && ok "History có dòng" || bad "History rỗng"
git -C "$ROOT" status --porcelain 2>/dev/null | grep -q . && warn "còn thay đổi chưa commit"
echo
if [ "$FAIL" -eq 0 ]; then echo "ĐÓNG ĐƯỢC ($WARN cảnh báo)."; exit 0; else echo "CHƯA ĐÓNG — $FAIL lỗi."; exit 1; fi
