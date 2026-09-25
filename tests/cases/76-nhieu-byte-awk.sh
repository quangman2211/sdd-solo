# 8.11.0 — không bao giờ nhảy qua một ký tự NHIỀU BYTE bằng một hằng số byte trong awk.
#
# `substr(t, i + 3)` sau `index(t, "→")` đúng với awk đếm BYTE (BSD awk của macOS, mawk) và SAI với awk
# đếm KÝ TỰ (gawk dưới locale UTF-8 — đúng thứ một runner Linux đưa cho), nơi mũi tên là MỘT ký tự chứ
# không phải ba. `length("→")` đúng ở cả hai.
#
# Đây không phải suy đoán: bộ test xanh trên macOS và đỏ trên ubuntu-latest đúng vì chỗ này, ở `rr_undecided`
# — luật đếm phát hiện còn tồn đọng, tức cái quyết định cổng Phase 5 có mở hay không. Cùng họ với bẫy
# CLAUDE.md đã ghi cho bash ("không đặt biến sát ký tự nhiều byte"), chỉ là ở awk.
#
# Kiểm TĨNH vì kiểm động cần hai awk khác nhau trên cùng một máy, thứ không có ở mọi nơi ca này chạy.
nr mb
chk "không còn substr(..., i + <số>) ngay sau index(..., \"→\")" \
  '! grep -rnE "index\([^)]*→[^)]*\)[^;]*substr\([^)]*\+ *[0-9]+\)" "$P/scripts/"'
chk "mọi DÒNG đi qua → đều dùng length(\"→\") trên chính dòng đó" \
  '! grep -rh "index(.*\"→\")" "$P/scripts/" | grep -v "length(\"→\")" | grep -q .'

# và phần cơ học vẫn cho đúng câu trả lời trên awk của máy đang chạy
N="$(printf -- '- F1 ... → Chưa quyết (chờ anh)\n- F2 ... → Đã quyết: xong\n' | (. "$P/scripts/lib.sh"; rr_undecided))"
chk "rr_undecided đếm đúng 1 tồn đọng thật (được $N)" '[ "$N" = 1 ]'
N2="$(printf -- '- F1 ... `→ Chưa quyết` nhắc lại → Đã quyết: xong\n' | (. "$P/scripts/lib.sh"; rr_undecided))"
chk "và không tính mũi tên nằm trong dấu nháy ngược (được $N2)" '[ "$N2" = 0 ]'
