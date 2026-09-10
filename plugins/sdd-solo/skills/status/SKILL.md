---
name: status
description: Xem đang ở đâu — STATE.md, danh sách UC theo status và cổng, trace ratio và AC coverage đếm bằng git; và sổ tra mọi quyết định của dự án xếp theo thời gian. Dùng khi user hỏi "đang tới đâu", "còn UC nào", "tỷ lệ commit có ID", "dự án đã quyết những gì", "có luật gì rồi", "cấm cái gì".
allowed-tools: Bash Read
---

Chạy và diễn giải ngắn (không lặp lại nguyên văn):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/status.sh"
```
Có mục `=== Version ===` thì nói ngay: mỗi dòng lệch đã kèm sẵn lệnh đúng cho **đúng khe** đó — ③ `/sdd-solo:init --update`, ② `/plugin update`, ① `/plugin marketplace update`. Đừng bảo user chạy cả ba.

Cuối output có mục `=== Phụ thuộc ===` thì nghĩa là thiếu một phụ thuộc **bắt buộc** (chỉ còn `git` và repo đã init) — nói ngắn thiếu gì. Đủ thì script im, đừng nhắc tới.

Nói: đang ở UC nào bước nào; UC nào đã qua cổng nhưng chưa implemented (đang code); UC draft còn lại; hai con số cuối và chúng có đang xấu đi so với lần user hỏi trước không (nếu biết). Không đề xuất viết code.

---

User hỏi **dự án đã quyết những gì** — "có luật gì rồi", "cấm cái gì", "sao hồi đó chọn thế",
"còn ràng buộc nào không" — thì đó KHÔNG phải `status.sh`. Chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/decisions.sh"
```
Nó gom CON · RULE · ADR · Cấm · CHG · ghi chú từ sáu chỗ về một dòng thời gian. Luôn exit 0,
không phải cổng. Và chiều ngược lại — *"UC này do cái gì quyết định?"*, *"sao tính năng này lại
thế?"* — là:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/context.sh" UC-### --why
```
chỉ in RULE · CON · ADR mà UC đó trích, kèm `## Cấm` của architecture. Hai lệnh là hai chiều của
cùng một câu hỏi: `decisions.sh` đi từ thời gian xuống quyết định, `--why` đi từ một UC lên.
`decisions.sh` luôn exit 0,
không phải cổng. In nguyên bảng cho user đọc — đây là bảng để **mắt người** đối chiếu, đừng
tóm tắt nó thành vài câu.

Ba khối cuối, nếu có, phải nói ra chứ đừng bỏ qua:
- **Quá hạn kiểm lại** — một ràng buộc tới hẹn xem lại mà chưa ai xem. Ràng buộc hết đúng khi
  *thế giới* đổi, và thế giới đổi thì không có gì trong repo động đậy; đây là lưới duy nhất.
- **Chưa có ngày** — không xếp được vào dòng thời gian. Nói thẳng đây là thứ duy nhất trong
  bộ tài liệu không tái tạo được: hai quyết định mất ngày thì sau này không ai dựng lại được
  cái nào ra trước khi chúng đá nhau.
- **`br.md` còn nguyên khuôn** — những dòng in ra là ví dụ dạy việc, chưa phải quyết định của
  dự án. Nói user chạy `/sdd-solo:intake` trước.
