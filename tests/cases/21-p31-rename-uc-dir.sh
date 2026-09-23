# P-31: git mv thư mục UC sang lát khác + sửa Metadata → cổng đọc như đổi hành vi toàn bộ?
nr p31
mkdir -p specs/orders/br-002/use-cases
sed 's/# BR-001: Bán hàng không rơi đơn/# BR-002: Đơn về đúng lát/; s/br-001/br-002/g; s/BR-001/BR-002/g' specs/orders/br-001/br.md > specs/orders/br-002/br.md
git mv "$UCD" specs/orders/br-002/use-cases/UC-001-notify-order
UC1=specs/orders/br-002/use-cases/UC-001-notify-order/UC-001.md
rep "$UC1" '- **Nghề:** orders · **Lát:** BR-001' '- **Nghề:** orders · **Lát:** BR-002'
rep "$UC1" '- **Liên quan tới BR:** BR-001' '- **Liên quan tới BR:** BR-002'
app "$UC1" "- v3 (2026-01-06, anh): về nhà br-002"
cm "docs(UC-001): về nhà br-002" 2026-01-06
S gate-check.sh UC-001
chk "P-31 · đổi thư mục UC không bị đọc là đổi HÀNH VI (được exit $R)" '! has "spec đổi HÀNH VI"'
