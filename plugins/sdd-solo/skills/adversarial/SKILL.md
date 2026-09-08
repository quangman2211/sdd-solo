---
name: adversarial
description: Adversarial pass ba vai đọc spec và liệt kê câu hỏi spec chưa trả lời. UC-### (bước ⑦) dùng ba vai khách cuối / vận hành / kẻ lợi dụng và hỏi về hành vi; BR-### (Phase 1) dùng ba vai người trả tiền / người vận hành mãi / người hoài nghi và hỏi về lý do tồn tại. Thay cho reviewer nghiệp vụ khi làm một mình.
disable-model-invocation: true
argument-hint: "UC-### | BR-###"
allowed-tools: Bash Read Write Edit Grep Agent
---

Adversarial pass cho `$1`.

`$1` bắt đầu bằng `UC-` → **phần A**. Bắt đầu bằng `BR-` → **phần B**. Khác hai dạng đó thì dừng và hỏi lại.

---

## A. Tầng UC — bước ⑦

1. Tìm file UC: `find specs/contexts -path "*use-cases/$1-*/$1.md"`. Đọc nó, `specs/glossary.md`, các `RULE-###` nó trích trong `specs/rules.md`, và `entities.md` của context.
2. Kiểm tiền điều kiện bằng **script**, không tự đánh giá — bốn điều kiện cũ đo cấu trúc nên template rỗng qua hết (#11):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/uc-ready.sh" $1
```
Exit ≠ 0 → **dừng**, in nguyên output, nói user viết xong nội dung rồi chạy lại. Không chạy ba vai trên spec còn placeholder.
3. **Chạy ba vai bằng subagent riêng** (Agent tool, mỗi vai một agent, không dùng context của session này để tránh bị neo bởi giả định đã có). Prompt cho mỗi agent: nội dung `.sdd/prompts/adversarial-pass.md` trong repo, phần vai tương ứng, kèm toàn bộ UC + glossary + RULE liên quan. Ràng buộc chuyển nguyên văn: chỉ hỏi, không đề xuất code/kiến trúc, không sửa spec, tối đa 12 câu, xếp theo hậu quả (tiền / quyền / dữ liệu khách trước), mỗi câu kèm bước/E#/AC liên quan.
4. Gộp kết quả, bỏ trùng, ghi vào mục `## Adversarial pass` của file UC theo dạng:
```
- Ngày chạy: YYYY-MM-DD · Session mới: [x]
- Vai khách cuối:
  - Q1 <câu hỏi> [liên quan: bước N / E# / AC-#] → <đầu ra: ___>
- Vai vận hành/kế toán: ...
- Vai kẻ lợi dụng: ...
```
Cột "đầu ra" để `___` — **user quyết**, không tự điền. Khi user chọn, ghi kèm **ID của thứ đã tạo**:
`→ spec: RULE-003` · `→ spec: E4, AC-5` · `→ Open Question` · `→ Out of Scope`.
Lời khai `→ spec` trống không kiểm được, và `gate-check` sẽ bắt (#12).
5. Trình cho user từng câu, hỏi user chọn đầu ra. Với mỗi lựa chọn:
   - spec → sửa đúng chỗ (thêm E#, AC, sửa RULE trong `rules.md`, thêm dòng Screens), rồi `## History` v+1 ghi "sau adversarial pass vai ___".
   - Open Question → thêm `- [ ] <câu> (quyết định tạm: <user nói>)`.
   - Out of Scope → thêm vào BR liên quan trong `specs/br.md`.
   Không được để câu nào không có đầu ra.
6. Kết thúc: `git add specs/ && git commit -m "docs($1): spec vN — sau adversarial pass"`. Commit này là điều kiện để `/sdd-solo:gate` kiểm "ngủ qua đêm" — gate sẽ đỏ nếu chạy cùng ngày.
7. STATE.md: `Đang làm: $1 · bước ⑧ — chờ đọc lại buổi sau`. Nói với user: **đóng máy, không code hôm nay**; buổi sau đọc lại với vai người trả lời ticket rồi `/sdd-solo:gate $1`.

---

## B. Tầng BR — Phase 1

Ba vai của tầng UC hỏi về **hành vi**. Tầng BR cần vai hỏi về **lý do tồn tại** — đó là câu hỏi khác hẳn, và không hỏi ở đây thì không còn chỗ nào hỏi nữa.

1. Đọc mục `# $1:` trong `specs/br.md`, cùng `specs/_intake.md` để biết bộ câu hỏi đã dùng.
2. Kiểm tiền điều kiện:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/br-check.sh" $1
```
Còn dòng ✗ → **dừng**, in output, bảo user viết xong BR rồi chạy lại. Cảnh báo `___` thì **cứ chạy tiếp** — `___` là trạng thái hợp lệ ở Phase 1, và mấy chỗ `___` chính là thứ ba vai sẽ soi.
3. **Chạy ba vai bằng subagent riêng** (Agent tool, mỗi vai một agent). Prompt: phần *Ba vai tầng BR* trong `.sdd/prompts/adversarial-pass.md`, kèm toàn bộ mục BR. Ràng buộc như tầng UC: chỉ hỏi, không đề xuất giải pháp, không sửa spec, tối đa 8 câu mỗi vai.

   - **Người trả tiền** — vì sao việc này đáng làm **trước** việc khác? không làm thì mất gì **đo được**? con số baseline lấy ở đâu?
   - **Người sẽ phải vận hành nó mãi** — ai chịu trách nhiệm khi nó hỏng lúc 2 giờ sáng? cái gì trong Out of Scope hôm nay sẽ thành ticket tuần sau?
   - **Người hoài nghi** — dòng `**Vì sao vẫn xây:**` trong Background nói gì? nếu nó ghi *"chưa có lý do"* thì **bắt đầu từ đó**: đã cân phương án không-phần-mềm nào chưa, cân xong chưa? có cách nào đạt Goal mà **không xây gì** không? BR này có thật là một BR, hay là một giải pháp đã chọn sẵn rồi viết ngược thành lý do?

   Vai thứ ba là vai quan trọng nhất và không có ở tầng UC. *"BR: xây dashboard theo dõi đơn hàng"* không phải BR — đó là giải pháp; BR thật nằm ở câu hỏi *vì sao cần theo dõi*. Nếu vai này kết luận BR đang là giải pháp viết ngược, **dừng và viết lại BR**, đừng ghi nó thành một Open Question rồi đi tiếp.

4. Ghi vào mục `## Adversarial pass` của BR:
```
- Ngày chạy: YYYY-MM-DD · Session mới: [x]
- Vai người trả tiền:
  - Q1 <câu hỏi> → <đầu ra: ___>
- Vai người sẽ vận hành nó mãi: ...
- Vai người hoài nghi: ...
```
5. Trình từng câu cho user chọn đầu ra. Bốn đầu ra hợp lệ, không có "để đó":
   - → `## Background` (kèm **nguồn** của con số; không có nguồn thì không phải Background)
   - → `## Open Questions` kèm quyết định tạm
   - → `## Out of Scope` + một nhánh `-.->` trên Impact Map
   - → một `CON-###` mới trong `## Constraints`
6. Chạy lại `br-check.sh $1`, rồi `git add specs/br.md && git commit -m "docs($1): BR sau adversarial pass"`.
7. STATE.md: `Đang làm: $1 · Phase 1 xong`. `Việc tiếp theo: /sdd-solo:start UC-### cho UC đầu tiên trong ## Related Use Cases`.

Không viết code. Không tạo thư mục UC.
