---
name: sdd-process
description: Kiến thức nền của quy trình SDD-Solo — 4 tầng yêu cầu (BR/UC/Entity/AC), hệ ID, cấu trúc repo, 14 bước mỗi UC, cách viết UC/AC/RULE/DMN, khi nào dùng changes/. Dùng khi user đang viết hoặc sửa spec, AC, rule, entity, sơ đồ luồng, màn hình, ADR trong repo có STATE.md, hoặc hỏi quy trình nên làm gì tiếp.
---

# SDD-Solo — cách hệ thống này viết spec

Nguồn: ebook *Spec Driven Development* (Nguyễn Thế Huy), AIUP, GitHub Spec Kit, OpenSpec; ký hiệu Mermaid (flowchart, stateDiagram, sequenceDiagram), DMN, UML, Impact Mapping, User Story Mapping. Bản này dành cho **một dev + AI**: giữ nguyên artifact của sách, thay mọi cơ chế cần người thứ hai.

## Luận điểm
Spec là giao diện giữa ba người đọc: user hôm nay, user ba tháng sau, và mỗi session AI mới. Mục tiêu duy nhất: **không để quyết định nghiệp vụ nào được đưa ra mà không ai biết nó đã được đưa ra**. Khi prompt thiếu rule, model lấp bằng xác suất → đó là quyết định ngầm. Việc của bạn khi làm việc trong repo này: **phát hiện và hỏi**, không lấp.

## Bốn tầng, bốn câu hỏi, bốn nơi
| Tầng | Câu hỏi | File | Biểu đồ đi kèm |
|---|---|---|---|
| BR | Vì sao làm | `specs/br.md` — `BR-000` là mẫu điền đủ, đọc trước khi viết | Impact Map (Mermaid, bắt buộc có ≥ 1 nhánh `-.->`) · Story Map |
| UC | Ai làm gì | `specs/contexts/<ctx>/use-cases/UC-###-slug/UC-###.md` | Flow mermaid (`UC-###.flow.md`, cùng thư mục UC) · Sequence nếu có mạng |
| Entity | Khái niệm nào, vòng đời nào | `specs/contexts/<ctx>/entities.md` | Domain Model (classDiagram) · State Machine cho mỗi entity có status |
| AC | Biết đúng bằng cách nào | trong file UC, `### AC-#` Given/When/Then | — |
| RULE | Ràng buộc xuyên UC | `specs/rules.md` — nơi duy nhất; UC/AC chỉ trích ID | DMN table khi ≥ 3 điều kiện |

Ranh giới spec/doc: **khách cảm nhận được → spec** (`specs/`). Chỉ người xây quan tâm → doc (`specs/internal/adr/`, `specs/internal/decisions.md`). Đang làm tới đâu → `STATE.md` ở root.

