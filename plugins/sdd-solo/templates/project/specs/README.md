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
| ADR-### | Vì sao xây thế này | `specs/internal/adr/ADR-###-slug.md` |
| CHG-### | Thay đổi trên baseline | `specs/changes/CHG-###-slug/` |

## Dự án này đã quyết những gì

```bash
.sdd/scripts/decisions.sh
```

Một màn hình, **mọi quyết định của dự án xếp theo thời gian** — gom từ cả sáu chỗ ở bảng
trên. Sinh ra lúc đọc, không phải file để commit: một bản sao thì trôi khỏi nguồn, mà trôi
thì lại đúng cái bẫy "báo xanh sai" cả bộ kiểm này sinh ra để chống.

Xếp theo thời gian là chủ ý. Hai quyết định viết cách nhau vài tháng, đọc rời từng file thì
cả hai đều trôi chảy; nằm cạnh nhau trên một dòng thời gian thì cái sau ngặt hơn cái trước
tự lộ ra. Đó là thứ không phép kiểm cơ học nào bắt được, nhưng mắt người bắt được ngay.

`--md` để xuất bảng markdown khi cần dán đi chỗ khác.

## Cách đọc repo (cho người mới và cho session AI mới)
1. `.sdd/scripts/decisions.sh` — dự án đã quyết những gì, theo thứ tự thời gian.
2. `specs/glossary.md` — ngôn ngữ chung.
3. `specs/contexts/<ctx>/entities.md` — danh từ và vòng đời.
4. UC đang làm + `specs/rules.md` các RULE nó trích.
5. `specs/internal/architecture.md` — ngăn xếp, ranh giới, điều cấm.
6. `STATE.md` — đang đứng ở bước nào.

## Trạng thái UC
`draft` → `reviewed` (qua cổng DoR) → `implemented` (qua DoD) → `deprecated`
