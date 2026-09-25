# 8.11.0 — `## Existing code`: mục khai duy nhất được thêm, và nó chỉ SIẾT.
#
# Với một UC nhận vào, close-check mất cả hai nguồn dựng tập file code: nguồn ① cần một commit mang
# ID và code cũ không có, nguồn ② cần code đặt tên theo slug UC và code cũ không thế. Nên `NF_=0`, và
# phép quét số literal — một trong những phép sắc nhất của bộ — im lặng KHÔNG chạy đúng trên thứ code
# có nhiều thời gian tích số ma thuật nhất, trong khi dòng đỏ lại đi sửa `code_paths`, sai chỗ.
# Mục này là nguồn ③. Ba phép kiểm ở cổng đều SIẾT — không phép nào cho lọt thứ cổng vốn chặn — và
# phép (a) là thứ giữ nó khỏi thành cửa sau: không khai được mã viết hôm qua là "có sẵn".
nr adopt8
mkdir -p src; printf 'const rate = 7;\n' > src/legacy.js
cm "chore(sdd): them ma cu" 2026-01-11

# (b) ngoài code_paths → đỏ
printf "\n## Existing code\n- notes/khong-phai-code.md\n" >> "$UC1"
cm "docs(UC-001): khai ma ngoai code_paths" 2026-01-12
S gate-check.sh UC-001
chk "khai một đường dẫn ngoài code_paths → cổng ĐỎ" 'has "outside code_paths/test_paths"'

# đường dẫn thật trong code_paths → xanh ở mục này
rep "$UC1" '- notes/khong-phai-code.md' '- src/legacy.js'
cm "docs(UC-001): khai ma that" 2026-01-13
S gate-check.sh UC-001
chk "khai một đường dẫn thật → mục này không còn đỏ" '! has "outside code_paths/test_paths"'
chk "và cổng nói đã đếm được" 'has "declared as existing code"'

# nguồn ③ làm close-check ĐỌC ĐƯỢC mã của UC nhận vào
S close-check.sh UC-001
chk "close-check tìm ra mã qua nguồn ③, không còn 'no code file can be read'" \
  '! has "no code file can be read"'
chk "và nói rõ có bao nhiêu file đến từ mục khai" 'has "declared in"'
chk "phép quét số literal THẬT SỰ chạy trên mã nhận vào" \
  'has "literal number" || has "no stray literal number"'

# (c) hai UC cùng khai một file → đỏ: một file, một UC
UC2="$(dirname "$UC1")/../UC-002-khac/UC-002.md"
mkdir -p "$(dirname "$UC2")"
printf '# UC-002\n\n## Existing code\n- src/legacy.js\n' > "$UC2"
cm "docs(UC-002): khai trung file" 2026-01-14
S gate-check.sh UC-001
chk "hai UC cùng khai một file → ĐỎ" 'has "already declared by"'