## Hệ ID
`BR-###` · `UC-###` · `UC-###/AC-#` · `RULE-###` · `CON-###` (trong BR) · `SCR-###-#` (màn hình của UC-###) · `ADR-###` · `CHG-###` (Phase 5). Commit: `<type>(ID): mô tả`. Test: `tests/use-cases/<ctx>/UC-###/AC-#.test.*`, describe `"UC-### / AC-#: tên"`.

## Phase 1 — trước khi có UC nào
`/sdd-solo:intake` là cửa vào: không tham số thì phỏng vấn bảy câu (khổ gì · ai khổ · tốn gì · không làm thì sao · có cách nào không xây phần mềm · cố ý không làm gì · đo bằng gì), có đường dẫn brief thì chuyển brief của agent khác thành BR theo luật **không bịa số** — số không nguồn thì `___` + Open Question, kể cả khi brief có ghi số. Rồi `br-check.sh BR-###` kiểm cơ học, và `/sdd-solo:adversarial BR-###` chạy ba vai *người trả tiền · người vận hành mãi · người hoài nghi*. Vai hoài nghi hỏi câu đắt nhất của cả tầng: **BR này có thật là BR, hay là một giải pháp đã chọn sẵn rồi viết ngược thành lý do?**

Ở tầng này `___` là câu trả lời hợp lệ và số bịa thì không. `br-check` chỉ **cảnh báo** khi còn `___`, nhưng **đỏ** khi mục còn nguyên placeholder `<...>`.

## 14 bước cho một UC (Phase 3)
① `/sdd-solo:start UC-###` → ② `/use-case-spec` (AIUP) điền nội dung → ③ user viết RULE (rules.md, DMN nếu cần), **`entities.md` + `glossary.md` của context**, và AC → ④ vẽ flow mermaid trong `UC-###.flow.md` → ⑤ Claude Design theo `.sdd/prompts/design-brief.md` → ⑥ đối chiếu SCR ↔ E# ↔ state → ⑦ `/sdd-solo:adversarial` (3 vai, session mới) → ⑧ **đọc lại bằng đầu chưa neo**: `/sdd-solo:verify UC-###` (subagent) hoặc đóng máy đọc lại buổi sau → ⑨ `/sdd-solo:gate` (đỏ/xanh) → `/speckit-specify` (mỏng, trích ID) → ⑩ `/speckit-plan` — user đọc, bắt lệch → ⑪ `/speckit-tasks` `/speckit-implement` → ⑫ test theo AC → ⑬ self-review 5 câu → ⑭ `/sdd-solo:close` → `/sdd-solo:state`.

Bốn câu để nhớ: **Viết xong chưa? Vẽ xong chưa? Soi xong chưa? Qua cổng chưa?**

## Câu hỏi nào phải chốt trước bước ②, câu nào treo được

Tình huống thật, nguyên văn chủ dự án: *"anh bị phân vân là nên nghiên cứu để trả lời câu hỏi, hay chạy tiếp `use-case-spec`. Flow không có gì hướng dẫn anh."* Ranh giới có thật, chỉ là chưa ai viết ra:

| Câu hỏi đổi cái gì | Ví dụ | Làm gì |
|---|---|---|
| **Hình dạng** của UC — actor là ai, dữ liệu đến từ đâu, ai được làm | *"đọc từ file Excel đang có hay kéo từ sàn về?"* · *"nối lần đầu bằng tay hay máy đoán rồi người duyệt?"* | **Chốt trước bước ②.** Main Flow viết ra theo giả định sai sẽ phải vứt, không phải sửa lời. |
| **Giá trị** bên trong một bước — ngưỡng, thời hạn, enum, khoá | *"khoá nối là SKU nhà cung cấp hay mã tự sinh?"* · *"giữ tối đa bao nhiêu dòng?"* | **Treo được.** Ghi `- [ ] <câu> (quyết định tạm: ___)`, thành `RULE-###` sau. `uc-ready.sh` không tính `___` trong Open Questions là chưa điền (#23). |

Bài kiểm một câu: *nếu câu trả lời ngược lại với giả định của mình, Main Flow có phải viết lại không?* Có → chốt trước. Không → treo.

## Cách viết từng thứ

**UC** — template ở `.sdd/templates/use-case/UC-000.md`. Bắt buộc: Actor, Trigger, Preconditions, Main Flow (bước "Hệ thống hiển thị" phải nêu SCR-ID), Alternative Flows (Na.), Exceptions (E#: điều kiện → màn hình → thông điệp bằng tiếng của khách → hệ thống làm gì), Postconditions, AC, Screens (bảng Nguồn | Màn hình | Khách thấy gì | Hành động), Dependencies, Open Questions (mỗi câu có "quyết định tạm"), Adversarial pass, History.

**AC** — Given/When/Then, một cho Main Flow, một cho mỗi E#. Không chép rule: viết "theo RULE-004". Mỗi AC sẽ thành đúng một file test.

**Exception vs bug** — "QR hết hạn thì hiện lỗi và cho tạo lại" là exception (viết vào spec). "App crash khi QR hết hạn" là bug (không viết).

**RULE** — `## RULE-###: tên` · Phát biểu một câu · Áp dụng cho UC nào · Nguồn · Status. Nhiều điều kiện → bảng DMN, hit policy ghi rõ, tham số (số, ngưỡng) để trong bảng tham số riêng — `___` nếu chưa chốt, KHÔNG điền số ước.

**Entity** — viết **trước** bước ⑦, không phải sau. Ba vai adversarial đọc `entities.md` làm đầu vào, và cổng ⑨ đòi nó có thật; chuỗi 14 bước trước 3.3.0 không đặt tên cho việc này ở đâu cả nên nó hay bị làm sau. Mô hình đổi sau khi đã chạy ba vai thì AC phải sửa lời — không mất trắng, nhưng là việc thừa. Mermaid `classDiagram` (tên, quan hệ, trường đáng chú ý gắn RULE-ID), rồi `stateDiagram-v2` cho mỗi entity có status; mỗi mũi tên ghi **nguyên nhân** kéo nó — thường là một `UC-###`, nhưng **không phải luôn**: trạng thái đổi vì thế giới bên ngoài (sàn khoá tài khoản, hết hạn theo đồng hồ, hệ thống khác đẩy sang) thì ghi đúng nguyên nhân đó, đừng dán một `UC-###` giả lên cho đủ hình thức. Cổng DoR vì vậy chỉ đòi **ít nhất một** mũi tên gắn UC có thật trong cả file, không đòi từng mũi tên. Trạng thái không có đường ra thì viết note nói đó là quyết định.

**Flow ↔ UC** (`UC-###.flow.md`, mermaid `flowchart`) — Actor = `subgraph` (chỉ khi ≥ 2 actor) · Trigger = node đầu `S([...])`, loại trigger ghi vào tên · Main Flow = `T#[...]` · Alternative = `D#{...}` với điều kiện trên mũi tên · Exception E# = mũi tên nhãn `|E# ...|` → node kết `X#([E#: ...])` · Postcondition = node kết `P#([...])`. **Chỉ nhãn giữa hai dấu `|` được đếm** — tên node không tính, kể cả khi chứa `E#`. Cổng DoR đối chiếu E# **cả hai chiều**: khai trong UC mà sơ đồ không có nhánh → đỏ; nhãn trong sơ đồ mà UC không có → cũng đỏ. `.bpmn` vẫn được nhận nhưng không đếm được gì.

**Màn hình (Claude Design)** — mỗi E# có một trạng thái màn hình; mỗi trạng thái entity nhìn thấy được ở đâu đó; không vẽ nút/trường không có nguồn trong UC. Ô trống trong bảng đối chiếu = spec thiếu, không phải design thiếu.

**ADR** — chỉ khi quyết định đắt để đảo ngược VÀ có phương án thay thế hợp lý bị loại. Phải có mục Alternatives considered và ít nhất một dấu trừ trong Consequences. Bài test: khách quan tâm → không phải ADR, là RULE/AC.

## Khi nào dùng `specs/changes/` (Phase 5)
UC có `Status: implemented` **và** thay đổi làm một AC cũ không còn đúng. Tạo `specs/changes/CHG-###-slug/` (proposal, delta ADDED/MODIFIED/REMOVED, design, tasks); baseline trong `specs/` chỉ đổi khi archive. Thêm AC mới không phá AC cũ → vẫn là Phase 3, History v+1.

## Quy tắc cho bạn (AI) trong repo này
1. Gặp số, ngưỡng, enum, quyền mà spec chưa nói → dừng, hỏi. Không chọn mặc định.
2. Khi user trả lời → nhắc ghi vào spec + commit `docs(UC-###)` trước khi code tiếp.
3. Không chạy `/speckit-specify` `/speckit-plan` `/speckit-tasks` `/speckit-implement` khi `.sdd/gate/UC-###.ok` chưa có.
4. Dùng đúng tên trong `specs/glossary.md`.
5. Không bịa số liệu để điền chỗ trống; để `___`.
5b. **Số mô tả dữ liệu thật phải ghi kèm lệnh đo ra nó.** Số nghiệp vụ đã chốt (ngưỡng, thời hạn)
   là quyết định nên không cần; nhưng *"427 dòng đang hỏng"* là một **phép đo**, và một phép đo
   không kèm lệnh thì sáu tháng sau không ai kiểm lại được. Con số là chỗ mục nhanh nhất trong
   spec: nó đúng lúc viết, không ai sửa khi dữ liệu đổi, và số đã mục trông y hệt số đúng.
   `/sdd-solo:verify` đo lại được chính vì lệnh đó nằm trong file. Lệnh nên in kèm **dấu vân tay
   của dữ liệu** (nguồn · số dòng · `sha256` ngắn · sửa lần cuối), và spec ghi lại vân tay đó — để
   lần chạy sau phân biệt được *dữ liệu đã đổi* với *spec sai* mà không phải đoán. Vân tay không
   bắt được lệnh đo tự nó đổi: **có lệnh đo làm số kiểm lại được, không làm số đúng.**
6. Khi được nhờ viết AC/UC/RULE: viết theo đúng template, tiếng Việt cho văn, tên entity/UC slug tiếng Anh.
