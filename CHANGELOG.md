# Changelog

## 4.0.1 — 2026-09-10

### Sửa — `filled()` báo đỏ oan trên ba loại cú pháp markdown hợp lệ

Ca gốc, đo trên `runxops`: `## Background` của `BR-001` dài **425 dòng**, mỗi khối số kèm lệnh đo,
**không một `<...>` nào** — vẫn ra `✗ ## Background rỗng hoặc còn placeholder`. Thủ phạm là **đúng
một dòng, dòng 238**: một dấu `>` đơn độc.

`filled()` có nhánh `>[[:space:]]*$` để bắt nửa **đóng** của placeholder trải nhiều dòng
(`<Vì sao ...` mở ở dòng này, `...>` đóng ở dòng sau). Nhưng trong markdown, một dòng chỉ có `>` là
**dòng trống bên trong blockquote** — cú pháp hợp lệ và dùng thường xuyên.

**Đo rồi mới sửa, và phép đo tìm ra ba chứ không phải một.** Phiên báo lỗi thấy ca blockquote; chạy
đủ bộ ca thì hiện thêm hai:

| Nội dung trong `## Background` | Tới 4.0.0 | Đúng ra |
|---|---|---|
| `>` đơn (dòng trống trong blockquote) | ✗ | ✓ |
| `A["<b>x</b><br/>y"] --> B` (mermaid) | ✗ | ✓ |
| `<!-- chú thích -->` | ✗ | ✓ |

Ca thứ hai là **đúng cùng hình lỗi `<br/>`** vừa chữa cho `design-check` ở 4.0.0, chỉ nằm ở nhánh
khác nên lượt vá đó không với tới. Một kết luận đúng nằm đúng một chỗ thì không bảo vệ được chỗ kia
— luật này CHANGELOG đã ghi, và lần này chính nó tái diễn trong cùng một bản.

**Thuốc là liệt kê đích danh, không phải nới regex.** `strip_markup()` mới bỏ ba thứ trước khi đi
tìm placeholder: khối `<!-- ... -->` (kể cả trải nhiều dòng) · thẻ HTML **có tên trong danh sách**
(`b` `br` `i` `em` `strong` `code` …) · autolink `<https://…>`. Nửa đóng đổi thành
`[^[:space:]>=-]>[[:space:]]*$` — phải có ký tự thật ngay trước `>`, và `-`/`=` bị loại vì đó là
mũi tên mermaid (`A -->`), không phải nửa đóng.

**Đo 12 ca, hai chiều.** Tám ca phải xanh (văn xuôi · blockquote có dòng `>` rỗng · mermaid có
`<b>`/`<br/>` · so sánh `a > b` · chú thích một dòng · chú thích nhiều dòng · mũi tên cuối dòng ·
autolink) và bốn ca phải đỏ (placeholder một dòng · trải hai dòng · chỉ nửa mở · chỉ nửa đóng), cộng
bốn ca cho hai nhánh cũ (rỗng · `...` · `- ...` · có chữ thật). **16/16.** Chiều thứ hai quan trọng
ngang chiều thứ nhất: sửa đỏ oan mà làm hụt đỏ thật là đổi một lỗi lấy một lỗi tệ hơn.

Trên `br.md` thật của `runxops`: `BR CHƯA DÙNG ĐƯỢC — 1 lỗi` → `BR DÙNG ĐƯỢC`.

### Sửa — `filled()` và `nonempty()` có HAI bản sao y hệt nhau

Chúng nằm trong `br-check.sh` **và** `change-check.sh`, không nằm ở `lib.sh`. Nên một lượt vá chỉ
trúng một nửa — và phiên báo lỗi còn báo nhầm địa chỉ là `lib.sh:49`, vì ai cũng cho rằng thứ dùng ở
hai nơi thì phải ở chỗ chung. Bản sao im lặng còn tốn thêm một lần nữa: nó làm chính người đi sửa
tin rằng mình đã sửa xong.

4.0.1 đưa cả hai về **một bản duy nhất** trong `lib.sh`; hai script gọi bản chung. Đây là cùng lý do
`design-check.sh` cố ý kiểm cả hai mức trong một script thay vì tách đôi.

**Vì sao vá ngay thay vì gộp vào bản sau.** `BR-001` là BR duy nhất của `runxops`, nên mỗi lần chạy
`br-check` là thấy đúng **một** dấu ✗ — và nó sai. Đỏ oan thì bị học cách phớt lờ, rồi kéo theo cả
những dòng đỏ thật. Chỗ nó đứng còn hiểm hơn: `filled()` gác `## Background`, nơi chứa **toàn bộ số
đo** của tầng BR. Phép kiểm bảo vệ chỗ nhiều số nhất lại là phép kiểm bị vô hiệu hoá đầu tiên.

## 4.0.0 — 2026-09-10

**Đổi lớn: sdd-solo chạy trọn vòng bằng chính nó.** Phụ thuộc bắt buộc từ ba xuống **không** —
chỉ còn `git`. Bước ⑩ đổi chủ: `/speckit-plan` → `/sdd-solo:design`. Và tầng thiết kế — thứ bốn
tầng BR/UC/Entity/AC chưa bao giờ có chỗ cho — giờ có nhà, ở **hai mức**.

Repo đang chạy **phải sửa tay**: xem mục *Nâng cấp* ở cuối.

### Vì sao Spec Kit ra khỏi chuỗi — ba phép đo, không phải sở thích

**① Hai hệ tranh nhau một thư mục.** `.specify/scripts/bash/create-new-feature.sh` hardcode
`SPECS_DIR="$REPO_ROOT/specs"`, và `get_highest_from_specs` quét `specs/*` để lấy số kế tiếp — tức
nó đang đếm cả `br.md`, `contexts/`, `changes/` của sdd-solo. Ở `runxops`: `specs/001-assign-product-key/`
nằm cạnh `specs/contexts/`. Hai hệ ID (`001-` và `UC-###`), một thư mục, không bên nào biết bên kia.

**② Bước quyết kiến trúc chạy trên hai đầu vào rỗng.** `speckit-plan/SKILL.md` bước 2, nguyên văn:
*"Read FEATURE_SPEC and `.specify/memory/constitution.md`"* — đúng hai thứ. FEATURE_SPEC là bản mỏng
21 dòng **chính sdd-solo sinh ra**, chỉ chứa ID. Còn `runxops/.specify/memory/constitution.md` vẫn
nguyên placeholder `[PROJECT_NAME]`, 50 dòng chưa ai điền. **Brief không nằm trong hai đầu vào đó và
chưa bao giờ nằm.** Sự lệch ở #34 — plan viết ra kiến trúc ngược hẳn brief suốt hai ngày — không
phải tai nạn. Nó là hệ quả số học của hai đầu vào rỗng.

**③ "Spec Kit" không phải một thứ.** Bốn repo trên cùng một máy: 10 · 24 · 25 · 35 lệnh `speckit-*`.
Tài liệu của mình gọi đích danh 4 lệnh. Đặt tên lệnh của người khác vào **quy tắc cứng** nghĩa là
quy tắc đó hỏng theo lịch release của người khác.

Nên luật mới: **quy tắc cứng nói về TRẠNG THÁI REPO, không nói tên lệnh.** `CLAUDE.md.tmpl` và
`session-start.sh` giờ chặn *"viết code khi chưa có `.sdd/gate/UC-###.ok` hoặc chưa có `design.md`"*
thay vì chặn *"chạy `/speckit-*`"*. Spec Kit vẫn đáng cài và đáng đọc — nó update thường xuyên và là
nguồn tham khảo thiết kế tốt; hình dạng `design.md` học thẳng từ `plan.md` của nó. Chỉ một luật: nó
ghi vào `.speckit/`, không ghi vào `specs/`.

### Thêm — tầng thiết kế hai mức

**Mức dự án: `specs/internal/architecture.md`.** File này đã nằm trong template từ 1.x, **không
script nào kiểm và không bước nào sinh ra** — một cái ngăn có sẵn mà chưa ai được giao bỏ gì vào.
Giờ nó có sáu mục bắt buộc: `## Ngăn xếp` · `## Nơi chạy` · `## Ai gọi` · `## Ranh giới` · `## Cấm` ·
`## Đã chốt từ brief`. Mục cuối là **chỗ nhận hàng** của cơ chế `→ chuyển:` mà 3.21.0 vừa dựng: trước
4.0.0 đó là một địa chỉ có thật nhưng chưa có nhà.

`___` hợp lệ (chưa quyết được, nhưng biết là mình chưa quyết); `<...>` thì **đỏ** — cùng ranh giới
tầng BR đã dùng.

**Mức UC: `/sdd-solo:design UC-###` (bước ⑩)** sinh `design.md` + `tasks.md` **trong chính thư mục
UC**. Nó đọc **sáu nguồn** thay vì hai nguồn rỗng: UC + flow + AC · các RULE được trích · entities +
glossary · mục BR · **brief nguồn** · architecture.md + ADR. `design.md` bắt buộc có
`## Đối chiếu architecture.md` và `## Đối chiếu brief` — mỗi chỗ đi khác phải **nói ra** kèm ADR.

**`scripts/design-check.sh`** kiểm cả hai mức trong một script. Cố ý gộp: thứ kiểm `design.md` bắt
buộc phải đọc `architecture.md` để biết nó đối chiếu với cái gì; tách đôi là tạo hai script đọc cùng
một bộ file rồi trôi khỏi nhau. Đỏ khi: chưa qua cổng DoR · `architecture.md` thiếu mục hoặc còn
`<...>` · thiếu `design.md`/`tasks.md` · hai mục đối chiếu **rỗng** · ID trích không có thật · AC nào
của UC thiếu việc trong `tasks.md`, **và chiều ngược** — `tasks.md` nhắc một `AC-#` UC không có.

`close-check.sh` (bước ⑭) nay đỏ khi UC không có `design.md`: đóng một UC mà không có nó nghĩa là
code đã viết ra từ một quyết định kỹ thuật không nằm ở đâu cả, và *"chưa bàn"* trông y hệt *"đã bàn
rồi quên ghi"*.

### Sửa — gộp lại cho gọn: 19 script còn 16, 12 skill vẫn 12 nhưng một cái đổi việc

| Gộp | Từ | Thành |
|---|---|---|
| ba script "pass" | `gate-pass` · `close-pass` · `change-pass` | `pass.sh <gate\|close\|change> <ID>` |
| hai chỉ số | `trace-ratio` · `ac-coverage` | `metrics.sh` |
| cổng nhỏ trước ⑦ | `uc-ready.sh` | `gate-check.sh --pre` |
| chuyển bố cục | `migrate-1to2.sh` (bố cục 1.x, đã chết) | `migrate.sh` (tách cây Spec Kit) |
| skill | `/sdd-solo:update` | `/sdd-solo:init --plugin` |
| mới | — | `design-check.sh` · `skills/design/` |

`pass.sh` nhận **mode tường minh**, không đoán theo tiền tố ID: `UC-###` đi qua **hai** pass khác
nhau (⑨ gate và ⑭ close), tiền tố không phân biệt được, và một script tự đoán sai giữa `reviewed`
với `implemented` thì hỏng im lặng. Từng câu commit message giữ nguyên **đúng ký tự** — `gate-check`
§9 và githook nhận diện commit bằng tiêu đề.

`uc-ready` và `gate-check` đo cùng bốn thứ trên cùng một file ở hai thời điểm. Để tách là để hai phép
đo cùng một thứ trôi khỏi nhau — mà đó là loại hỏng repo này đã ghi nhiều lần.

`deps-check.sh` 122 dòng còn 53, và **không bao giờ đỏ vì một thứ tuỳ chọn** nữa. Nó chỉ còn kiểm
`git` + repo đã `git init`. Spec Kit · AIUP · Camunda mỗi thứ một dòng `–`. Thêm một cảnh báo có
điều kiện: `specs/` đang chứa thư mục `00N-*` thì chỉ đúng lệnh `migrate.sh --dry-run` — và **chỉ
nói khi thật sự có gì để dọn**, vì nói khi không có gì là dạy người ta phớt lờ dòng đó.

### Sửa — hai lỗi bắt được trong lúc test, cùng loại đang chữa

**`uc-steps` ⑩ mượn được dấu vết của UC khác.** Bản đầu quét `plan.md`/`tasks.md` ở **bất kỳ đâu**
dưới `specs/` — nên một `plan.md` của UC khác làm UC này báo *"đã thiết kế"*. Cùng hình lỗi với #32.
Sửa: hỏi đúng thư mục của chính nó. Đo: `UC-002` có `design.md` copy từ `UC-001` vẫn ra `?`.

**`design-check` báo đỏ oan trên `<br/>`.** Phép tìm placeholder `<...>` bắt luôn `<br/>` trong khối
mermaid của `architecture.md` — tức một file **đã điền xong** vẫn đỏ. Dòng đỏ oan thì bị học cách
phớt lờ, rồi kéo theo cả những dòng đỏ thật. Sửa bằng `strip_tags()` liệt kê **đích danh** những thẻ
HTML có thật trong template, không nới regex thành "bỏ mọi `<...>` ngắn". Lượt sửa đó đồng thời gỡ
một bộ lọc sai khác (`grep -v '"<'`) vốn đang **giấu** placeholder thật trong node mermaid.

### Nâng cấp — repo đang chạy phải làm tay

```
/plugin marketplace update sdd-solo   →   /plugin update sdd-solo
/sdd-solo:init --update
bash .sdd/scripts/migrate.sh --dry-run     # xem trước
bash .sdd/scripts/migrate.sh               # git mv, giữ history; KHÔNG tự commit
```
rồi **mở session mới**. Sau đó điền `specs/internal/architecture.md` — mọi UC chưa `implemented` sẽ
cần nó ở bước ⑩. `/sdd-solo:update` không còn; dùng `/sdd-solo:init --plugin`.

## 3.21.0 — 2026-09-10

### Sửa — brief thành file chỉ-ghi ngay sau intake, và không phép kiểm nào có nhiệm vụ nhìn tới nó (#34)

Ca thật ở `runxops`. Ngày 1: `/sdd-solo:intake` nạp một brief 259 dòng, sinh `specs/br.md` đúng
luật — kể cả mục `## Đã loại khỏi brief` dài 13 dòng, trong đó có:

> *"Mục 3 toàn bộ kiến trúc ba lớp — là thiết kế, thuộc `/speckit-plan` và ADR, không thuộc tầng BR"*

Ngày 3: `plan.md` được viết với kiến trúc **ngược hẳn brief**. Brief: một MCP server từ xa giữ token
của hàng trăm shop. Plan: plugin chạy trên máy khách, *"thông tin đăng nhập không bao giờ rời khỏi
máy"* — viết như một điểm mạnh. Hai tài liệu nói ngược nhau hai ngày, không ai thấy, vì **mỗi bên
tự nó nhất quán**.

`intake` không có lỗi. Nó làm đúng cả sáu luật. Chỗ hỏng nằm ở chữ *"thuộc `/speckit-plan`"*:
`/speckit-plan` đọc `spec.md` + `constitution.md`, nó **không đọc brief** và chưa bao giờ đọc.
Đó là **một địa chỉ chuyển tiếp mà không ai giao hàng** — và nó trông y hệt một việc đã bàn giao xong.

Loại hỏng này khác mọi loại đã ghi ở đây. Trước nay là *phép kiểm đo sai thứ* hoặc *phép kiểm báo
xanh sai*. Lần này **không phép kiểm nào sai cả** — chỉ là không phép kiểm nào được giao nhìn vào
vùng đó. `gate-check` đo trong `specs/`, `verify` đọc trong `specs/`, ba vai adversarial **cố ý** mù
với brief (để không mượn kết luận của người viết brief). Ba lớp phòng thủ, cùng một điểm mù.

**Sửa — và không chỗ nào trong số dưới đây một mình đủ:**

- `.sdd/config` có `brief_path=`; `lib.sh` có `brief_path()` · `brief_sha()` · `brief_rec_sha()`.
- **SessionStart nạp brief vào ngữ cảnh bắt buộc.** Đây là chỗ duy nhất trong cả bộ nhìn ra ngoài
  `specs/`. Kèm cảnh báo khi sha brief lệch bản đã nạp.
- `br-check.sh`: brief khai mà không có file → **đỏ**; `br.md` chưa ghi `**Nguồn brief:** <đường dẫn>
  · sha256 <12 hex> · nạp <ngày>` → cảnh báo; sha lệch → **đỏ** (brief sửa sau intake nghĩa là hai
  tài liệu có thể đang cãi nhau).
- `br-check.sh`: dòng trong `## Đã loại khỏi brief` mà lý do là **hoãn** (`thuộc tầng thiết kế`,
  `/speckit-plan`, `ADR`, `Phase 5`, `sau này`) thì phải ghi `→ chuyển: <đích>`. Hoãn không đích là
  hoãn vào hư không.
- `intake/SKILL.md` luật 7: sau khi chuyển brief, **bắt buộc** khai `brief_path=` và dán dòng
  `**Nguồn brief:**`. Không có bước này thì cả bốn chỗ trên nằm im — một luật không có ai sản xuất
  dấu vết cho nó thì không kiểm được gì.
- `CLAUDE.md.tmpl`: brief vào **thứ tự đọc bắt buộc**, mục 6.

### Thêm — cổng ⑨ hỏi giả định triển khai (#35, phương án nhẹ)

Bốn tầng yêu cầu (BR → UC → Entity → AC) **không có ngăn nào** cho *"dựng bằng gì · chạy ở đâu · ai
gọi"*. Nên thiết kế rơi hết vào `/speckit-plan`, mà `/speckit-plan` nằm **sau** cổng ⑨. Hệ quả: UC
qua cổng với Main Flow đứng trên một giả định chưa ai viết ra; hôm sau plan lộ ra giả định khác, ba
câu trong Main Flow không thi hành được, phải mở cổng ra sửa.

`gate-check.sh` §7c: thiếu dòng `**Giả định triển khai:** <chạy ở đâu · ai gọi · ngăn xếp>` →
**cảnh báo, không chặn**. Cổng không quyết hộ được kiến trúc; nhưng bắt *nói ra* thì rẻ, và nó bắt
đúng ca `runxops` vừa dính. Thêm vào `UC-000.md` và checklist DoR.

Đề xuất **nặng** của #35 — bỏ `/speckit-specify` khỏi chuỗi và kéo `/speckit-plan` lên trước cổng ⑨,
14 bước còn 13 — **chưa làm**: nó đổi thứ tự quy trình đã ghi trong tài liệu, thuộc quyền quyết của
anh, không phải của em hay của một phiên khác.

### Sửa — cảnh báo lệch sha ở SessionStart chưa bao giờ chạy được (bắt trong lúc test)

Bản đầu của khối này viết `grep -oE '\*\*Nguồn brief:\*\*[^\n]*sha256 ...'`. Trong ERE của `grep`,
`[^\n]` là *"mọi ký tự trừ `\` và `n`"* — không phải "trừ xuống dòng", vì `grep` vốn đã làm việc theo
dòng. Đường dẫn brief nào có chữ `n` (`runxops-brief.md` chẳng hạn) là hụt, và **hụt thì im**: khối
vẫn in dòng brief, chỉ thiếu đúng câu cảnh báo. Y hệt loại đang chữa — một vùng không ai nhìn tới.

Bắt được vì test hỏi *"câu cảnh báo có ra không"*, không hỏi *"khối có chạy không"*. Rút cả phép đo
về một chỗ (`brief_rec_sha()` trong `lib.sh`) để hai nơi dùng không thể lệch nhau nữa — `br-check`
viết đúng, `session-start` viết sai, cùng một con số, khác nhau ở một ký tự.

## 3.20.0 — 2026-09-10

### Sửa — `uc-steps` báo xanh sai: hai script của plugin, cùng một commit, hai kết luận ngược nhau (#32)

Lần đầu chạy `uc-steps.sh` trên một UC thật, nó in:

```
✓ ⑩⑪ Spec Kit + code (commit feat/fix mang UC-009)
```

Trong khi `src/` **không tồn tại**, `plan.md` và `tasks.md` **không có**, và **không một dòng code
sản phẩm nào**. Nó xanh vì đúng một commit — `feat(UC-009): script chuyển ItemSell…` — đụng
`scripts/itemsell-to-sheet.py`, tức **đúng `tool_paths`, thứ 3.19.0 vừa ship để khai rằng nó không
thuộc UC nào và không thể thuộc.**

**Cùng một commit, hai script của plugin, hai kết luận ngược nhau.** `trace-ratio.sh` (3.19.0) cố ý
loại nó ra kèm chú thích *"đếm nó vào commit có ID truy vết được là hỏi một câu không có câu trả
lời đúng"*. `uc-steps.sh` (3.18.0) lấy đúng commit ấy làm bằng chứng rằng code đã viết xong. **Hai
bản vá cách nhau một phiên bản và không biết đến nhau.**

- **⑩⑪ hỏi theo PHẠM VI FILE, không theo câu chữ trong message.** Cùng lý do đã nhận ở #31 — *thứ
  cần phân loại là file, không phải câu chữ*. Ở #31 nó áp cho phép **chặn**; ở đây cho phép **đọc**.
  Luật đã nằm trong code ba hôm trước, chỉ chưa áp hết chỗ.
- **Tách ⑩ khỏi ⑪** — hai bước, hai bằng chứng khác nhau: ⑩ có `plan.md`/`tasks.md` trong `specs/`;
  ⑪ có commit `feat`/`fix` mang ID **đụng `code_paths`/`test_paths` trừ `tool_paths`**. Gộp lại thì
  một bằng chứng yếu ở vế này che chỗ trống ở vế kia — đúng chuyện vừa xảy ra.

