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
   - file UC `$1.md`, `$1.flow.md`, `$1.sequence.md` nếu có
   - `entities.md` + `glossary.md` của context, `specs/rules.md`, mục BR mà UC trỏ tới trong `specs/br.md`
   - `git log --oneline -20 -- <thư mục UC>` để soi được loại sai #2 (commit khai một đằng, file một nẻo)
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
6. Sửa những chỗ user chọn sửa. Rồi commit **riêng, đúng tiêu đề này** — cổng nhận diện bằng nó:
```bash
git add specs/ && git commit -m "docs($1): đọc lại — <n> phát hiện, <m> phải sửa"
```
7. Nói với user: giờ chạy `/sdd-solo:gate $1` được ngay, **không cần đợi qua đêm**. Nếu lần đọc
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

## Ba giới hạn — nói với user, không giấu

1. **Nó sinh dương tính giả.** Đó là giá của việc đọc nghĩa thay vì đếm — và là lý do skill này
   **không phải** một script trong cổng: một phép kiểm báo đỏ oan sẽ bị học cách phớt lờ, rồi kéo
   theo cả những dòng đỏ thật.
2. **"Không thấy gì" là bằng chứng yếu.** Không được nói *"tài liệu nhất quán"* hay *"đã kiểm toàn
   bộ"*. Câu đúng: *"lần đọc này không tìm ra gì trong phạm vi đã đọc"* — **kèm liệt kê phạm vi**.
3. **Không thay bước ⑦.** Ba vai hỏi *"spec chưa trả lời gì"*; verify hỏi *"spec có tự mâu thuẫn
   không"*. Chạy verify rồi bỏ adversarial là bỏ mất câu hỏi đắt nhất của cả quy trình.

Không viết code. Không tự sửa spec khi user chưa chọn.
