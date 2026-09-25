# 8.11.0 — kho KHÔNG có gì để nhận vào phải hành xử y hệt 8.10.0, byte cho byte.
#
# Cùng bảo đảm `tool_paths` đưa ra ở #31: repo chưa khai thì mọi dòng mới là no-op. Đây là ca giữ cho
# một bản minor thật sự là minor — nếu nó đỏ thì bản này đổi hành vi của mọi repo đang chạy.
nr adopt4
chk "repo scaffold trên kho trắng KHÔNG có adopt_from" \
  '! grep -qE "^adopt_from=." .sdd/config'
S adopt.sh
chk "adopt.sh nói thẳng là không có gì để nhận (exit $R)" '[ $R = 0 ] && has "no adoption baseline"'
chk "và không dựng đứng một bảng đếm rỗng" '! has "ever touched"'

printf 'const z = 1;\n' > src/z.js 2>/dev/null || { mkdir -p src; printf 'const z = 1;\n' > src/z.js; }
cmv "feat: code moi khong ID"
chk "kho trắng: code không ID vẫn bị chặn đúng như trước" \
  'git log -1 --format=%s | grep -qv "code moi khong ID"'
chk "và KHÔNG in một dòng nhận-vào nào" \
  '! grep -q "adoption baseline" "$W/hookerr.txt"'
S status.sh
chk "status không mọc thêm mục Adoption trên kho trắng" '! has "Adoption ("'
