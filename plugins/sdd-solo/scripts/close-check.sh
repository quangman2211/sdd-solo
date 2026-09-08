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
D0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^docs($ID)" 2>/dev/null | head -1)"
F0="$(git -C "$ROOT" log --reverse --format=%ct --grep="^feat($ID)" 2>/dev/null | head -1)"
if [ -z "$F0" ]; then warn "chưa có commit feat($ID) — commit code trước khi close"
elif [ -n "$D0" ] && [ "$D0" -lt "$F0" ]; then ok "docs($ID) đứng trước feat($ID)"; else bad "feat($ID) không có docs($ID) đứng trước"; fi
# rule ngầm: số literal trong code của UC.
# Slug có thể là THƯ MỤC (src/domain/<slug>/index.js) hoặc FILE (src/domain/<slug>.js).
# Chỉ tìm thư mục thì với phần lớn dự án bước này không bao giờ chạy mà DoD vẫn xanh.
CP="$(code_paths "$ROOT")"
# Gộp MỌI đường dẫn khớp, không head -1. Thư mục rỗng cạnh file thật (git mv
# để lại đúng như vậy — git không theo dõi thư mục rỗng) từng thắng file thật
# và biến DoD thành "sạch, 0 cảnh báo".
SDS=""
for d in $CP; do
  [ -d "$ROOT/$d" ] || continue
  SDS="$SDS $(cd "$ROOT" && find "$d" -type d -name "$SLUG" 2>/dev/null)"
  SDS="$SDS $(cd "$ROOT" && find "$d" -type f -name "$SLUG.*" 2>/dev/null)"
done
SDS="$(printf '%s' "$SDS" | tr ' ' '\n' | awk 'NF&&!a[$0]++')"
# Đếm file THẬT SỰ đọc được. 0 file = "không biết", không phải "sạch".
NF_=0
if [ -n "$SDS" ]; then
  NF_="$(cd "$ROOT" && find $SDS -type f 2>/dev/null | grep -vcE '\.(test|spec)\.' )"
fi
if [ "$NF_" -gt 0 ]; then
  # Lọc theo NGỮ CẢNH, không theo độ dài chữ số. Bản 1.6.0 dùng {2,} nên quét
  # sạch luôn ngưỡng nghiệp vụ một chữ số — mà đó là loại phổ biến nhất:
  # graceDays: 7 · maxRetries: 3 · otpLength: 6 · maxDevices: 1. Xem #9.
  # KHÔNG lọc chuỗi: pattern vốn không khớp số nằm sau dấu nháy, và thà dương
  # tính giả — đây là bước ngồi soi cùng user, không phải cổng chặn.
  L="$(cd "$ROOT" && grep -rnE '([=<>!]=?|:|,|\() *[0-9]+\b' $SDS 2>/dev/null \
       | grep -vE '\.(test|spec)\.[a-z]+:|RULE-|CON-|ADR-' \
       | grep -vE '\[[0-9]+\]' \
       | grep -vE '\b(i|j|k|n|idx|index)\b *[=<>!]=? *[0-9]+' \
       | grep -vE 'v?[0-9]+\.[0-9]+\.[0-9]+' \
       | head -8)"
  if [ -n "$L" ]; then
    warn "số literal cần soi (phải trích RULE/CON hoặc giải thích):"; echo "$L" | sed 's/^/      /'
    # Spec đã đánh dấu chỗ trống mà code đã điền số — rule ngầm đắt nhất.
    if grep -qiE '(Open Question|Câu hỏi mở)' "$F" 2>/dev/null && grep -qE '^[[:space:]]*[-*] \[ \]' "$F" 2>/dev/null; then
      warn "$ID còn Open Question chưa đóng mà code đã có số — soi hai chỗ này với nhau"
    fi
  else
    ok "không thấy số literal lạ trong $NF_ file của $SLUG"
  fi
elif [ -n "$F0" ]; then
  bad "đã có feat($ID) nhưng không đọc được file code nào cho $SLUG trong: $CP — sửa .sdd/config hoặc đặt tên file/thư mục theo slug"
else
  warn "chưa tìm thấy code của $SLUG trong: $CP — chưa soi được rule ngầm"
fi
grep -qE '^- v[0-9]+ ' "$F" && ok "History có dòng" || bad "History rỗng"
git -C "$ROOT" status --porcelain 2>/dev/null | grep -q . && warn "còn thay đổi chưa commit"
echo
if [ "$FAIL" -eq 0 ]; then echo "ĐÓNG ĐƯỢC ($WARN cảnh báo)."; exit 0; else echo "CHƯA ĐÓNG — $FAIL lỗi."; exit 1; fi
