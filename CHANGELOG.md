# Changelog

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
