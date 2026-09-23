---
name: deprecate
description: Bỏ một UC (viết lại hoặc không làm nữa) cho tử tế — Status deprecated, History v+1 ghi lý do + UC thay thế, gỡ marker cổng .sdd/gate/UC-###.ok, một dòng specs/decisions.md, bảng Related Use Cases trong br.md của lát, một commit. Dùng khi user nói "bỏ UC này", "viết lại thành UC khác", "deprecated".
disable-model-invocation: true
argument-hint: "UC-### [--by UC-###] [lý do]"
allowed-tools: Bash Read Edit AskUserQuestion
---

Bỏ `$1`.

**Chế độ phiếu (7.3) — khi chạy dưới lời giao của agent khác** (lời giao mở đầu `Vai:`/`Lượt`, hoặc
`bash .sdd/scripts/role.sh --xem` ra một vai không phải điều phối, hoặc không chắc có người ở đầu kia): **không mở
`AskUserQuestion`** — không ai bấm, lượt treo tới hết hạn (#53). Mỗi câu lẽ ra hỏi user thành một phiếu:
`bash .sdd/scripts/phieu.sh new "<việc>" <vai>` với Câu · Đã tra · Nếu chọn sai thì · Agent nghiêng về; chỗ phụ thuộc
câu đó để `___` + quyết định tạm; rồi **DỪNG** và kết bằng `role.sh --ketqua <khoá> ket=chan hoi=#<n>`. Chủ dự án tự
gõ lệnh này trong phiên của mình thì hỏi như thường.

**Vì sao có lệnh này (#45):** ở runxops chủ dự án chọn viết lại UC-009 và UC-012 — đặt `Status: deprecated` bằng tay,
nhưng `.sdd/gate/UC-009.ok` và `UC-012.ok` vẫn còn (githook vẫn cho commit `feat(UC-009)`), `status.sh` không nói gì,
History và `decisions.md` ghi tay và quên, STATE ghi nợ nhiều ngày. Bốn việc rời nhau thì một việc luôn bị bỏ sót.

1. Tìm UC: `find specs -path "*/br-*/use-cases/$1-*/$1.md"`. Không có → dừng, báo.
   Status đã `deprecated` và không còn marker → nói "đã bỏ rồi", dừng.
2. **Lý do và UC thay thế** — hai thứ History phải ghi. Lấy từ `$ARGUMENTS` (`--by UC-###` và phần chữ còn lại).
   Thiếu lý do → hỏi **bằng lời** một câu: *"bỏ vì sao — viết lại, gộp vào UC khác, hay không làm nữa?"*. Thiếu UC
   thay thế → hỏi bằng `AskUserQuestion`: mỗi UC `draft` trong bảng `## Related Use Cases` của mọi `specs/*/br-*/br.md` một lựa chọn, thêm
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
   - cột Status trong bảng `## Related Use Cases` của `br.md` lát đó → `deprecated`;
   - một dòng `specs/decisions.md` (gốc): `- <ngày> — Bỏ $1 (<lý do>). Loại: giữ $1. Chi tiết: <UC thay thế>`.
   In nguyên output.
5. Bảng `## Related Use Cases` của lát còn trỏ `$1` ở dòng nào khác (hay lát khác cũng trỏ tới) → nói với user, đề nghị
   sửa tay (đổi sang UC thay thế); không tự sửa BR. UC thay thế nằm ở **lát khác** thì nói rõ nó sẽ được tạo ở
   `specs/<core|nghề>/br-###/use-cases/` nào — `/sdd-solo:start` hỏi lát, không suy từ UC cũ.
6. STATE.md: `Đang làm: <UC thay thế> · bước ① — kế thừa từ $1`; `Việc tiếp theo: /sdd-solo:start <UC thay thế>` (nếu
   chưa mở). Nhắc `/sdd-solo:state`.

`/sdd-solo:status` từ 6.4.0 cảnh báo *"marker cổng của UC deprecated"* và *"UC deprecated còn trong STATE"* — nếu
ai đó bỏ UC bằng tay thay vì lệnh này thì vẫn có chỗ nhắc.

Không viết code. Không xoá file. Không đụng UC thay thế.
