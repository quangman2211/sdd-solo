#!/usr/bin/env bash
# br-scope-diff.sh BR-### [<rev>] — "được và mất": In Scope · Out of Scope · Đã loại khỏi brief của BR
# trong cây làm việc so với <rev> (mặc định HEAD). In dòng thêm (+) / bớt (−) từng mục, không diễn giải.
#
# Vì sao (7.0, plan §1): BR-003 của runxops co ba lần qua ba lượt adversarial — mỗi lượt áp phiếu đều
# hợp lệ, và không lượt nào nói ra "BR sẽ co từ gì thành gì". Skill adversarial gọi script này trước
# khi ghi History v+1 rồi nói bằng lời thường cho chủ dự án gật. Script chỉ đếm; lời là việc của skill.
ID="$1"; REV="${2:-HEAD}"
[ -z "$ID" ] && { echo "dùng: br-scope-diff.sh BR-### [<rev>]"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; BF="$(br_file "$ID" "$ROOT")"
[ -f "$BF" ] || { bad "không có ${BF#$ROOT/}"; exit 1; }
REL="${BF#$ROOT/}"
OLD="$(git -C "$ROOT" show "$REV:$REL" 2>/dev/null)"
[ -z "$OLD" ] && { info "$REL chưa có ở $REV — mọi thứ là mới, không có gì để so"; exit 0; }
sec_of() { printf '%s\n' "$1" | awk -v h="# $ID:" 'index($0,h)==1{f=1;next} f&&/^# BR-/{exit} f{print}' \
           | awk -v s="$2" 'index($0,s)==1{f=1;next} f&&/^## /{exit} f{print}' | grep -E '^[[:space:]]*[-*] ' | sed -E 's/^[[:space:]]*[-*] +//'; }
CH=0
echo "=== $ID — được và mất so với $REV ==="
for S in '## In Scope' '## Out of Scope' '## Đã loại khỏi brief'; do
  A="$(sec_of "$OLD" "$S")"; B="$(sec_of "$(cat "$BF")" "$S")"
  ADD="$(printf '%s\n' "$B" | grep -vxF -f <(printf '%s\n' "$A") | grep -v '^$')"
  DEL="$(printf '%s\n' "$A" | grep -vxF -f <(printf '%s\n' "$B") | grep -v '^$')"
  [ -z "$ADD" ] && [ -z "$DEL" ] && continue
  CH=$((CH+1))
  printf '%s\n' "$S"
  [ -n "$DEL" ] && printf '%s\n' "$DEL" | sed 's/^/  − /' | cut -c1-140
  [ -n "$ADD" ] && printf '%s\n' "$ADD" | sed 's/^/  + /' | cut -c1-140
done
if [ "$CH" -eq 0 ]; then ok "In Scope · Out of Scope · Đã loại không đổi so với $REV"
else
  echo
  info "đọc cho chủ dự án bằng lời thường: BR co từ gì thành gì (dòng − ở In Scope, + ở Out of Scope), mở thêm gì (ngược lại); gật rồi mới ghi History v+1"
  info "dòng + ở Out of Scope trùng từ khoá ## Không thu hẹp của specs/vision.md thì br-check sẽ đỏ — trừ khi chủ dự án chốt 'cố ý thu hẹp — chủ dự án chốt YYYY-MM-DD'"
fi
