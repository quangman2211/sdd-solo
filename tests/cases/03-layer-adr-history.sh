# layer-check: ADR gốc trích RULE nghề ở ## History → xanh; ở ## Decision → đỏ, số dòng đúng
nr layer
printf '# Business Rules — orders\n\n## RULE-012: Đơn eBay\n- Phát biểu: x\n' > specs/orders/rules.md
mkdir -p specs/adr
printf '# ADR-001: Kho file\n\n## Decision\nDùng một kho.\n\n## History\n- v1 (2026-09-01): tách từ RULE-012 cũ\n' > specs/adr/ADR-001-kho.md
S layer-check.sh --file specs/adr/ADR-001-kho.md
chk "History trích RULE-012 → exit 0 (được $R)" '[ $R = 0 ]'
rep specs/adr/ADR-001-kho.md 'Dùng một kho.' 'Dùng một kho theo RULE-012.'
S layer-check.sh --file specs/adr/ADR-001-kho.md
chk "Decision trích RULE-012 → exit 1 (được $R), số dòng 4" '[ $R = 1 ] && has "4:Dùng một kho theo RULE-012"'