**Lần thứ ba trong ba ngày** của chỗ đã khai là chưa vá: *mọi luật kiểm ID **có tồn tại** không,
không luật nào kiểm ID **có dính gì** tới thứ đang gắn nó không.* Lần một hệ ID AIUP (#29) · lần
hai commit gắn ID không liên quan (#31) · lần ba `uc-steps` dùng ID trong message làm bằng chứng về
**nội dung** commit.

### Sửa — `repo_has_code` chưa biết `tool_paths` nên đỏ oan (#33)

`repo_has_code()` không loại `tool_paths`, nên `scripts/*.py` lọt qua và `trace-ratio` in *"repo có
file nguồn nhưng không commit nào đụng: src tests → sửa code_paths/test_paths"* trên một repo vừa
làm **đúng** thứ 3.19.0 bảo họ làm.

Đỏ oan, và tệ hơn im lặng một bậc vì **nó hướng người ta đi sửa một thứ đang đúng**: ai nghe lời sẽ
gỡ `tool_paths` hoặc nhét `scripts` vào `code_paths` — **quay ngược đúng cái bẫy #31 vừa gỡ**. Cùng
hình với #26, nơi một dòng đỏ oan tự tạo ra chính cái nó cảnh báo.

`status.sh` dùng chung `repo_has_code` nên mang cùng lỗi (chỗ #26 từng vá) — sửa ở `lib.sh` là cả
hai hết. Kèm một chỉnh nhỏ cho chính xác: khi đã khai `tool_paths`, câu *"repo chưa có code"* đổi
thành *"chưa có code sản phẩm; code công cụ đã khai ở tool_paths"* — repo **có** code, chỉ là code
không thuộc UC nào.

Bốn ca đo: `tool_paths` rỗng → vẫn cảnh báo (config có thể sai thật) · khai rồi → hết đỏ oan · có
code thật trong `src/` mà chưa commit nào đụng → **vẫn** cảnh báo · `status.sh` chuyển từ `✗` sang
một dòng `!` nói đúng tình trạng.

### Ghi nhận — phần còn lại của `uc-steps` đúng hết

`runxops` đối chiếu 13 dòng còn lại với bảng đếm tay: khớp. Cơ chế phân biệt *bỏ có ghi lý do* với
*quên làm* chạy đúng thiết kế — thêm dòng `**Bỏ bước ⑤:**` thì `?` chuyển sang `–` ngay.

Và đó chính là lý do #32 phải vá nhanh, ghi nguyên văn: **mười ba dòng kia đủ tin để người ta tin
luôn dòng thứ mười bốn.** Một bảng gần đúng nguy hiểm hơn một bảng sai hẳn.

## 3.19.0 — 2026-09-10

### Sửa — `ac-coverage` trộn hai câu hỏi vào một chỉ số (#30)

Trên `runxops`: `Tổng AC: 11` = `UC-009` (reviewed, 9 AC) + `UC-008` (**draft**, 2 AC). Khi
`UC-009` implement đủ, chỉ số đọc **9/11** — và **không thể lên 100%** chừng nào `UC-008` còn
draft, mà nằm draft nhiều tháng là chuyện `/sdd-solo:start` khuyến khích.

**Đây là loại sai #9 ở tầng chỉ số:** `82%` là con số **đúng** cho một câu hỏi **không ai đang
hỏi**. Nó trộn *"cái tôi đã cam kết có test chưa"* với *"spec xây được bao nhiêu"*. Và một chỉ số
không bao giờ đạt được đích thì bị thôi nhìn — đúng luật 3.4.2, ở một script khác.

Nay in **hai dòng, mỗi dòng khai rõ mẫu số**:

```
AC có test / AC của UC đã qua cổng:       9/9      ← đạt 100% được, nên mới có nghĩa để theo dõi
AC có test / AC của MỌI UC (kể cả draft): 9/11
```

### Thêm — `tool_paths`: code thật không thuộc UC nào (#31)

`runxops` có **695 dòng Python** trong `scripts/` không thuộc UC nào và **không thể thuộc**. Hook
cằn nhằn mỗi commit *"Thêm vào `code_paths` nếu đó là code thật"*. Nó **là** code thật. Làm đúng
lời khuyên rồi đo:

```
code_paths=src scripts
  fix(scripts): sửa lệnh đo    exit=1  ✗ phải có ID
  chore(scripts): dọn          exit=1  ✗ phải có ID
  fix(UC-009): sửa lệnh đo     exit=0
```

**Nghe lời hook thì hook chặn.** Ba đường ra, và đường **dễ đi nhất là gắn một ID không liên
quan** — lúc đó `id_exists` **cho qua** vì ID tồn tại thật, và `trace-ratio` đếm nó là đã truy vết.
Cùng hình #16, khác một chữ: lần đó nhãn bịa là ID **không tồn tại**; lần này ID **tồn tại nhưng
không liên quan**. Luật hiện tại kiểm *ID có thật không*, **không kiểm ID có dính gì tới commit
này không** — đúng chỗ vừa ghi khi đóng #29, giờ lộ ra ở tầng thứ hai.

**Và chỗ mâu thuẫn sắc nhất là của chính plugin này:** luật 5b (3.6.0) bắt *"số mô tả dữ liệu thật
phải ghi kèm lệnh đo ra nó"* — tức **plugin đang YÊU CẦU viết loại code này** — rồi hook không cho
commit nó mà không gắn ID giả. **Hai luật đều đúng; đặt cạnh nhau thì hở.**

- `tool_paths` trong `.sdd/config`: miễn ID ở cả hai githook, **không tính vào mẫu số**
  `trace-ratio`. **Mặc định rỗng** — repo chưa khai hành xử y hệt hôm nay.
- **Miễn trừ theo FILE, không theo câu chữ trong commit.** Phương án rẻ hơn (miễn theo tiền tố
  commit cấu hình được) bị bỏ vì thứ cần phân loại là **file**, không phải **câu chữ**: phân loại
  theo câu chữ thì ai gõ nhầm tiền tố là lọt, còn file thì không tự đổi chỗ.
- Cơ chế miễn trừ vốn đã có (`^Merge|^Revert|^chore\(sdd\)`), chỉ là đóng cứng vào một tiền tố.

Đo trên repo tạm, đủ ba chiều: trước khi khai `tool_paths` mọi thứ y như cũ · khai rồi thì commit
chỉ đụng `scripts/` qua mà **không cần ID** · commit đụng `src/` **vẫn bị chặn** như trước ·
`trace-ratio` bỏ `scripts` khỏi danh sách mẫu số.

### Thêm vào loại #7 — một PHÉP THỬ cũng là một phép đo

Ghi chú phương pháp từ `runxops`, và nó **suýt làm cả #31 không tồn tại**:

> Phép thử đầu cho `exit=0` cả ba dòng. Tôi dùng `touch` nên **không có gì được stage** — phép thử
> rỗng, mà kết quả trông y hệt *"hook cho qua, không có vấn đề gì"*. Nếu tôi tin nó thì kết luận sẽ
> **ngược hoàn toàn**.

Thứ bắt được nó là **con số trông vô lý** — ba dòng `exit=0` cạnh một nhánh `exit 1` đọc thấy rõ
trong code. Đúng luật 8, lần này áp cho một phép thử chứ không cho một con số trong tài liệu.

**Và nó xảy ra lần thứ hai ngay trong bản này**: phép thử githook đầu tiên của phiên plugin cho
`exit=127` ba dòng liền — gọi `.githooks/commit-msg` trong khi `core.hooksPath` là `.sdd/hooks`.
Lần đó `127` lộ liễu nên bắt được ngay; nếu nó là `0` thì đã báo cáo một kết quả rỗng. Một ca nữa
trong cùng lượt: `src/a.py` còn kẹt trong stage từ phép thử trước làm một ca "phải qua" thành
`exit=1`.

Luật thêm vào prompt: **trước khi tin một phép thử, in ra thứ nó đang đo** — danh sách file đã
stage, số dòng đầu vào, đường dẫn thật của lệnh.

## 3.18.0 — 2026-09-10

### Sửa — bước ② trỏ vào một lệnh không nên chạy, và không ai biết nó chưa chạy (#29)

**Cách nó lộ ra đáng kể hơn nội dung.** `UC-009` vừa qua cổng — 30 phát hiện verify, 30 phải sửa,
dương tính giả 0. Phiên viết spec soi lại 14 bước và báo *"② → ⑥ đều xong"*. Chủ dự án trả lời:
*"anh nhớ hình như anh chưa chạy `use-case-spec` bao giờ."*

Đúng. **Bước ② chưa từng chạy, suốt cả một UC đi trọn vòng**, và không phép kiểm nào hỏi tới. Lời
khai *"② xong"* dựa trên việc **kết quả tồn tại** — mà kết quả tồn tại vì nó được **viết tay**. Mọi
phép kiểm trong plugin đo **sản phẩm**; không cái nào đo **bước**. Người duy nhất biết sự thật là
người duy nhất gõ được lệnh.

**Rồi đọc `SKILL.md` của `aiup-core` thì hoá ra không nên chạy.** Đo trên bản cài, 4/4 lệnh:

| Lệnh AIUP | Ghi ra | Ta cần |
|---|---|---|
| `use-case-spec` | `docs/use_cases/UC-XXX-<kebab>.md` | `specs/contexts/<ctx>/use-cases/` |
| `entity-model` | `docs/entity_model.md` | `specs/contexts/<ctx>/entities.md` (cổng đọc đúng đường này) |
| `use-case-diagram` | `docs/use_cases.puml` | mermaid, ta đếm nhãn `\|E# …\|` |
| `requirements` | đọc `docs/vision.md` | không skill nào tạo file đó |

**4/4 ghi sai cây, 3/4 sai định dạng.** Và `use-case-spec` còn **đụng hệ ID** — nguyên văn:
*"`BR-XXX` business-rule IDs are unique within their own file only and **restart at `BR-001` in
every file**"*. `BR-###` của nó là business **rule**; `BR-###` của ta là business **requirement**
trong `specs/br.md`.

**Githook sẽ CHO QUA.** Luật *"`BR-` phải có heading trong `specs/br.md`"* thấy `BR-002` có heading
thật và cho đi — trong khi commit đang nói về một business rule của `UC-005`. **Báo xanh sai ở
tầng hệ ID**, đúng #24, và là ca đầu tiên của lớp đó ở tầng *quy ước đặt tên* chứ không ở tầng dữ
liệu.

Kết luận này plugin **đã tự rút ra một lần rồi**: `skills/init` viết *"đừng đề xuất `/requirements`
— AIUP đọc `docs/vision.md` mà không skill nào tạo ra file đó"*. Đúng, nhưng **không lan sang ba
lệnh còn lại**. Một kết luận đúng nằm đúng một chỗ thì không bảo vệ được ba chỗ kia.

- `sdd-process` bước ② đổi **chủ ngữ từ LỆNH sang VIỆC PHẢI XONG**: *điền nội dung UC cùng user
  (Actor · Trigger · Preconditions · Main Flow — bước hiển thị nêu SCR-ID · Alternative ·
  Exceptions · Postconditions)*, kèm khối lý do đầy đủ ở trên.
- `CLAUDE.md.tmpl` bỏ `(AIUP /use-case-spec)` khỏi chuỗi lệnh — nằm trong khối scaffold nên **mọi
  repo nhận sau `init --update`**.
- `deps-check.sh` hạ AIUP từ **dòng đỏ** xuống ghi chú. Nó đang bắt người ta cài một thứ để **không
  bao giờ gọi** — và một dòng đỏ đòi việc vô ích chỉ dạy người ta phớt lờ dòng đỏ.

### Thêm — `uc-steps.sh`: UC này đi qua những bước nào

Phép **liệt kê**, không phải phép kiểm: **luôn `exit 0`, không chặn gì**. Cổng DoR vẫn là
`gate-check.sh`; thêm một cổng thứ hai đo cùng thứ chỉ tạo nhiễu. `/sdd-solo:status` gọi nó cho UC
trong dòng `Đang làm:` của `STATE.md`.

Ba trạng thái, và **ranh giới giữa hai cái sau mới là chỗ đáng giá**:

```
✓  có dấu vết trong file
–  cố ý bỏ, CÓ ghi lý do   (dòng `**Bỏ bước <ký hiệu>:** <lý do>` trong file UC)
?  không có dấu vết nào — có thể đã làm, có thể chưa, KHÔNG AI BIẾT
```

Đối chứng sạch ngay trong `UC-009`: bước ⑤ (Claude Design) **cũng bị bỏ** — `screens/` chỉ có
`README`. Nhưng nó bỏ **có ghi lý do** trong mục Screens (*"cả hai màn hình là text thuần, không có
giao diện đồ hoạ ở v1"*). **Bỏ có ghi lý do và bỏ mà không ai biết là bỏ cho cùng một kết quả trên
đĩa** — sáu tháng sau chỉ cái đầu còn đọc lại được.

Script nói thẳng giới hạn của nó: `⑥` không có artifact riêng (cổng kiểm), `⑬` self-review **không
để lại dấu vết nên không đo được**. Và `?` được ghi rõ là *"không có dấu vết"*, **không phải "chưa
làm"** — hai câu đó khác nhau, và gộp chúng lại là đúng loại lỗi bản này đang sửa.

`uc-steps.sh` thêm vào danh sách `scaffold` copy sang `.sdd/scripts/`; `status.sh` **im nếu không
thấy file** để bản `.sdd/` cũ không gãy cả lượt vì một mục mới. Đo cả hai chiều trên repo tạm.

### Cùng họ #27, khác một chữ

#27 là **luật đúng đặt sai bước** — không bao giờ có cơ hội chạy. #29 là **bước chạy được nhưng
chạy thì hỏng**. Cả hai đều không phải lỗi nội dung, và cả hai chỉ lộ ra khi có người đi hết một
vòng thật rồi hỏi *"khoan, tôi có gõ lệnh đó bao giờ chưa?"*

## 3.17.0 — 2026-09-09

### Đo được — `/sdd-solo:verify` lần chạy thật đầu tiên: 30 phát hiện, 30 phải sửa, **0 dương tính giả**

Con số chờ suốt bảy bản, từ `runxops-54` — phiên thật sự chạy lệnh trên repo thật. Chủ dự án bác
**0** cái.

Cách chạy, để biết con số đo cái gì: **hai** subagent riêng, không cái nào có context buổi viết
spec. Một vai đọc *tài liệu ↔ tài liệu* (loại #1–#6), một vai đối chiếu *con số ↔ dữ liệu thật*
(loại #7), chạy **đúng lệnh đo có sẵn trong spec, không bịa lệnh**. `22 + 10 = 32` thô → gộp trùng
còn `29` → cộng 1 bắt được sau = **30**.

**Tỷ lệ 0 đến từ chỗ nhiễu bị lọc TRONG vai, không đẩy lên người:** hai vai tự bác 4 mục kèm lý do
*trước* khi trình, và ~25 con số chạy lại khớp thì **im**. Đó đúng là hình mà luật *"khớp → im"*
và *"bác phải rẻ"* nhắm tới.

Quan sát về chia vai, đáng giữ: **vai đo số một mình đóng góp 10 phát hiện, 8/10 là loại #7** —
thứ vai đọc tài liệu **không thể** tìm ra vì phải chạy lệnh. Gộp hai vai làm một thì phần đọc sẽ
ăn hết ngân sách chú ý.

Loại #7 nổ **8** lần; loại #8 nổ **2** lần — `glossary.md` để tiêu đề *"Năm entity"* trên danh sách
**sáu**, và `entities.md` viết *"Bảy nhóm lệch cờ tồn"* **bằng chữ** cách bảng ghi `10` đúng 13
dòng, sống sót một commit vừa khai là *"đã quét mọi câu khai số lượng"* — **vì phép quét tìm chữ
số.** Luật *hit lịch sử hợp lệ* (3.11.0): đối chiếu cả 30, **không cái nào** rơi vào diện phải hạ
xuống dòng đếm — nên nó không tốn gì trên lượt này, và cũng **chưa được thử**.

### Thêm — `gate-check` kiểm ID khai trong `## Đọc lại`, y hệt §7 cho adversarial

**Bước sửa tự sinh lỗi mới, và trước bản này không có gì chạy sau nó.** Ca thật: sửa
`RULE-006 → RULE-007` để tránh trùng mã; `RULE-007` chưa có heading trong `rules.md` → **vừa tạo
đúng loại ID rỗng mà luật repo cấm**. Sửa lại xong, cổng **vẫn** đỏ: dòng `F27` trong chính mục
`## Đọc lại` vẫn ghi `RULE-007`.

**Sửa thân mà quên sửa chỗ ghi lại việc sửa** — loại #8, do chính lượt đọc-lại sinh ra, trong chính
cái mục ghi kết quả đọc lại. Cả hai lỗi **cổng bắt, verify không**, vì verify đã chạy xong từ
trước. Cái thiếu là **một vòng kiểm sau bước sửa**, không phải một vai đọc thứ ba.

- `gate-check` §9: mọi `RULE-###` / `AC-#` / `E#` khai trong `## Đọc lại` phải **có thật** — cùng
  luật #12 đã áp cho adversarial. Không kiểm thì **cửa 2 mở bằng một lời khai trỏ vào chỗ không
  tồn tại**. Đầu ra không mang ID (*"không phải lỗi vì …"*) vẫn hợp lệ, không bị đòi ID.
- Bước 6 của skill: quét **cả giá trị MỚI**, không chỉ giá trị cũ — lỗi do bước sửa sinh ra là
  giá trị *mới nằm sai chỗ*, quét giá trị cũ không thấy. Và **mục `## Đọc lại` không được miễn**:
  nó ghi lại việc sửa nên nó trôi như mọi chỗ khác. **Chỗ ghi lại việc sửa cũng là một chỗ phải
  sửa.**

Năm ca đo: khai `RULE-007` không có → ✗ · sửa thành `RULE-006` có thật → ✓ · khai `AC-9` không có →
✗ · `AC-1` có thật → ✓ · đầu ra không mang ID → ✓ (không đòi).

### Hai mục còn lại trong báo cáo — đã vá trước khi báo cáo tới

`runxops-54` nêu ba việc; hai việc đầu đã xong ở bản trước, nên ghi lại đây cho khớp mốc thời
gian: ca mẫu `536 / 525` đã sửa (3.12.0 → 3.16.0, nay là `545` / `601` kèm nhãn đơn vị), và lỗ cấu
tạo *luật quét nằm trong cơ chế không chạy được nó* đã chuyển về bước 6 ở **3.15.0** — đề nghị của
họ trùng khít với thứ đã ship, kể cả điều kiện *"chỉ commit khi kết quả rỗng hoặc mọi hit còn lại
là hit lịch sử hợp lệ"*.

## 3.16.0 — 2026-09-09

### Thêm — loại sai #9: số đúng, chủ ngữ sai

Câu hỏi treo ở 3.15.0 (*ba con số `249 / 1006 / 2523` có mục không?*) có câu trả lời, và nó quan
trọng hơn ánh xạ: **cả ba đo đúng. Chúng chỉ đo đúng một câu hỏi KHÁC.**

```
249   ĐÚNG cho "dòng có TỔNG giá trị > 1"     (Color: Red ; Size: L đếm 2)
215   ĐÚNG cho "dòng gom nhiều Variant"        ← câu trong tài liệu nói về cái này
1006  ĐÚNG cho "tổng giá trị, phép CỘNG"
 920  ĐÚNG cho "tổng tổ hợp, phép NHÂN"        ← số Variant thật khi bung
2523  = 1517 + 1006
2437  = 1517 +  920                            ← số dòng sau khi bung
```

**Đây không phải loại #7.** Loại #7 là *"số từng đúng, dữ liệu đổi bên dưới"* — chữa bằng **đo
lại**. Loại này đo lại vẫn ra `249`, **mãi mãi**. Hỏng không nằm ở con số, nằm ở **cái câu nó được
gắn vào**. Chữa bằng **đọc lại câu**, không bằng đo.

Và **không tầng nào trong bốn tầng bắt được**: vân tay khớp · lệnh đo có thật và in đúng số · cấu
trúc không đổi · phép cộng khớp. **Cả bốn kiểm quan hệ số ↔ dữ liệu; không tầng nào kiểm quan hệ
số ↔ CÂU.** Luật 11 hỏi *lệnh có in ra số này không* — ở đây lệnh in ra thật, nhãn đúng, và vẫn sai.

> **Loại #9 — Số đúng, chủ ngữ sai.** Phép đo hợp lệ nhưng trả lời một câu hỏi khác câu hỏi trong
> văn bản. Dấu hiệu: **một cột sinh ra nhiều mẫu số đều hợp lệ.** Câu phải hỏi: *con số này trả
> lời câu hỏi nào, và câu trong tài liệu đang hỏi câu nào?*

**Kiểm rẻ:** cột nào sinh ra **nhiều hơn một mẫu số hợp lệ** thì mọi con số lấy từ nó **phải mang
nhãn mẫu số, không được đứng trần**.

### Sửa — ba chỗ trong ca mẫu, theo ánh xạ đo được

- Ca `132 → 249` → **`132 → 215`**. Chủ ngữ của câu là *"một listing gom nhiều Variant"*, mà
  `Color: Red ; Size: L` là hai trục mỗi trục một giá trị — **một** Variant.
- Ca *"nhiều hơn 1986"*: `2523` → **`2437`**, và `+27%` → **`+23%`**.
- Bảng đơn vị: `1006` **giữ nguyên nhưng nay mang nhãn `(CỘNG)`**, đứng cạnh `920 (NHÂN)`. `1006`
  chỉ sai khi bị dùng cho phép bung; dùng cho tổng giá trị thì đúng. **Hai số cạnh nhau có nhãn
  mẫu số là hình đúng của cả loại #9.**

Phép quét bước 6 chạy sau khi sửa: hai chỗ `249` còn lại đều nằm trong đoạn **giải thích chính ca
đó**, tức hit hợp lệ. `1517 + 920 = 2437` ✓ và `1517 + 1006 = 2523` ✓ — cộng thử trước khi ghi.

### Ghi lại — `grep` bắt được cả thứ không ai đang đi tìm

Nhận xét từ `runxops` về ca đoạn-văn-trùng ở 3.15.0, giữ lại vì nó là lý do đầy đủ nhất cho toàn
bộ thiết kế của `verify`:

> Bạn chạy `grep` để kiểm `536`, nó trả về một lỗi **khác hẳn**. Người đọc lại thì chỉ tìm được
> thứ mình đang tìm.

Đó là khác biệt giữa **đọc để kiểm một giả thuyết** và **một phép đếm đứng ngoài mắt mình**: cái
đầu bị giới hạn bởi những gì mình nghĩ tới, cái sau thì không.

### Và một ca `13/13` cuối, do chính người dựng ra nó mắc

`runxops` viết *"tôi là người duy nhất trong ba người vi phạm luật đó hôm nay"* — một mẫu số chưa
lọc: họ cũng là người **cầm dữ liệu nhiều nhất**, nên có nhiều cơ hội viết-trước-khi-đo nhất. Hai
phiên kia không vi phạm vì hai phiên kia không cầm bút trên dữ liệu. Họ nhận ngay khi được chỉ ra.

Đáng ghi vì nó khép lại đúng chỗ mở đầu của loạt bản này: **cái bẫy `13/13` bắt được cả người vừa
dựng ra nó**, và lần này ở chỗ khó ngờ nhất — một câu tự kể về mình.

## 3.15.0 — 2026-09-09

### Sửa — luật quét-cả-cây nằm trong một cơ chế cấu tạo không chạy được nó

Chẩn đoán từ `runxops-54`, phiên đang cầm bút trên `specs/`, và nó sắc hơn một dòng bỏ sót:

> Luật quét-cả-cây ở `verify-pass.md` chỉ có nghĩa **sau** khi sửa — vì **trước** khi sửa thì chưa
> có "giá trị cũ" nào để quét theo. Nhưng verify pass chạy **trước** khi sửa. Nên luật ấy đang nằm
> trong một cơ chế **cấu tạo không chạy được nó.**

**Không phải ai quên — là đặt sai bước.** Ca thật: cặp số cũ nằm ở **bốn** chỗ (`entities.md` ·
`br.md` · docstring một script · prompt của chính plugin), và **hai vai verify đọc rất kỹ vẫn bỏ
sót chỗ thứ tư**. Thứ bắt được nó là một `grep -rn` chạy **sau** khi sửa.

- Phép quét chuyển về **bước 6 của `skills/verify`** — sau khi người quyết đã điền đầu ra và các
  sửa đổi đã áp, **trước** khi commit, và là **bắt buộc**: với mỗi giá trị vừa đổi, `grep -rn` giá
  trị **cũ** trên cả cây; còn hit nào ngoài `## History` và ngoài câu `<cũ> → <mới>` thì chưa xong.
- Prompt giữ luật ở dạng *cách soi* cho hai vai; chỗ **thi hành** nằm ở skill.

Đây là ca đầu tiên trong cả loạt mà chỗ hỏng **không** ở một con số hay một nhãn, mà ở **thứ tự
các bước** — cùng họ loại sai #5 (*"thứ tự nói ngược nội dung"*), nhưng ở **tầng quy trình** chứ
không ở tầng tài liệu. Bốn tầng kiểm số dựng trong ngày đều đo **trạng thái**, không tầng nào đo
**thứ tự**, và lỗ này chỉ lộ khi có người đi hết một vòng thật.

### Sửa — một đoạn văn nằm HAI lần trong `verify-pass.md`

Bản 3.14.0 chèn một đoạn mới mà không gỡ đoạn cũ nó thay thế, nên hai đoạn gần như y hệt cùng nằm
trong file. Đúng loại sai #3, trong tài liệu dạy cách bắt loại #3. **Bắt được bằng `grep -rn '536'`
chạy để kiểm chuyện khác** — không phải bằng đọc lại, dù đoạn trùng cách nhau đúng năm dòng.

### Thêm — quan hệ `545 / 555`: hai câu, hai lý do khác nhau

3.14.0 để chỗ này là **một ô trống có nhãn** *"chưa có phép đo nào"*. `runxops` đo xong, và kết quả
đáng ghi vì nó cho thấy ô trống ấy là đúng:

```
545 mã gỡ từ ô `Name Product`  +  10 mã từ cột `Product ID` gốc  =  555 mã
555 mã = 555 ô     VÌ ĐO ĐƯỢC rằng mọi ô chỉ mang MỘT mã ({1: 555})
```

Câu đầu là phép cộng. **Câu sau không suy ra được** — nó là một tính chất của dữ liệu: chỉ cần một
ô mang hai ISBN là đẳng thức gãy. Nếu 3.14.0 viết đại *"555 ô ứng với 545 mã cộng 10"* thì câu đó
**đúng**, và vẫn là **bịa**, vì tính chất chống đỡ nó lúc ấy chưa ai đo. **Kết quả giống hệt, giá
trị khác hẳn.**

Nguyên tắc, và nó là câu gọn nhất của cả ngày: **không viết ra thứ mình chưa đo, kể cả khi nó chắc
chắn đúng.**

### Đo được — verify: 12/12, không có dương tính giả nào

Vòng đầu của `/sdd-solo:verify` trên `runxops`: **12 phát hiện đã sửa xong, 0 dương tính giả**; 17
cái còn lại chờ người quyết. Chưa phải con số cuối, nhưng nếu 17 cái kia giữ hình đó thì phát biểu
đúng **không** phải *"verify chấp nhận được mức nhiễu"* mà là *"verify gần như không nhiễu ở tầng
nghiệp vụ"* — và hai phát biểu đó dẫn tới hai quyết định khác hẳn nhau về việc có bắt buộc chạy nó
trước mọi cổng hay không. **Quyết định đó chờ số cuối, không chốt bằng 12/12.**

Một dấu hiệu luật 11 viết đủ rõ: `runxops-54` **từ chối gắn lệnh đo** cho ba con số nó không tự
dựng lại được, ghi thẳng vào tài liệu rằng chúng chưa có lệnh — *"thà thiếu nhãn còn hơn dán nhãn
sai"* — và nó tự rút ra điều đó, không ai bảo.

## 3.14.0 — 2026-09-09

### Sửa — phép khớp chéo thêm ở 3.13.0 chỉ đúng MỘT phía

3.13.0 khoe `454 + 15 = 469` khớp số ô có biến thể, và kết luận bộ số *"tự chứng minh đã phân
hết"*. `runxops` đo nốt phía kia:

```
phía biến thể   454 + 15 = 469  ✓
phía định danh  513 + 15 = 528  ✗  số ô có Identifiers là 555 — hụt 27
```

Ai đọc ca mẫu rồi **thử phép đối xứng** — việc hoàn toàn tự nhiên ngay sau khi được dạy rằng phân
rã phải cộng đúng — sẽ ra `528 ≠ 555` và kết luận bộ số hỏng.

Nó không hỏng; nó **thiếu hai số hạng mà `982` theo định nghĩa không thể chứa**: `10` từ cột
`Product ID` gốc, và — chỗ đắt — **`17` ô MỘT dòng**, định danh dính sau dấu `|` ngay trên dòng
tên. Mười bảy ô đó nằm ngoài `982` **theo đúng định nghĩa của 982** (*ô có nội dung ngoài
tên+link*). `513 + 15 + 10 + 17 = 555` ✓.

**Phát biểu đúng: `982` KHÔNG phải tập cha của định danh.** Nó là tập cha của trục biến thể (469
nằm trọn trong đó) nhưng chỉ chứa 528/555 ô mang định danh. Bộ số cũ đọc như thể `982` bao cả hai —
**đúng ảo giác mà `536 + 525` tạo ra từ đầu, sống nguyên qua BA lần sửa liên tiếp**, mỗi lần đều
do một bên tưởng mình vừa sửa xong nó.

### Thêm — luật 11 vế 3: thử phân rã ở CẢ HAI phía

> Một phía cộng đúng **chưa chứng minh được gì** — nó chỉ chứng minh phía ấy đúng. **Phía gãy mới
> là phía chỉ ra tập cha thật sự bao cái gì.**

Rẻ hơn cả hai vế trước, và 3.13.0 là bằng chứng: bản đó **dừng lại ngay sau phía khớp**, rồi dùng
phía khớp ấy làm bảo chứng cho cả bộ. Một phép khớp thành công là chỗ dễ dừng nhất.

Ca này mạnh hơn `13/13` một bậc: `13/13` là mẫu số đã lọc mà không nói đã lọc gì — **giấu thông
tin**. `982` bị tưởng là bao cả hai trong khi chỉ bao một — **tạo ra một quan hệ không tồn tại**,
và quan hệ sai kéo theo **mọi suy luận dựng trên nó**, không chỉ một con số.

### Ghi lại — vì sao `536 + 525 ≠ 982` sống được sáu bản

3.13.0 quy cho *"không ai buồn cộng"*. `runxops` đưa lý do đúng hơn, và nó có hệ quả thiết kế:

> Không ai coi ba con số ấy là **một hệ**. Chúng nằm cạnh nhau trong một câu văn, không nằm trong
> một bảng, nên không ai thấy chúng phải khớp với nhau. Cái làm chúng thành một hệ — và làm phép
> cộng thành bắt buộc — chính là việc xếp chúng thành bảng ở 3.12.0.

**Phép kiểm rẻ nhất chỉ xuất hiện sau khi trình bày đúng.** Đó là lý do luật 11 đòi *trưng ra phép
cộng* chứ không chỉ đòi *cộng đúng*: bảng không phải cách trình bày đẹp hơn, nó là **thứ làm phép
kiểm trở nên khả thi**.

### Chỗ chưa đo, nêu ra thay vì lặng lẽ hoà giải

`555` là số **ô** mang định danh; `545` ở tầng kia là số **mã** định danh. Quan hệ giữa hai số đó
**chưa có phép đo nào**. Ca mẫu nói thẳng điều này thay vì suy ra một quan hệ nghe hợp lý — vì tự
bịa một quan hệ ở đúng chỗ này là **đúng cái lỗi cả mục đó đang dạy cách bắt**.

## 3.13.0 — 2026-09-09

### Sửa — ca mẫu vẫn treo người đọc giữa chừng; và luật 11 có vế thứ hai

3.12.0 sửa số và thêm câu *"hai số này KHÔNG cộng lại thành 982"*. Câu đó **đúng cả hai vế** nhưng
vẫn để người đọc treo: gặp `545` và `601` cạnh `982` thì ai cũng hỏi *"vậy bao nhiêu ô mang cả
hai?"*, và câu trả lời trực giác `545 + 601 − 982 = 164` **sai hơn mười lần** — số thật là **15**.

Sai vì **ba con số đó mang ba đơn vị khác nhau**: `982` là số **ô**, `545` là số **mã**, `601` là
số **dòng**. Không có gì trong văn bản nói ra điều đó.

Ca mẫu nay trưng **hai tầng**, vì mỗi tầng dạy một thứ:

```
ĐƠN VỊ = Ô     982 = 513 (chỉ định danh) + 454 (chỉ trục) + 15 (cả hai) + 0   ✓
ĐƠN VỊ = MÃ / DÒNG     545 mã · 601 dòng · 1006 giá trị   — KHÔNG cộng vào đâu cả
```

Phân rã theo ô **cộng đúng, nên tự chứng minh đã phân hết**, và còn khớp chéo: `454 + 15 = 469`,
đúng bằng số ô *"có biến thể"* đo được ở một lần đếm khác.

**Luật 11 vế 2:** con số nào **tự nhận là phân rã** của một con số khác thì **phải cộng lại đúng**,
và chỗ trình bày phải **trưng ra phép cộng**. Cộng không ra → thiếu một nhóm, hoặc các nhóm chồng
nhau, hoặc — hay gặp nhất — **không cùng đơn vị**. Kiểm được bằng máy, rẻ hơn mọi luật khác trong
danh sách.

Chỗ tự phê đáng ghi: **`536 + 525 ≠ 982` đáng lẽ đã bắt được bộ số cũ sáu bản trước, không cần
verify.** Một phép cộng hai số. Nó nằm ngay trong câu, suốt sáu bản, và không ai cộng thử — kể cả
sau khi verify đã bắt được hai con số ấy sai và cả hai phiên cùng ngồi sửa đúng dòng đó.

### Ghi lại — `grep` không phải mẹo vặt

Khi thêm luật 11 ở 3.12.0, bản nháp chèn nó **trước** luật 9 và 10 — lần thứ hai trong hai bản
liên tiếp, cùng một tay, ba phút sau khi viết luật về chính lỗi đó. `runxops` mắc đúng chuỗi ấy
**ba lần trong một ngày**, lần thứ ba ngay sau khi khai vào spec là đã sửa. **Bốn ca, hai tay, một
ngày, không ca nào bắt được bằng đọc kỹ hơn.**

Nhận xét từ `runxops`, giữ nguyên vì nó là cách phát biểu đúng nhất của cả loạt bản này:

> `grep -nE '^[0-9]+\. '` không phải mẹo vặt — nó là **hình thức tối giản của chính luận điểm mà
> `verify` được dựng lên để chứng minh: một phép đếm đứng ngoài mắt mình.**

Đó cũng là lý do bốn ca trên **không phải mẫu về sự bất cẩn**, mà là mẫu về **thứ mà chú ý không
mua được**: biết luật, vừa viết xong luật, biết mình dễ mắc, và vẫn mắc.

## 3.12.0 — 2026-09-09

### Sửa — ca mẫu của loại #7 mang đúng cái lỗi nó dạy cách bắt

**`/sdd-solo:verify` chạy thật lần đầu, và thứ nó bắt được nằm trong `verify-pass.md` của chính
plugin này.** Ca mẫu ghi *"982 ô nhiều dòng — 536 trục biến thể và 525 định danh"*. Đo lại:

| | đang ghi | đúng |
|---|---|---|
| ô có nội dung ngoài tên+link | 982 | **982** ✓ |
| ô mang định danh | 525 | **545** |
| ô mang trục biến thể (số **dòng**) | 536 | **601** |
| ô mang trục biến thể (số **giá trị**) | — | 1006 |

`982` đúng; hai số kia sai **cùng một chiều, cùng một nguyên nhân** — chúng ra từ script khảo sát
đầu tiên, chạy **trước** khi bỏ ký tự vô hình `U+200E` và trước khi bắt được 32 giá trị biến thể
không mang tên trục. Tức **đúng chữ ký mà chính đoạn văn đó đang dạy người ta nhận ra.**

Để nguyên thì thiệt hại là thật và cụ thể: ai chạy `measure` trên `runxops` và ra `545/601` sẽ
kết luận **cơ chế sai**, chứ không phải **con số trong ví dụ sai**.

- Sửa thành `982 · 545 định danh · 601 dòng trục`, kèm câu **hai số này KHÔNG cộng lại thành 982**
  vì một ô mang được cả hai. Bản cũ đọc như một phép chia đôi mà `536 + 525` cũng chẳng ra `982` —
  không ai để ý, vì hai con số thật đứng cạnh nhau trông luôn hợp lý.
- Thêm ca *hai mẫu số cho cùng một thứ*: `601 dòng` cạnh `1006 giá trị` — một ô ghi
  `Color: Brown | Dark Grey` là **một** dòng trục nhưng **hai** giá trị. Dán nhầm số nọ vào câu
  của số kia thì cả hai đều là số thật, câu vẫn trôi chảy, không phép so nào bắt được. **Luôn nói
  rõ đang đếm ĐƠN VỊ nào.**
- Giữ lại trong prompt chính câu chuyện này — ca mẫu từng mang lỗi nó dạy cách bắt — vì nó dạy
  nhiều hơn bộ số đúng.

### Thêm — luật 11: lệnh đo phải THẬT SỰ in ra con số nó được gắn vào

Ca nặng nhất của cả loạt. Hai con số ở `runxops` được gắn `python3 scripts/measure-catalog.py` làm
lệnh đo, mà **lệnh đó không in ra con số nào trong hai**. Không phải số mục — là **một cái nhãn
xác thực dán sai**, và nó **tệ hơn không có nhãn**: không nhãn thì con số trông như chưa ai kiểm,
đúng như nó vốn thế; dán nhãn sai thì nó trông **như đã được kiểm**.

> **Kiểm bằng cách chạy lệnh rồi tìm con số đó trong đầu ra. Không thấy → nhãn sai.**

Luật này đóng chỗ hở mà **ba tầng kia không với tới**: vân tay hỏi *dữ liệu nào* (3.8.0) · luật 5b
hỏi *lệnh nào* (3.6.0) · chốt cấu trúc hỏi *lệnh còn đúng hình dạng không* (3.11.0) — **cả ba đều
giả định lệnh và số là một cặp đúng**, và không tầng nào kiểm chính cái cặp đó. Rẻ, và kiểm được
bằng máy.

### Thêm — giới hạn: lý do bác phải đến từ người ĐỌC, không từ người VIẾT spec

Đưa trước cho verify một danh sách *"ngữ cảnh giúp bác nhanh"* do tác giả spec soạn là **lấy mất
chỗ đứng của nó**: nó sẽ bác đúng những phát hiện mà tác giả đã có sẵn câu trả lời — tức đúng
những chỗ tác giả **tin là mình không sai**.

Ca thật: một danh sách như vậy bị subagent từ chối, và **hai mục trong đó sau đó tự rơi vào nhóm
"khớp / đã bác" bằng phép đo riêng của verify**. Bằng chứng ấy chỉ tồn tại **vì** nó không nghe.
Cùng họ với luật *"chỉ báo, không sửa"*: người có lợi ích trong kết luận không được cầm bút.

### Sửa — hai cái nhãn mang số nữa, lại đúng loại #8

Khi thêm luật 11, bản nháp **chèn nó trước luật 9 và 10** — lần thứ hai trong hai bản liên tiếp,
cùng một tay, ba phút sau khi viết luật về nó. Và mục `## Ba giới hạn` thành bốn dòng ở cả
`verify-pass.md` lẫn `skills/verify/SKILL.md`.

Cả hai bắt được bằng `grep -nE '^[0-9]+\. '`, **không phải bằng đọc**. Cùng cách chữa với 3.9.0:
tiêu đề bỏ hẳn số đếm (`## Giới hạn`), vì **một cái nhãn mang số thì mỗi lần thêm dòng là một lần
nó có thể mục**.

### Đo được — verify hoạt động, và nhiễu nằm ở đâu

Lần chạy thật đầu tiên sinh **29 phát hiện** sau khi gộp; triage chưa xong nên chưa có tỉ lệ dương
tính giả. Đã biết một nửa: **nhiễu tập trung ở tầng 5 (vệ sinh), không ở tầng 1–2.** Và bằng chứng
đắt nhất là chính bản vá này: công cụ tìm ra một lỗi thật **trong tài liệu định nghĩa ra nó**.

## 3.11.0 — 2026-09-09

### Thêm — chốt cấu trúc: lệnh đo khai hình dạng nó giả định, sai thì DỪNG

3.10.0 đặt tên cho loại mục thứ ba — **"lệnh đúng với thế giới cũ"** — và nói là không so số nào
bắt được, vì lệnh vẫn chạy trơn và vẫn ra một con số hợp lý. `runxops` chặn được **một nửa**: bắt
lệnh **khai ra cấu trúc nó đang giả định**, rồi kiểm cấu trúc đó **trước khi** đếm.

`measure-catalog.py` khai ba giả định — tên cột phải có · dấu ngăn trục trong `Variant` là ` ; ` ·
không ô nào còn xuống dòng. Thử đổi ` ; ` thành ` / ` trên một bản tạm:

```
itemsell-flat.csv không còn hình dạng mà lệnh này giả định — KHÔNG đếm,
vì một con số đếm trên cấu trúc đã đổi trông y hệt một con số đúng:
  ✗ không ô Variant nào chứa ' ; ' — dấu ngăn trục có thể đã đổi
EXIT = 1
```

Nó **dừng, không in con số nào**. Đây là nguyên tắc mở đầu của cả repo áp vào chỗ hẹp nhất: *báo
xanh sai tệ hơn không có phép kiểm*, nên **một lệnh đo không chắc mình đang đo đúng thứ thì việc
đúng đắn là im, không phải đoán.**

**Ba thứ, viết thành một câu** — đây là hình gọn của cả loại #7 sau một ngày, đặt lên đầu mục:

> Một con số kiểm lại được cần **ba** thứ, thiếu một là mục lặng: **dữ liệu nào** (vân tay, 3.8.0)
> · **lệnh nào** (luật 5b, 3.6.0) · **lệnh đó còn đúng với hình dạng hiện tại không** (chốt cấu
> trúc, bản này). Hai thứ đầu bắt được số **sai**; chỉ thứ ba bắt được số **đúng-trên-thế-giới-cũ**.

**Nửa còn hở, khai cho đủ:** chốt cấu trúc bắt được **cấu trúc dữ liệu** đổi. Nó **không** bắt được
người sửa cả lệnh lẫn phần khai giả định cùng lúc cho khớp nhau — lúc đó nó lại là một lệnh đúng
với thế giới cũ, chỉ khác là thế giới cũ vừa được viết lại cho hợp. **Ba tầng, tầng nào cũng chỉ
đẩy chỗ mù lùi một bậc chứ không xoá được.** Prompt bắt nói ra chỗ mù còn lại, không được hứa nó
đã hết.

### Sửa — một cái nhãn mang số nữa, cùng loại #8

*"Sáu loại đầu đọc tài liệu so với tài liệu"* → *"Mọi loại trên…"*. Câu đó đúng lúc viết (khi bảng
có sáu dòng), vẫn đúng về mặt kỹ thuật sau khi thêm #7 và #8, nhưng **đã bắt đầu gây hiểu nhầm** —
và mỗi dòng thêm vào bảng là một lần nó gần hơn với chỗ sai hẳn. Cùng cách chữa với tiêu đề ở
3.9.0: **bỏ con số đi thì không còn gì để mục.**

### Nguyên tắc rút ra từ cả loạt 3.5.0–3.11.0 — và một cách kể sai đã bị bác

Trong loạt này có một lúc `runxops` **dừng, không commit** `glossary.md`, dù commit đó sẽ làm dòng
✗ cuối cùng của cổng thành ✓. Cách kể đầu tiên của phiên plugin là *"ở vị trí làm cổng xanh bằng
một lệnh, biết nó sẽ xanh, và không làm"* — tức quy công cho phẩm chất người vận hành. **`runxops`
bác cách kể đó, và bác đúng:**

> *"Tôi không nghĩ tới chuyện 'làm cổng xanh rồi từ chối'. Tôi chỉ thấy commit đó sẽ làm dòng ✗
> thành ✓ trong khi thứ nó đo chưa thay đổi gì. Nó không phải một lựa chọn đạo đức, nó là nhận ra
> phép kiểm đang đo cái khác với cái tôi sắp làm."*

Lý do bác quan trọng hơn chuyện ai đúng: **nếu ghi là "biết mà không làm" thì lần sau người ta
trông chờ vào phẩm chất của người vận hành** — mà chính loạt này vừa chứng minh phẩm chất không
dựa vào được. Cùng cái đầu đó trượt loại #8 **ba lần liền** trong cùng một ngày vì sửa theo trí
nhớ. Hình đúng của nó là:

> **Một phép kiểm đo được đúng thứ nó tuyên bố đo thì việc lách nó trông rõ ràng là lách, kể cả
> với người đang định lách.**

Đó là công của `gate-check`, không phải của ai. Và nó là **vế thứ hai, nặng hơn, của bài học #24**:
một phép kiểm báo xanh sai không chỉ bỏ lọt lỗi — **nó còn làm việc lách trông giống việc làm**,
kể cả trong mắt người đang lách. Đó mới là lý do đầy đủ để câu *"báo xanh sai tệ hơn không có phép
kiểm"* đứng ở đầu repo này.

Ghi kèm cách loạt bản này được làm, vì nó là điều kiện để những nguyên tắc trên có nghĩa: **sáu
lần hai phiên bất đồng, cả sáu lần kết thúc bằng một phép đo, không lần nào bằng nhượng bộ** —
`allowed-tools` truy trong transcript · `26/40` truy trong `br_body` · vùng loại trừ truy bằng chỗ
dấu `→` thật sự được dùng. Không lần nào phải tin nhau.

### Ghi nhận — một chuyện đã đo trước khi bump

`3.9.0 → 3.10.0` là lần đầu số minor lên hai chữ số. `vcmp` trong `lib.sh` so **từng thành phần
bằng số**, nên an toàn — đã chạy thử cả ba chiều trước khi bump. Nếu nó so chuỗi thì `3.10.0 <
3.9.0` và **cả chuỗi bốn mắt xích cảnh báo version sẽ im lặng nói ngược**, đúng dạng hỏng tệ nhất
trong cả bộ này.

## 3.10.0 — 2026-09-09

### Sửa — luật 9 và luật quét kéo ngược nhau; phân loại hit thay vì chỉ tìm hit

`runxops` chạy thử luật quét-cả-cây trên 13 con số đã đổi trong ngày và bắt thêm một chỗ mà **hai
lượt sửa trước đều trượt**: `entities.md` còn ghi *"132 dòng có nhiều giá trị biến thể"* trong khi
số thật là **249**. Phép đếm cũ ra `132` vì nó chỉ thấy dấu `|` **nằm cùng dòng với `Color:`** —
không phải regex sai, mà là **cấu trúc nó đang đếm chưa tồn tại lúc ấy**. Gần gấp đôi.

Nhưng phát hiện đáng giá hơn là một **mâu thuẫn giữa hai luật của chính bản 3.9.0**:

- **Luật 9** (loại #7): sửa số thì **giữ số cũ kèm lý do lệch**.
- **Luật quét** (loại #8): số vừa đổi thì **quét cả cây tìm mọi chỗ nhắc tới nó**.

Càng tuân thủ luật 9 thì cây càng đầy số cũ **hợp lệ**, nên luật quét ra càng nhiều hit đúng-mà-
phải-bác. Hôm nay tỷ lệ còn tốt vì mới một ngày; sau vài tháng mỗi số đổi kéo theo hàng chục hit
lịch sử. Lúc đó *"bác một phát hiện phải rẻ"* (giới hạn 1) **không còn đủ — cái rẻ phải là không
phải bác.**

**Cách giải: phân loại hit ngay khi tìm ra, máy tự dán nhãn, và không bỏ qua chỗ nào.** Hit ở
`## History` hoặc trong câu dạng `<số cũ> → <số mới>` là **hit lịch sử hợp lệ** → gộp thành **một
dòng đếm**, không thành `F#`. Mọi chỗ khác → `F#`.

Chỗ này em cố ý làm **khác** đề nghị gốc (*"chỉ soi hit ngoài `## History` và ngoài câu có dấu
`→`"*): không **loại bỏ** nhóm một khỏi phép quét, chỉ **hạ nó xuống một dòng đếm**. Loại bỏ hẳn
thì một câu văn xuôi sống vô tình mang dấu `→` sẽ **tàng hình vĩnh viễn** — và đó đúng là loại lỗi
cả tài liệu này sinh ra để bắt. Rẻ phải đến từ *đã bác sẵn kèm lý do*, không từ *không nhìn*.

### Thêm — câu định tính đứng thay một con số cũng là hit

*"sẽ nhiều hơn 1986 dòng"* không sai. Số thật là **2523** — **+27%**, và *"nhiều hơn"* che mất đúng
cái phần khiến người ta phải quyết khác đi. Cùng hình với `13/13` ở luật 10: **câu không sai, chỉ
là không đủ để ai quyết được gì.**

### Đo được — luật quét chịu được chạy tự động

`runxops` viết vòng lặp grep 13 con số, **mất một phút**, và phân loại đúng: mọi hit ở History và
ở các câu *"số cũ 1459 → 1388 vì …"* đều hợp lệ; **chỉ một hit** là văn xuôi sống mang số chết.
Tỷ lệ nhiễu thấp hơn dự đoán, nên luật này không cần người lọc trước.

### Ghi lại — thứ chữa được loại #8 không phải cẩn thận hơn

Nhận xét từ `runxops`, giữ nguyên vì nó đúng và đo được: hôm đó `runxops` trượt loại #8 **ba lần
liền** vì sửa theo trí nhớ; bản nháp 3.9.0 của plugin trượt **một lần** và bắt được — không phải
nhờ đọc kỹ hơn, mà nhờ chạy `grep -nE '^[0-9]+\. '`. **Thứ chữa được lớp lỗi này là có một phép
đếm đứng ngoài mắt mình**, không phải quyết tâm cẩn thận.

Và một khái quát đáng giữ, cũng từ `runxops`: **một cái nhãn mang số là một bản sao của thứ nó dán
lên, mà mọi bản sao đều trôi.** Cùng luật với việc tách một entity ra khi một trường bị chép ở
nhiều dòng — hai tầng khác hẳn nhau, một luật.

## 3.9.0 — 2026-09-09

### Thêm — một con số ĐÚNG vẫn có thể là phát hiện

Chín dòng luật của loại #7 tới 3.8.0 đều đi tìm số **sai**. `runxops` tìm ra chiều còn thiếu, và
nó là chiều duy nhất mà bước 3 (*"khớp → im"*) **bỏ sót theo thiết kế**, vì chạy lại vẫn ra đúng
con số đó.

`RULE-004` khai *"phân định được 13/13 nhóm"*. Đo lại: **đúng 13/13**. Nhưng mẫu số thô là **16** —
ba nhóm bị loại vì khoá là chữ giữ chỗ (`Does not apply`, thứ eBay tự điền khi người bán bỏ
trống). **Loại chúng ra là quyết định đúng.** Vấn đề là `13` một mình giấu mất **9 listing không
nhóm được bằng bất cứ khoá nào** — mà đúng chín cái đó là phần việc gán khoá tay của `UC-009`,
tức chỗ đau chính của cả BR.

- **Luật 10 của loại #7:** một con số đúng vẫn là phát hiện nếu nó là **mẫu số đã lọc mà không nói
  đã lọc gì**. Hai câu hỏi: *phép đếm này bỏ ra bao nhiêu?* · *cái bị bỏ ra có phải chính là thứ
  tài liệu đang bàn không?*
- **Hệ quả cho luật 5b:** lệnh đo in **mẫu số thô lẫn mẫu số đã lọc**, kèm cái gì bị lọc và vì sao.
  `13/13` trông hoàn hảo; `16 thô → loại 3 giữ chỗ → 13` nói thật.
- Cùng họ với ca `437 / 32` ở 3.7.0 — thứ bắt được nó là **một con số thứ hai đứng cạnh**. Khác ở
  chỗ ca kia con số trông vô lý, ca này **cả hai đều hợp lý**, nên không có con số thứ hai thì
  không có gì để mà nghi.

### Thêm — loại sai #8: nhãn không đi theo nội dung

Tiêu đề, câu tóm tắt, số đếm trong tiêu đề — ai sửa thân thường không sửa nhãn. Tách riêng khỏi #3
vì nó có **chữ ký riêng**: cái sai do **chính lần sửa trước gây ra**, và nó nằm cách chỗ sửa vài
dòng tới vài trăm dòng nên không lọt vào mắt người vừa sửa.

Ba ca đo được trong **một ngày**, ba người khác nhau:

| Ca | Nhãn | Thân |
|---|---|---|
| `verify-pass.md` (bản 3.6.0–3.7.0) | *"Sáu loại sai phải soi"* | bảng **bảy** dòng |
| `UC-009` một `AC` | tiêu đề nói một đằng | thân nói một nẻo |
| `entities.md` mục `Sourcing` | câu văn xuôi còn *"7 nhóm"* | bảng số và History đã sửa thành **10** |

Ca thứ ba đắt nhất về mặt bài học: nó **sống sót qua chính lượt đi sửa số mục**, vì người sửa sửa
**theo chỗ mình nhớ là có số**, không theo một phép quét. Nên luật soi là: mỗi lần một con số hoặc
một quyết định vừa đổi, **quét cả cây tìm mọi chỗ khác nhắc tới nó**. Trí nhớ của người vừa sửa là
thứ dở nhất để dựa vào — nó nhớ **ý định**, không nhớ **chữ**. Đúng câu mở đầu của `verify-pass.md`,
chỉ khác chỗ áp dụng.

### Sửa — tiêu đề bảng loại sai thôi mang số đếm

`## Bảy loại sai phải soi` → `## Các loại sai phải soi`. Một cái nhãn mang số thì **mỗi lần thêm
dòng là một lần nó có thể mục** — 3.6.0 đã mục đúng như vậy, 3.8.0 sửa con số, và bản này bỏ hẳn
con số đi để lần sau không còn gì để mục. Sửa nguyên nhân thay vì sửa triệu chứng.

Ghi thêm cho trung thực: khi thêm luật 10 ở bản này, bản nháp đầu **chèn dòng 10 lên trước dòng
9** — đúng loại sai #8, ngay trong lượt thêm loại sai #8. Đã sửa trước khi commit; nói ra vì nó là
bằng chứng tốt nhất cho lập luận ở trên rằng lớp lỗi này không chừa ai.

## 3.8.0 — 2026-09-09

### Thêm — lệnh đo in dấu vân tay của dữ liệu nó đọc

3.7.0 kết bằng câu *"có lệnh đo làm số kiểm lại được, không làm số đúng"*, và nói thẳng là **không
có cách chữa**. `runxops` tìm ra **nửa** cách chữa, và nó rẻ: lệnh đo in dấu vân tay của chính dữ
liệu nó vừa đọc, spec ghi lại vân tay đó cạnh bảng số.

```
Nguồn: itemsell-flat.csv · 1986 dòng · sha256 70daf43f · sửa lần cuối 2026-09-09 22:22
Đo lúc: 2026-09-09 22:26
```

Giá trị của nó không nằm ở chỗ bắt thêm lỗi, mà ở chỗ **chuyển một luật người phải nhớ thành một
dòng máy in ra**. Bước 4 của prompt viết *"lệch không có nghĩa spec sai — có thể dữ liệu đã đổi"*;
đó là một câu đúng mà mỗi lần gặp lệch vẫn phải ngồi đoán lại. Có vân tay thì hết đoán: vân tay
khác → dữ liệu đã đổi · vân tay khớp mà số khác → spec sai hoặc lệnh sai.

**Chỗ nó không bịt được, ghi thẳng vào prompt:** vân tay bắt được **dữ liệu** đổi, **không** bắt
được **lệnh** đổi. Sửa chính lệnh đo cho nó đếm sai đi thì vân tay vẫn khớp và cả bảng số vẫn mục
cùng một chiều — lần này còn khó thấy hơn, vì tài liệu trông như *đã được kiểm*. Câu của 3.7.0
đứng nguyên, chỉ hẹp lại đúng một nửa.

`sdd-process` luật 5b mở rộng theo.

### Sửa — tiêu đề `verify-pass.md` nói "Sáu loại sai" trong khi bảng có bảy

3.6.0 thêm loại #7 vào bảng mà quên sửa tiêu đề ngay trên nó. Đúng loại sai #3 của chính tài liệu
này — *hai chỗ nói ngược nhau* — trong file dạy cách tìm loại sai đó, và không phép kiểm nào bắt
được vì cả hai chỗ đều là văn xuôi hợp lệ.

### Đo được — cổng 3.7.0 chạy trên repo thật

`UC-009` ở `runxops`: **32 dòng xanh, 1 dòng đỏ**, và dòng đỏ đúng là cửa 2 như thiết kế. Dòng
`– hai cách qua: …` in ngay dưới dòng ✗ — nhận xét từ `runxops` đáng giữ lại: *"nó biến một dòng
chặn thành một dòng chỉ đường; đó là khác biệt giữa cổng và tường."*

`/sdd-solo:verify` chưa chạy được ở đó: phiên đang mở vẫn nạp 3.4.3 trong khi bản cài đã là 3.7.0.
Đúng cảnh báo ④ của `version-check` — **không lệnh nào sửa được, phải mở session mới.** Hai con số
còn chờ (tỉ lệ dương tính giả của verify, và `UC-009` có qua cửa 2 trong ngày không) vẫn chưa có.

## 3.7.0 — 2026-09-09

### Sửa — loại sai #7 không rơi lẻ, và cách báo nó phải theo cụm

Áp luật 5b vào `entities.md` của `runxops` ra kết quả không ai đoán: **không phải một con số mục,
mà năm.** Cả năm đều đo trên cùng một bản `itemsell-flat.csv` cũ, nhóm theo `Product Name` lúc cột
đó còn dính `Color: Brown` — nên hai dòng cùng sản phẩm khác màu đếm thành hai tên.

| | cũ | đo lại |
|---|---|---|
| tên sản phẩm | 1459 | **1388** |
| nhóm > 1 dòng | 281 | **320** |
| lệch Stock Flag | 7 | **10** |
| lệch Stock Checked | 138 | **158** |
| có biến thể | 427 | **469** |
| thoái hoá | 1559 | **1517** |

**Một phép đo mục thì mọi số dẫn xuất từ cùng nguồn mục theo, và tài liệu vẫn tự nhất quán hoàn
hảo.** Đó là lý do không phép kiểm nội-tại nào bắt được: không có gì mâu thuẫn để mà thấy.

- **Gộp cụm, đừng tách lẻ.** Nhiều số cùng một nguồn thiếu lệnh đo → **một** `F#` nêu cả cụm. Năm
  dòng đỏ giống hệt nhau là thứ người ta học cách phớt lờ nhanh nhất, rồi phớt lờ luôn dòng thứ
  sáu khác hẳn — đúng bẫy đã ghi ở 3.4.2. Cụm **khoanh đúng vùng**, và khoanh đúng vùng đã đủ để
  người biết dữ liệu đi kiểm; vai này không cần tự tìm ra con số đúng.
- **Xem HƯỚNG lệch, không chỉ xem có lệch.** Nhiều số cùng lệch **một chiều** là chữ ký của một
  nguồn chung đã mục, không phải của nhiều sai sót rời rạc. Ở ca này cả năm đều đếm **thiếu**, và
  đều thiếu theo hướng làm vấn đề trông **nhẹ hơn** thực tế: `7 nhóm lệch cờ tồn` là con số dùng
  để lập luận phải tách một entity, và nó nhỏ hơn sự thật **43%**. Lập luận vẫn đúng — nhưng người
  quyết phải biết nó đang đứng trên cái gì.
- **Một con số trông vô lý là một phát hiện, kể cả khi nó CÓ lệnh đo.** Lệnh sai vẫn chạy trơn. Ca
  thật: ghép dòng biến thể bằng ` | ` trong khi ` | ` đã mang nghĩa *"nhiều giá trị cùng một
  trục"*, nên `Color: Brown | Dark Grey` đọc ra thành hai trục và phép đếm ra `437` thay vì `32`.
  Thứ bắt được nó là **con số trông vô lý**, không phải phép kiểm nào.
- **Sửa số thì giữ số cũ kèm lý do lệch, đừng xoá.** *"1459 → 1388 (số cũ nhóm theo `Product Name`
  khi cột đó còn dính trục biến thể)"* dạy được nhiều hơn `1388` trơ trọi — nó nói phép đo cũ hỏng
  ở đâu, nên lần sau khỏi hỏng lại.

### Giới hạn thật của loại #7, đo được chứ không đoán

Vai #7 **không** tự tìm ra `427 → 469`; nó chỉ báo *"những số này không có cách đo lại"*. Nhưng khi
báo theo cụm thì kết quả đó mạnh hơn tưởng: **năm dòng cùng thiếu cách đo, cùng dẫn từ một file,
là một hình đủ rõ để người đọc đi kiểm.** Nó không tìm ra con số đúng — nó khoanh đúng vùng.

Nên phát biểu chính xác của giới hạn là: **loại #7 bắt được số mục chỉ khi ai đó đã từng ghi lại
cách đo; không có lệnh đo thì nó chỉ khoanh được vùng cần người vào xem.** Ghi ra để đừng ai
trông đợi nhiều hơn thế.

Và một điều đúng mãi: **loại #7 phát sinh ngay trong lúc sửa loại #7.** Mọi con số vừa đo lại sẽ
mục lần nữa khi dữ liệu đổi. Khác biệt duy nhất — và là toàn bộ giá trị của luật 5b — là lần này
có lệnh chạy lại.

## 3.6.0 — 2026-09-09

### Thêm — `verify` đối chiếu tài liệu với DỮ LIỆU THẬT, không chỉ với tài liệu

Ca thật ở `runxops`, xảy ra vài giờ sau khi 3.5.0 ra. `entities.md` ghi *"427 dòng đang có trục
nằm kẹt trong `Product Name`"*. Câu đó **qua adversarial pass và ba lượt cổng**. Đo lại: **982**
ô nhiều dòng — 536 trục biến thể **và 525 định danh**. Thứ bắt được nó không phải script nào, mà
là một câu của người biết dữ liệu: *"dữ liệu chưa chuẩn"*.

Sáu loại sai của 3.5.0 đều đọc **tài liệu so với tài liệu**. Loại này khác hẳn, và nó là chỗ mục
nhanh nhất trong cả spec: **con số đúng lúc viết, không ai sửa nó khi dữ liệu đổi, và một con số
đã mục trông y hệt một con số đúng.** Không phép kiểm cấu trúc nào phân biệt được — cổng DoR chỉ
hỏi *"mục này có nội dung chưa"*, và `427` là nội dung hợp lệ y như `982`.

- **Loại sai #7 — con số đã mục**, cùng một vai riêng trong `.sdd/prompts/verify-pass.md`. Số
  nghiệp vụ đã chốt (ngưỡng, thời hạn trong `RULE-###`) **không** thuộc loại này: đó là quyết
  định, không phải phép đo.
- **Mỗi con số mô tả dữ liệu phải có một lệnh đo lại được.** Không có → **bản thân việc thiếu đó
  đã là một phát hiện**. Cấm tự bịa lệnh rồi coi như đã đối chiếu: lệnh mình nghĩ ra không phải
  lệnh tác giả đã dùng, nên hai số lệch nhau chẳng chứng minh được gì.
- **Luật "trích nguyên văn hai phía" áp thẳng vào đây**, chỉ khác chỗ phía B là **một lệnh và đầu
  ra của nó hôm nay** thay vì một dòng file. Người quyết chạy lại lệnh đó là biết ngay.
- **Lệch KHÔNG có nghĩa spec sai.** Có thể dữ liệu đã đổi, có thể lệnh cũ đếm hụt. Báo cả hai số,
  **không kết luận bên nào đúng** — người biết dữ liệu quyết.
- **Soi chỗ phép đếm không nhìn thấy được.** Đây là chỗ ca thật trượt, và nó đáng ghi vì phép đếm
  cũ **không sai công thức**: nó grep `Color:`/`Size:` và đếm đúng thứ nó grep. Nó trượt vì hai
  thứ nằm ngoài tầm với của mọi phép grep — **ký tự vô hình** (`U+200E` dính đầu một ISBN, nhìn y
  hệt dãy số thường) và **giá trị không có nhãn trục** (`Paperback`, `M | L | XL`). Khi số đo lại
  khác số trong spec, câu hỏi đầu tiên là: *phép đếm này không nhìn thấy cái gì?*

`sdd-process` thêm luật 5b: **số mô tả dữ liệu thật phải ghi kèm lệnh đo ra nó.** Một phép đo
không kèm lệnh thì sáu tháng sau không ai kiểm lại được — và `/sdd-solo:verify` đo lại được chính
vì lệnh đó nằm trong file.

## 3.5.0 — 2026-09-09

### Thêm — bước ⑧ có cửa thứ hai, và `/sdd-solo:verify` (#27, #28)

Nguyên văn chủ dự án: *"Tạo issue cần ngủ 1 đêm là không đúng. Tìm giải pháp khác."*

**Bằng chứng nặng nhất nằm trong chính plugin này.** `.sdd/prompts/adversarial-pass.md` dòng 1:
*"chạy trong một session MỚI, không phải session đang viết spec"*. Bước ⑦ và bước ⑧ cần **đúng
một thứ**: người đọc không bị neo bởi giả định của người viết. Bước ⑦ mua nó bằng session mới;
bước ⑧ mua nó bằng một đêm lịch. Không dòng tài liệu nào nói vì sao cùng một nhu cầu lại có hai
giá — và ô `Session mới: [x]` của bước ⑦ **chưa từng được script nào kiểm**, tức chỗ nhẹ hơn thì
tin lời khai, chỗ nặng hơn thì bắt đợi.

**Một đêm đo thời gian trôi qua, không đo việc đọc có xảy ra không.** Ca thật đo được hôm nay trên
`runxops`: commit lúc 21:18 · cổng đỏ đúng một lỗi là dòng ngủ-một-đêm lúc 21:28 · đọc lại ngay
lúc 21:30 tìm ra **7 chỗ, 3 chỗ phải sửa trước cổng** — một trong đó là một Open Question vẫn đang
dạy phương án mà chính `Q18` đã bác vài giờ trước. Thứ luật một-đêm muốn mua **đã xảy ra**, cách
commit 10 phút, và cổng vẫn đỏ. Còn đợi tới mai thì không bảo đảm gì: cùng người, cùng cái neo.

- **Cửa 1 giữ nguyên** — commit `docs(UC-###)` đã qua một đêm. Repo đang chạy không phải sửa gì.
- **Cửa 2 mới:** mục `## Đọc lại` có **ít nhất một** dòng `F#` mang **cả `[neo: ...]` lẫn đầu ra
  khác `___`**, và commit mới nhất là `docs(UC-###): đọc lại …`. Ba điều kiện cùng đúng thì qua
  cổng **trong ngày**.
- **Chốt chống khai gian nằm ở chữ "ít nhất một".** Đọc mà không thấy gì thì cửa 2 không mở, rơi
  về cửa 1 — nên nói dối ở đây tốn **đúng bằng** làm thật: phải bịa ra một phát hiện có neo trỏ
  vào chỗ có thật và có một đầu ra mang ID.
- **`/sdd-solo:verify`** — skill mới. `verify UC-###` chạy **subagent** đọc lại (không có context
  của buổi viết → không bị neo **do cấu tạo**, chứ không do ai khai), trình từng `F#` bằng
  `AskUserQuestion`, ghi `## Đọc lại`, commit riêng. `verify` không tham số thì quét cả cây.

### Vì sao là skill, không phải thêm một phép kiểm vào cổng (#28)

Nguyên văn chủ dự án: *"cần có 1 skill để chạy kiểm tra tính xác thực của tài liệu. Bởi vì đang
trong giai đoạn plan plan có lệch rất nguy hiểm"*. Mười ca thật trên `runxops` trong **đúng một
ngày**, không ca nào bị script bắt — `br.md` kết luận một bảng *"chưa tồn tại"* trong khi commit
trước đó đã tạo nó · commit khai một khối nội dung chưa hề vào file · `RULE-001` đổi sang UUID mà
`br.md` còn ba đoạn nói ngược · `AC-6` hứa hệ thống *biết* một thứ mà không bước nào đi lấy · và
cả con số `26/40` sai trong issue #25.

Đây **không** cùng họ với #11/#13/#17/#24/#26. Bốn cái đó là *"đếm đúng nhưng đếm nhầm chỗ"* —
sửa được bằng cách sửa phép đếm. Loại này là *"không có phép đếm nào cho nó"*: cả sáu loại sai đều
đòi **đọc và so nghĩa**. Viết bằng `grep` sẽ ra đúng cái bẫy đã ghi ở 3.4.2 — một phép kiểm báo đỏ
oan rồi bị học cách phớt lờ. Nên nó là **skill có người quyết từng dòng**, không phải cổng.

Bốn ràng buộc, cả bốn có tiền lệ trong plugin: chỉ báo không sửa (như ba vai) · mỗi phát hiện
**trích nguyên văn hai chỗ đang cãi nhau** (#25 — và đó là thứ làm phát hiện kiểm lại được) · mỗi
phát hiện có đầu ra mang ID (#12) · phạm vi là **cả cây**, vì 6/10 ca là lệch **giữa** các file,
đọc từng file riêng không thấy cái nào.

Ba giới hạn ghi thẳng vào skill, không giấu: nó **sinh dương tính giả** nên bác phải rẻ và lý do
bác phải được ghi lại · **"không thấy gì" là bằng chứng yếu**, cấm in ra câu nào nghe như bảo
chứng, chỉ được nói *"không tìm ra gì trong phạm vi đã đọc"* kèm liệt kê phạm vi · chi phí đọc cả
cây phải thu về theo `git diff` khi cây lớn.

### Sửa kèm

- `uc-ready.sh` bỏ qua mục `## Đọc lại`. Không bỏ thì mục của bước ⑧ còn nguyên template sẽ làm
  uc-ready đỏ ở bước ⑦, `adversarial` từ chối chạy, và không có đường ra: muốn qua ⑦ phải điền
  trước một mục chỉ tồn tại sau ⑦.

### Hai bẫy shell gặp khi viết bản này — cùng họ với những bẫy đã ghi

1. **`${VAR#docs($ID): ...}` không khớp gì cả** vì dấu ngoặc đơn trong pattern bóc tiền tố. Nó trả
   về **y nguyên** chuỗi vào, nên điều kiện luôn sai và cửa 2 **không bao giờ mở** — không lỗi,
   không cảnh báo. Dùng `case ... in "docs($ID): đọc lại"*)`. Cùng họ `ls a b` (#16).
2. **Dấu nháy đơn trong comment tiếng Việt bên trong khối `awk '...'`** đóng chuỗi của shell sớm
   và giết cả chương trình awk. Triệu chứng giống hệt bẫy trên: biến rỗng, không thông báo.

Cả hai đều bị bắt vì test đo **từng ca một** thay vì chạy một ca rồi kết luận. Bốn ca khai gian
(F# không neo · đầu ra còn `___` · `→ đầu ra: ___` có nhãn · commit sai tiêu đề) đều phải đỏ, ba
ca thật phải xanh — bảy ca, đo đủ bảy.

## 3.4.3 — 2026-09-09

### Sửa — `status.sh` tố `code_paths` sai trong khi `code_paths` đang đúng (#26)

Ca đầu tiên của luật vừa ghi ở 3.4.2 — *báo đỏ oan thì bị học cách phớt lờ* — và lần này là đỏ
oan **thật**, đo trên `runxops`, không phải giả định.

`status.sh` gộp hai mối lo khác nhau vào **một `if` HOẶC** rồi thân `if` không kiểm lại vế nào đã
đúng:

```bash
if ! has_code_path "$ROOT" || [ ! -d "$ROOT/$UCT_" ]; then
  ...  bad "code_paths=… — không thư mục nào tồn tại"      # in cả khi has_code_path TRUE
```

Nên chỉ cần `tests/use-cases/` chưa có là `code_paths` bị tố oan. Đo bằng chính hàm của plugin:
`has_code_path` **TRUE**, `[ -d tests/use-cases ]` **không** → vẫn in *"không thư mục nào tồn
tại"*.

**Vì sao nó tệ hơn một dòng đỏ oan bình thường:**

1. **Nó bảo người ta đi sửa một file đang đúng.** `.sdd/config` có comment *"Sửa tay thoải mái"*,
   nên người tin dòng ✗ sẽ đổi `code_paths` sang thứ khác — và **lúc đó githook mới thật sự chặn
   hụt**. Dòng cảnh báo tự tạo ra chính cái nó cảnh báo.
2. Nó đứng ngay cạnh một dòng `!` **đúng** về `uc_test_dir`, nên người đọc học cách bỏ qua cả cụm.

Và nó không hiếm: đúng với mọi repo đã có thư mục code mà chưa implement UC nào — tức khoảng thời
gian `sdd-solo` ở lâu nhất, từ `scaffold` tới `/speckit-implement` đầu tiên. Ở `runxops` thứ làm
`repo_has_code` TRUE chỉ là một script chuyển dữ liệu một lần, không phải code sản phẩm.

- **Tách hai mối lo, hỏi riêng.** `code_paths` chỉ nói khi `has_code_path` sai; `uc_test_dir` chỉ
  nói khi thư mục thiếu.
- **`uc_test_dir` vắng ở Phase 1–2 là BÌNH THƯỜNG** — chưa AC nào implement thì chưa có test nào
  để đặt vào. Dòng `!` nay chỉ hiện khi đã có UC `Status: implemented` mà thư mục vẫn vắng.

Bốn ca đo trên repo thật, `src/` có · `tests/use-cases/` chưa có:

| Ca | Trước | Sau |
|---|---|---|
| `has_code_path` TRUE, chưa UC implemented | ✗ oan | **im** |
| Có UC implemented, chưa có `tests/use-cases/` | ✗ oan + ! đúng | **chỉ ! đúng** |
| Đã có `tests/use-cases/` | ✗ oan | **im** |
| `code_paths` trỏ sai thật, repo có file nguồn | ✗ đúng | **✗ đúng** — giữ nguyên |

`status.sh` vẫn `exit 0`; lỗi này chưa bao giờ chặn cổng hay CI, chỉ dạy người ta ngờ output.

## 3.4.2 — 2026-09-09

### Sửa — bản vá đảo thứ tự bước mà giữ nguyên số thì không cổng nào bắt được

Ca thật ở `runxops`, tìm ra khi sửa nhãn `E#` của `UC-009`: câu adversarial Q1 bảo *duyệt trước,
ghi sau*. Bản vá **đảo nội dung hai bước nhưng giữ nguyên số**, nên đọc `Main Flow` từ 1 xuống vẫn
ra thứ tự cũ — ghi trước, duyệt sau. `UC-009.flow.md` vẽ theo đó nên cũng vẽ ngược.

Nửa sai đó sống sót qua **một lượt adversarial và ba lần chạy cổng**. Không phép kiểm nào bắt
được, và không phép kiểm nào *đáng lẽ* bắt được: mỗi bước đều tồn tại, đánh số đủ, mọi nhãn đều
deref được. **Cái sai nằm ở thứ tự — thứ chỉ đọc mới thấy.** Đây đúng là loại lỗi bước ⑧ *"đóng
máy, đọc lại buổi sau"* sinh ra để bắt, và nó thuộc về người đọc chứ không thuộc về script.

Bước 5 của `skills/adversarial` nay bắt buộc, khi bản sửa làm đổi thứ tự bước:

1. **Đánh số lại** theo thứ tự đúng, sửa luôn `UC-###.flow.md` cho khớp.
2. **Remap mọi nhãn theo NGHĨA, không theo số** — `Main 5` sau khi đánh số lại có thể trỏ vào bước
   khác hẳn. **Số không phải danh tính**; nó là vị trí, và vị trí thì đổi.
3. `## History` ghi **vì sao số đổi**, không chỉ ghi "đã sửa".

### Không thêm cổng cho lớp lỗi này — và ghi rõ vì sao

Phép kiểm gần nhất là đối chiếu thứ tự node trong `flow.md` với thứ tự bước trong `## Main Flow`.
Flow có nhánh nên "thứ tự" không tuyến tính → sẽ **báo oan**. Theo đúng luật của repo này, *một
phép kiểm báo xanh sai tệ hơn không có phép kiểm* — và một phép kiểm báo đỏ oan thì bị người ta
học cách phớt lờ, rồi kéo theo cả những dòng đỏ thật. Ghi lại đây để lần sau không ai đi làm nó.

### Đo được — cổng KHÔNG quá chặt

Phân loại 9 dấu ✗ của `UC-009` trên repo thật, sau khi `glossary.md` được viết (19 thuật ngữ,
`UC-009` còn **2 ✗**):

| Loại | Số dòng |
|---|---|
| Spec thiếu thật | **7/9** — 5 nhãn `E#` vắng trong flow · `E3` không có dòng Screens · glossary còn template |
| Thủ tục, tan khi `/sdd-solo:adversarial` chạy xong | 2/9 |
| **Cổng quá chặt / bắt oan** | **0/9** |

Không dòng nào bắt oan. 9 dòng nhiều là vì spec thiếu thật 7 chỗ, không phải vì cổng khó tính.
Đây là lần đầu có số liệu từ repo sản xuất trả lời câu hỏi đó.

## 3.4.1 — 2026-09-09

### Đính chính — `allowed-tools` KHÔNG phải whitelist

3.4.0 viết: *"không skill nào khai `AskUserQuestion` … không khai thì không gọi được … chưa bao
giờ dùng được ở đâu cả."* **Sai.** Tài liệu chính thức của Claude Code, nguyên văn:

> *"The `allowed-tools` field grants permission for the listed tools during the turn that invokes
> the skill … **It does not restrict which tools are available: every tool remains callable**, and
> your permission settings still govern tools that are not listed."*

Nó là **cấp quyền trước** cho một lượt, không phải hàng rào. Phiên `runxops` đo trên transcript
của chính nó: `AskUserQuestion` được gọi **14 lần**, trong đó có lệnh gọi nằm gọn trong khoảng
`/sdd-solo:intake` với nội dung *"BR-001 viết lại quanh vết thương nào?"* — tức intake đã hỏi
bằng cơ chế đó, chạy thật, người thật trả lời. Tiền đề gốc của #25 đúng ngay từ đầu.

**Hệ quả cho ai đọc sau:** bản vá thật của #25 là **sửa văn bản bước 5**, không phải sửa
frontmatter. Dòng `allowed-tools` giữ lại vì nó bớt được một lần hỏi quyền giữa buổi phỏng vấn,
nhưng ghi sai nguyên nhân thì lần sau gặp lại triệu chứng này sẽ có người đi sửa frontmatter thay
vì sửa câu chữ — và sửa xong sẽ không có gì đổi.

Cách tự kiểm sau này: `allowed-tools` mà thiếu một tool thì triệu chứng là **một lời hỏi quyền**,
không phải một lỗi *"tool không tồn tại"*. Thấy skill vẫn gọi được tool không khai → đó là hành vi
đúng, không phải lỗ hổng.

### Sửa — nhãn nguồn có ba nơi để tra, không phải một (#25 nối tiếp)

`runxops` duyệt cả 24 câu adversarial của `UC-009`, tách từng nhãn rồi truy ngược vào file thật:
**50 nhãn · deref được 49** (Main 19 · E 10 · AC 9 · Section 5 · SCR 3 · RULE 1 · Alt 1 · OpenQ 1).
Không nhãn nào trỏ vào chỗ rỗng — nguyên liệu để dereference có thật.

Cái trượt duy nhất là **`CON-011`**, và nó tồn tại thật ở `specs/br.md`. Script chỉ tra hai chỗ:
file UC và `rules.md`. Bước 5 của `skills/adversarial` cũng vậy — nên ai cài phần "dán nguyên
văn" theo đúng chữ của 3.4.0 sẽ **im lặng bỏ sót mọi nhãn `CON-`**: không lỗi, không cảnh báo,
chỉ là câu hỏi đó mất đúng phần ngữ cảnh đắt nhất, vì `CON-` là nhãn mang ràng buộc.

- Bước 5a nay có **bảng ba nguồn tường minh**: file `UC-###.md` (`Main N` · `Alt Na` · `E#` ·
  `AC-#` · `SCR-###-#`) · `specs/rules.md` (`RULE-###`) · **`specs/br.md`** (`CON-###` ·
  `Background` · `Success Metrics` · `Out of Scope` · `Impact Map`).
- Tra không thấy → **nói thẳng trong câu hỏi** (*"nhãn `[CON-011]` không tìm thấy trong
  `br.md`"*), không lặng lẽ bỏ nhãn đi. Cùng một luật với `→ spec:` trống ở #12: lời khai không
  kiểm được thì phải hiện ra, không được biến mất.

## 3.4.0 — 2026-09-09

### Thêm — câu hỏi phải trả lời được, không chỉ phải trả lời (#25)

Nguyên văn chủ dự án: *"các câu hỏi hiện tại chỉ là 1 dòng. Anh không biết được có nên trả lời
nó hay không. Và ngữ cảnh của câu hỏi là gì, giải pháp nào anh nên chọn."*

3.3.0 trả lời *"câu nào buộc chốt trước bước ②"*. Bản này trả lời câu tiếp theo: **đã biết phải
chốt rồi thì lấy gì mà chốt.** Phân loại xong mà vẫn đưa một dòng thì người dùng biết mình *phải*
trả lời nhưng vẫn không trả lời được — tệ hơn trước, vì giờ không bỏ qua được nữa.

Đo trên `runxops`: **26/40** câu treo ở `br.md` có `(quyết định tạm: ___)` rỗng · **21/24** câu
adversarial của `UC-009` còn `→ đầu ra: ___`.

- **Nguyên liệu đã thu rồi, chỉ là không ai giải nén.** Prompt đã bắt mỗi câu kèm nhãn nguồn
  `[Main 7, RULE-003]`, và ba vai làm đúng **24/24**. Nhưng bước 5 của `skills/adversarial` chỉ
  nói *"trình cho user từng câu"* — không đọc `Main 7` và `RULE-003` ra. Nay bắt buộc
  **dereference**: dán **nguyên văn** chỗ spec đang nói gì.
- **`AskUserQuestion` nay nằm trong `allowed-tools`** của `adversarial`, `intake`, `start`.
  ~~Trước bản này không skill nào khai nó, nên cơ chế tưởng đã có sẵn thật ra chưa skill nào gọi
  được.~~ → **Câu gạch trên SAI. Xem Đính chính ở 3.4.1.** Việc thêm vào `allowed-tools` vẫn giữ,
  nhưng nó chỉ bớt một lần hỏi quyền, không phải nguyên nhân gốc.
- **Mỗi câu kèm ba thứ**, thiếu một là câu hỏi không trả lời được: ngữ cảnh **trích dẫn nguyên
  văn** (tóm tắt là chỗ lén thêm giả định) · mỗi lựa chọn kèm **cái mất** · `Chưa quyết` **luôn
  hiện sẵn** như một lựa chọn, không phải thứ phải tự gõ ra để thoát.
- **Áp bài kiểm hình dạng/giá trị của 3.3.0 vào từng câu**: câu đổi hình dạng thì hỏi, câu đổi giá
  trị thì ghi thẳng Open Question. Hỏi hết 24 câu là cách nhanh nhất để user bấm bừa cho xong.
- **Vai BR nay cũng phải kèm nhãn nguồn** (`[Background]` · `[CON-002]` · `[Success Metrics]`) như
  vai UC. Sửa 36/40 câu treo ở `br.md` không truy được về đâu.
- **Cảnh báo khi `___` chiếm quá nửa** — `br-check` trên `## Open Questions`, `gate-check` trên
  `## Adversarial pass`. `___` là đầu ra hợp lệ và không được biến mất; nhưng khi nó chiếm đa số
  áp đảo thì đó không còn là *"đã cân nhắc và chưa quyết được"*, mà là *"không có gì để cân"*.

### Ranh giới — vì sao đề xuất được phép, và phép tới đâu

Đưa phương án cho người dùng đụng thẳng vào thứ cả tầng BR sinh ra để chặn: AI nêu một con số
nghe hợp lý rồi nó thành sự thật trong spec. Bốn ràng buộc, ba cái đầu từ issue và cái thứ tư là
cái duy nhất **để lại dấu vết trong file**:

1. **Căn cứ phải truy được trong repo, hoặc là một lệnh chạy lại được.** Kiến thức chung của model
   không phải căn cứ — cái đó gọi là *hướng có thể đi*, không được gọi là *khuyến nghị*.
2. **Không xếp hạng, không đánh dấu "nên chọn"** cho câu đổi giá trị nghiệp vụ. Bày ra không gian
   lựa chọn là đưa thông tin; chọn hộ là ra quyết định.
3. **Giá trị do AI nêu mà user chỉ gật thì chưa phải của user** → ghi `___ (AI gợi ý X, chưa ai
   duyệt)`. Chỉ khi user tự nói ra bằng lời của họ mới thành quyết định. Đây đúng là bẫy gật đầu
   `/sdd-solo:intake` đã vá ở 3.2.3 — cùng cái bẫy, chỗ khác.
4. Ba ràng buộc trên sống trong **hội thoại**; ràng buộc này sống trong **file**. Đóng terminal thì
   chỉ còn file — nên provenance của mọi con số phải nằm trong spec, không nằm trong lời nói.

## 3.3.2 — 2026-09-09

### Sửa

- **Dòng ✗ của glossary nói đúng cái gì sai, nhưng không nói bắt đầu từ đâu.** Đo trên lần chạy
  thật ở `runxops`: trong cùng một lần `gate-check`, dòng cảnh báo ngay phía trên nói luôn phải
  gõ gì (*"dùng `P#` cho node kết thường, `X#` cho node kết của ngoại lệ"*), còn dòng glossary chỉ
  nói nó sai. Mà glossary là file **khó bắt đầu hơn nhiều**: *"đổi E1 thành X1"* là một phép thay,
  còn *"viết glossary đi"* là một trang giấy trắng.

  Nay nó chỉ nguồn có sẵn. Người ở bước ⑨ gần như luôn đã viết xong `entities.md`, và tên entity
  chính là mẻ thuật ngữ đầu tiên — nên script đọc thẳng tên entity ra và in kèm:

  ```
  ✗ specs/glossary.md còn nguyên template — CLAUDE.md bảo dùng đúng tên trong đó, mà trong đó chưa có tên nào
    – mẻ đầu có sẵn — tên entity anh đã viết: Account Listing
    – mỗi dòng một từ, dưới heading '## catalog':  - **Tên** — nghĩa một câu. Không nhầm với **từ gần nghĩa**.
  ```

  Biến một trang trắng thành việc chép. `entities.md` chưa có thì nó nói lấy từ đâu.

### Không phải lỗi — đã kiểm

- Báo cáo *"`gate-check.sh` thoát với EXIT rỗng qua pipe"* không phải lỗi của script. Đo lại:
  chạy trực tiếp → `exit 1` đúng; qua pipe thì `$?` là của lệnh cuối trong pipe, đúng chuẩn shell.
  `${PIPESTATUS[0]}` rỗng là vì **zsh** dùng `$pipestatus[1]` (chữ thường, đánh số từ 1), còn
  `PIPESTATUS` viết hoa là của bash. Đo hai chiều:

  ```
  bash:  PIPESTATUS[0] = 1
  zsh:   PIPESTATUS[0] = ''   ·  pipestatus[1] = 1
  ```

  Ai đọc exit code của script trong CI dưới zsh thì nhớ chỗ này; script không cần sửa.

## 3.3.1 — 2026-09-09

### Làm rõ

- **Không phải mũi tên nào trên state diagram cũng do một UC kéo.** Luật cũ viết tuyệt đối —
  *"mỗi mũi tên ghi UC nào được kéo nó"* — nhưng có ca thật ngược lại: `đangSống --> đãSuspend`
  xảy ra vì sàn khoá tài khoản, không UC nào gây ra. Trạng thái đổi vì thế giới bên ngoài (hệ
  thống khác đẩy sang, hết hạn theo đồng hồ) là chuyện bình thường, và ép nó mang một `UC-###`
  cho đủ hình thức chính là **bịa** — đúng thứ cả quy trình này sinh ra để chặn.

  Luật nay viết đúng: mỗi mũi tên ghi **nguyên nhân**, thường là `UC-###` nhưng không bắt buộc.
  Template context có sẵn một mũi tên dạng đó để thấy nó hợp lệ.

- `gate-check` §6 **cố ý** quét cả file thay vì xét từng mũi tên — chỉ cần một mũi tên gắn UC có
  thật là qua. Hành vi này không đổi ở 3.3.0; cái đổi là **lý do của nó nay nằm trong code**, kèm
  ca thật, để lần sau không ai "sửa" nó thành per-arrow rồi bắt oan. Cùng bài học #21: luật không
  để lại dấu vết ở chỗ người ta sẽ đọc thì sẽ trôi — lần này chỗ đó là comment cạnh phép kiểm.

### Đính chính

- Ghi chú nâng cấp ở 3.3.0 nói repo đang chạy sẽ đỏ *bốn* dòng ở §6. Đo trên `runxops` sau khi
  `entities.md` v2 đã viết xong: **đỏ một dòng** (`glossary.md` còn template). Ba phép kiểm còn
  lại xanh trên file viết tử tế — phép kiểm mũi tên bắt đúng thứ nó định bắt và không bắt oan.

## 3.3.0 — 2026-09-09

**Đọc trước khi nâng:** repo nào có `entities.md` hoặc `glossary.md` còn là template sẽ bắt đầu
**đỏ ở cổng DoR**. Đó không phải quy tắc mới — cổng vẫn luôn đòi hai file đó; phép kiểm chỉ báo
xanh sai suốt từ đầu. Viết chúng ở bước ③ là xong.

### Sửa

- **`uc-ready.sh` chặn `___` trong `## Open Questions`, nên lối thoát duy nhất là bịa số** (#23).
  Người viết trung thực `- [ ] Khoá nối là gì? (quyết định tạm: ___)` bị chặn ở bước ⑦, và cách
  duy nhất đi tiếp là thay `___` bằng một giá trị nghĩ ra tại chỗ. Đó đúng là thứ cả tầng BR sinh
  ra để chặn — `specs/br.md` viết thẳng *"`___` là câu trả lời hợp lệ, số bịa thì không"*, rồi bước
  ⑦ của chính quy trình đó chặn `___`.

  Ba chỗ trong quy trình đã nói ngược nhau về cùng một thứ: `gate-check` §8 cho qua (chỉ đỏ khi
  *thiếu* `quyết định tạm`), `br-check` chỉ cảnh báo, `uc-ready` chặn. Nay `___` trong Open Questions
  là hợp lệ và có một dòng `–` nói rõ nó được bỏ qua; `<...>` thì vẫn đỏ ở mọi chỗ, kể cả trong
  Open Questions — đó mới là "chưa ai viết nội dung".

- **`gate-check` §6 báo ✓ trên `entities.md` chưa ai đụng vào** (#24). Phép kiểm là
  `grep -q stateDiagram`, mà template context có sẵn một khối `stateDiagram-v2` mẫu — nên nó khớp
  vào chính nó. `entities.md` còn nguyên `class EntityA` / `class EntityB` vẫn in `✓ context <ctx>
  có entities.md` và không warn một chữ.

  **Một phép kiểm báo xanh sai tệ hơn không có phép kiểm** — không có thì người ta còn tự nhớ.
  Cùng hình lỗi đã vá hai lần: #11 (tiền điều kiện đo cấu trúc) và #13 (RULE placeholder lọt gate).
  Nay đo nội dung: tên entity của template, tiêu đề `<Context>`, và mũi tên state diagram phải ghi
  một `UC-###` có thật thay vì `<UC-### tạo>`.

- **`glossary.md` không script nào kiểm** — `grep -ric glossar scripts/` ra **0 trên cả 15 script**,
  trong khi khối `CLAUDE.md` phát cho dự án bảo AI *"dùng đúng tên trong `specs/glossary.md`"*. File
  đó trôi im lặng suốt. Nay cổng DoR đỏ nếu nó còn nguyên template, và đếm số thuật ngữ thật.

### Thêm

- **`uc-ready.sh` cảnh báo** (không chặn) khi `entities.md` của context hoặc `glossary.md` còn là
  template. Ba vai adversarial đọc hai file đó làm đầu vào; chạy ba subagent trên một mô hình chưa
  viết thì mô hình đổi sau đó và AC phải **sửa lời**. Chi phí thật là vậy — không phải mất trắng,
  nên **cảnh báo chứ không chặn**: chặn ở đây là lặp lại đúng hình lỗi của #23.

- **Chuỗi 14 bước nay đặt tên cho việc viết `entities.md` + `glossary.md`** (bước ③). Trước đây
  bước ⑥ (*đối chiếu SCR ↔ E# ↔ state*) và cổng ⑨ đều đã đòi hai file đó, nhưng không bước nào
  trong chuỗi nói ai viết chúng và lúc nào — nên chúng hay bị làm sau bước ⑦. `skills/adversarial`
  không sai khi đòi đọc `entities.md`; chuỗi bước mới là chỗ thiếu.

- **Câu hỏi nào phải chốt trước bước ②, câu nào treo được** — mục mới trong `sdd-process`, và
  `/sdd-solo:start` nay hỏi và phân loại giúp. Từ câu hỏi thật của chủ dự án: *"anh bị phân vân là
  nên nghiên cứu để trả lời câu hỏi, hay chạy tiếp `use-case-spec`. Flow không có gì hướng dẫn anh."*

  Ranh giới: câu đổi **hình dạng** của UC (actor là ai · dữ liệu đến từ đâu · ai được làm) phải
  chốt trước, vì Main Flow viết theo giả định sai sẽ phải **vứt**. Câu đổi **giá trị** trong một
  bước (ngưỡng · thời hạn · enum · khoá) thì **treo được** bằng `quyết định tạm: ___`. Bài kiểm một
  câu: *câu trả lời ngược lại thì Main Flow có phải viết lại không?*

## 3.2.3 — 2026-09-08

Ba phát hiện từ phép thử bộ câu hỏi (#22): hai subagent đóng vai người dùng, hai đóng vai người
phỏng vấn, **không bên nào biết đang bị đo cái gì**; cả hai nhân vật gật đầu ngay với bất kỳ con số
nào người phỏng vấn nêu ra, nên số nào có trong BR mà không có trong lời nhân vật đều là số do
skill đẻ ra — so file với transcript là ra.

Kết quả nền: cả ba BR qua `br-check` vòng đầu, **0 số nghiệp vụ bịa**, không BR nào để giải pháp
lọt vào Goal.

### Sửa

- **Câu 5 không chặn được gì — chỗ nặng nhất.** SKILL.md gọi câu 5 (*"có cách nào đạt được điều đó
  mà không xây phần mềm không?"*) là *"thứ duy nhất chặn được việc xây một phần mềm không cần tồn
  tại"*. Nhưng khi user trả lời *"chưa nghĩ tới"*, hướng dẫn chỉ bảo ghi một Open Question rồi đi
  tiếp — mà Open Question **không chặn gì**. Một BR ghi thẳng trong Background *"BR này hiện chưa
  có lý do chọn xây phần mềm"* vẫn ra `BR DÙNG ĐƯỢC`, không gì phân biệt nó với BR đã chứng minh xong.

  `## Background` nay có một dòng bắt buộc `**Vì sao vẫn xây:**`, `br-check` **cảnh báo** khi thiếu
  (không đỏ — Phase 1 vẫn phải mềm), và vai hoài nghi ở `/sdd-solo:adversarial BR-###` đọc dòng đó
  **trước tiên**; ghi *"chưa có lý do"* thì đó là câu hỏi số một của nó. Ghi *"chưa có lý do"* vẫn
  qua kiểm — trung thực là hợp lệ; thứ không hợp lệ là im lặng.

- **Bẫy gật đầu: hai luật trong SKILL.md đá nhau.** Một dòng cấm gợi ý số để user gật; một dòng
  khác bắt cách đo không được để trống. Với người chưa từng đo cái gì thì hai câu đó không cùng
  thoả được — họ cần một ví dụ, mà ví dụ nào cũng kèm ngưỡng. Phép thử bắt được đúng ca này: người
  phỏng vấn nêu *"quá một ngày mới trả lời"*, user gật ngay. Nó thoát **nhờ tự giác** (tự ghi Open
  Question rằng số đó là của mình), **không nhờ luật** — và `br-check` báo ✓ cả hai đằng, vì nó
  kiểm *có* cách đo chứ không kiểm cách đo đó **của ai**.

  Ranh giới nay viết rõ: được nêu **khung đếm** (đếm ở đâu · đếm cái gì · bao lâu một lần), không
  được nêu **ngưỡng bên trong khung**; ngưỡng luôn `___` kể cả khi user đã gật. Kèm một mẫu câu an
  toàn, và bắt buộc ghi Open Question *"số này do người phỏng vấn nêu, user chưa quyết"*.

- **Câu 5 mâu thuẫn nhẹ với luật "không đề xuất tính năng".** Muốn user bác được phương án
  không-phần-mềm thì phải nêu phương án; người chưa nghĩ tới không tự liệt kê được. Nay nói rõ đây
  là ngoại lệ có chủ ý, với hai ràng buộc: chỉ nêu phương án **không-phần-mềm**, và nêu **ít nhất
  ba** để user không bị dẫn vào đúng một cái rồi gật.

- `_intake.md`: thêm cảnh báo về số **user tự đoán** (*"tuần nào cũng vài lần"*) — ca này khó hơn
  *"không biết"* thẳng, vì chính user mở đường cho con số vào Background.

## 3.2.2 — 2026-09-08

### Sửa

- **Luật 4 của `/sdd-solo:intake` không để lại dấu vết nào trong file** (#21). Luật này bảo
  *"in danh sách thứ đã bỏ kèm lý do"* — và agent làm đúng chữ đó: đọc ra một danh sách khá kỹ,
  rồi thôi. Grep toàn bộ BR sinh ra: không mục nào ghi thứ đã bỏ. Toàn bộ sản phẩm của luật này
  sống trong **lời nói**; đóng terminal là mất, và sáu tháng sau không ai biết brief từng có
  những gì, vì sao chúng biến mất.

  Ba luật kia đều để lại dấu vết trong file — `___`, Open Question, nhánh `-.->` — nên kiểm được.
  Luật 4 là luật duy nhất không. Cùng họ với #11 #12 #13: **cái gì không kiểm được thì cuối cùng
  sẽ trôi**; khác ở chỗ lần này thứ trôi là một luật chứ không phải một cổng.

  - Template `br.md` có thêm mục `## Đã loại khỏi brief` (chỉ dùng khi BR chuyển từ brief) và
    dòng `- **Nguồn:**` trong Metadata.
  - `br-check.sh` **cảnh báo** khi Metadata nói nguồn là brief mà mục đó thiếu hoặc rỗng. Chỉ
    cảnh báo, và chỉ với BR từ brief — BR viết từ phỏng vấn không loại cái gì nên không có mục
    đó là đúng.
  - Luật 4 trong SKILL.md đổi từ *"in danh sách"* thành *"ghi vào `## Đã loại khỏi brief`, rồi
    mới đọc lại cho user nghe"*.

### Làm rõ

- **Ranh giới số trong luật 1.** Luật cấm số ở chỗ **quyết định nghiệp vụ** — ngưỡng, thời hạn,
  quota, quyền. Nó **không** cấm số ở chỗ **cách đo**: *"bấm giờ 20 lượt đặt bàn liên tiếp"* là
  một cách đo cụ thể và tốt hơn hẳn *"bấm giờ vài lượt"*. Cấm luôn thì cách đo tụt về mơ hồ, tức
  mất đúng thứ `BR-000` đang dạy. Cụ thể ở cách đo là đúng; cụ thể ở quyết định mà không ai duyệt
  là bịa. Đã nói rõ trong `skills/intake/SKILL.md`.

### Ghi nhận

Ba luật đầu chạy đúng trên brief giả 29 dòng: mọi số không nguồn bị hạ thành
`___ (brief đề xuất …, chưa ai duyệt)`, ba khẳng định không bằng chứng xuống Open Questions,
5/8 tính năng ra Out of Scope kèm nhánh `-.->`, dark mode bị gọi thẳng là mồ côi. Con số duy
nhất được giữ nguyên là một số hiệu nghị định — thứ có nguồn thật.

## 3.2.1 — 2026-09-08

### Sửa

- **Cửa vào mới của 3.2.0 chưa được gắn vào đường cũ** (#20). `/sdd-solo:intake` tồn tại,
  nhưng câu chỉ đường **đầu tiên** user đọc — dòng cuối của `scaffold.sh`, ngay sau
  `/sdd-solo:init` — vẫn là:

  > *Bước tiếp: đọc specs/README.md · viết STATE.md · /requirements (AIUP) hoặc tự viết specs/br.md*

  Cả hai lựa chọn đó đều dẫn vào tường: `/requirements` đọc `docs/vision.md` mà không skill
  nào tạo ra, còn *"tự viết br.md"* chính là chỗ người ta đứng lại. `grep intake scripts/`
  ra 5 chỗ trong `status.sh` và **0 chỗ** trong `scaffold.sh` — file nói trước là file sai,
  file đúng chỉ nói khi user đã biết gõ `status`.

  Sửa **sáu** chỗ cùng loại, không phải một:
  - `scaffold.sh` — dòng chỉ đường sau `init`.
  - `skills/init/SKILL.md` bước 5 — chỗ này tệ hơn cả, vì nó là chỉ dẫn cho **chính AI**:
    *"nói bước tiếp là Phase 1 — `/requirements` hoặc tự viết BR"*. Tức trợ lý được dặn
    chỉ sai đường ngay sau khi cài xong.
  - `hooks` SessionStart — khi `br.md` còn nguyên template thì câu đầu mỗi phiên nói thẳng
    *đang ở Phase 1, đừng nói về UC, đừng đề xuất viết code*, thay vì "đang ở UC nào".
  - `specs/README.md` — thêm mục **Bắt đầu từ đâu** lên đầu.
  - `STATE.md` — dòng `Đang làm:` giả định sẵn là đang ở một UC nào đó trong 14 bước.
  - `README.md` — bước sau `init`.

- `specs/_intake.md` không có **chỗ để viết câu trả lời**: nó bảo "không có Claude Code thì
  tự trả lời bảy câu bằng giấy bút", nhưng bảy câu nằm trong hai bảng markdown, không ô trống
  nào. Thêm hai khối trích dẫn đánh số sẵn.

Bài học chung với #10 và #17: thứ mình vừa xây chạy đúng, nhưng chỗ người dùng thật sự đứng
thì vẫn trỏ đi hướng cũ.

## 3.2.0 — 2026-09-08

### Thêm — Phase 1 có cửa vào và có kiểm (#18, #19)

Plugin đi từ 1.0.0 lên 3.1.1 với 17 issue, mà dự án nó phục vụ vẫn chưa có **một dòng BR nào**.
Không phải lười: người dùng nói thẳng là không biết viết thế nào cho đúng. Đo lại thì tầng BR
là tầng duy nhất trong bốn tầng không có gì đỡ ngoài một file template — không script kiểm,
không skill, `/sdd-solo:adversarial` chỉ nhận `UC-###`. Và không skill nào của sdd-solo **hay
của AIUP** tạo ra `vision.md` mà `/requirements` cần: nó *tiêu thụ* file đó.

Chi tiết đáng ghi nhất từ phiên `runxops`: người dùng nói *"chưa có template để mô tả 1 BR đúng"*
**trong khi đang nhìn thẳng vào một template có đủ Background, Goal, Metrics, Impact Map.** Nên
thứ thiếu không phải cái biểu mẫu — mà là **cách đi tới nội dung**. Bản này ưu tiên theo đúng
thứ tự đó: bộ câu hỏi trước, biểu mẫu sau.

- **`/sdd-solo:intake [brief]`** — cửa vào Phase 1, đối xứng với `/sdd-solo:start` của Phase 3.
  - *Không tham số* → **phỏng vấn**, một câu một lượt: khổ gì · ai khổ · tốn gì, rồi bốn câu đào
    sâu. Câu 5 (*"có cách nào đạt được điều đó mà không xây phần mềm không?"*) là câu hay bị bỏ
    nhất và là thứ duy nhất chặn được việc xây một phần mềm không cần tồn tại.
  - *Có đường dẫn* → **chuyển brief** của agent khác, theo bốn luật không có ngoại lệ: số không
    nguồn thì `___` + Open Question **kể cả khi brief có ghi số** (brief *đề xuất* ≠ ai đó *đã
    duyệt*) · mọi "xây X" phải đẩy ngược lên được một mục tiêu đo được, không ra thì đánh dấu mồ
    côi · khẳng định không bằng chứng thì thành Open Question chứ không thành Background · cuối
    phiên phải in ra thứ đã bỏ kèm lý do.
- **`specs/_intake.md`** — bộ bảy câu hỏi nằm **trong dự án**, dùng được cả khi không mở Claude Code.
- **`scripts/br-check.sh BR-###`** — kiểm cơ học tầng BR. Đáng kể nhất: Success Metrics được phép
  để `___` ở phần **số** nhưng **không** được thiếu **cách đo** — đó là ranh giới giữa một metric
  thật và một câu nói hay; Impact Map phải có ít nhất một nhánh `-.->`, vì không có nhánh đứt nào
  nghĩa là chưa map gì, chỉ là đường thẳng từ Goal xuống danh sách việc đã định sẵn; và Goal dùng
  từ mơ hồ (*tối ưu · cải thiện · nâng cao*) khi Metrics chưa có số nào thì đỏ.
- **`/sdd-solo:adversarial BR-###`** — ba vai của tầng BR, hỏi về **lý do tồn tại** chứ không phải
  hành vi: *người trả tiền* · *người sẽ phải vận hành nó mãi* · *người hoài nghi*. Vai thứ ba không
  có ở tầng UC và là vai quan trọng nhất — nó bắt lỗi **BR viết ngược từ giải pháp**. *"Xây dashboard
  theo dõi đơn hàng"* không phải BR; BR thật nằm ở câu hỏi *vì sao cần theo dõi*. Nếu vai này kết
  luận BR đang là giải pháp viết ngược thì **dừng và viết lại**, không ghi thành Open Question rồi đi tiếp.
- **`BR-000` — một BR điền đủ, nằm trong `specs/br.md` của dự án**, kèm cả mục Adversarial pass đã
  chạy. Đọc một BR viết đúng cạnh cái mình sắp viết là cách dạy rẻ nhất; `RULE-000` đã làm vậy ở #13.
  `br-check.sh` bỏ qua `BR-000`.
- **`/sdd-solo:status`** liệt kê BR kèm trạng thái, **đỏ** khi `br.md` còn nguyên template mà repo đã
  có UC (đang xây trên nền chưa viết — loại sai đắt nhất vì nó ở gốc), và cảnh báo khi có
  `docs/requirements.md` của AIUP mà chưa có BR.

Hai chỗ cố ý **mềm hơn** đề xuất trong issue, vì bản gắt sẽ đỏ trên mọi BR trung thực:

- **`___` chỉ cảnh báo, không đỏ.** Ở Phase 1, `___` là dốt một cách trung thực. Ép điền sớm đẻ ra
  đúng loại số bịa mà cả bước intake đang cố chặn. Placeholder `<...>` thì vẫn đỏ.
- **UC trong `## Related Use Cases` chưa tồn tại chỉ cảnh báo** — BR viết *trước* UC, đỏ ở đây thì
  không sửa được. Nhưng **chiều ngược thì đỏ**: UC đã khai `Liên quan tới BR: BR-###` mà BR không
  liệt kê nó là trôi thật, và luôn sửa được. Cùng bài học hai chiều của #12, #15, #17.

### Sửa

- `filled()` trong `br-check.sh` và `change-check.sh` không bắt được **placeholder trải nhiều dòng**:
  `<Vì sao có requirement này —` mở ở dòng này, `... như sự thật>` đóng ở dòng sau, nên regex một
  dòng `<[^>]+>` không khớp cái nào và mục rỗng đi qua như có nội dung. `## Background` của khung BR
  trống lọt đúng theo đường này. Nay bắt cả dòng chỉ mở và dòng chỉ đóng.

### Cách nâng

```
/plugin marketplace update sdd-solo
/plugin update sdd-solo
/sdd-solo:init --update          # br.md, _intake.md, prompts nằm trong templates/
```
`specs/br.md` đã sửa tay thì `init --update` **không** ghi đè — bản mới nằm cạnh dưới tên `br.md.new`,
tự merge rồi xoá `.new`.

## 3.1.1 — 2026-09-08

### Sửa

- **Phép đếm E# của 3.1.0 khớp `E<số>` ở bất cứ đâu trong file, kể cả tên node — nên
  cho `✓` GIẢ** (#17). Đặt một node kết là `E1([Đăng nhập được])` — tức một kết thúc
  **thành công** — thì cổng tin rằng đường lỗi `E1` đã được vẽ, kể cả khi nhánh ngoại lệ
  thật không còn nhãn nào. Sai về đúng phía nguy hiểm: không phải đỏ oan, mà là xanh sai.
  Chiều ngược thì kêu nhầm chỗ — node tên `E7` bị báo là "nhãn bịa".

  Nay **chỉ nhãn cạnh được đếm**: phần nằm giữa hai dấu `|` trên dòng có mũi tên. Tên node
  không bao giờ ở đó. Kèm một cảnh báo mềm khi vẫn có id node dạng `E<số>` — nó không giả
  mạo được nhãn nữa nhưng vẫn khó đọc cho người.

  Đáng sửa vì nó chạm đúng lý do đổi sang mermaid ở 3.1.0: để phép đếm *"số nhánh ngoại lệ
  = số E#"* **chạy được bằng máy** thay vì là một dòng chữ trong checklist. Đếm khớp cả tên
  node thì phép đếm đó chưa đúng, tức lợi ích chính của 3.1.0 chưa thành.

### Đính chính

- CHANGELOG 3.1.0 nói hồi quy chạy trên `runxops`. Không đúng: **`runxops` chưa có UC nào**
  — nó còn ở Phase 0, `specs/` toàn template. Mọi UC có `.bpmn` thật đều nằm ở bàn thử.
  Nên tới giờ chưa có bằng chứng nào từ một repo sản xuất, cho cả 3.1.0 lẫn bản này.

## 3.1.0 — 2026-09-08

### Đổi — bước ④ vẽ bằng Mermaid, không cần cài app

Bước ④ trước đây đòi `UC-###.bpmn` vẽ bằng **Camunda Modeler**, một app desktop phải cài.
Đọc lại thì cái giá đó gần như không mua được gì:

- `gate-check.sh` **chỉ kiểm file có tồn tại**. `.bpmn` là XML nén, script không đọc nổi.
- Checklist DoR đòi *"số error boundary event = số E#"* — một phép **đếm**, và đó mới là
  giá trị thật của bước này: nó ép tìm cho đủ ngoại lệ. Phép đếm ấy **chưa bao giờ chạy
  bằng máy**, chỉ là một dòng trong checklist.
- `git diff` trên `.bpmn` không đọc được, và phải nhớ export thêm `.bpmn.svg`.

Mermaid đảo cả ba: là text nên gõ bằng bàn phím, `git diff` đọc được, Claude sửa được,
VS Code (`Cmd+Shift+V`) và GitHub render sẵn. Và vì là text nên **cổng DoR đếm được E# thật**.

- **`UC-###.flow.md`** — artifact mới, mermaid `flowchart`, nằm trong thư mục UC.
  Template ở `.sdd/templates/use-case/UC-000.flow.md`.
- **`gate-check.sh` đối chiếu E# cả hai chiều**: E# khai trong `## Exceptions` mà sơ đồ
  không có nhánh → đỏ; nhãn `E#` trong sơ đồ mà UC không có Exception đó → cũng đỏ.
  Chiều ngược là bài học của #12 và #15: nhãn bịa đi qua mọi cổng nếu không ai đối chiếu.
  Thêm hai cảnh báo mềm: không có khối mermaid `flowchart`; không có node kết `([...])`.
- Không đếm lane/actor và Postcondition bằng máy — hai mục đó là văn xuôi tự do, đếm bằng
  regex sẽ đỏ oan. Bài học #16: file người viết tay trình bày tự do vẫn phải parse được.
- **Camunda Modeler xuống hàng tuỳ chọn** trong `deps-check.sh` — chỉ còn cần khi muốn
  chạy RULE bằng DMN engine, hoặc mở `.bpmn` cũ (`https://demo.bpmn.io` mở được trên
  trình duyệt, không phải cài).

**Không phá vỡ.** `.bpmn` vẫn được cổng DoR chấp nhận, chỉ không đếm được gì. Repo đang
dùng `.bpmn` không phải sửa gì.

### Sửa

- `.sdd/templates/use-case/UC-000.md` — dòng metadata trỏ `../../diagrams/UC-000.bpmn.svg`,
  sai từ 2.0.0 (bản đó đã dời diagram vào trong thư mục UC) mà không ai để ý. Nay là
  `**Flow:** UC-000.flow.md`.
- `skills/start/SKILL.md` liệt kê **đích danh** ba file để copy khi tạo UC mới, nên một
  template mới thêm vào `.sdd/templates/use-case/` sẽ không bao giờ tới tay dự án. Đã thêm
  `UC-000.flow.md` vào danh sách — chỗ này đáng nhớ cho mọi lần thêm template UC sau.

### Cách nâng

```
/plugin marketplace update sdd-solo
/plugin update sdd-solo
/sdd-solo:init --update          # template mới nằm trong templates/, không tự lan
```
UC đang dùng `.bpmn` cứ để nguyên. UC mới sẽ có sẵn `UC-###.flow.md`.

## 3.0.1 — 2026-09-08

### Sửa

- `close-check.sh` — bớt nhiễu ở bước soi số literal, theo số đo của phiên `runxops`
  trên một file 18 dòng viết theo lối thường: 4 dòng bị nêu, 2 đúng 2 sai. Hai ca sai
  đều là dạng máy loại được:
  - `+= n` / `-= n` — phép tăng giảm, lọt vào vì có dấu `=` ngay trước số. Gần như
    không bao giờ là ngưỡng nghiệp vụ.
  - `substring(0, 8)` / `slice(a, b)` / `padStart` / `padEnd` / `charAt` / `toFixed` —
    tham số chỉ số chuỗi, cùng họ với `[0]` đã loại từ trước.

  Dòng nào chứa chuỗi `số * số` thì **giữ trước khi xét hai luật đó**: `timeout += 30 * 60 * 1000`
  là tham số nghiệp vụ chứ không phải phép đếm, và luật `+=` một mình sẽ nuốt mất nó.
  Trên cùng file thử: từ 4 dòng (2 đúng 2 sai) còn 3 dòng, cả ba đều là tham số thật.

  Không đo được trên code sản xuất: `runxops` chưa có dòng code ứng dụng nào, `src/`
  chỉ có README stub. Con số trên là file viết cho giống code thường, không phải bằng
  chứng từ repo thật — ghi rõ ở đây để lần sau không ai trích nó như thể là.

### Không đổi

- Hồi quy 3.0.0 trên `runxops`: cổng Phase 5 đúng cả bốn mục, không mở issue nào.
  Một CHG do người viết tay (delta viết văn xuôi tự do, không theo dạng template) vẫn
  parse chuẩn — `✓ sửa AC-1 · ✓ sửa AC-4 · ✓ thêm AC-5`. Đây là rủi ro lớn nhất của
  3.0.0 (cổng chỉ được thử trên change do chính tác giả viết đúng template) và nó không
  xảy ra. Bốn dòng ✗ mà change đó rớt đều là lỗi thật của người viết.

## 3.0.0 — 2026-09-08

**Nâng cấp có phá vỡ.** Repo đang có `CHG-###` dở dang phải chạy `/sdd-solo:change CHG-###`
một lần cho mỗi change, nếu không githook sẽ chặn commit code gắn `(CHG-###)`.
Xem mục *Cách nâng* cuối bản này.

### Thêm — cổng Phase 5 (#16)

Phase 3 có 22 kiểm cơ học ở `gate-check.sh`. Phase 5 — chỗ **đổi hành vi đã giao cho
khách** — trước bản này có **không một kiểm nào**: không script, không skill. Một change
vào được repo với `proposal.md` nguyên xi template, không nói đụng UC nào, không nói lật
AC nào, và không gì chặn. Rủi ro của Phase 5 cao hơn Phase 3 mà hàng rào thì thấp hơn.

- **`/sdd-solo:change CHG-###`** — skill mới, cổng của Phase 5.
- **`change-check.sh`** kiểm, trong đó ba nhóm đáng kể:
  - *Có đúng là Phase 5 không.* Mọi UC trong `## Scope` phải có thật, phải `implemented`,
    phải có `.sdd/gate/UC-###.ok`. UC còn `draft` → đây là Phase 3, đóng change lại.
    Và phải có ít nhất một mục `MODIFIED`/`REMOVED`: chỉ thêm AC mới thì cũng là Phase 3.
  - *Delta có nói đúng về baseline không.* `REMOVED AC-7` khi baseline không có `AC-7`,
    `ADDED AC-1` khi baseline đã có `AC-1` — hai kiểu này trước đây không ai bắt, và
    chúng có nghĩa là delta đang mô tả một baseline khác với baseline thật.
  - *Có phải template không.* `<...>` còn sót, chuỗi `CHG-000`, `delta/UC-000.delta.md`,
    và mục chỉ chứa `...`. Bản thử đầu để lọt đúng cái cuối: `- ...` trong
    `## Rủi ro và cách lùi` đi qua cổng như một câu trả lời hợp lệ, vì nó *không rỗng*.
  - Cùng luật ngủ-qua-đêm với cổng DoR: `docs(CHG-###)` phải commit từ một buổi khác.
- **`change-pass.sh`** đặt `Status: applying`, thêm dòng History, ghi `.sdd/gate/CHG-###.ok`.
- `/sdd-solo:status` liệt kê change đang mở kèm status và dấu cổng.

### Đổi quy tắc

- **`commit-msg`: commit code gắn `(CHG-###)` giờ đòi `.sdd/gate/CHG-###.ok`**, không chỉ
  đòi thư mục tồn tại. Đây là phần phá vỡ. Nó làm cho `CHG-` đối xứng với `UC-`: cả hai
  đều phải qua cổng trước khi được đụng vào code.

### Sửa

- `close-check.sh` bỏ sót chuỗi nhân giữa các hằng số: `15 * 60 * 1000`, `24 * 60 * 60`,
  `1024 * 1024`. Toán tử nhân không nằm trong nhóm toán tử của bản trước, mà một chuỗi
  như vậy gần như luôn là khoảng thời gian hoặc kích thước — tức tham số nghiệp vụ. Ca
  thật do phiên `runxops` đo được: spec ghi `thời gian khoá = ___` còn code chạy
  `15 * 60 * 1000` và bước soi số literal không hề nêu nó ra. Chỉ nới cho `số * số`,
  không nới sang `+` `-` (`i + 1` nhiều vô kể).

### Cách nâng

```
/plugin marketplace update sdd-solo
/plugin update sdd-solo
/sdd-solo:init --update          # bắt buộc: hook và template nằm trong templates/
```
Rồi với **mỗi** change đang dở (`Status` chưa phải `verified`/`archived`):
```
/sdd-solo:change CHG-###
```
Change nào đã `archived` thì bỏ qua — không còn commit code nào gắn ID đó nữa.

## 2.1.2 — 2026-09-08

### Sửa

- **`commit-msg` chỉ kiểm ID có thật với tiền tố `UC-`** (#15, nặng). Bốn tiền tố còn
  lại — `CHG-` `ADR-` `BR-` `RULE-` — chỉ bị kiểm *hình dạng*: đúng regex là qua.
  `feat(CHG-999): …` với ID bịa hoàn toàn commit được, `feat(ADR-777)`, `feat(BR-888)`,
  `feat(RULE-666)` cũng vậy. Đây là đường vòng ba ký tự quanh lời hứa "không có cờ bỏ
  qua": không cần cờ, chỉ cần đổi `UC` thành `CHG` trong message. Giờ mỗi tiền tố phải
  chứng minh ID tồn tại — `CHG` cần `specs/changes/<ID>-*/`, `ADR` cần file trong
  `specs/internal/adr/`, `RULE` và `BR` cần heading tương ứng trong `specs/rules.md` /
  `specs/br.md`. Không tìm thấy thì chặn và nói rõ chỗ phải tạo.
- **`ls a* b*` trả lỗi nếu *bất kỳ* glob nào không khớp** — nên nhánh `CHG-`/`ADR-`
  vừa viết ở trên chặn nhầm cả ID thật: `specs/changes/CHG-001-…/` có thật, nhưng
  glob đường dẫn 1.x (`changes/CHG-001-*`) không khớp là `ls` exit 1 và hook kết luận
  "ID bịa". Tách thành hai phép thử nối bằng `||`. Cùng họ với bẫy `grep -c || echo 0`
  và command substitution dưới `set -e`: **lệnh thành công một phần vẫn là lệnh thất bại**.
- **`trace-ratio.sh` đếm mọi thứ trông giống ID** (#16, một phần). Chỉ số "commit có
  trace" vì thế đếm luôn cả nhãn dán. Giờ chỉ đếm ID `id_exists()` xác nhận có thật,
  và cảnh báo riêng số commit mang ID không tồn tại ở đâu trong repo.
- `specs/changes/README.md` trỏ `_template/` — đường dẫn 1.x, đã đổi từ 2.0.0. Sửa
  thành `.sdd/templates/change/`.

### Thêm

- `id_exists <ID> <root>` trong `lib.sh` — một chỗ định nghĩa "ID có thật". Githook
  chạy bash trần không nạp `lib.sh` được nên vẫn phải chép logic; hai bản phải đi cùng nhau.

## 2.1.1 — 2026-09-08
Đóng #14 — **2.0.3 chặn sạch `/sdd-solo:init` trên repo trắng, chết im lặng.**

`PV="$(cat "$ROOT/.sdd/version" 2>/dev/null)"` — chốt chặn hạ cấp thêm ở 2.0.3. Dưới `set -e`, một command substitution thất bại ở **vế phải của phép gán** làm thoát ngay. Repo trắng chưa có `.sdd/version` — chính `scaffold` mới là thứ tạo ra nó — nên:

```
2.0.2:  exit=0 · 49 dòng output · 55 file
2.1.0:  exit=1 ·  0 dòng output ·  0 file      ← không một dòng ✗, stderr rỗng
```

Người dùng thấy con trỏ nhảy về và `ls` chỉ có `.git`. Thêm `|| true`.

**Vì sao nó lọt qua khâu kiểm của cả hai bên:** chỉ dính repo **trắng**. Mọi bàn thử đều đã có `.sdd/version` từ bản trước nên `init --update` chạy bình thường; runxops-93 vấp phải vì đang dựng repo trắng để kiểm #13, không phải vì đi tìm nó. Ba bản 2.0.3 → 2.1.0 đều được kiểm trên repo đã cài sẵn.

Quét cả ba script có `set -e` tìm chỗ cùng dạng: `close-pass.sh:8,10,15` và `scaffold.sh:45,62` đều an toàn — chúng là pipeline (mã thoát của `head`/`tr`/`tail`) hoặc đọc file luôn tồn tại trong plugin. Chỉ có đúng một chỗ hỏng.

Kèm: `uc-ready.sh` được chép vào `.sdd/scripts/` cho đủ bộ — runxops-93 hỏi đúng, tuy `gate-check` không gọi nó nên chưa lặp lại #10.

## 2.1.0 — 2026-09-08
Đóng #11 #12 #13 — cả ba do runxops-93 tìm ra khi chạy `/sdd-solo:adversarial` thật. Chủ đề chung: **chốt đo cấu trúc chứ không đo nội dung**.

- **#11 — tiền điều kiện adversarial là chốt tuỳ lượt.** Bốn điều kiện ở `skills/adversarial` bước 2 đếm cấu trúc (có bước Main Flow, có AC, có E#, có dòng Screens) nên **template rỗng qua hết** — mà `/sdd-solo:start` copy chính template đó, nên mọi UC vừa tạo đều lọt. Thêm `scripts/uc-ready.sh`: giữ bốn kiểm cũ, thêm **đếm placeholder** (`<...>`, `___`) và in ra tối đa 8 chỗ. Skill gọi script thay vì tự đánh giá — biến chốt do model thi hành thành kiểm cơ học, đúng như README hứa "chặn cứng".
- **#12 — lời khai `→ spec` không kiểm được.** UC ghi `Q3 … → spec` mà không tạo RULE/AC/E# nào, gate vẫn `✓ adversarial pass đã chạy` rồi QUA CỔNG. Chỗ này **do chính adversarial pass bắt ra** — hai vai độc lập cùng chỉ vào nó. Giờ `→ spec` phải kèm ID (`→ spec: RULE-003`, `→ spec: E4, AC-5`) và `gate-check` kiểm ID đó có thật trong `rules.md` hoặc trong file UC. Thiếu ID cũng là ✗ — lời khai không kiểm được thì không tính là đã làm.
- **#13 — placeholder RULE của template trả lời thay.** `rules.md` phát sẵn `## RULE-001:` và `## RULE-002:` — đúng hai ID dự án đầu tiên chắc chắn dùng tới, nên UC trích `RULE-001` **qua cổng dù chưa ai viết rule nào**; viết rồi thì file có hai heading cùng ID mà gate vẫn `✓`. Đổi ID mẫu sang `RULE-000`/`RULE-000b` cho nhất quán với `UC-000`/`ADR-000`, và `gate-check` giờ bắt cả **ID trùng heading** lẫn **heading còn placeholder**.

Một lỗi tự bắt khi thử: `C="$(grep -cE … || echo 0)"` — `grep -c` in `0` **rồi mới** exit 1, nên `|| echo 0` tạo chuỗi hai dòng và phá cả hai phép so sánh phía sau, khiến ca "không có heading" lại báo `✓`. Fallback đặt sai chỗ còn tệ hơn không có.

## 2.0.3 — 2026-09-08
Đóng #10, và một lỗ cùng họ tự lộ ra khi thử.

- **`deps-check --fix` chết ở bản sao `.sdd/scripts/`** (#10, runxops-93 báo). Nó suy đường dẫn `scaffold.sh` cạnh chỗ nó nằm, mà bản sao **cố ý** không chứa `scaffold.sh` — nên bản sao, đúng thứ README 2.0.0 dạy dùng cho CI, đổ ra `No such file or directory`. Thêm `plugin_script()` trong `lib.sh`: tìm cạnh mình → **bản đang cài theo `installed_plugins.json`** → cùng lắm mới quét cache và lấy version cao nhất. Không thấy thì in `✗` kèm câu nhắc, thoái lui tử tế thay vì để lỗi shell lòi ra.
- **Chặn hạ cấp.** Thử #10 lộ ra: bản vá đầu vơ bừa `scaffold.sh` **1.3.0** trong cache và chạy nó lên một repo đã 2.0 — nó dựng lại nguyên cây 1.x (`checklists/ prompts/ .githooks/ .gitmessage`) cạnh cây 2.x, đúng trạng thái "hai cây" mà 2.0.1 vừa đi chặn. Chốt chặn 2.0.1 chỉ canh chiều tiến (plugin mới trên repo cũ). Giờ `scaffold` cũng từ chối khi `.sdd/version` **mới hơn** version plugin đang chạy.

runxops-93 ghi nhận một chỗ đáng giữ: phần "Kiểm lại sau khi cài" của `deps-check --fix` **không nói dối** — nó chạy lại từ đầu và báo `✗ spec-template vẫn là bản gốc` kèm lệnh sửa, nên #10 chỉ gây phiền chứ không thành một ca hỏng im lặng nữa. Đúng lời hứa "không tin bộ đếm" ở 1.1.0.

## 2.0.2 — 2026-09-08
Đóng #9 — bộ lọc literal của 1.6.0 lọc theo **độ dài chữ số** nên nuốt mất ngưỡng nghiệp vụ một chữ số.

`[0-9]{2,}` quét sạch `graceDays: 7` · `maxRetries: 3` · `otpLength: 6` · `maxDevices: 1` — loại phổ biến nhất. Và nó không im lặng bỏ qua mà **khẳng định sạch**: `✓ không thấy số literal lạ` cộng `ĐÓNG ĐƯỢC (0 cảnh báo)`. Cùng họ với #5, khác ở chỗ nguyên nhân nằm trong bộ lọc chứ không trong phạm vi quét.

Ca do runxops-93 dựng nói đúng vấn đề: dự án test có **RULE-001 "một license một thiết bị"**, con số của rule đó là `1`, code viết `maxDevices: 1` — `close-check` không nhìn thấy con số của chính cái rule nó đi soi.

Lọc theo ngữ cảnh thay vì độ dài: bắt mọi số đứng ngay sau so sánh, `:`, `=`, `,` hoặc `(`; loại chỉ số mảng, biến đếm vòng lặp (`i j k n idx index`), số version. **Bỏ hẳn bộ lọc chuỗi** — pattern vốn không khớp số nằm sau dấu nháy (`log("đã nạp 3 mục")` không dính), và thà dương tính giả: đây là bước ngồi soi cùng user, không phải cổng chặn.

Đo trên mẫu chỉ có số một chữ số: bắt `!== 6` `graceDays: 7` `maxDevices: 1`, vẫn bỏ `list[0]`, `for (let i = 0; i < list.length; i++)`, `n * 2`, `VERSION = "1.4.2"`.

## 2.0.1 — 2026-09-08
Đóng #8 — lỗi nặng nhất của cả đợt, và là lỗi trong **hướng dẫn của chính tôi**.

Làm đúng thứ tự tôi chỉ định (`/sdd-solo:update` rồi `migrate`) thì `scaffold --update` dựng sẵn toàn bộ cây đích bằng template rỗng, migrate thấy đích đã có nên bỏ qua hết, root không đổi, **mọi file nhân đôi và bản có nội dung thật kẹt ở chỗ cũ**. Không một dòng ✗ nào — script in `Xong 3 việc` rồi thoát bình thường. Đúng cơ chế đã vá cho `--dry-run` ở 2.0.0, chỉ khác thủ phạm là bước 1 của quy trình.

Ba lớp, theo đúng thứ tự độ kín mà runxops-2c xếp:

1. **`scaffold` từ chối chạy** khi repo đã cài sdd-solo mà còn dấu vết 1.x (`checklists/definition-of-ready.md`, `prompts/adversarial-pass.md`, `specs/contexts/_template`, `changes/_template`, `.githooks/commit-msg`, `.gitmessage`). Chặn đúng bước người ta hay chạy trước theo thói quen. Không dùng riêng `docs/` làm dấu hiệu — repo có thể có `docs/` của họ.
2. **`migrate` quét trước, dời sau.** Phát hiện "hai cây cùng tồn tại" giờ xảy ra **trước khi đụng file đầu tiên** — bản vá đầu của tôi kêu đúng nhưng dừng giữa chừng, đúng thứ chính tôi viết là trạng thái tệ nhất có thể.
3. **Bỏ cổng `[ ! -d specs/internal ]`** ở khối `docs/` và `changes/`. Đây mới là chỗ im lặng thật: đích tồn tại thì **cả khối** bị bỏ qua, `mv1` không bao giờ được gọi nên không có gì để kêu. Giờ để `mv1` xét từng file.

Kèm: `.sdd/manifest` khử trùng theo đường dẫn sau khi đổi tên, giữ dòng cuối đúng như `scaffold` đọc — nếu không, một đường dẫn có hai dòng và `init --update` có thể ghi đè nhầm. README thêm mục **Nâng cấp 1.x → 2.0.0** với thứ tự đúng.

Đã thử: đường đúng (18 việc, `Postgres` và `RULE-001` theo sang chỗ mới, manifest 0 dòng trùng, `init --update` sau đó chạy được) · `init --update` trên repo 1.x bị chặn, nội dung không suy suyển · repo hai cây thì dừng và **chưa đụng file nào** (so danh sách file trước/sau, khớp tuyệt đối).

## 2.0.0 — 2026-09-08
Gom về hai thư mục như Spec Kit. Đóng #3 và #7. **Bản major — dự án đang chạy phải chạy `migrate-1to2.sh`.**

### Bố cục
```
.sdd/     config gate/ scripts/ hooks/ checklists/ prompts/ templates/ gitmessage version manifest
specs/    br.md rules.md … contexts/  internal/ (từ docs/)  changes/ (từ changes/)
STATE.md  CLAUDE.md  <code>/  <tests>/
```
Root từ 10 mục xuống 4. `_template` rời khỏi cây nội dung nên `ac-coverage` và `status` bỏ được `--exclude-dir`/`-not -path`. Artifact của một UC nằm trọn trong thư mục UC, kể cả `.bpmn` — `gate-check` đọc `$DIR/$ID.bpmn`, không cần dựng lại đường dẫn từ `ctx_of()`; thấy file còn ở chỗ cũ thì bảo chạy migrate.

### Ranh giới đổi có chủ đích
`.sdd/scripts/` giữ **bản sao** script kiểm. Trái với "plugin giữ hành vi" của 1.x, và đã được chấp nhận đổi: cổng DoR giờ chạy được ở CI và trên máy người clone repo, thay vì dừng ở máy tác giả — `.sdd/gate/UC-###.ok` nằm trong repo mà trước đây không ai ngoài tác giả xác minh được. Giá phải trả là bản sao có thể trôi version; `.sdd/version` so với version plugin, lệch thì hook SessionStart và `status` cảnh báo (cơ chế dựng sẵn ở 1.2.0–1.4.0).

### `scripts/migrate-1to2.sh`
`git mv` nên giữ history — đã kiểm `git log --follow` xuyên qua chỗ dời và git ghi nhận `rename … (100%)`. Viết lại `.sdd/manifest` theo đường dẫn mới, đổi `core.hooksPath` và `commit.template`. **Dừng ngay từ đầu nếu working tree bẩn** — dừng giữa chừng ở script dời file là trạng thái tệ nhất. Idempotent. `--dry-run` liệt kê trước.

Ba lỗi tự bắt khi thử: `--dry-run` **có đụng đĩa** (`mkdir` thư mục đích) khiến lần chạy thật bỏ qua `docs/` và `changes/`; nhãn "(thử)" hiện cả khi chạy thật (`${DRY:+…}` với `DRY=0` vẫn khai triển); dry-run liệt kê trùng vì không nhớ thứ đã dời. Ca thiếu `.bpmn.svg` không làm script dừng — đúng cảnh báo của runxops-2c.

### #7 — `gate-pass` tự phá điều kiện qua cổng
`gate-pass` tạo commit `docs(UC-###): spec reviewed — qua cổng DoR` hôm nay, rồi `gate-check` lần sau thấy commit docs mới hôm nay và báo đỏ "spec phải được đọc lại ở một buổi khác". Qua cổng xong thì cổng đỏ liên tục tới hôm sau. Xếp là **lỗi, không phải nới ranh giới**: quy tắc ngủ qua đêm đo việc người sửa spec, còn đây là commit sổ sách của chính script. Chỉ bỏ qua khi commit docs mới nhất **khớp đúng tiêu đề** gate-pass sinh ra — sửa spec thật sau khi qua cổng vẫn phải ngủ lại một đêm.

### Khác
- Githook: dotfile thuần (`.gitmessage`, `.gitignore`) không còn bị coi là file nguồn — 1.6.0 tính `.tên` là có phần mở rộng nên báo nhầm.
- `templates/project` bỏ `src/README.md` và `tests/README.md`: tạo sẵn `src/`+`tests/` là đúng thứ `.sdd/config` sinh ra để thôi đoán.

## 1.6.2 — 2026-09-08
Đóng #6. Gốc là lỗi của `bash` 3.2 trên macOS, không phải của plugin — runxops-2c tìm ra.

```
bash -c 'M=1.6.1; echo "→ $M…"' | od -c
0000000    →  **  **     200 246  \n          ← "1.6.1" bay mất, "…" cụt đầu
```

`echo` của bash 3.2 nuốt cả phép khai triển biến khi nó đứng **ngay trước** một ký tự nhiều byte. Không riêng `…`: `$M→` `$M✓` `$Mà` đều hỏng. Chèn một ký tự ASCII vào giữa là hết. Chỉ hỏng dưới locale UTF-8 — tức đúng môi trường thật của người dùng, sạch dưới `C`/`POSIX`. `printf` và `zsh` không dính.

Khớp mọi dữ kiện từng mâu thuẫn: `is_semver` cho qua và `od -c` sạch vì **biến chưa bao giờ bẩn** — byte chỉ mất lúc `echo` ghi ra; nhánh quyết định luôn đúng vì `vcmp` đọc biến trong bộ nhớ, không qua `echo`; chỉ dòng ② hỏng vì nó là dòng duy nhất có `$MKT` dính `…`. Bảng `version-check` thoát nhờ `printf %-8s` chèn khoảng trắng — 1.2.0 đảo thứ tự vì lý do canh cột, hoá ra chữa luôn chỗ này.

- Dòng ② dùng `printf` nên giữ lại được `②` `→` `…` cho dễ đọc, không phải bỏ.
- Gỡ `od -c` chẩn đoán của 1.6.0.
- Quét cả repo tìm biến dính sát ký tự phi-ASCII trong mọi script và githook: **0 chỗ**. Kiểm động 5 script, không script nào in ra byte hỏng.

Bốn giả thuyết trước đều sai và đều bị bác bỏ bằng thực nghiệm: output ANSI/CR, đọc file viết dở, version cộng đuôi rác, spinner ghi thẳng `/dev/tty` (loại bằng: phiên không có tty mà vẫn hỏng, và dòng in **trước** mọi lệnh `claude` cũng đã hỏng sẵn).

## 1.6.1 — 2026-09-08
- `/sdd-solo:status` nhắc lại `uc_test_dir` chừng nào thư mục còn chưa tồn tại. `!` lúc init đủ cho lần đầu, nhưng từ lần `--update` thứ hai trở đi người ta lướt qua output — mà `ac-coverage` mù thì không tự lộ ra ở đâu khác.

## 1.6.0 — 2026-09-08
Xanh giả trong `close-check`, và ba góp ý của runxops-2c sau khi kiểm 1.5.0. Đóng #5.

- **Thư mục rỗng thắng file thật (#5).** `find -type d` chạy trước và `head -1` cắt phần còn lại, nên `mkdir src/domain/place-order` cạnh `place-order.js` là DoD nhảy từ "1 cảnh báo" sang **"sạch, 0 cảnh báo"**. Thư mục rỗng đó không ai dựng cố ý: `git mv <slug>/index.js <slug>.js` để lại đúng như vậy vì git không theo dõi thư mục rỗng — refactor bình thường là dính. Giờ gộp mọi đường dẫn khớp, quét hết, và **đếm số file thật sự đọc được**: 0 file là "không biết", không phải "sạch".
- **Dòng nhắc Open Question không chạy.** Regex cũ đòi chữ "Open Question" nằm ngay trên dòng gạch đầu dòng, trong khi spec viết nó là tiêu đề mục còn các câu là `- [ ]` bên dưới. Tách làm hai điều kiện.
- **Danh sách đuôi file đổi từ CHO PHÉP sang LOẠI TRỪ.** Danh sách cho phép bỏ sót `.sql` (migration, ràng buộc CHECK), `.sh`, `.tf`, `.ex`, `.scala`, `.dart`, `.lua`… — đúng những chỗ hay chứa số nghiệp vụ. Sai sót giờ nghiêng về chặn nhầm thay vì bỏ lọt. File không có phần mở rộng (Makefile, Dockerfile) không tính, để repo chưa có code không bị chặn oan.
- **`uc_test_dir` là ĐOÁN thì phải nói.** `tests/` · `__tests__/` · `spec/` là ba quy ước khác hẳn nhau; đoán trượt thì `ac-coverage` mù mà không ai biết. Init in `!` khi thư mục test suy ra chưa tồn tại, thay vì ghi lặng vào config.
- Nhãn `trace-ratio` khử trùng đường dẫn (`app, lib, lib` → `app, lib`). `close-check` không còn rỉ `fatal: no commits yet` ở repo mới.

**#6 chưa đóng.** Chuỗi rác ở dòng ② sống sót qua bản vá 1.4.1, và lần này `is_semver` — **neo hai đầu** `^[0-9]+\.[0-9]+\.[0-9]+$` — đã cho qua, `od -c` không in gì. Nghĩa là **biến sạch, hiển thị hỏng**; giả thuyết "version hợp lệ cộng đuôi rác" của 1.4.1 cũng sai. Manh mối còn lại: chỉ dòng có `→` và `…` sát số mới hỏng, còn bảng của `version-check` (version trước, nhãn sau) chưa hỏng lần nào. Bản này bỏ hết ký tự nhiều byte khỏi dòng ② và in `od -c` **vô điều kiện** một lần để lần bump sau có vật chứng thay vì giả thuyết thứ tư.

## 1.5.0 — 2026-09-08
`.sdd/config` — bỏ giả định `src`/`tests`. Đóng #2. Kèm hai lỗi `close-check` do runxops-2c báo.

- **Lỗ chính:** `src|tests` viết chết ở 6 chỗ. Repo đặt code ở `app/` thì `commit-msg` không thấy code nên **cho qua mọi commit không ID, không cần marker gate**, `pre-commit` cho trộn spec với code, hai con số đếm ra `0/0`. Không một dòng cảnh báo. README quảng cáo "không có cờ bỏ qua" — hoá ra không cần cờ, chỉ cần đặt code sai chỗ.
- **`.sdd/config`** sinh một lần lúc init bằng cách dò repo (`src app lib cmd internal pkg apps packages source`), **không** nằm trong `templates/project` nên `init --update` không bao giờ ghi đè — đây là nội dung của dự án. Mặc định `src`/`tests` giữ nguyên hành vi cũ cho repo đang chạy.
- **Githook parse config bằng shell thuần** (`sed -n 's/^key=//p'`), không cần `lib.sh` — hook chạy `bash` trần, không có `${CLAUDE_PLUGIN_ROOT}`.
- **Config sai thì chặn, không chỉ cảnh báo.** Phân biệt "repo chưa có code" với "config sai" bằng chính danh sách file đang stage: có file nguồn mà không thư mục nào trong `code_paths` tồn tại → `✗`, kèm tên file. Có file nguồn nằm ngoài `code_paths` trong khi thư mục vẫn tồn tại → `!`.
- **`0/0` đọc như "sạch" chứ không như "mù".** `trace-ratio` in `? — repo có file nguồn nhưng không commit nào đụng: <paths>`; `ac-coverage` in `?` khi thiếu `uc_test_dir`. `/sdd-solo:status` in mục `=== .sdd/config ===` khi lệch.
- **`close-check`: soi rule ngầm chỉ chạy khi slug là THƯ MỤC.** `src/domain/place-order.js` (file) thì không tìm ra, in `!` rồi đóng được — mà đặt file là cách phổ biến hơn, nên với phần lớn dự án bước này chưa bao giờ chạy. Giờ tìm cả file lẫn thư mục; đã có `feat(UC-###)` mà vẫn không tìm ra thì là `✗`, không phải `!`.
- **`close-check`: grep literal bỏ sót số trong object literal.** Bắt `> 20` nhưng bỏ `holdMinutes: 15` — đúng loại đắt nhất, vì spec ghi Open Question còn code đã âm thầm điền số. Mở rộng sang số sau `:` `,` `(` `=`, trừ chỉ số mảng, số một chữ số, chuỗi và số version. Thêm nhắc khi UC còn Open Question mà code đã có literal.

Cả 4 test của runxops-2c đã chạy lại trên bàn thử layout `app/` + `lib/__tests__/`: test 1 chuyển từ lọt sang chặn, test 2 và 3 chặn đúng, test 4 chuyển từ `0/0` sang `?`.

## 1.4.2 — 2026-09-08
Hai lỗi ở nhánh `--remote`, do session runxops-2c báo.

- **Cache 24h phục vụ số thiu, không có đường thoát.** TTL hợp lý cho người dùng, sai hẳn cho tác giả bump ba lần trong một buổi. Thêm `--no-cache`, và quan trọng hơn: **cache tự biết mình thiu** — nếu bản cục bộ đã vượt số trong cache thì cache chắc chắn cũ, hỏi lại ngay dù còn hạn. Không phải nhớ gõ cờ.
- **`✓ không lệch` mâu thuẫn với bảng nó vừa in.** Khe ① chỉ bắt chiều "GitHub mới hơn"; chiều ngược bị bỏ. Mà chiều ngược có nghĩa thật: **cục bộ mới hơn GitHub = có bản chưa push**. Giờ in `!`. Im ở đây đúng là loại hỏng im lặng mà cả file này sinh ra để chống.
- Chỉ nhận số từ GitHub khi đúng dạng semver, nên không ghi rác vào cache.

Khe ④ của 1.4.0 đã được xác nhận chạy đúng end-to-end trên repo thật: session mới, hook ghi cache, bảng ra đủ bốn dòng có số.

## 1.4.1 — 2026-09-08
Bản vá "chuỗi rác" ở 1.3.0 không giữ được. Lần này tìm ra vì sao, và bịt đúng chỗ nguy hiểm.

- **Glob `[0-9]*.[0-9]*` của 1.3.0 quá lỏng.** Nó CHO QUA `1.4.0<rác>` nên không bao giờ đọc lại. Giá trị hỏng là **version hợp lệ cộng đuôi rác**, không phải rác hoàn toàn — điều đó giải thích trọn bộ triệu chứng: `vcmp 1.3.0 "1.4.0junk"` ra `-1` (vì `awk` tách theo `.` rồi `+0`, nuốt đuôi), nên nhánh update **vẫn chạy và vẫn ra quyết định đúng**, chỉ có dòng in là xấu.
- **Chỗ nguy hiểm không phải dòng in, mà là `vcmp` ăn giá trị không tin được** — lần này quyết định đúng do may. Thêm `is_semver` (neo hai đầu `^[0-9]+\.[0-9]+\.[0-9]+$`) và `clean_ver`; mọi giá trị đi vào so sánh đều lọc trước, không khớp thì thành `-`.
- **`update.sh` không đọc được version marketplace thì bỏ qua bước ②** kèm lệnh làm tay, thay vì đi tiếp. Cùng nguyên tắc "không có dữ liệu thì in `?`, không đoán" của khe ④.
- **Cài dụng cụ đo:** không khớp thì `od -c` ra bytes. Hai giả thuyết trước — output ANSI của `claude plugin`, và đọc trúng file viết dở — đều đã **bác bỏ bằng thực nghiệm** (output không có ESC/CR; file cắt dở cho ra rỗng chứ không ra rác). Nguồn của đuôi rác vẫn chưa biết; lần sau sẽ có bytes để lần.
- `version-check.sh` chỉ nhận version từ GitHub khi đúng dạng semver, nên không ghi rác vào cache 24h.

Lỗi do session runxops-d0 báo về, kèm nhận xét đúng trọng tâm: giá trị hỏng chỉ dùng để in, nhưng nếu `vcmp` cũng ăn nó thì có ngày quyết định sai trong im lặng.

## 1.4.0 — 2026-09-08
Khe thứ tư: phiên Claude Code đang mở. Lỗi do một session khác báo về.

- **`✓ không lệch` từng nói dối đúng lúc nguy hiểm nhất.** Vừa `/plugin update` xong, `.sdd/` đã mới, mọi thứ trên đĩa đều khớp — nhưng phiên đang mở vẫn chạy code nạp lúc mở. Gõ `/sdd-solo:gate` là nhận logic cũ. Bảng cũ không có dòng nào cho chỗ đó.
- **Nhãn cũ "plugin đang chạy" nói quá.** Nó là version của bản mà *script đang nằm trong*, chỉ đúng nghĩa "đang chạy" khi gọi qua skill. Gọi thẳng bằng đường dẫn — như `update.sh` vẫn làm — thì nó là bản mới, trong khi phiên vẫn là bản cũ. Đổi thành **`bản đã cài`**, đọc từ `installed_plugins.json` cho đúng nguồn.
- **Thêm dòng `phiên này đang chạy` và khe ④.** Không lệnh nào sửa được khe này, chỉ mở session mới.
- **Cách biết phiên nạp bản nào:** hook SessionStart chạy *từ* thư mục plugin mà phiên thật sự nạp — chỗ duy nhất biết điều đó — nên nó ghi version ra `${XDG_CACHE_HOME:-~/.cache}/sdd-solo/session-$CLAUDE_CODE_SESSION_ID`, dọn file quá 7 ngày. Không biết thì in `—`, không đoán.
- **`CLAUDE_PLUGIN_ROOT` không phải env var** — nó là token Claude Code thay trong `hooks.json` và `SKILL.md`. `env | grep CLAUDE` không có nó. Đề xuất ban đầu định đọc biến này; dùng `CLAUDE_CODE_SESSION_ID` (có thật trong env) mới chạy được.
- `update.sh` lấy dòng "phiên này đang chạy" từ cùng nguồn, thôi suy từ đường dẫn script.

## 1.3.0 — 2026-09-08
`/sdd-solo:update` — một lệnh thay ba.

- **`scripts/update.sh`** chạy đúng thứ tự và **chỉ những khe đang lệch**: `claude plugin marketplace update` → `claude plugin update` → `scaffold --update`. Cả ba gọi được từ bash nên không cần gõ slash command.
- **Dùng `scaffold.sh` của bản VỪA CÀI, không phải bản đang chạy.** Đường dẫn lấy từ `installed_plugins.json`. Nếu chạy scaffold của bản cũ thì dự án nhận template cũ — đúng thứ mà `/plugin update` rồi `init --update` bằng tay hay dính.
- **Nói thật về giới hạn:** bản mới không áp vào phiên đang mở. Claude Code cũng vậy (`claude plugin update` in sẵn *"restart required to apply"*). Nên cuối script in bảng ba dòng — bản đã cài · `.sdd/` · phiên này đang chạy — và bảo mở session mới.
- Không gọi lại `version-check.sh` ở cuối: sau update thì `.sdd/` mới hơn phiên đang chạy, nó sẽ báo động giả "plugin bị hạ cấp".
- `jver`/`vcmp`/`mkt_of`/`mkt_field` chuyển lên `lib.sh` dùng chung.
- Đọc `marketplace.json` ngay sau khi làm mới clone có lần ra chuỗi rác — nghi đọc trúng lúc file đang được ghi. Kiểm dạng semver, không đúng thì đọc lại một lần.

Đã chạy thật: bản cài 1.0.0 → 1.2.0 trong một lệnh.

## 1.2.0 — 2026-09-08
`version-check.sh` — cảnh báo khi đang chạy bản cũ. Dựng trước 2.0.0 vì bản đó chép `scripts/` vào dự án, cần sẵn cái này để bắt trôi version.

- **Không phải một chỗ lệch mà là chuỗi bốn mắt xích:** `GitHub ──①──▶ marketplace đã tải ──②──▶ plugin đã cài ──③──▶ .sdd/ của dự án`. Mỗi khe một lệnh sửa khác nhau (`/plugin marketplace update` · `/plugin update` · `/sdd-solo:init --update`), nên script chỉ đúng lệnh cho đúng khe thay vì bảo chạy cả ba như CLAUDE.md trước đây.
- **Khe ① không thấy được nếu không hỏi mạng.** Đo trên máy thật: mọi file cục bộ nói "khớp 1.0.0" trong khi GitHub đã có 1.1.0. Nên `--remote` hỏi `raw.githubusercontent.com` (0.6s, chặn cứng bằng `curl --max-time 3` vì macOS không có `timeout(1)`), nhớ kết quả 24h ở `${XDG_CACHE_HOME:-~/.cache}/sdd-solo/remote-check`.
- **Hook SessionStart không bao giờ gọi mạng** — chỉ so ② ③. Hook có `timeout: 10`, mà github.com đã từng timeout 75 giây; một lần như thế là mọi session mở ra đều treo.
- **`gate-check.sh` không gọi version-check.** Cổng DoR đo chất lượng spec; cho version làm rớt cổng là thêm lý do chặn không liên quan tới spec.
- Bắt thêm chiều ngược: `.sdd/` **mới hơn** plugin đang chạy → repo init bằng bản dev, hoặc plugin bị hạ cấp.
- Lệch major in ✗, minor/patch in `!`.
- Đọc metadata từ `installed_plugins.json` và `known_marketplaces.json` của Claude Code thay vì glob mò đường dẫn.
- So semver bằng awk (bash 3.2, đúng cả `1.0.9 < 1.0.10`). Bảng in version trước nhãn sau, vì `printf %-8s` đệm theo byte nên nhãn tiếng Việt có dấu làm lệch cột.

## 1.1.0 — 2026-09-08
`deps-check.sh` và `/sdd-solo:init --with-deps` — mục (a) (b) của #1. Xong #1.

- **`scripts/deps-check.sh`** — kiểm Spec Kit (lệnh `specify`, `.specify/`, spec-template đã thay chưa, đủ 4 lệnh `/speckit-*`), AIUP (`aiup-core` trong cache plugin), Camunda Modeler (chỉ macOS). Mỗi ✗ kèm lệnh copy-paste đúng. Exit 1 nếu thiếu.
  Kiểm được cả **cái bẫy thứ tự**: `.specify/` có nhưng spec-template vẫn là bản gốc → dấu hiệu đã chạy `specify init` SAU `/sdd-solo:init`, mà lần init sau không nhắc lại nữa. Trước đây chỗ này hỏng im lặng.
- **`/sdd-solo:init --with-deps`** — chạy `deps-check.sh --fix`: `specify init` (đủ cờ non-interactive), `claude plugin marketplace add` + `install aiup-core`, rồi tự chạy lại `scaffold --update` để thay spec-template. Sau khi cài thì **tự kiểm lại từ đầu** thay vì tin bộ đếm, nên dòng tổng kết không nói dối. Không có cờ thì hành vi y như cũ: chỉ nhắc, không đụng vào máy — đúng ranh giới trong CLAUDE.md.
  `--fix` không cài lệnh `specify` (cần `uv`), chỉ in `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git`.
- **`/sdd-solo:status`** in mục `=== Phụ thuộc ===` khi thiếu, im khi đủ.
- `trace-ratio.sh`: repo chưa có commit nào thì `git log` in `fatal:` ra stderr giữa output init. Nuốt đi.
- **Đính chính 1.0.1:** mục cuối ghi đã sửa `<github-user>` trong `plugins/sdd-solo/README.md` — thực ra chưa, lệnh sửa nằm sau một bước fail nên không chạy. Sửa ở bản này.

## 1.0.1 — 2026-09-08
Sửa tên lệnh Spec Kit và cách cài phụ thuộc — phần (c) của #1. Không đổi hành vi script.

- **Tên lệnh Spec Kit sai ở 10 file.** Spec Kit 1.0.5 cài skill với tiền tố `speckit-`: `/specify` `/plan` `/tasks` `/implement` thật ra là `/speckit-specify` `/speckit-plan` `/speckit-tasks` `/speckit-implement`. Gõ tên cũ không ra gì.
  Nặng hơn tài liệu: **cả hai tầng chặn mềm đều gọi sai tên nên không chặn được**. `templates/CLAUDE.md.tmpl` và `scripts/session-start.sh` dặn AI "không chạy `/specify` cho UC chưa qua cổng" — user gõ `/speckit-specify`, không khớp danh sách cấm, AI chạy tiếp. Sửa ở: README (2 bản), `CLAUDE.md.tmpl`, `session-start.sh`, `gate-pass.sh`, `skills/` (sdd-process, gate, init), `templates/speckit/spec-template.md`, playbook.
- **URL AIUP không cài được.** `add ai-unified-process/marketplace` sai hoa thường (thật là `AI-Unified-Process`) và dạng `owner/repo` rơi sang SSH → `Permission denied (publickey)` trên máy chưa có SSH key. Đổi sang URL https đầy đủ, và `install aiup-core@ai-unified-process-marketplace`.
- **`specify init --here` treo trong session agent** vì hỏi tương tác. Đổi thành `specify init --here --force --non-interactive --integration claude`.
- **Nói rõ thứ tự bắt buộc:** `specify init` chạy TRƯỚC `/sdd-solo:init --update`. Ngược lại thì spec-template mỏng không được cài, và lần init sau không nhắc lại nữa vì nó chỉ cảnh báo khi thiếu `.specify/` — hỏng im lặng.
- `plugins/sdd-solo/README.md` còn ghi `add <github-user>/sdd-solo` — sửa thành `quangman2211`.

Còn lại của #1: `deps-check.sh` và `--with-deps` (mục a, b) để bản 1.1.0.

## 1.0.0 — 2026-09-07
- Bản đầu: 8 skill (sdd-process, init, start, adversarial, gate, close, state, status), hook SessionStart, git hooks, scaffold có manifest, template dự án, spec-template mỏng cho Spec Kit, playbook mẫu.
