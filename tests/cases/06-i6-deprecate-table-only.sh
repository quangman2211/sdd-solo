# #51 (I-6): pass.sh deprecate cho UC chỉ có dòng trong bảng, chưa có file
nr dep
ins_after specs/orders/br-001/br.md '| UC-001 | Báo đơn mới |' '| UC-009 | Đơn huỷ | Seller | BR-001 | draft |'
cm "docs(BR-001): thêm UC-009 vào bảng"
S pass.sh deprecate UC-009 gộp vào UC-001
chk "exit 0 (được $R)" '[ $R = 0 ]'
chk "bảng UC-009 → deprecated" 'grep -q "^| UC-009 .*| deprecated |$" specs/orders/br-001/br.md'
chk "decisions có dòng Bỏ UC-009" 'grep -q "Bỏ UC-009 (" specs/decisions.md'
chk "đã commit, cây sạch" '[ -z "$(git status --porcelain specs)" ] && git log -1 --format=%s | grep -q "^docs(UC-009): deprecated"'
chk "nói chưa có file UC" 'has "has no UC file"'
S pass.sh deprecate UC-077 x
chk "ID không có ở đâu → exit 1 (được $R)" '[ $R = 1 ]'
