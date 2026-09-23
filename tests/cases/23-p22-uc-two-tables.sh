# P-22: một UC nằm trong bảng Related Use Cases của HAI lát — không phép kiểm nào đỏ
nr p22
mkdir -p specs/core/br-002
sed 's/# BR-001: Bán hàng không rơi đơn/# BR-002: Lõi báo/; s/BR-001/BR-002/g; s/- \*\*Lát:\*\* orders · lát 1 "báo đơn"/- **Lát:** core · lát 1 "báo đơn"/' specs/orders/br-001/br.md > specs/core/br-002/br.md
S br-check.sh BR-001
chk "P-22 · br-check đỏ khi UC-001 có ở hai bảng BR" 'hasE "UC-001.*(hai|2) bảng|trùng.*UC-001"'
