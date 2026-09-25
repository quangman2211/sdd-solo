# 8.10.0 — thư mục `screens/` không được tự mọc ở mọi UC.
#
# `start` chép `screens/README.md` vô điều kiện, nên mọi UC đều có một thư mục giao diện kể cả UC
# không có giao diện nào. Đo trên runxops 25/09: 21 UC có `screens/`, **10 trong đó chỉ chứa mỗi
# README** — gần một nửa là ngăn kéo trống, đúng thứ ranh giới 5.0.0 cấm ("khuôn không rơi vào dự án
# trừ khi có script/skill đọc hoặc user điền"). Không script nào ĐÒI thư mục đó: `mmd_lint` bỏ qua
# file không có, và `uc-steps` bước ⑤ tìm file KHÁC README nên không thư mục = bước chưa làm, đúng.
# Ai vẽ thì người đó tạo, lúc có cái để bỏ vào.
nr scr
# đo ĐÚNG cái nó định đo: danh sách file `start` TẠO không được có screens — chứ không phải "đừng
# nhắc chữ screens", vì văn mới PHẢI nhắc nó để nói ai tạo và lúc nào.
chk "danh sách file start tạo không có screens" \
  '! grep -qE "copy .UC-000[.]md[^)]*screens" "$P/skills/start/SKILL.md"'
chk "và nói rõ ai tạo nó, lúc nào" \
  'grep -q "Do NOT create" "$P/skills/start/SKILL.md" && grep -q "step ⑤" "$P/skills/start/SKILL.md"'
chk "khuôn vẫn GIỮ screens/ — để người vẽ có cái mà chép" \
  '[ -f "$P/templates/skel/use-case/screens/README.md" ]'
# và phần cơ học phải chạy được trên một UC KHÔNG có thư mục đó
rm -rf "$(dirname "$UC1")/screens"
cm "docs(UC-001): bỏ thư mục screens rỗng"
S gate-check.sh --pre UC-001
chk "cổng-trước vẫn xanh khi không có thư mục screens/ (exit $R)" '[ $R = 0 ]'
chk "cổng đọc BẢNG Screens trong thân UC, không đọc thư mục" 'has "Screens table has a SCR"'
S uc-steps.sh UC-001
chk "uc-steps chạy được, bước ⑤ là chưa làm chứ không phải lỗi (exit $R)" \
  '[ $R = 0 ] && has "screens"'
S gate-check.sh UC-001
chk "cổng đầy đủ không đỏ vì thiếu thư mục screens/" '! has "screens/"'
