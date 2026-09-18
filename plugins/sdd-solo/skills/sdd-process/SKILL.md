---
name: sdd-process
description: Kiến thức nền của quy trình SDD-Solo — 5 tầng yêu cầu (Hướng/BR/UC/Entity/AC), hệ ID, cây specs/ theo core|nghề × lát, ranh giới lõi/nghề, 14 bước mỗi UC, cách viết UC/AC/RULE/DMN, khi nào dùng changes/. Dùng khi user đang viết hoặc sửa spec, vision, AC, rule, entity, sơ đồ luồng, màn hình, ADR trong repo có STATE.md, hoặc hỏi quy trình nên làm gì tiếp.
---

# SDD-Solo — cách hệ thống này viết spec

Nguồn: ebook *Spec Driven Development* (Nguyễn Thế Huy), AIUP, GitHub Spec Kit, OpenSpec — **đọc để học hình dạng artifact, không phụ thuộc lệnh của cái nào**; ký hiệu Mermaid (flowchart, stateDiagram, sequenceDiagram), DMN, UML, Impact Mapping, User Story Mapping. Bản này dành cho **một dev + AI**: giữ nguyên artifact của sách, thay mọi cơ chế cần người thứ hai.

## Luận điểm
Spec là giao diện giữa ba người đọc: user hôm nay, user ba tháng sau, và mỗi session AI mới. Mục tiêu duy nhất: **không để quyết định nghiệp vụ nào được đưa ra mà không ai biết nó đã được đưa ra**. Khi prompt thiếu rule, model lấp bằng xác suất → đó là quyết định ngầm. Việc của bạn khi làm việc trong repo này: **phát hiện và hỏi**, không lấp.

## Năm tầng, năm câu hỏi, năm nơi
| Tầng | Câu hỏi | File | Biểu đồ đi kèm |
|---|---|---|---|
| Hướng | Đi về đâu, cái gì **không được co lại** | `specs/vision.md` — tầng 0, **chủ dự án viết**, miễn luật "không số" | bảng `## Nghề và lát` |
| BR | Vì sao làm **lát này** | `specs/<core\|nghề>/br-###/br.md` — mỗi BR một lát, một file; `BR-000` ở `specs/core/br-000/` là mẫu điền đủ, đọc trước khi viết | Impact Map (Mermaid, bắt buộc có ≥ 1 nhánh `-.->`) · Story Map |
| UC | Ai làm gì | `specs/<core\|nghề>/br-###/use-cases/UC-###-slug/UC-###.md` | Flow mermaid (`UC-###.flow.md`, cùng thư mục UC) · Sequence nếu có mạng |
| Entity | Khái niệm nào, vòng đời nào | **mỗi entity một file**: `specs/core/entities/<Tên>.md` · `specs/<nghề>/entities/<Tên>.md` | Domain Model (classDiagram, ở `entities/README.md`) · State Machine trong file entity có status |
| AC | Biết đúng bằng cách nào | trong file UC, `### AC-#` Given/When/Then | — |
| RULE | Ràng buộc xuyên UC | `specs/rules.md` (xuyên suốt) · `specs/<nghề>/rules.md` (riêng nghề) — **một dãy `RULE-###` cho cả dự án**; UC/AC chỉ trích ID | DMN table khi ≥ 3 điều kiện |

Tầng 0 sinh ra vì bốn tầng dưới không tầng nào giữ **ý định**: một BR bị co ba lần qua ba lượt adversarial, mỗi lần đều đúng luật, cho tới khi thứ còn lại nhỏ hơn hẳn điều chủ dự án muốn — và không phép kiểm nào thấy. `vision.md` là của chủ dự án: **agent không tự viết mục nào trong đó**, chỉ hỏi và chép. UC hay BR phát hiện tầm nhìn sai → ghi một dòng `## Sổ sửa ngược` và hỏi, không sửa lặng lẽ.

Ranh giới spec/doc: **khách cảm nhận được → spec** (`specs/`). Chỉ người xây quan tâm → doc (`specs/adr/`, `specs/<nghề>/adr/`, `specs/decisions.md`). Vết quá trình giữa các agent (hỏi đáp, biên bản soát, bản đồ) → `notes/{hoi-dap,soat,ban-do}/`, **ngoài `specs/`**. Đang làm tới đâu → `STATE.md` ở root.

