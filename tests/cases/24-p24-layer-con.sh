# P-24: layer-check không đo CON-### — lõi trích ràng buộc của nghề vẫn xanh
nr p24
rep specs/orders/br-001/br.md '- **CON-001 Technical:** ...' '- **CON-001 Technical:** chỉ chạy được ở máy có Multilogin.'
mkdir -p specs/core/br-002
printf '# BR-002: Lõi\n\n## Goal\nLõi phải tôn trọng CON-001 của nghề.\n' > specs/core/br-002/br.md
S layer-check.sh --file specs/core/br-002/br.md
xfail P-24 "core trích CON-001 của nghề → đỏ (được exit $R)" '[ $R = 1 ]'
