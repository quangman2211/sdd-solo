# specs/ — source of truth nghiệp vụ

## Bắt đầu từ đâu

Chỉ còn `core/br-000/` mẫu → **`/sdd-solo:intake`**. Bước 0 của nó là `vision.md` — chủ dự án nói
hướng đi bằng lời thường, intake chép; rồi bảy câu để viết BR đầu tiên vào đúng nghề.
Cầm sẵn brief của agent khác thì `/sdd-solo:intake duong/dan/brief.md`.
Muốn tự viết: đọc `BR-000` mẫu trong `core/br-000/br.md`, và `_intake.md` là bảy câu đó bản giấy bút.

Có BR rồi mới tới UC: `/sdd-solo:start UC-###`. Ngược lại là xây trên nền chưa viết —
`/sdd-solo:status` sẽ báo đỏ.

## Ba tầng chỗ (7.0)
```
specs/
  vision.md · glossary.md · rules.md · architecture.md · decisions.md · adr/   ← GỐC: xuyên suốt cả dự án
  changes/ · traceability.md
  core/                                                                       ← LÕI: dùng chung, ngang hàng nghề
    entities/<Tên>.md            mỗi entity một file
    br-###/                      một lát của lõi
      br.md · evidence.md · use-cases/UC-###-slug/{UC-###.md, UC-###.flow.md, screens/, design.md, tasks.md}
  <nghề>/                                                                     ← NGHỀ: mỗi thời điểm một nghề mở
    glossary.md · rules.md · adr/ · entities/<Tên>.md    riêng nghề
    br-###/ …                                            mỗi lát một BR
```
Luật ranh giới: gốc và `core/` **không trích ID của nghề**; nghề trích gốc và `core` thoải mái.
`src/core` không import `src/<nghề>`. `layer-check.sh` kiểm; githook `pre-commit.d/20-layer-boundary` chặn.
Không còn "context" như đơn vị thư mục (T3, 2026-09-18); tên context cũ chỉ còn trong glossary nếu cần.

## Ranh giới
- **hướng** = đi về đâu, không co lại cái gì, nghề nào mở khi nào. → `vision.md` (tầng 0, chủ dự án viết, miễn luật "không số")
- **spec** = hệ thống phải hành xử thế nào. Khách hàng cảm nhận được. Đổi khi nghiệp vụ đổi. → `core/` · `<nghề>/`
- **kiến trúc & quyết định** = xây bằng cách nào, vì sao. → gốc `architecture.md` · `adr/` · `decisions.md`
- **change** = thay đổi đang đề xuất trên hành vi đã ship. → `changes/` (Phase 5)
- **state** = đang làm tới đâu. → `STATE.md` (root, không nằm trong specs/)
- **vết quá trình** = hỏi đáp giữa agent, biên bản soát, bản đồ. → `notes/{hoi-dap,soat,ban-do}/` (ngoài specs/)
- **dấu vết** = giấy nháp đã dùng xong: `UC-###.trace.md` (adversarial · đọc lại · history sau khi UC đóng)
  và `evidence.md` của lát (thân chứng cứ của `## Background`). Mở khi tranh chấp, không phải file đọc thường;
  `context.sh` và `decisions.sh` không đọc chúng.

Một câu hỏi, một nơi trả lời. Nơi khác chỉ trích ID, không chép nội dung.

Khuôn UC/nghề/lát/entity/change nằm trong plugin (`templates/skel/`), skill copy khi cần — không rơi
vào dự án. Phase 0 (Design System) và Phase 4 (feedback) **chưa có lệnh**; cần thì mở issue.

## Hệ ID
| Họ | Trả lời | File |
|---|---|---|
| — | Đi về đâu, không thu hẹp gì | `specs/vision.md` |
| BR-### | Vì sao làm lát này | `specs/<core\|nghề>/br-###/br.md` — một dãy số cho cả dự án |
| UC-### | Ai làm gì | `specs/<core\|nghề>/br-###/use-cases/UC-###-slug/UC-###.md` |
| UC-###/AC-# | Biết đúng bằng cách nào | trong file UC |
| RULE-### | Ràng buộc xuyên nhiều UC | `specs/rules.md` (xuyên suốt) · `specs/<nghề>/rules.md` (riêng nghề) — một dãy số |
| CON-### | Ràng buộc kỹ thuật / pháp lý / thời gian | trong mục Constraints của BR |
| ENT | Khái niệm, quan hệ, trạng thái | `specs/core/entities/<Tên>.md` · `specs/<nghề>/entities/<Tên>.md` |
| SCR-###-# | Màn hình / trạng thái màn hình của UC-### | `.../UC-###-slug/screens/` |
| ADR-### | Vì sao xây thế này | `specs/adr/ADR-###-slug.md` · `specs/<nghề>/adr/` — một dãy số |
| CHG-### | Thay đổi trên baseline | `specs/changes/CHG-###-slug/` |

## Dự án này đã quyết những gì

```bash
.sdd/scripts/decisions.sh
```

Một màn hình, **mọi quyết định của dự án xếp theo thời gian** — gom từ CON của mọi BR, RULE gốc và
nghề, ADR gốc và nghề, `## Cấm` của `architecture.md`, `decisions.md`. Sinh ra lúc đọc, không phải
file để commit: một bản sao thì trôi khỏi nguồn, mà trôi thì lại đúng cái bẫy "báo xanh sai" cả bộ
kiểm này sinh ra để chống.

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
2. `specs/vision.md` — đi về đâu, nghề nào đang mở.
3. `.sdd/scripts/decisions.sh` — dự án đã quyết những gì, theo thứ tự thời gian.
4. `.sdd/scripts/context.sh UC-###` — trọn bối cảnh đang hiệu lực của UC đang làm, một lệnh.
5. `specs/architecture.md` — ngăn xếp, ranh giới, điều cấm (đã nằm trong 4, đọc riêng khi sửa nó).

## Trạng thái UC
`draft` → `reviewed` (qua cổng DoR) → `implemented` (qua DoD) → `deprecated`
