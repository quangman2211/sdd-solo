# P-38: tên thẻ HTML trong văn xuôi (`<tr>`) bị --pre coi là placeholder
nr p38
ins_after "$UC1" "- SCR-001-1 Danh sách đơn" "Không dùng bảng vì \`<tr>\` không bọc được link — mỗi dòng là một vùng chạm."
S gate-check.sh --pre UC-001
chk "P-38 · --pre không coi <tr> trong nháy mã là chưa điền (được exit $R)" '[ $R = 0 ]'
