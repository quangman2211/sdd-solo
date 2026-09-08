---
name: sdd-process
description: Kiến thức nền của quy trình SDD-Solo — 4 tầng yêu cầu (BR/UC/Entity/AC), hệ ID, cấu trúc repo, 14 bước mỗi UC, cách viết UC/AC/RULE/DMN, khi nào dùng changes/. Dùng khi user đang viết hoặc sửa spec, AC, rule, entity, BPMN, màn hình, ADR trong repo có STATE.md, hoặc hỏi quy trình nên làm gì tiếp.
---

# SDD-Solo — cách hệ thống này viết spec

Nguồn: ebook *Spec Driven Development* (Nguyễn Thế Huy), AIUP, GitHub Spec Kit, OpenSpec; ký hiệu BPMN 2.0, DMN, UML, Impact Mapping, User Story Mapping. Bản này dành cho **một dev + AI**: giữ nguyên artifact của sách, thay mọi cơ chế cần người thứ hai.

## Luận điểm
Spec là giao diện giữa ba người đọc: user hôm nay, user ba tháng sau, và mỗi session AI mới. Mục tiêu duy nhất: **không để quyết định nghiệp vụ nào được đưa ra mà không ai biết nó đã được đưa ra**. Khi prompt thiếu rule, model lấp bằng xác suất → đó là quyết định ngầm. Việc của bạn khi làm việc trong repo này: **phát hiện và hỏi**, không lấp.

## Bốn tầng, bốn câu hỏi, bốn nơi
| Tầng | Câu hỏi | File | Biểu đồ đi kèm |
|---|---|---|---|
| BR | Vì sao làm | `specs/br.md` | Impact Map (Mermaid) · Story Map (`specs/story-map.md`) |
| UC | Ai làm gì | `specs/contexts/<ctx>/use-cases/UC-###-slug/UC-###.md` | BPMN 2.0 (`UC-###.bpmn`, cùng thư mục UC) · Sequence nếu có mạng |
| Entity | Khái niệm nào, vòng đời nào | `specs/contexts/<ctx>/entities.md` | Domain Model (classDiagram) · State Machine cho mỗi entity có status |
| AC | Biết đúng bằng cách nào | trong file UC, `### AC-#` Given/When/Then | — |
| RULE | Ràng buộc xuyên UC | `specs/rules.md` — nơi duy nhất; UC/AC chỉ trích ID | DMN table khi ≥ 3 điều kiện |

Ranh giới spec/doc: **khách cảm nhận được → spec** (`specs/`). Chỉ người xây quan tâm → doc (`specs/internal/adr/`, `specs/internal/decisions.md`). Đang làm tới đâu → `STATE.md` ở root.

## Hệ ID
`BR-###` · `UC-###` · `UC-###/AC-#` · `RULE-###` · `CON-###` (trong BR) · `SCR-###-#` (màn hình của UC-###) · `ADR-###` · `CHG-###` (Phase 5). Commit: `<type>(ID): mô tả`. Test: `tests/use-cases/<ctx>/UC-###/AC-#.test.*`, describe `"UC-### / AC-#: tên"`.

## 14 bước cho một UC (Phase 3)
① `/sdd-solo:start UC-###` → ② `/use-case-spec` (AIUP) điền nội dung → ③ user viết RULE (rules.md, DMN nếu cần) và AC → ④ vẽ BPMN ở Camunda → ⑤ Claude Design theo `.sdd/prompts/design-brief.md` → ⑥ đối chiếu SCR ↔ E# ↔ state → ⑦ `/sdd-solo:adversarial` (3 vai, session mới) → ⑧ **đóng máy, đọc lại buổi sau** → ⑨ `/sdd-solo:gate` (đỏ/xanh) → `/speckit-specify` (mỏng, trích ID) → ⑩ `/speckit-plan` — user đọc, bắt lệch → ⑪ `/speckit-tasks` `/speckit-implement` → ⑫ test theo AC → ⑬ self-review 5 câu → ⑭ `/sdd-solo:close` → `/sdd-solo:state`.

Bốn câu để nhớ: **Viết xong chưa? Vẽ xong chưa? Soi xong chưa? Qua cổng chưa?**

## Cách viết từng thứ

**UC** — template ở `.sdd/templates/use-case/UC-000.md`. Bắt buộc: Actor, Trigger, Preconditions, Main Flow (bước "Hệ thống hiển thị" phải nêu SCR-ID), Alternative Flows (Na.), Exceptions (E#: điều kiện → màn hình → thông điệp bằng tiếng của khách → hệ thống làm gì), Postconditions, AC, Screens (bảng Nguồn | Màn hình | Khách thấy gì | Hành động), Dependencies, Open Questions (mỗi câu có "quyết định tạm"), Adversarial pass, History.

**AC** — Given/When/Then, một cho Main Flow, một cho mỗi E#. Không chép rule: viết "theo RULE-004". Mỗi AC sẽ thành đúng một file test.

**Exception vs bug** — "QR hết hạn thì hiện lỗi và cho tạo lại" là exception (viết vào spec). "App crash khi QR hết hạn" là bug (không viết).

**RULE** — `## RULE-###: tên` · Phát biểu một câu · Áp dụng cho UC nào · Nguồn · Status. Nhiều điều kiện → bảng DMN, hit policy ghi rõ, tham số (số, ngưỡng) để trong bảng tham số riêng — `___` nếu chưa chốt, KHÔNG điền số ước.

**Entity** — Mermaid `classDiagram` (tên, quan hệ, trường đáng chú ý gắn RULE-ID), rồi `stateDiagram-v2` cho mỗi entity có status; mỗi mũi tên ghi UC nào được kéo nó; trạng thái không có đường ra thì viết note nói đó là quyết định.

**BPMN ↔ UC** — Actor = lane · Trigger = start event (click/none, webhook/message, cron/timer) · Main Flow = task · Alternative = exclusive gateway · Exception E# = error boundary event → end event có tên · Postcondition = end event có tên. Số error event phải = số E#.

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
6. Khi được nhờ viết AC/UC/RULE: viết theo đúng template, tiếng Việt cho văn, tên entity/UC slug tiếng Anh.
