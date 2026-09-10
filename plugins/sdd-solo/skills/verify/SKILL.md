---
name: verify
description: Đọc lại tài liệu bằng subagent chưa bị neo để tìm chỗ spec tự mâu thuẫn hoặc khai điều không có thật. UC-### là bước ⑧ (mở cửa thứ hai của cổng DoR, không phải đợi qua đêm); không tham số là quét cả cây specs/. Dùng khi sắp qua cổng, hoặc khi tài liệu vừa đổi nhiều và cần biết còn chỗ nào nói ngược nhau.
disable-model-invocation: true
argument-hint: "[UC-###]"
allowed-tools: Bash Read Write Edit Grep Glob Agent AskUserQuestion
---

Verify pass cho `$1`.

Có `UC-###` → **phần A** (bước ⑧, mở cửa thứ hai của cổng). Không tham số → **phần B** (quét cây).

**Vì sao skill này tồn tại:** người viết không đọc được cái mình vừa viết — mắt đọc *ý định*, không
đọc *chữ*. Bước ⑦ đã giải đúng nhu cầu đó bằng session mới cho ba vai. Bước ⑧ cần **cùng một thứ**,
và trước 3.5.0 nó mua bằng một đêm lịch. Một đêm đo **thời gian trôi qua**, không đo **việc đọc có
xảy ra không** — cùng người, cùng cái neo, sáng mai lướt 30 giây vẫn qua cổng.

---

## A. `/sdd-solo:verify UC-###` — bước ⑧

1. Tìm UC: `find specs/contexts -path "*use-cases/$1-*/$1.md"`. Không có → dừng, báo.
2. Kiểm đã chạy bước ⑦ chưa: mục `## Adversarial pass` phải có nội dung thật. Chưa có → dừng, bảo
   chạy `/sdd-solo:adversarial $1` trước. Đọc lại trước khi soi là đọc lại một bản sắp đổi.
