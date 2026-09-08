---
name: adversarial
description: Bước ⑦ — adversarial pass ba vai (khách cuối, vận hành/kế toán, kẻ lợi dụng) đọc spec một UC và liệt kê câu hỏi spec chưa trả lời; ghi kết quả vào mục Adversarial pass của UC; kết thúc bằng commit docs(UC-###). Thay cho reviewer nghiệp vụ khi làm một mình.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read Write Edit Grep Agent
---

Adversarial pass cho `$1`.

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
