# I-4 (#43): context.sh bỏ ba mục vết của UC, in RULE được trích
nr ctx
S context.sh UC-001
chk "context.sh exit 0 (được $R)" '[ $R = 0 ]'
chk "không in dòng F1 của ## Đọc lại" '! has "F1 Main 2 nói gửi"'
chk "in RULE-001 được trích" 'has "RULE-001"'
S context.sh UC-001 --brief
chk "--brief exit 0 (được $R)" '[ $R = 0 ]'
