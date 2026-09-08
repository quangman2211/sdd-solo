---
name: adversarial
description: Bước ⑦ — adversarial pass ba vai (khách cuối, vận hành/kế toán, kẻ lợi dụng) đọc spec một UC và liệt kê câu hỏi spec chưa trả lời; ghi kết quả vào mục Adversarial pass của UC; kết thúc bằng commit docs(UC-###). Thay cho reviewer nghiệp vụ khi làm một mình.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read Write Edit Grep Agent
---

Adversarial pass cho `$1`.

1. Tìm file UC: `find specs/contexts -path "*use-cases/$1-*/$1.md"`. Đọc nó, `specs/glossary.md`, các `RULE-###` nó trích trong `specs/rules.md`, và `entities.md` của context.
2. Kiểm tiền điều kiện, thiếu thì dừng và nói rõ: có `## Main Flow` có nội dung; có ≥ 1 `### AC-`; có ≥ 1 E# trong Exceptions; bảng `## Screens` có ít nhất một dòng. Adversarial pass trên spec rỗng là vô ích.
3. **Chạy ba vai bằng subagent riêng** (Agent tool, mỗi vai một agent, không dùng context của session này để tránh bị neo bởi giả định đã có). Prompt cho mỗi agent: nội dung `.sdd/prompts/adversarial-pass.md` trong repo, phần vai tương ứng, kèm toàn bộ UC + glossary + RULE liên quan. Ràng buộc chuyển nguyên văn: chỉ hỏi, không đề xuất code/kiến trúc, không sửa spec, tối đa 12 câu, xếp theo hậu quả (tiền / quyền / dữ liệu khách trước), mỗi câu kèm bước/E#/AC liên quan.
4. Gộp kết quả, bỏ trùng, ghi vào mục `## Adversarial pass` của file UC theo dạng:
```
- Ngày chạy: YYYY-MM-DD · Session mới: [x]
- Vai khách cuối:
  - Q1 <câu hỏi> [liên quan: bước N / E# / AC-#] → <đầu ra: spec | Open Question | Out of Scope | ___>
- Vai vận hành/kế toán: ...
- Vai kẻ lợi dụng: ...
```
Cột "đầu ra" để `___` — **user quyết**, không tự điền.
5. Trình cho user từng câu, hỏi user chọn đầu ra. Với mỗi lựa chọn:
   - spec → sửa đúng chỗ (thêm E#, AC, sửa RULE trong `rules.md`, thêm dòng Screens), rồi `## History` v+1 ghi "sau adversarial pass vai ___".
   - Open Question → thêm `- [ ] <câu> (quyết định tạm: <user nói>)`.
   - Out of Scope → thêm vào BR liên quan trong `specs/br.md`.
   Không được để câu nào không có đầu ra.
6. Kết thúc: `git add specs/ && git commit -m "docs($1): spec vN — sau adversarial pass"`. Commit này là điều kiện để `/sdd-solo:gate` kiểm "ngủ qua đêm" — gate sẽ đỏ nếu chạy cùng ngày.
7. STATE.md: `Đang làm: $1 · bước ⑧ — chờ đọc lại buổi sau`. Nói với user: **đóng máy, không code hôm nay**; buổi sau đọc lại với vai người trả lời ticket rồi `/sdd-solo:gate $1`.