## Ba tầng chỗ: gốc · lõi · nghề (7.0)

Cây `specs/` không còn chia theo `contexts/` — "bounded context" như **đơn vị thư mục** đã bỏ (T3, 2026-09-18). Trục mới là **`core | <nghề>`** × **`br-###`**:

```
specs/
  vision.md · glossary.md · rules.md · architecture.md · decisions.md · adr/   ← GỐC: xuyên suốt cả dự án
  changes/ · traceability.md
  core/entities/<Tên>.md · core/br-###/{br.md, evidence.md, use-cases/…}       ← LÕI: dùng chung, ngang hàng nghề
  <nghề>/{glossary.md, rules.md, adr/, entities/<Tên>.md, br-###/…}            ← NGHỀ: mỗi thời điểm MỘT nghề mở
notes/{hoi-dap,soat,ban-do}/                                                   ← vết quá trình, ngoài specs/
tests/use-cases/<core|nghề>/UC-###/AC-#.test.*
```

- **Nghề** = một mảng nghiệp vụ (eBay · Khải Kids · …), mỗi nghề một thư mục. `core` là lõi dùng chung, **ngang hàng** với nghề.
- **Lát** = một `BR-###`, một thư mục `br-###/`. Một dãy số BR cho cả dự án, không đánh lại theo nghề. Mỗi BR khai `- **Lát:** <core | nghề> · <tên lát>`, và tên lát phải có trong bảng `## Nghề và lát` của `vision.md` — `br-check` đỏ khi thiếu, lệch nghề thư mục, hoặc không có trong bảng.
- **Luật ranh giới:** gốc `specs/*.md`, `specs/adr/`, `specs/core/` **không trích ID của nghề**; nghề trích gốc và `core` thoải mái. `src/core` **không import** `src/<nghề>`. Lõi không biết nghề; nghề biết lõi. `layer-check.sh` kiểm bằng máy; githook `pre-commit.d/20-layer-boundary` chặn nợ mới.
- **Mỗi thời điểm một nghề mở.** Nghề sau mở khi nghề trước "xong" theo mục `## "Xong" của mỗi nghề` của `vision.md` — không phải khi thấy hứng.

Thứ tự đọc của một session mới: `STATE.md` → `specs/vision.md` → `specs/glossary.md` gốc rồi `specs/<nghề>/glossary.md` → file entity UC nhắc tên → UC + các `RULE-###` nó trích → `specs/decisions.md` và ADR → brief nguồn (`brief_path`). `context.sh UC-###` gom sẵn đúng thứ tự đó.

