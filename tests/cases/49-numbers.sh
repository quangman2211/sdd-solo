# 8.0.0: gom câu hỏi số — ô trống trong bảng là tham số, và nói rõ UC nào đang chờ nó
nr num
# một RULE có tham số còn trống, và UC-001 trích RULE-001 (fixture đã trích sẵn)
app specs/rules.md ''
app specs/rules.md '## RULE-009: Trần gửi lại'
app specs/rules.md ''
app specs/rules.md '| Tham số | Giá trị | Ý nghĩa |'
app specs/rules.md '|---|---|---|'
app specs/rules.md '| `Notify.maxRetries` | `___` | Gửi lại tối đa mấy lần |'
app specs/rules.md '| `Notify.window` | 15 phút | Cửa sổ gộp |'
app specs/rules.md '- Một câu văn có `___` ở giữa, đây là văn xuôi chứ không phải tham số.'
ins_after "$UC1" '## Dependencies' '- Theo RULE-009'
S numbers.sh
chk "chạy được, exit 0, đếm được ba loại (exit $R)" '[ $R = 0 ] && hasE "blank\(s\): [0-9]+ in tables"'
chk 'ô ___ đứng một mình trong ô bảng → param, có tên tham số' 'hasE "param +RULE-009 Notify.maxRetries"'
chk "ô có giá trị thật không bị đếm" '! has "Notify.window"'
chk "câu văn có ___ là prose, không phải param" 'hasE "prose"'
chk "nói rõ UC nào đang chờ RULE-009" 'hasE "RULE-009 Notify.maxRetries" && has "blocks: UC-001"'
S numbers.sh --rules-only
chk "--rules-only chỉ giữ ô bảng" 'has "Notify.maxRetries" && ! hasE "^ +[0-9]+ +prose"'
S numbers.sh UC-001
chk "numbers.sh UC-001 chỉ soi UC đó + rules/ADR (exit $R)" '[ $R = 0 ] && has "for UC-001" && has "Notify.maxRetries"'
# repo không còn ô trống nào → nói thẳng
nr num2
node -e 'const fs=require("fs");for(const f of process.argv.slice(1)){fs.writeFileSync(f,fs.readFileSync(f,"utf8").split("___").join("5"));}' $(grep -rl '___' specs --include='*.md' | grep -v '\.trace\.md')
S numbers.sh
chk "không còn ô trống → nói rõ đã quyết hết (exit $R)" '[ $R = 0 ] && has "nothing is blank"'