3. **Chạy verify bằng subagent riêng** (Agent tool). Đây là chỗ không được rút gọn: subagent
   **không có context của buổi viết**, nên nó không bị neo **do cấu tạo**, chứ không phải do ai
   khai là mình không bị neo. Prompt = nội dung `.sdd/prompts/verify-pass.md`, kèm:
   - output của `"${CLAUDE_PLUGIN_ROOT}/scripts/context.sh" $1` — UC (bỏ ba mục dấu vết), flow,
     RULE/CON/ADR được trích, BR cha, architecture, entity/glossary. **Cộng thêm** `$1.sequence.md` nếu
     có, và **toàn bộ `specs/rules.md`** (verify soi cả rule UC *không* trích mà lẽ ra phải trích —
     đó là loại sai #4, context.sh cố ý không in rule không được trích).
   - `git log --oneline -20 -- <thư mục UC>` để soi được loại sai #2 (commit khai một đằng, file một nẻo)

   **Nếu spec có con số mô tả dữ liệu thật** (đếm dòng, tỉ lệ) thì subagent phải được phép **chạy
   lệnh đo lại** — đó là loại sai #7, và nó là loại duy nhất không thể phát hiện bằng cách đọc.
   Không có lệnh đo trong spec thì bản thân việc thiếu đó **đã là một phát hiện**; đừng tự bịa
   lệnh rồi coi như đã đối chiếu.
4. Trình từng `F#` bằng `AskUserQuestion`, **một phát hiện một lượt**, kèm **nguyên văn cả hai chỗ
   đang cãi nhau** như subagent đã trích. Bốn đầu ra hợp lệ:
   - → sửa spec (kèm ID chỗ sửa: `UC-009 Main 7` · `RULE-001` · `AC-6`)
   - → `Open Question` kèm quyết định tạm
   - → `không phải lỗi vì <lý do>` — **bác phải rẻ**, một dòng là đủ; nhưng **lý do phải được ghi
     lại**, để lần chạy sau không moi lại đúng câu đó
   - → `Chưa quyết` — luôn hiện sẵn
5. Ghi vào mục `## Đọc lại` của file UC, **đúng dạng này vì cổng đọc nó bằng máy**:
```
## Đọc lại
- Ngày chạy: YYYY-MM-DD · Đầu chưa neo: subagent
- F1 <phát hiện> [neo: Main 7 · RULE-003] → sửa UC-009 Main 7
- F2 <phát hiện> [neo: AC-6] → không phải lỗi vì <lý do>
```
   Cổng đòi **ít nhất một** dòng `F#` có **cả `[neo: ...]` lẫn đầu ra khác `___`**. Đó là toàn bộ
   chốt chống khai gian: bịa một dòng như vậy tốn đúng bằng đọc thật.
6. Sửa những chỗ user chọn sửa. **Rồi QUÉT LẠI CẢ CÂY trước khi commit — bắt buộc, không bỏ:**

```bash
# với MỖI con số / quyết định vừa đổi, tìm giá trị CŨ trên cả cây
grep -rn '<giá trị cũ>' specs/ scripts/ *.md
```
   Còn hit nào **ngoài** `## History` và **ngoài** câu dạng `<cũ> → <mới>` thì **chưa xong**.

   **Quét cả giá trị MỚI, không chỉ giá trị cũ.** Bước sửa **tự sinh lỗi mới**: đổi sang một
   `RULE-###` chưa có heading, đổi rồi đổi lại, gõ nhầm một `AC-#`. Quét giá trị cũ không thấy
   những cái đó — chúng là giá trị *mới* nằm sai chỗ.

   **Và mục `## Đọc lại` KHÔNG được miễn.** Nó ghi lại việc sửa, nên nó **trôi như mọi chỗ khác**,
   và trôi ngay trong chính lượt đang sửa. Ca thật (`runxops`): sửa `RULE-006 → RULE-007`, thấy
   `RULE-007` chưa có heading nên đổi lại — **thân sửa xong, dòng `F#` ghi lại việc sửa thì
   không**. Cổng bắt, verify không, vì verify đã chạy xong từ trước. **Chỗ ghi lại việc sửa cũng
   là một chỗ phải sửa.** (`gate-check` nay kiểm mọi ID khai trong `## Đọc lại` có thật — cùng
   luật §7 dành cho adversarial, #12.)

   **Vì sao phép quét này nằm ở đây chứ không ở `verify-pass.md`:** luật quét chỉ có nghĩa **sau**
   khi sửa — trước khi sửa thì chưa có "giá trị cũ" nào để quét theo. Mà hai vai verify chạy
   **trước** khi sửa. Đặt luật ấy trong prompt của họ là đặt nó vào một cơ chế **cấu tạo không
   chạy được nó** — và đó không phải chuyện ai quên, mà là **đặt sai bước**.

   Ca thật (`runxops`): cặp số cũ nằm ở **bốn** chỗ — `entities.md` · `br.md` · docstring một
   script · và prompt của chính plugin. **Hai vai verify đọc rất kỹ vẫn bỏ sót chỗ thứ tư.** Thứ
   bắt được nó là một `grep -rn` chạy **sau** khi sửa. Người đọc không thấy chỗ mình không nghĩ tới
   là có; `grep` không cần nghĩ.

7. Rồi commit **riêng, đúng tiêu đề này** — cổng nhận diện bằng nó:
```bash
git add specs/ && git commit -m "docs($1): đọc lại — <n> phát hiện, <m> phải sửa"
```
8. Nói với user: giờ chạy `/sdd-solo:gate $1` được ngay, **không cần đợi qua đêm**. Nếu lần đọc
   này không ra dòng `F#` nào có đầu ra thật thì cửa thứ hai **không mở** — rơi về luật cũ, đợi
   một đêm. Nói thẳng điều đó, đừng để user chạy cổng rồi mới ngạc nhiên.

---

## B. `/sdd-solo:verify` — quét cây

Dùng khi tài liệu vừa đổi nhiều và cần biết còn chỗ nào nói ngược nhau. Không gắn với cổng nào.

1. **Chọn phạm vi trước, đừng đọc thưa cả cây.** Cây nhỏ (< ~3.000 dòng) thì đọc hết. Lớn hơn:
   lấy `git diff --name-only <lần verify trước>..HEAD -- specs/` cộng **mọi file mà đám đó trích ID
   tới** (`RULE-###` → `rules.md`, `CON-###`/`BR-###` → `br.md`, `UC-###` → file UC đó). Đọc thưa
   cả cây là cách chắc chắn nhất để bỏ sót loại sai #3 và #4, vốn là hai loại hay gặp nhất.
2. Chạy **subagent** với `.sdd/prompts/verify-pass.md` trên phạm vi đó. Cây lớn thì chia theo
   tầng — một agent BR↔RULE, một agent UC↔AC↔flow, một agent entities↔glossary — nhưng **mỗi agent
   vẫn phải thấy cả hai phía** của cặp nó soi, nếu không nó chỉ đọc được một nửa cuộc cãi.
3. Trình từng `F#` như phần A bước 4.
4. Ghi kết quả vào `specs/internal/verify-<YYYY-MM-DD>.md`: phạm vi đã đọc, từng `F#` kèm nguyên
   văn hai phía, đầu ra. **Cả những dòng bị bác cũng ghi, kèm lý do bác** — đó là thứ làm lần chạy
   sau rẻ đi, và là thứ duy nhất còn lại sau khi đóng terminal.
5. Sửa những chỗ user chọn, rồi `git commit -m "docs: verify pass <ngày> — <n> phát hiện"`.

---

## Giới hạn — nói với user, không giấu

1. **Lý do bác phải đến từ người ĐỌC phát hiện, không từ người VIẾT spec.** Đừng đưa trước cho
   subagent một danh sách *"ngữ cảnh giúp bác nhanh"* do tác giả spec soạn — nó sẽ bác đúng những
   chỗ tác giả tin là mình không sai, tức lấy mất chỗ đứng của cả lượt verify.
2. **Nó sinh dương tính giả.** Đó là giá của việc đọc nghĩa thay vì đếm — và là lý do skill này
   **không phải** một script trong cổng: một phép kiểm báo đỏ oan sẽ bị học cách phớt lờ, rồi kéo
   theo cả những dòng đỏ thật.
3. **"Không thấy gì" là bằng chứng yếu.** Không được nói *"tài liệu nhất quán"* hay *"đã kiểm toàn
   bộ"*. Câu đúng: *"lần đọc này không tìm ra gì trong phạm vi đã đọc"* — **kèm liệt kê phạm vi**.
4. **Không thay bước ⑦.** Ba vai hỏi *"spec chưa trả lời gì"*; verify hỏi *"spec có tự mâu thuẫn
   không"*. Chạy verify rồi bỏ adversarial là bỏ mất câu hỏi đắt nhất của cả quy trình.

Không viết code. Không tự sửa spec khi user chưa chọn.
