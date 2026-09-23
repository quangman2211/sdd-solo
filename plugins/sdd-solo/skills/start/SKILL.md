---
name: start
description: Bước ① của vòng lặp UC — tạo folder use case từ template trong lát (br-###) của nó, gán ID, kiểm ID chưa trùng và BR tồn tại, ghi STATE.md. Dùng khi user bắt đầu một use case mới.
disable-model-invocation: true
argument-hint: "UC-### [BR-###] [<slug-tieng-anh>]"
allowed-tools: Bash Read Write Edit Glob Grep AskUserQuestion
---

Tạo khung cho use case `$1`.

**Chế độ phiếu (7.3) — khi chạy dưới lời giao của agent khác** (lời giao mở đầu `Vai:`/`Lượt`, hoặc
`bash .sdd/scripts/role.sh --xem` ra một vai không phải điều phối, hoặc không chắc có người ở đầu kia): **không mở
`AskUserQuestion`** — không ai bấm, lượt treo tới hết hạn (#53). Mỗi câu lẽ ra hỏi user thành một phiếu:
`bash .sdd/scripts/phieu.sh new "<việc>" <vai>` với Câu · Đã tra · Nếu chọn sai thì · Agent nghiêng về; chỗ phụ thuộc
câu đó để `___` + quyết định tạm; rồi **DỪNG** và kết bằng `role.sh --ketqua <khoá> ket=chan hoi=#<n>`. Chủ dự án tự
gõ lệnh này trong phiên của mình thì hỏi như thường.

Khuôn nằm trong plugin: `${CLAUDE_PLUGIN_ROOT}/templates/skel/` (không thay được biến: `find ~/.claude/plugins -type d -name skel -path '*sdd-solo*' | head -1`). Từ 5.0.0 khuôn không còn được chép vào
`.sdd/templates/` của dự án — chỉ skill đọc khuôn, mà skill chỉ chạy khi có plugin, nên bản sao trong dự án
là 13 file không ai đụng tới (đo ở runxops: nguyên byte sau nhiều tuần).

1. Xác định root repo (`git rev-parse --show-toplevel`). Nếu thiếu `specs/` → bảo chạy `/sdd-solo:init` trước.
2. ID: `$1` phải dạng `UC-###`. Kiểm chưa tồn tại: `find specs -path "*/br-*/use-cases/$1-*"`. Trùng → dừng, báo.
3. **Lát (`$2`) — UC nào cũng thuộc đúng một lát `BR-###`.** Không có `$2`, hoặc không rõ, thì liệt kê các lát đang có (`ls -d specs/*/br-*/`) và hỏi user chọn **bằng `AskUserQuestion`**: mỗi lát một lựa chọn, ghi kèm nghề và tên lát lấy từ dòng `**Lát:**` của `br.md`.

   **Nghề suy ra từ thư mục của BR**, không hỏi riêng: `specs/core/br-007/` là lát của lõi, `specs/ebay/br-012/` là lát của nghề `ebay`.

   BR user chọn **chưa có thư mục** → **dừng, bảo user chạy `/sdd-solo:intake` trước**. Không tự tạo `br-###/`: BR là tầng trên, viết nó là việc của intake cùng chủ dự án, và một `br.md` khung do skill này đẻ ra sẽ đứng đó như thể đã có người viết.
4. Slug (`$3`): tiếng Anh, kebab-case, là động từ + danh từ theo glossary (ví dụ `activate-device`). Không có → đề xuất từ tên UC trong bảng `## Related Use Cases` của `br.md` lát đó nếu UC đã có stub, rồi hỏi xác nhận.
5. Tạo:
   - `specs/<core|nghề>/br-###/use-cases/$1-<slug>/` từ `${CLAUDE_PLUGIN_ROOT}/templates/skel/use-case/` (copy `UC-000.md` → `$1.md`, `UC-000.flow.md` → `$1.flow.md`, `UC-000.sequence.md` → `$1.sequence.md`, `screens/README.md`). Thay mọi `UC-000` thành `$1`, `Last updated` thành hôm nay, `Status: draft`.
   - Metadata của UC: `- **Nghề:** <core | nghề> · **Lát:** BR-###` — nghề đúng bằng thư mục chứa lát. Kiểm BR có thật: `br.md` của lát phải tồn tại và có heading `# BR-###`.
   - Thêm/cập nhật dòng của UC trong bảng `## Related Use Cases` của `br.md` lát đó, cột `| UC | Tên | Actor | BR | Status |`.
6. STATE.md: sửa dòng `Đang làm:` thành `$1 · bước ① — khung đã tạo, chưa có nội dung`; `Việc tiếp theo:` thành `điền nội dung $1 cùng user (bước ②) rồi viết RULE + AC`.
7. Báo user: đường dẫn file, và bước tiếp là **điền nội dung cùng user** theo skill `sdd-process` — **ghi vào file vừa tạo**, không tạo file mới.
8. **Hỏi user có câu nghiệp vụ nào chưa trả lời được không, rồi phân loại giúp** — đây là chỗ user hay đứng lại mà không biết nên nghiên cứu tiếp hay bắt đầu viết Main Flow:
   - Câu đổi **hình dạng** của UC (actor là ai · dữ liệu đến từ đâu · ai được làm) → **chốt trước**, vì Main Flow viết theo giả định sai sẽ phải vứt chứ không sửa lời được. **Trình nhóm này bằng `AskUserQuestion`** — ≤ 4 câu một lượt, mỗi câu 2–4 hướng kèm hệ quả, đề nghị đặt đầu "(Recommended)", và luôn có lựa chọn "chưa quyết — dừng ở đây, đi hỏi/đo, quay lại sau". Không viết chúng thành bullet cuối tin nhắn (ca UC-012, #36: user phải tự đánh số trả lời).
   - Câu đổi **giá trị** trong một bước (ngưỡng · thời hạn · enum · khoá) → **treo được**. **Không hỏi.** Ghi ngay vào `## Open Questions` dạng `- [ ] <câu> (quyết định tạm: ___)` rồi chạy tiếp. `___` ở đó là hợp lệ, `gate-check.sh --pre` không tính là chưa điền.
   Bài kiểm một câu: *câu trả lời ngược lại thì Main Flow có phải viết lại không?*
9. **Entity UC nhắc tên mà chưa có file** → copy `${CLAUDE_PLUGIN_ROOT}/templates/skel/entity.md` thành `<Tên>.md`, một file một entity. Hỏi user **bằng `AskUserQuestion`** mỗi entity thuộc đâu:
   - `specs/core/entities/<Tên>.md` — mọi nghề đều dùng khái niệm này;
   - `specs/<nghề>/entities/<Tên>.md` — chỉ nghề này dùng.

   Không tự chọn: entity đặt nhầm vào `core` thì nghề khác thừa kế một khái niệm không phải của nó, mà đặt nhầm vào nghề thì lõi không được trích nó (luật ranh giới). Tên file = tên entity trong code = tên trong glossary. Điền nội dung là việc của bước ③ cùng user, skill này chỉ dựng khung.
10. Nếu file entity nào còn nguyên khuôn, hoặc `specs/glossary.md` (gốc) và `specs/<nghề>/glossary.md` còn là template, nói cho user biết ngay: chúng là đầu vào của ba vai ở bước ⑦ và là điều kiện cứng ở cổng ⑨. Viết chúng ở bước ③ rẻ hơn nhiều so với sau bước ⑦ — đổi mô hình sau đó thì AC phải sửa lời.
11. **UC nằm ở `specs/core/` thì không được trích ID của nghề nào** — `RULE-###`/`ADR-###`/`UC-###`/`BR-###` sống trong `specs/<nghề>/`, hay tên entity ở `specs/<nghề>/entities/`. Lõi không biết nghề. Nói điều này với user ngay khi lát chọn là `core`; `gate-check` và `design-check` gọi `layer-check` và sẽ cảnh báo.
12. Không viết code. Không commit (commit docs đầu tiên do `/sdd-solo:adversarial` làm).
