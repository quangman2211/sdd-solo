# specs/ — source of truth nghiệp vụ

## Bắt đầu từ đâu

`specs/br.md` còn nguyên template → **`/sdd-solo:intake`**. Nó hỏi bảy câu rồi viết BR giúp.
Cầm sẵn brief của agent khác thì `/sdd-solo:intake duong/dan/brief.md`.
Muốn tự viết: đọc `BR-000` mẫu trong `br.md`, và `_intake.md` là bảy câu đó bản giấy bút.

Có BR rồi mới tới UC: `/sdd-solo:start UC-###`. Ngược lại là xây trên nền chưa viết —
`/sdd-solo:status` sẽ báo đỏ.

## Ranh giới
- **spec** = hệ thống phải hành xử thế nào. Khách hàng cảm nhận được. Đổi khi nghiệp vụ đổi. → `specs/`
- **kiến trúc & quyết định** = xây bằng cách nào, vì sao. → `specs/internal/` (`architecture.md` · `adr/` · `decisions.md`)
- **change** = thay đổi đang đề xuất trên hành vi đã ship. → `specs/changes/` (Phase 5)
- **state** = đang làm tới đâu. → `STATE.md` (root, không nằm trong specs/)
- **dấu vết** = giấy nháp đã dùng xong: `UC-###.trace.md` (adversarial · đọc lại · history sau khi UC đóng)
  và `br.evidence.md` (thân chứng cứ của `## Background`). Mở khi tranh chấp, không phải file đọc thường;
  `context.sh` và `decisions.sh` không đọc chúng.

Một câu hỏi, một nơi trả lời. Nơi khác chỉ trích ID, không chép nội dung.

Từ 5.0.0 khuôn chỉ rơi vào dự án **16 file** (trước: 43). Khuôn UC/context/change nằm trong plugin
(`templates/skel/`), skill copy khi cần. Phase 0 (Design System) và Phase 4 (feedback) **chưa có lệnh**
— không có file nào hứa hộ chúng nữa; cần thì mở issue.

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

Chiều ngược lại — *tính năng này do cái gì quyết định?*:

```bash
.sdd/scripts/context.sh UC-### --why
```

chỉ in RULE · CON · ADR mà UC đó trích, kèm `## Cấm`. Bỏ `--why` thì in **trọn bối cảnh đang hiệu lực**
của UC — đó là thứ agent đọc trước khi thiết kế hay viết code, thay cho 15 file rải sáu thư mục.

## Cách đọc repo (cho người mới và cho session AI mới)
1. `STATE.md` — đang đứng ở bước nào.
2. `.sdd/scripts/decisions.sh` — dự án đã quyết những gì, theo thứ tự thời gian.
3. `.sdd/scripts/context.sh UC-###` — trọn bối cảnh đang hiệu lực của UC đang làm, một lệnh.
4. `specs/internal/architecture.md` — ngăn xếp, ranh giới, điều cấm (đã nằm trong 3, đọc riêng khi sửa nó).

## Trạng thái UC
`draft` → `reviewed` (qua cổng DoR) → `implemented` (qua DoD) → `deprecated`
