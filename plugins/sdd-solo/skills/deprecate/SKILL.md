---
name: deprecate
description: Bỏ một UC (viết lại hoặc không làm nữa) cho tử tế — Status deprecated, History v+1 ghi lý do + UC thay thế, gỡ marker cổng .sdd/gate/UC-###.ok, một dòng specs/internal/decisions.md, bảng use-cases.md của context, một commit. Dùng khi user nói "bỏ UC này", "viết lại thành UC khác", "deprecated".
disable-model-invocation: true
argument-hint: "UC-### [--by UC-###] [lý do]"
allowed-tools: Bash Read Edit AskUserQuestion
---

Bỏ `$1`.

**Vì sao có lệnh này (#45):** ở runxops chủ dự án chọn viết lại UC-009 và UC-012 — đặt `Status: deprecated` bằng tay,
nhưng `.sdd/gate/UC-009.ok` và `UC-012.ok` vẫn còn (githook vẫn cho commit `feat(UC-009)`), `status.sh` không nói gì,
History và `decisions.md` ghi tay và quên, STATE ghi nợ nhiều ngày. Bốn việc rời nhau thì một việc luôn bị bỏ sót.

1. Tìm UC: `find specs/contexts -path "*use-cases/$1-*/$1.md"`. Không có → dừng, báo.
   Status đã `deprecated` và không còn marker → nói "đã bỏ rồi", dừng.
2. **Lý do và UC thay thế** — hai thứ History phải ghi. Lấy từ `$ARGUMENTS` (`--by UC-###` và phần chữ còn lại).
   Thiếu lý do → hỏi **bằng lời** một câu: *"bỏ vì sao — viết lại, gộp vào UC khác, hay không làm nữa?"*. Thiếu UC
   thay thế → hỏi bằng `AskUserQuestion`: mỗi UC `draft` trong `specs/contexts/*/use-cases.md` một lựa chọn, thêm
   *"UC mới chưa mở — ghi ID dự kiến"* và *"không có UC thay thế"*. Không tự chọn.
3. Nếu UC đã `implemented` và có code gắn `($1)`: nói rõ **code không bị đụng** — bỏ UC chỉ là bỏ *spec đang hiệu
   lực*; gỡ code là việc của CHG (Phase 5) hoặc của UC thay thế. Không xoá file UC, không xoá thư mục.
4. Chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/pass.sh" deprecate $1 --by <UC-### | ->  "<lý do>"
```
(không thay được biến: `find ~/.claude/plugins -type f -name pass.sh -path '*sdd-solo*' | head -1`.)
   Script làm đúng năm việc, một commit `docs($1): deprecated — <lý do>`:
   - `**Status:** deprecated` + `Last updated` hôm nay trong file UC;
   - `## History` v+1: `deprecated — <lý do> · thay bằng <UC-###>`;
   - gỡ `.sdd/gate/$1.ok` (githook từ đó chặn `feat($1)`: UC bỏ rồi thì không có commit code nào mang tên nó nữa);
   - cột Status trong bảng `use-cases.md` của context → `deprecated`;
   - một dòng `specs/internal/decisions.md`: `- <ngày> — Bỏ $1 (<lý do>). Loại: giữ $1. Chi tiết: <UC thay thế>`.
   In nguyên output.
5. `## Related Use Cases` của BR cha còn trỏ `$1` → nói với user, đề nghị sửa tay (đổi sang UC thay thế); không tự
   sửa BR.
6. STATE.md: `Đang làm: <UC thay thế> · bước ① — kế thừa từ $1`; `Việc tiếp theo: /sdd-solo:start <UC thay thế>` (nếu
   chưa mở). Nhắc `/sdd-solo:state`.

`/sdd-solo:status` từ 6.4.0 cảnh báo *"marker cổng của UC deprecated"* và *"UC deprecated còn trong STATE"* — nếu
ai đó bỏ UC bằng tay thay vì lệnh này thì vẫn có chỗ nhắc.

Không viết code. Không xoá file. Không đụng UC thay thế.
