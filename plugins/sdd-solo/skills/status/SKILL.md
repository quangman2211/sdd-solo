---
name: status
description: Xem đang ở đâu — STATE.md, danh sách UC theo status và cổng, trace ratio và AC coverage đếm bằng git. Dùng khi user hỏi "đang tới đâu", "còn UC nào", "tỷ lệ commit có ID".
allowed-tools: Bash Read
---

Chạy và diễn giải ngắn (không lặp lại nguyên văn):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/status.sh"
```
Cuối output có mục `=== Phụ thuộc ===` thì nghĩa là đang thiếu Spec Kit hoặc AIUP — nói ngắn thiếu gì và gợi ý `/sdd-solo:init --with-deps`. Đủ thì script im, đừng nhắc tới.

Nói: đang ở UC nào bước nào; UC nào đã qua cổng nhưng chưa implemented (đang code); UC draft còn lại; hai con số cuối và chúng có đang xấu đi so với lần user hỏi trước không (nếu biết). Không đề xuất viết code.
