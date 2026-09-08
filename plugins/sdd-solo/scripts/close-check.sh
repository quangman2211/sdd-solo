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
UCT="$(uc_test_dir "$ROOT")"
TD="$ROOT/$UCT/$CTX/$ID"
for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
  ls "$TD"/AC-$n.test.* >/dev/null 2>&1 && ok "AC-$n có test" || bad "AC-$n chưa có $UCT/$CTX/$ID/AC-$n.test.*"
done
# thứ tự docs → feat
D0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^docs($ID)" | head -1)"
F0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^feat($ID)" | head -1)"
if [ -z "$F0" ]; then warn "chưa có commit feat($ID) — commit code trước khi close"
elif [ -n "$D0" ] && [ "$D0" -lt "$F0" ]; then ok "docs($ID) đứng trước feat($ID)"; else bad "feat($ID) không có docs($ID) đứng trước"; fi
# rule ngầm: số literal trong code của UC.
# Slug có thể là THƯ MỤC (src/domain/<slug>/index.js) hoặc FILE (src/domain/<slug>.js).
# Chỉ tìm thư mục thì với phần lớn dự án bước này không bao giờ chạy mà DoD vẫn xanh.
CP="$(code_paths "$ROOT")"
SD=""
for d in $CP; do
  [ -d "$ROOT/$d" ] || continue
  SD="$(cd "$ROOT" && find "$d" -type d -name "$SLUG" 2>/dev/null | head -1)"
  [ -n "$SD" ] && break
  SD="$(cd "$ROOT" && find "$d" -type f -name "$SLUG.*" 2>/dev/null | grep -vE '\.(test|spec)\.' | head -1)"
  [ -n "$SD" ] && break
done
if [ -n "$SD" ]; then
  # Bắt số sau so sánh, sau ':' (object literal), sau '=' và trong đối số/mảng.
  # Bỏ chỉ số mảng, 0/1 đứng một mình, số trong chuỗi và số version.
  L="$(cd "$ROOT" && grep -rnE '([=<>!]=?|:|,|\() *[0-9]{2,}\b' "$SD" 2>/dev/null \
       | grep -vE '\.(test|spec)\.[a-z]+:|RULE-|CON-|ADR-' \
       | grep -vE '\[[0-9]+\]|v?[0-9]+\.[0-9]+\.[0-9]+|"[^"]*[0-9]{2,}[^"]*"' \
       | head -8)"
  if [ -n "$L" ]; then
    warn "số literal cần soi (phải trích RULE/CON hoặc giải thích):"; echo "$L" | sed 's/^/      /'
    # Spec đã đánh dấu chỗ trống mà code đã điền số — loại rule ngầm đắt nhất.
    if grep -qiE '^\s*[-*] *(\[ \])? *(Open Question|Câu hỏi mở)' "$F" 2>/dev/null; then
      warn "$ID còn Open Question chưa đóng mà code đã có số — soi kỹ hai chỗ này với nhau"
    fi
  else
    ok "không thấy số literal lạ trong $SD"
  fi
elif [ -n "$F0" ]; then
  # Đã có commit feat mà không tìm thấy code của UC → không soi được rule ngầm,
  # đó là chưa đủ điều kiện đóng, không phải cảnh báo nhỏ.
  bad "đã có feat($ID) nhưng không tìm thấy code của $SLUG trong: $CP — sửa .sdd/config hoặc đặt tên file/thư mục theo slug"
else
  warn "chưa tìm thấy code của $SLUG trong: $CP — chưa soi được rule ngầm"
fi
grep -qE '^- v[0-9]+ ' "$F" && ok "History có dòng" || bad "History rỗng"
git -C "$ROOT" status --porcelain 2>/dev/null | grep -q . && warn "còn thay đổi chưa commit"
echo
if [ "$FAIL" -eq 0 ]; then echo "ĐÓNG ĐƯỢC ($WARN cảnh báo)."; exit 0; else echo "CHƯA ĐÓNG — $FAIL lỗi."; exit 1; fi