## Hệ ID
`BR-###` · `UC-###` · `UC-###/AC-#` · `RULE-###` · `CON-###` (trong BR) · `SCR-###-#` (màn hình của UC-###) · `ADR-###` · `CHG-###` (Phase 5). Commit: `<type>(ID): mô tả`. Test: `tests/use-cases/<core|nghề>/UC-###/AC-#.test.*`, describe `"UC-### / AC-#: tên"`.

`RULE-###`, `ADR-###` và `BR-###` mỗi họ **một dãy số cho cả dự án**, dù file nằm ở gốc hay trong một nghề — trùng số là đỏ ở cổng.

## Phase 1 — trước khi có UC nào
`/sdd-solo:intake` là cửa vào. **Bước 0 là tầng 0:** chưa có `specs/vision.md` (hay nó còn nguyên khuôn) thì intake hỏi chủ dự án bằng lời thường — đi về đâu · 3–5 điều không được co lại · nghề nào mở trước và "xong" nghĩa là gì — rồi **chép lại**, không viết hộ. BR nào cũng phải tự nhận `**Lát:**` ở bảng `## Nghề và lát`, nên không có tầng 0 thì bảy câu dưới không có chỗ để đứng.

Rồi bảy câu (khổ gì · ai khổ · tốn gì · không làm thì sao · có cách nào không xây phần mềm · cố ý không làm gì · đo bằng gì) viết ra `specs/<core|nghề>/br-###/br.md`; có đường dẫn brief thì chuyển brief của agent khác thành BR theo luật **không bịa số** — số không nguồn thì `___` + Open Question, kể cả khi brief có ghi số. Rồi `br-check.sh BR-###` kiểm cơ học, và `/sdd-solo:adversarial BR-###` chạy ba vai *người trả tiền · người vận hành mãi · người hoài nghi*. Vai hoài nghi hỏi câu đắt nhất của cả tầng: **BR này có thật là BR, hay là một giải pháp đã chọn sẵn rồi viết ngược thành lý do?**

Mỗi dòng `## Out of Scope` và `## Đã loại khỏi brief` phải nói nó đi **đâu**: `→ lát ___` · `→ mở lại khi ___` · `→ chuyển: …` cho mục kiến trúc. Hoãn mà không ghi đích là hoãn vào hư không — không cơ chế nào tự mang nó tới đó. Dòng Out of Scope trùng một từ khoá ở `## Không thu hẹp` của `vision.md` thì `br-check` đỏ, trừ khi dòng đó ghi `cố ý thu hẹp — chủ dự án chốt YYYY-MM-DD`.

Ở tầng này `___` là câu trả lời hợp lệ và số bịa thì không. `br-check` chỉ **cảnh báo** khi còn `___`, nhưng **đỏ** khi mục còn nguyên placeholder `<...>`.

## 14 bước cho một UC (Phase 3)
① `/sdd-solo:start UC-###` → ② **điền nội dung UC cùng user** (Actor · Trigger · Preconditions · Main Flow — bước hiển thị nêu SCR-ID · Alternative · Exceptions · Postconditions) → ③ user viết RULE (`specs/rules.md` gốc hoặc `specs/<nghề>/rules.md`, DMN nếu cần), **file entity của mỗi entity UC nhắc tên + `glossary.md`** (gốc cho từ chung, `specs/<nghề>/glossary.md` cho từ riêng nghề), và AC → ④ vẽ flow mermaid trong `UC-###.flow.md` → ⑤ Claude Design theo `.sdd/prompts/design-brief.md` → ⑥ đối chiếu SCR ↔ E# ↔ state → ⑦ `/sdd-solo:adversarial` (3 vai, session mới) → ⑧ **đọc lại bằng đầu chưa neo**: `/sdd-solo:verify UC-###` (subagent; bắt buộc từ 6.0.0 — không còn cửa "đóng máy đọc lại buổi sau") → ⑨ `/sdd-solo:gate` (đỏ/xanh) → ⑩ `/sdd-solo:design` — sinh `design.md` + `tasks.md` trong thư mục UC, user đọc, bắt lệch → ⑪ viết code theo `tasks.md` → ⑫ test theo AC → ⑬ self-review 5 câu → ⑭ `/sdd-solo:close` → `/sdd-solo:state`.

Bốn câu để nhớ: **Viết xong chưa? Vẽ xong chưa? Soi xong chưa? Qua cổng chưa?**

**⑦ → ⑧ → ⑨ phải liền nhau, không chen sửa (#41).** Áp **hết** phát hiện của ⑦ (kể cả sửa chữ, nhãn,
file bên cạnh: glossary gốc và nghề · file entity · `Áp dụng cho` của RULE) **trước** khi chạy ⑧. Sau ⑧, **mọi** commit
đụng spec — dù chỉ áp chữ — làm cổng ⑨ đỏ *"spec đổi sau lần đọc lại"*, vì cổng đòi commit đọc lại là
commit spec mới nhất; sửa sau ⑧ nghĩa là chấp nhận verify lại (từ 6.3.0: `/sdd-solo:verify UC-### --since`
chỉ đọc phần đổi). Ca thật runxops UC-014: một đợt áp phiếu chữ sau verify → gate đỏ; luật đúng, chỉ
chưa được viết ra cho người làm.

**Không dùng lệnh sinh spec của plugin khác cho bước ② ③ ④.** Chúng ghi ra cây và hệ ID của họ (`docs/`, `BR-###` nghĩa là *rule*), cổng DoR đọc `specs/` và `BR-###` nghĩa là *requirement* — githook cho qua một commit gắn ID có heading thật mà sai nghĩa. Số đo và tên lệnh cụ thể ở CHANGELOG 3.x (#29); quy tắc cứng ở đây cố ý không gọi tên lệnh của ai (4.0.0).

**Bước nào cố ý bỏ thì ghi vào file UC một dòng `**Bỏ bước <ký hiệu>:** <lý do>`.** Bỏ có ghi lý do
và bỏ mà không ai biết là bỏ cho **cùng một kết quả trên đĩa**, nhưng sáu tháng sau chỉ cái đầu còn
đọc lại được. `/sdd-solo:status` liệt kê ba trạng thái: `✓` có dấu vết · `–` bỏ có lý do · `?`
không có dấu vết nào.

## Câu hỏi nào phải chốt trước bước ②, câu nào treo được

Tình huống thật, nguyên văn chủ dự án: *"anh bị phân vân là nên nghiên cứu để trả lời câu hỏi, hay chạy tiếp `use-case-spec`. Flow không có gì hướng dẫn anh."* Ranh giới có thật, chỉ là chưa ai viết ra:

| Câu hỏi đổi cái gì | Ví dụ | Làm gì |
|---|---|---|
| **Hình dạng** của UC — actor là ai, dữ liệu đến từ đâu, ai được làm | *"đọc từ file Excel đang có hay kéo từ sàn về?"* · *"nối lần đầu bằng tay hay máy đoán rồi người duyệt?"* | **Chốt trước bước ②.** Main Flow viết ra theo giả định sai sẽ phải vứt, không phải sửa lời. |
| **Giá trị** bên trong một bước — ngưỡng, thời hạn, enum, khoá | *"khoá nối là SKU nhà cung cấp hay mã tự sinh?"* · *"giữ tối đa bao nhiêu dòng?"* | **Treo được.** Ghi `- [ ] <câu> (quyết định tạm: ___)`, thành `RULE-###` sau. `gate-check.sh --pre` không tính `___` trong Open Questions là chưa điền (#23). |

Bài kiểm một câu: *nếu câu trả lời ngược lại với giả định của mình, Main Flow có phải viết lại không?* Có → chốt trước. Không → treo.

## Cách viết từng thứ

**UC** — khuôn ở `${CLAUDE_PLUGIN_ROOT}/templates/skel/use-case/UC-000.md`. Bắt buộc: Actor, Trigger, Preconditions, Main Flow (bước "Hệ thống hiển thị" phải nêu SCR-ID), Alternative Flows (Na.), Exceptions (E#: điều kiện → màn hình → thông điệp bằng tiếng của khách → hệ thống làm gì), Postconditions, AC, Screens (bảng Nguồn | Màn hình | Khách thấy gì | Hành động), Dependencies, Open Questions (mỗi câu có "quyết định tạm"), Adversarial pass, History.

**AC** — Given/When/Then, một cho Main Flow, một cho mỗi E#. Không chép rule: viết "theo RULE-004". Mỗi AC sẽ thành đúng một file test.

**Exception vs bug** — "QR hết hạn thì hiện lỗi và cho tạo lại" là exception (viết vào spec). "App crash khi QR hết hạn" là bug (không viết).

**RULE** — `## RULE-###: tên` · Phát biểu một câu · Áp dụng cho UC nào · Nguồn · Status. Luật xuyên suốt vào `specs/rules.md` gốc; luật chỉ một nghề dùng vào `specs/<nghề>/rules.md`. **ID không trùng nhau giữa hai chỗ** — một dãy cho cả dự án. Nhiều điều kiện → bảng DMN, hit policy ghi rõ, tham số (số, ngưỡng) để trong bảng tham số riêng — `___` nếu chưa chốt, KHÔNG điền số ước.

**Entity** — **mỗi entity một file** (khuôn `${CLAUDE_PLUGIN_ROOT}/templates/skel/entity.md`): `specs/core/entities/<Tên>.md` nếu mọi nghề dùng chung, `specs/<nghề>/entities/<Tên>.md` nếu chỉ nghề đó dùng. Tên file = tên entity trong code = tên trong glossary; Domain Model chung nằm ở `entities/README.md`. Viết **trước** bước ⑦, không phải sau. Ba vai adversarial đọc các file entity UC nhắc tên làm đầu vào, và cổng ⑨ đòi chúng có thật; chuỗi 14 bước trước 3.3.0 không đặt tên cho việc này ở đâu cả nên nó hay bị làm sau. Mô hình đổi sau khi đã chạy ba vai thì AC phải sửa lời — không mất trắng, nhưng là việc thừa. Mermaid `classDiagram` (tên, quan hệ, trường đáng chú ý gắn RULE-ID), rồi `stateDiagram-v2` cho mỗi entity có status; mỗi mũi tên ghi **nguyên nhân** kéo nó — thường là một `UC-###`, nhưng **không phải luôn**: trạng thái đổi vì thế giới bên ngoài (sàn khoá tài khoản, hết hạn theo đồng hồ, hệ thống khác đẩy sang) thì ghi đúng nguyên nhân đó, đừng dán một `UC-###` giả lên cho đủ hình thức. Cổng DoR vì vậy chỉ đòi **ít nhất một** mũi tên gắn UC có thật trong các file entity UC nhắc tên, không đòi từng mũi tên. Trạng thái không có đường ra thì viết note nói đó là quyết định.

**Flow ↔ UC** (`UC-###.flow.md`, mermaid `flowchart`) — Actor = `subgraph` (chỉ khi ≥ 2 actor) · Trigger = node đầu `S([...])`, loại trigger ghi vào tên · Main Flow = `T#[...]` · Alternative = `D#{...}` với điều kiện trên mũi tên · Exception E# = mũi tên nhãn `|E# ...|` → node kết `X#([E#: ...])` · Postcondition = node kết `P#([...])`. **Chỉ nhãn giữa hai dấu `|` được đếm** — tên node không tính, kể cả khi chứa `E#`. Cổng DoR đối chiếu E# **cả hai chiều**: khai trong UC mà sơ đồ không có nhánh → đỏ; nhãn trong sơ đồ mà UC không có → cũng đỏ. `.bpmn` vẫn được nhận nhưng không đếm được gì.

**Màn hình (Claude Design)** — mỗi E# có một trạng thái màn hình; mỗi trạng thái entity nhìn thấy được ở đâu đó; không vẽ nút/trường không có nguồn trong UC. Ô trống trong bảng đối chiếu = spec thiếu, không phải design thiếu.

**ADR** — chỉ khi quyết định đắt để đảo ngược VÀ có phương án thay thế hợp lý bị loại. Phải có mục Alternatives considered và ít nhất một dấu trừ trong Consequences. Bài test: khách quan tâm → không phải ADR, là RULE/AC.

## Khi nào dùng `specs/changes/` (Phase 5)
UC có `Status: implemented` **và** thay đổi làm một AC cũ không còn đúng. Tạo `specs/changes/CHG-###-slug/` (proposal, delta ADDED/MODIFIED/REMOVED, design, tasks); baseline trong `specs/` chỉ đổi khi archive. Thêm AC mới không phá AC cũ → vẫn là Phase 3, History v+1.

## Quy tắc cho bạn (AI) trong repo này
- **Cần bối cảnh của một UC thì chạy `${CLAUDE_PLUGIN_ROOT}/scripts/context.sh UC-###`**, không tự đi nhặt file. Nó in đúng phần đang hiệu lực + đúng những RULE/CON/ADR UC trích (5.0.0); `--why` khi chỉ cần biết UC do cái gì quyết định. Ba mục `## Adversarial pass` · `## Đọc lại` · `## History` là dấu vết — không phải đầu vào để viết code.
1. Gặp số, ngưỡng, enum, quyền mà spec chưa nói → dừng, hỏi. Không chọn mặc định.
1b. **Câu cần người quyết thì hiện bằng công cụ `AskUserQuestion`, không kết tin nhắn bằng văn
   xuôi** (5.2.0, #36). Đo ở runxops một ngày: bốn câu "chốt trước" viết thành bullet cuối tin
   nhắn → chủ dự án phải tự đánh số trả lời, trả lời một nửa; cùng ngày, cùng người, câu đi qua
   `AskUserQuestion` (E1/E5/E9 của UC-009, lát của UC-012) → trả lời dứt điểm ngay. Văn xuôi
   là để lập luận *trước* khi hỏi; câu hỏi lẫn giữa lập luận thì bị đọc lướt. Khuôn: ≤ 4 câu một
   lượt · mỗi câu 2–4 lựa chọn, mỗi lựa chọn ghi **hệ quả** một câu · lựa chọn đề nghị đặt đầu
   kèm "(Recommended)" · **`Chưa quyết — ghi Open Question` luôn là một lựa chọn** (`___` hợp lệ
   ở mọi tầng). Câu *treo được* (đổi giá trị, xem bảng trên) thì không hỏi — ghi thẳng Open
   Question kèm quyết định tạm. Câu mở ("khổ gì?", "ai khổ?") không có lựa chọn thì vẫn hỏi
   bằng lời; luật này là cho câu **chọn giữa các hướng**.
2. Khi user trả lời → nhắc ghi vào spec + commit `docs(UC-###)` trước khi code tiếp.
3. Không viết code cho UC khi `.sdd/gate/UC-###.ok` chưa có, hoặc khi thư mục UC chưa có `design.md`.
4. Dùng đúng tên trong `specs/glossary.md` (gốc) và `specs/<nghề>/glossary.md` của nghề đang làm. Từ trùng chữ mà khác nghĩa thì glossary nghề ghi "Không nhầm với …" — đọc cả hai trước khi đặt tên class, hàm, test.
4b. **Không trích ID của nghề vào gốc hay `core`.** Viết `specs/*.md`, `specs/adr/`, hay bất cứ gì dưới `specs/core/` mà muốn nhắc một `RULE-###`/`ADR-###`/`UC-###`/`BR-###` sống trong `specs/<nghề>/` → dừng và hỏi: hoặc thứ đó thuộc về lõi (dời lên), hoặc câu đang viết thuộc về nghề. `layer-check.sh` kiểm; ở `src/` thì `src/core` không import `src/<nghề>`.
5. Không bịa số liệu để điền chỗ trống; để `___`.
5b. **Số mô tả dữ liệu thật phải ghi kèm lệnh đo ra nó.** Số nghiệp vụ đã chốt (ngưỡng, thời hạn)
   là quyết định nên không cần; nhưng *"427 dòng đang hỏng"* là một **phép đo**, và một phép đo
   không kèm lệnh thì sáu tháng sau không ai kiểm lại được. Con số là chỗ mục nhanh nhất trong
   spec: nó đúng lúc viết, không ai sửa khi dữ liệu đổi, và số đã mục trông y hệt số đúng.
   `/sdd-solo:verify` đo lại được chính vì lệnh đó nằm trong file. Lệnh nên in kèm **dấu vân tay
   của dữ liệu** (nguồn · số dòng · `sha256` ngắn · sửa lần cuối), và spec ghi lại vân tay đó — để
   lần chạy sau phân biệt được *dữ liệu đã đổi* với *spec sai* mà không phải đoán. Vân tay không
   bắt được lệnh đo tự nó đổi: **có lệnh đo làm số kiểm lại được, không làm số đúng.** Và lệnh phải
   **khai hình dạng dữ liệu nó giả định và dừng hẳn nếu hình dạng đã đổi** — một con số đếm trên
   cấu trúc đã đổi trông y hệt một con số đúng, nên im còn hơn đoán. Và lệnh phải
   in **mẫu số thô lẫn mẫu số đã lọc** — `13/13` trông hoàn hảo, `16 thô → loại 3 giữ chỗ → 13`
   nói thật; một tỉ lệ đã lọc mà không khai là đã lọc thì đúng số mà vẫn giấu mất phần đang bàn.
6. Khi được nhờ viết AC/UC/RULE: viết theo đúng template, tiếng Việt cho văn, tên entity/UC slug tiếng Anh.
