---
name: status
description: Xem đang ở đâu — STATE.md, danh sách UC theo status và cổng, trace ratio và AC coverage đếm bằng git. Dùng khi user hỏi "đang tới đâu", "còn UC nào", "tỷ lệ commit có ID".
allowed-tools: Bash Read
---

Chạy và diễn giải ngắn (không lặp lại nguyên văn):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/status.sh"
```
Có mục `=== Version ===` thì nói ngay: mỗi dòng lệch đã kèm sẵn lệnh đúng cho **đúng khe** đó — ③ `/sdd-solo:init --update`, ② `/plugin update`, ① `/plugin marketplace update`. Đừng bảo user chạy cả ba.

Cuối output có mục `=== Phụ thuộc ===` thì nghĩa là thiếu một phụ thuộc **bắt buộc** (chỉ còn `git` và repo đã init) — nói ngắn thiếu gì. Đủ thì script im, đừng nhắc tới.

Nói: đang ở UC nào bước nào; UC nào đã qua cổng nhưng chưa implemented (đang code); UC draft còn lại; hai con số cuối và chúng có đang xấu đi so với lần user hỏi trước không (nếu biết). Không đề xuất viết code.
