# specs/ — source of truth nghiệp vụ

## Bắt đầu từ đâu

`specs/br.md` còn nguyên template → **`/sdd-solo:intake`**. Nó hỏi bảy câu rồi viết BR giúp.
Cầm sẵn brief của agent khác thì `/sdd-solo:intake duong/dan/brief.md`.
Muốn tự viết: đọc `BR-000` mẫu trong `br.md`, và `_intake.md` là bảy câu đó bản giấy bút.

Có BR rồi mới tới UC: `/sdd-solo:start UC-###`. Ngược lại là xây trên nền chưa viết —
`/sdd-solo:status` sẽ báo đỏ.

## Ranh giới
- **spec** = hệ thống phải hành xử thế nào. Khách hàng cảm nhận được. Đổi khi nghiệp vụ đổi. → `specs/`
- **doc** = mình đã chọn xây bằng cách nào và vì sao. Chỉ người xây quan tâm. → `docs/`
- **change** = thay đổi đang đề xuất trên hành vi đã ship. → `changes/` (Phase 5)
- **state** = đang làm tới đâu. → `STATE.md` (root, không nằm trong specs/)

Một câu hỏi, một nơi trả lời. Nơi khác chỉ trích ID, không chép nội dung.

## Hệ ID
| Họ | Trả lời | File |
|---|---|---|
| BR-### | Vì sao làm | `specs/br.md` |
| UC-### | Ai làm gì | `specs/contexts/<ctx>/use-cases/UC-###-slug/UC-###.md` |
| UC-###/AC-# | Biết đúng bằng cách nào | trong file UC |
| RULE-### | Ràng buộc xuyên nhiều UC | `specs/rules.md` — nơi duy nhất |
| CON-### | Ràng buộc kỹ thuật / pháp lý / thời gian | trong mục Constraints của BR |
| ENT | Khái niệm, quan hệ, trạng thái | `specs/contexts/<ctx>/entities.md` |
| SCR-###-# | Màn hình / trạng thái màn hình của UC-### | `.../UC-###-slug/screens/` |
| ADR-### | Vì sao xây thế này | `docs/adr/` |
| CHG-### | Thay đổi trên baseline | `changes/CHG-###-slug/` |

## Cách đọc repo (cho người mới và cho session AI mới)
1. `specs/glossary.md` — ngôn ngữ chung.
2. `specs/contexts/<ctx>/entities.md` — danh từ và vòng đời.
3. UC đang làm + `specs/rules.md` các RULE nó trích.
4. `docs/decisions.md` — quyết định kỹ thuật liên quan.
5. `STATE.md`.

## Trạng thái UC
`draft` → `reviewed` (qua cổng DoR) → `implemented` (qua DoD) → `deprecated`
