# pass.sh gate → cổng vẫn xanh (nhánh gate-pass) → design/test/feat → close-check xanh → pass.sh close nén vết
nr gc
S pass.sh gate UC-001
chk "gate: Status reviewed + bảng reviewed + marker" 'grep -q "Status:\*\* reviewed" "$UC1" && grep -q "^| UC-001 .*| reviewed |$" specs/orders/br-001/br.md && [ -f .sdd/gate/UC-001.ok ]'
chk "gate: commit tiêu đề chuẩn" 'git log --format=%s | grep -q "^docs(UC-001): spec reviewed — qua cổng DoR$"'
S gate-check.sh UC-001
chk "gate-check sau gate-pass vẫn xanh (exit $R)" '[ $R = 0 ] && has "commit của gate-pass"'
code_uc1
S close-check.sh UC-001
chk "close-check xanh sau design + test + feat (exit $R)" '[ $R = 0 ]'
S pass.sh close UC-001
chk "close: Status implemented, bảng implemented" 'grep -q "Status:\*\* implemented" "$UC1" && grep -q "^| UC-001 .*| implemented |$" specs/orders/br-001/br.md'
chk "close: ba mục vết dời sang trace.md" '[ -f "$UCD/UC-001.trace.md" ] && grep -q "^## Đọc lại" "$UCD/UC-001.trace.md" && grep -c "→ UC-001.trace.md" "$UC1" | grep -q "^3$"'
chk "close: traceability +2 dòng AC" '[ "$(grep -c "| UC-001 | AC-" specs/traceability.md)" = 2 ]'
S gate-check.sh UC-001
chk "gate-check sau close: chỉ đỏ status implemented, không đỏ §9" 'has "status đã implemented" && ! has "spec đổi HÀNH VI"'
