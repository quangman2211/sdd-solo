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
PH="$(grep -nE '<[^>]+>|___' "$F" | grep -vE '^\s*[0-9]+:\s*<!--' | grep -vE 'Ngày chạy|đầu ra' | head -8)"
PN="$(grep -cE '<[^>]+>|___' "$F")"
if [ -n "$PH" ]; then
  bad "còn $PN chỗ chưa điền — adversarial pass trên spec rỗng là vô ích:"
  echo "$PH" | sed 's/^/      /'
else
  ok "không còn placeholder"
fi

echo
if [ "$FAIL" -eq 0 ]; then echo "ĐỦ ĐIỀU KIỆN — chạy ba vai được."; exit 0; fi
echo "CHƯA ĐỦ — $FAIL lỗi. Viết xong nội dung rồi chạy lại."; exit 1
