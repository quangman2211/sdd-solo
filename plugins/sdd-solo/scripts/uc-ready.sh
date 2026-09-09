#!/usr/bin/env bash
# uc-ready.sh UC-### — đủ điều kiện chạy adversarial pass chưa. exit 0 = đủ.
# Bốn tiền điều kiện cũ ở skills/adversarial đo CẤU TRÚC nên template rỗng qua
# hết: 4 dòng Main Flow đánh số, 2 AC, 2 E#, 3 dòng Screens — mà cả file còn 23
# placeholder. Và /sdd-solo:start copy chính template đó. Xem #11.
ID="$1"; [ -z "$ID" ] && { echo "dùng: uc-ready.sh UC-###"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; F="$(find_uc "$ID" "$ROOT")"
echo "Sẵn sàng adversarial — $ID"
[ -z "$F" ] && { bad "không tìm thấy file UC"; exit 1; }

grep -qE '^[0-9]+\.' "$F" && ok "Main Flow có bước đánh số" || bad "Main Flow chưa có bước nào"
A="$(grep -cE '^### AC-[0-9]+' "$F")"; [ "$A" -ge 1 ] && ok "$A AC" || bad "chưa có AC nào"
E="$(grep -cE '^- +(\*\*)?E[0-9]+[.:]' "$F")"; [ "$E" -ge 1 ] && ok "$E exception" || bad "chưa có E# nào"
grep -qE 'SCR-[0-9]+-[0-9]+' "$F" && ok "bảng Screens có SCR-###-#" || bad "bảng Screens chưa có SCR nào"

# Đây mới là chốt thật: còn placeholder nghĩa là chưa ai viết nội dung.
# NGOẠI LỆ: '___' nằm trong ## Open Questions là hợp lệ. Bản trước tính nó là
# placeholder, nên người viết trung thực '- [ ] <câu hỏi> (quyết định tạm: ___)'
# bị chặn, và lối thoát duy nhất là BỊA một giá trị — đúng thứ cả tầng BR sinh ra
# để chặn. gate-check §8 cho qua, br-check chỉ cảnh báo; chỉ script này chặn.
# '<...>' thì vẫn đỏ ở mọi chỗ, kể cả trong Open Questions. Xem #23.
PHALL="$(awk '
  /^## Open Questions/ { oq=1; dl=0; next }
  # ## Đọc lại là mục của bước ⑧, mà script này chạy ở bước ⑦ — nó CÒN NGUYÊN
  # template là đúng lịch, không phải chưa điền. Không bỏ qua thì uc-ready đỏ,
  # adversarial từ chối chạy, và không có đường nào ra: muốn qua bước ⑦ phải
  # điền trước một mục chỉ tồn tại sau bước ⑦.
  /^## Đọc lại/ { dl=1; oq=0; next }
  /^## / { oq=0; dl=0 }
  {
    if (dl) next
    ang = ($0 ~ /<[^>]+>/); us = ($0 ~ /___/)
    if (!ang && !us) next
    if ($0 ~ /^[[:space:]]*<!--/) next
    if ($0 ~ /Ngày chạy|đầu ra/) next
    if (oq && !ang) next
    printf "%d:%s\n", NR, $0
  }' "$F")"
PN="$(printf '%s\n' "$PHALL" | awk 'NF' | wc -l | tr -d ' ')"
if [ "$PN" -gt 0 ]; then
  bad "còn $PN chỗ chưa điền — adversarial pass trên spec rỗng là vô ích:"
  printf '%s\n' "$PHALL" | head -8 | sed 's/^/      /'
else
  ok "không còn placeholder"
fi
OQU="$(sed -n '/^## Open Questions/,/^## /p' "$F" | grep -c '___')"; [ -z "$OQU" ] && OQU=0
[ "$OQU" -gt 0 ] && info "$OQU chỗ ___ trong Open Questions — hợp lệ, không tính là chưa điền"

# entities.md và glossary.md của context: CẢNH BÁO, không chặn.
# Ba vai đọc hai file này làm đầu vào. Chạy khi chúng còn là template thì mô hình
# đổi sau đó và AC phải sửa lời — chi phí thật, nhưng không đủ lớn để khoá người
# dùng ra khỏi bước ⑦. Chặn ở đây là lặp lại đúng hình lỗi của #23. Xem #24.
CTX_="$(ctx_of "$F")"; EF="$ROOT/specs/contexts/$CTX_/entities.md"
if [ ! -f "$EF" ]; then
  warn "context $CTX_ chưa có entities.md — ba vai sẽ hỏi mà không có mô hình để đối chiếu"
elif grep -qE '(class|## )Entity[AB]([^A-Za-z0-9]|$)' "$EF" 2>/dev/null; then
  warn "entities.md của $CTX_ còn EntityA/EntityB của template — mô hình đổi sau adversarial thì AC phải sửa lời"
fi
grep -qE '<Thuật ngữ>|<Context A>' "$ROOT/specs/glossary.md" 2>/dev/null &&   warn "specs/glossary.md còn là template — ba vai và code sẽ gọi cùng một thứ bằng những tên khác nhau"

echo
if [ "$FAIL" -eq 0 ]; then echo "ĐỦ ĐIỀU KIỆN — chạy ba vai được ($WARN cảnh báo)."; exit 0; fi
echo "CHƯA ĐỦ — $FAIL lỗi, $WARN cảnh báo. Viết xong nội dung rồi chạy lại."; exit 1
