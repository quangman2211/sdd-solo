# 7.0.1: tên lát có dấu · (orders · báo đơn · kênh Telegram) — br-check nhận ra
nr lat
rep specs/vision.md '| orders | lát 1 "báo đơn" |' '| orders | báo đơn · kênh Telegram |'
rep specs/orders/br-001/br.md '- **Lát:** orders · lát 1 "báo đơn"' '- **Lát:** orders · báo đơn · kênh Telegram'
S br-check.sh BR-001
chk "br-check: lát 'báo đơn · kênh Telegram' nhận ra" 'has "slice: orders · báo đơn · kênh Telegram — present"'
