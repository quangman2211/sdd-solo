# Changelog

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
